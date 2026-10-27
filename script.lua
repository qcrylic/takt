--[[
    Dummies vs Noobs Premium Script – Final Optimized
    qcrylic – All-in-one combat, utility, and automation for Dummies vs Noobs

    This version includes all original 12 improvements plus:
     1. Reused tables in the damage multiplier hook to eliminate per-hit allocations
     2. Immediate HUD position update when cycling in settings
     3. Immediate hold duration feedback (re-schedules fade on slider change)
     4. Periodic cleanup of notification throttle timestamps
     5. Responsive auto-vote loop (detects new vote within 1 sec)
     6. Prompt cache invalidation on descendant removal
     7. NPC count shown in refresh button notification
     8. Persistent killaura status indicator (togglable in HUD settings)
     9. Complete teardown of all background task.spawn threads on re-execution

    Version: 2.2
    Last modified: 2026-10-27
]]

-- Wait for the game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================================================================
-- Teardown: disconnect old connections, close old threads, destroy old GUIs.
-- ============================================================================
do
    if getgenv()._killauraAttackThread then pcall(coroutine.close, getgenv()._killauraAttackThread) end
    if getgenv()._killauraScanThread then pcall(coroutine.close, getgenv()._killauraScanThread) end
    if getgenv()._heartbeatConn then pcall(function() getgenv()._heartbeatConn:Disconnect() end) end
    if getgenv()._inputBeganConn then pcall(function() getgenv()._inputBeganConn:Disconnect() end) end
    if getgenv()._inputEndedConn then pcall(function() getgenv()._inputEndedConn:Disconnect() end) end
    if getgenv()._wsChildAddedConn then pcall(function() getgenv()._wsChildAddedConn:Disconnect() end) end
    if getgenv()._wsChildRemovedConn then pcall(function() getgenv()._wsChildRemovedConn:Disconnect() end) end
    if getgenv()._hudGui then pcall(function() getgenv()._hudGui:Destroy() end) end
    if getgenv()._mobileGui then pcall(function() getgenv()._mobileGui:Destroy() end) end
    if getgenv()._statusGui then pcall(function() getgenv()._statusGui:Destroy() end) end
    
    -- FIX: Close background task.spawn threads to prevent memory leaks on re-execution
    if getgenv()._pdcThread then pcall(coroutine.close, getgenv()._pdcThread) end
    if getgenv()._mercyMouseThread then pcall(coroutine.close, getgenv()._mercyMouseThread) end
    if getgenv()._bolterThread then pcall(coroutine.close, getgenv()._bolterThread) end
    if getgenv()._autoVoteThread then pcall(coroutine.close, getgenv()._autoVoteThread) end
    
    -- FIX: Reset running flags so the new execution actually initializes the loops
    getgenv()._pdcLoopRunning = false
    getgenv()._mercyMouseLoopRunning = false
    getgenv()._bolterLoopRunning = false
    getgenv()._autoVoteLoopRunning = false
end

-- Load external libraries
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/Fluentvv/refs/heads/main/fluent.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Services
local PlayersService, UserInputService, RunService, TweenService, TextService =
    game:GetService("Players"), game:GetService("UserInputService"),
    game:GetService("RunService"), game:GetService("TweenService"), game:GetService("TextService")
local LocalPlayer, Camera = PlayersService.LocalPlayer, workspace.CurrentCamera

-- Mobile UI open button
local DeviceType = UserInputService.TouchEnabled and "Mobile" or "PC"
if DeviceType == "Mobile" then
    local ClickButton = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local ImageLabel = Instance.new("ImageLabel")
    local TextButton = Instance.new("TextButton")
    local UICorner = Instance.new("UICorner")
    local UICorner_2 = Instance.new("UICorner")

    ClickButton.Name = "ClickButton"
    ClickButton.Parent = game.CoreGui
    ClickButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    getgenv()._mobileGui = ClickButton

    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ClickButton
    MainFrame.AnchorPoint = Vector2.new(1, 0)
    MainFrame.BackgroundTransparency = 0.8
    MainFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(1, -60, 0, 10)
    MainFrame.Size = UDim2.new(0, 45, 0, 45)

    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = MainFrame

    UICorner_2.CornerRadius = UDim.new(0, 10)
    UICorner_2.Parent = ImageLabel

    ImageLabel.Parent = MainFrame
    ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    ImageLabel.BorderSizePixel = 0
    ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel.Size = UDim2.new(0, 45, 0, 45)
    ImageLabel.Image = "rbxassetid://"

    TextButton.Parent = MainFrame
    TextButton.BackgroundColor3 = Color3.new(1, 1, 1)
    TextButton.BackgroundTransparency = 1
    TextButton.BorderSizePixel = 0
    TextButton.Position = UDim2.new(0, 0, 0, 0)
    TextButton.Size = UDim2.new(0, 45, 0, 45)
    TextButton.AutoButtonColor = false
    TextButton.Font = Enum.Font.SourceSans
    TextButton.Text = "Open"
    TextButton.TextColor3 = Color3.new(220, 125, 255)
    TextButton.TextSize = 20

    TextButton.MouseButton1Click:Connect(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, "LeftControl", false, game)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, "LeftControl", false, game)
    end)
end

-- ============================================================================
-- Centralized configuration
-- ============================================================================
local CONFIG = {
    tuning = {
        attackBaseDelay = 0.18,
        attackMinDelay = 0.07,
        rescanInterval = 0.3,
        highTargetThreshold = 8,
        lowTargetThreshold = 2,
        forcedRescanInterval = 2,
        burstCap = 150,
        burstDelay = 0.01,
        attributeRefresh = 0.025,
        mercySwings = 3,
        mercyDelay = 0.17,
        bolterDelay = 0.08,
        voteDelay = 1,
        idleVoteDelay = 10,
        landmineDelay = 0.5,
        teleportDelay = 0.1,
        tankDistance = 13,
        defaultDistance = 5.7,
    },
    hud = {
        enabled = true,
        fadeDuration = 1.2,
        holdDuration = 0.4,
        minWidth = 0.34,
        maxWidth = 0.55,
        yPosition = 0.86,
        position = "top-right",
        showStatusIndicator = false,
    },
}

-- Feature toggles (persisted via getgenv().config)
local savedConfig = getgenv().config or {}
local config = {
    killauraEnabled = savedConfig.killauraEnabled or false,
    isTeleportEnabled = savedConfig.isTeleportEnabled or false,
    shouldDestroyLandmines = savedConfig.shouldDestroyLandmines or false,
    isMercyKillEnabled = savedConfig.isMercyKillEnabled or false,
    isMercyKillMouseEnabled = savedConfig.isMercyKillMouseEnabled or false,
    isBolterCoinHitEnabled = savedConfig.isBolterCoinHitEnabled or false,
    isAutoVoteEnabled = savedConfig.isAutoVoteEnabled or false,
    isPDCChargesEnabled = savedConfig.isPDCChargesEnabled or false,
    isSuperWeaponsEnabled = savedConfig.isSuperWeaponsEnabled or false,
    hud = savedConfig.hud or CONFIG.hud,
}
getgenv().config = config

-- Exclusion lists
local EXCLUDED = { Landmine=1, Man=1, Turret=1, Stonehenge=1, Sprayer=1, Sentinel=1, Refugee=1,
    PDC=1, MADS=1, Lifeline=1, Hallucinator=1, Governor=1, FAST_point=1, Barrier=1, Administrator=1, Nuke=1 }
local NOT_TELEPORTABLE = { Platform=1, Hermes=1 }
for i = 1, 11 do if i ~= 8 then EXCLUDED["dead guy " .. i] = 1 end end

-- Shared input state
getgenv()._semiDown = false
getgenv()._qDown = false

-- ============================================================================
-- Runtime state
-- ============================================================================
local cachedWeapon, lastScanTime, killauraActive, killauraAttackThread, killauraScanThread = nil, 0, false, nil, nil
local swingCounter, mercyBusy = 0, false
local metatableModified, gameMetatable, originalNamecall, savedHook = false, nil, nil, nil
local currentTargetHumanoid, targetLocked, isBursting = nil, false, false

-- ============================================================================
-- Double‑buffered NPC cache
-- ============================================================================
local npcBufA, npcBufB = {}, {}
local npcCache = npcBufA
local useBufA = true
local npcStale = true

-- ============================================================================
-- Notification throttle helper
-- ============================================================================
local notificationThrottleTimestamps = {}
local function notifyThrottled(message, interval)
    local now = tick()
    local last = notificationThrottleTimestamps[message]
    if not last or now - last >= (interval or 10) then
        notificationThrottleTimestamps[message] = now
        Fluent:Notify({Title = "System", Content = message, Duration = 5})
    end
end

-- Background cleanup of throttle timestamps
task.spawn(function()
    while true do
        task.wait(60)
        local now = tick()
        for msg, ts in pairs(notificationThrottleTimestamps) do
            if now - ts > 120 then
                notificationThrottleTimestamps[msg] = nil
            end
        end
    end
end)

-- ============================================================================
-- Utility helpers
-- ============================================================================
local function notify(title, content, duration) Fluent:Notify({Title=title, Content=content, Duration=duration or 5}) end
local function getLocalPlayerHRP() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end
local function isHoldingTool() local character = LocalPlayer.Character return character and character:FindFirstChildOfClass("Tool") ~= nil end

-- Raycast for mouse position
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { Camera }
local function getMouseWorldPosition()
    local mouseLocation = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
    local hit = workspace:Raycast(Camera.CFrame.Position, ray.Direction * 1000, rayParams)
    return hit and hit.Position
end

local function generateSwingToken() swingCounter = swingCounter + 1 return "sweep_" .. swingCounter .. "_" .. math.random(1000, 9999) end
local function getLiveHumanoid(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then return hum end
end

-- Workspace child tracking
getgenv()._wsChildAddedConn = workspace.ChildAdded:Connect(function(c)
    if c:IsA("Model") then npcStale = true end
end)
getgenv()._wsChildRemovedConn = workspace.ChildRemoved:Connect(function(c)
    if c:IsA("Model") then npcStale = true end
end)

-- ============================================================================
-- NPC Cache helpers
-- ============================================================================
local function cacheAddTarget(staging, model, humanoid)
    if not humanoid then return false end
    humanoid.Died:Once(function() npcStale = true end)
    staging[#staging+1] = {model=model, target=humanoid}
    return true
end

local function scanModelChildren(staging, parent, model, pattern)
    local foundAny = false
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Model") and string.match(child.Name, pattern) and cacheAddTarget(staging, model, getLiveHumanoid(child)) then
            foundAny = true
        end
    end
    return foundAny
end

local function scanNPCs(force)
    if not force and not npcStale then return npcCache end

    local staging = useBufA and npcBufB or npcBufA
    table.clear(staging)
    local children = workspace:GetChildren()

    for _, model in ipairs(children) do
        if not model:IsA("Model") then continue end
        if PlayersService:GetPlayerFromCharacter(model) then continue end

        local name = model.Name

        if name == "Hermes" then
            if not scanModelChildren(staging, model, model, "^Launcher%d+$") then
                cacheAddTarget(staging, model, getLiveHumanoid(model))
            end
        elseif name == "Drone" then
            cacheAddTarget(staging, model, getLiveHumanoid(model))
        elseif EXCLUDED[name] then continue
        elseif name ~= "Model" and name ~= "Folder" then
            if name == "Platform" then
                local found = false
                for _, child in ipairs(model:GetDescendants()) do
                    if child:IsA("Model") and string.match(child.Name, "^Emplacement%d+$") then
                        if cacheAddTarget(staging, model, getLiveHumanoid(child)) then found = true end
                    end
                end
                if not found then cacheAddTarget(staging, model, getLiveHumanoid(model)) end
            elseif name == "Tank" then
                if not scanModelChildren(staging, model, model, "^PropaneTank$") then
                    cacheAddTarget(staging, model, getLiveHumanoid(model))
                end
            elseif name == "APU" then
                cacheAddTarget(staging, model, getLiveHumanoid(model:FindFirstChild("Pilot")) or getLiveHumanoid(model))
            else
                cacheAddTarget(staging, model, getLiveHumanoid(model))
            end
        end
    end

    npcCache = staging
    useBufA = not useBufA
    npcStale = false

    if _G.killauraDebug then
        local names = {}
        for _, e in ipairs(staging) do names[#names+1] = e.model.Name end
        print("[killaura] cache (" .. #staging .. "): " .. table.concat(names, ", "))
    end
    return npcCache
end

-- ============================================================================
-- Teleport NPCs
-- ============================================================================
local function bringNPCs()
    local hrp = getLocalPlayerHRP() if not hrp then return end
    local forward = hrp.CFrame.LookVector
    local yaw = hrp.Orientation.Y
    for _, entry in ipairs(scanNPCs(false)) do
        if entry.target.Parent and entry.target.Health > 0 and not NOT_TELEPORTABLE[entry.model.Name] then
            local primaryPart = entry.model.PrimaryPart or entry.model:FindFirstChild("HumanoidRootPart")
            if primaryPart then
                local distance = entry.model.Name == "Tank" and CONFIG.tuning.tankDistance or CONFIG.tuning.defaultDistance
                pcall(function()
                    entry.model:PivotTo(CFrame.new(hrp.Position + forward * distance) * CFrame.Angles(0, math.rad(yaw), 0))
                end)
            end
        end
    end
end

-- ============================================================================
-- Landmine destruction
-- ============================================================================
local function destroyLandmines()
    local any
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Landmine" then obj:Destroy(); any = true end
    end
    if any then notify("System", "Landmine cleared", 4) end
end

-- ============================================================================
-- Proximity prompt fire
-- ============================================================================
local promptCache = {}
local function firePrompt(promptName)
    local cached = promptCache[promptName]
    if cached and cached.Parent then
        pcall(fireproximityprompt, cached)
        return
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and string.find(obj.ObjectText or "", promptName, 1, true) then
            promptCache[promptName] = obj
            pcall(fireproximityprompt, obj)
            return
        end
    end
    notify("Automation Error", "Prompt not found: " .. promptName, 4)
end

workspace.DescendantRemoving:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        for name, prompt in pairs(promptCache) do
            if prompt == descendant then
                promptCache[name] = nil
            end
        end
    end
end)

-- ============================================================================
-- Weapon detection
-- ============================================================================
local function refreshWeapon()
    if cachedWeapon and cachedWeapon.Parent and cachedWeapon.Parent == LocalPlayer.Character then
        return cachedWeapon
    end
    local function findWeaponIn(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and (tool:GetAttribute("Class") == "Melee" or tool.Name == "Shovel") then
                local vh = tool:FindFirstChild("VerifyHit")
                if vh and vh:IsA("RemoteEvent") then return tool end
            end
        end
    end
    cachedWeapon = findWeaponIn(LocalPlayer.Character) or findWeaponIn(LocalPlayer:FindFirstChild("Backpack"))
    if not cachedWeapon then
        notifyThrottled("Melee weapon not found – equip a shovel or melee tool.", 10)
    end
    return cachedWeapon
end

-- ============================================================================
-- Attack interval calculation
-- ============================================================================
local function calculateAttackInterval(targetCount)
    if targetCount == 0 then return CONFIG.tuning.rescanInterval end
    if targetCount <= CONFIG.tuning.lowTargetThreshold then return CONFIG.tuning.attackMinDelay end
    if targetCount >= CONFIG.tuning.highTargetThreshold then return CONFIG.tuning.attackBaseDelay end
    return CONFIG.tuning.attackMinDelay +
        (CONFIG.tuning.attackBaseDelay - CONFIG.tuning.attackMinDelay) *
        ((targetCount - CONFIG.tuning.lowTargetThreshold) / (CONFIG.tuning.highTargetThreshold - CONFIG.tuning.lowTargetThreshold))
end

-- ============================================================================
-- HUD display
-- ============================================================================
local DISPLAY = { Tank="Tank", Drone="Drone", Hermes="Hermes", APU="APU", Platform="Platform", Man="Infantry",
    Turret="Turret", Launcher1="Launcher I", Launcher2="Launcher II", Launcher3="Launcher III",
    Launcher4="Launcher IV", Emplacement1="Emplacement", PropaneTank="Propane Weakpoint" }
local COLORS = {
    Launcher1=Color3.fromRGB(255,70,70), Launcher2=Color3.fromRGB(255,70,70),
    Launcher3=Color3.fromRGB(255,70,70), Launcher4=Color3.fromRGB(255,70,70),
    Hermes=Color3.fromRGB(255,70,70), APU=Color3.fromRGB(255,140,50),
    Drone=Color3.fromRGB(255,200,80), Emplacement1=Color3.fromRGB(255,200,80),
    Tank=Color3.fromRGB(220,220,230), Platform=Color3.fromRGB(220,220,230) }
local DEFAULT_COLOR = Color3.fromRGB(255,255,255)
local ORDERED_TYPES = { "Launcher1","Launcher2","Launcher3","Launcher4","Hermes","APU","Drone",
    "Emplacement1","Tank","Platform","Man","Turret","PropaneTank" }
local orderedSet = {} for _, t in ipairs(ORDERED_TYPES) do orderedSet[t] = true end

local hudGui, hudContainer, hudBackground, hudLabel, hudHideTask, hudShown, hudFadeTween

local function initHUD()
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "KillauraHUD"
    hudGui.ResetOnSpawn = false
    hudGui.DisplayOrder = 100
    hudGui.Parent = game:GetService("CoreGui")
    getgenv()._hudGui = hudGui

    hudContainer = Instance.new("Frame")
    hudContainer.BackgroundTransparency = 1
    hudContainer.AutomaticSize = Enum.AutomaticSize.Y
    hudContainer.Parent = hudGui

    hudBackground = Instance.new("Frame")
    hudBackground.BackgroundColor3 = Color3.fromRGB(12,12,18)
    hudBackground.BorderSizePixel = 0
    hudBackground.AutomaticSize = Enum.AutomaticSize.Y
    hudBackground.Size = UDim2.new(1,0,0,0)
    hudBackground.Parent = hudContainer
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,6); corner.Parent = hudBackground
    local padding = Instance.new("UIPadding")
    padding.PaddingTop, padding.PaddingBottom, padding.PaddingLeft, padding.PaddingRight =
        UDim.new(0,8), UDim.new(0,8), UDim.new(0,12), UDim.new(0,12)
    padding.Parent = hudBackground

    hudLabel = Instance.new("TextLabel")
    hudLabel.BackgroundTransparency = 1
    hudLabel.Font = Enum.Font.GothamMedium
    hudLabel.TextSize = 14
    hudLabel.TextXAlignment = Enum.TextXAlignment.Right
    hudLabel.RichText = true
    hudLabel.Text = ""
    hudLabel.AutomaticSize = Enum.AutomaticSize.Y
    hudLabel.Size = UDim2.new(1,0,0,0)
    hudLabel.Parent = hudBackground
end

local function formatLine(typeName, count)
    local col = COLORS[typeName] or DEFAULT_COLOR
    return string.format("<font color='rgb(%d,%d,%d)'>%s  x%d</font>",
        math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255),
        DISPLAY[typeName] or typeName, count)
end

local function applyHUDPosition()
    local pos = config.hud.position or "top-right"
    local anchorX, anchorY, px, py, yOffset

    if pos == "top-right" then
        anchorX, anchorY, px, py = 1, 0, 1, 0
        yOffset = config.hud.yPosition or 0.86
    elseif pos == "bottom-right" then
        anchorX, anchorY, px, py = 1, 1, 1, -10
        yOffset = 1
    elseif pos == "top-left" then
        anchorX, anchorY, px, py = 0, 0, 0, 10
        yOffset = config.hud.yPosition or 0.86
    elseif pos == "bottom-left" then
        anchorX, anchorY, px, py = 0, 1, 0, 10
        yOffset = 1
    else
        anchorX, anchorY, px, py = 1, 0, 1, 0
        yOffset = config.hud.yPosition or 0.86
    end

    if hudContainer then
        hudContainer.AnchorPoint = Vector2.new(anchorX, anchorY)
        hudContainer.Position = UDim2.new(px, 0, yOffset, 0)
    end
end

local function showHUD(counts)
    if not config.hud.enabled then return end
    if not hudGui then initHUD() end
    applyHUDPosition()

    local total = 0
    local lines = { "<b><font size='12'>KILLAURA</font></b>" }
    for _, typeName in ipairs(ORDERED_TYPES) do
        local cnt = counts[typeName]
        if cnt and cnt > 0 then total = total + cnt; lines[#lines+1] = formatLine(typeName, cnt) end
    end
    for typeName, cnt in pairs(counts) do
        if not orderedSet[typeName] and cnt > 0 then total = total + cnt; lines[#lines+1] = formatLine(typeName, cnt) end
    end
    lines[#lines+1] = string.format("<b><font size='13'>Total: %d target%s</font></b>", total, total==1 and "" or "s")
    hudLabel.Text = table.concat(lines, "\n")

    local viewportSize = Camera.ViewportSize
    local stripped = hudLabel.Text:gsub("<[^>]+>", "")
    local textWidth = TextService:GetTextSize(stripped, 14, Enum.Font.GothamMedium, Vector2.new(math.huge, math.huge)).X
    local containerWidth = math.clamp((textWidth + 24) / viewportSize.X, config.hud.minWidth, config.hud.maxWidth)
    hudContainer.Size = UDim2.new(containerWidth, 0, 0, 0)

    if hudHideTask then task.cancel(hudHideTask); hudHideTask = nil end
    if hudFadeTween then hudFadeTween:Cancel(); hudFadeTween = nil end
    if not hudShown then
        hudShown = true
        hudBackground.Visible = true
    end
    hudBackground.BackgroundTransparency = 0.2

    hudHideTask = task.delay(config.hud.holdDuration, function()
        if not hudShown or not hudGui or not hudGui.Parent then return end
        hudFadeTween = TweenService:Create(hudBackground,
            TweenInfo.new(config.hud.fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1})
        hudFadeTween:Play()
        hudFadeTween.Completed:Once(function()
            hudShown = false
            hudBackground.Visible = false
            hudFadeTween = nil
        end)
    end)
end

-- ============================================================================
-- Persistent killaura status indicator
-- ============================================================================
local statusGui, statusLabel
local function updateStatusIndicator()
    if not config.hud.showStatusIndicator then
        if statusGui then statusGui:Destroy(); statusGui = nil end
        return
    end
    if not statusGui then
        statusGui = Instance.new("ScreenGui")
        statusGui.Name = "KAStatus"
        statusGui.ResetOnSpawn = false
        statusGui.DisplayOrder = 99
        statusGui.Parent = game:GetService("CoreGui")
        getgenv()._statusGui = statusGui

        statusLabel = Instance.new("TextLabel")
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextSize = 18
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusLabel.TextXAlignment = Enum.TextXAlignment.Center
        statusLabel.Text = "KA OFF"
        statusLabel.Position = UDim2.new(0.5, 0, 0, 10)
        statusLabel.AnchorPoint = Vector2.new(0.5, 0)
        statusLabel.AutomaticSize = Enum.AutomaticSize.XY
        statusLabel.Parent = statusGui
    end
    if killauraActive then
        statusLabel.Text = "KA ON"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        statusLabel.Text = "KA OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function setKillauraActive(state)
    killauraActive = state
    updateStatusIndicator()
end

-- ============================================================================
-- Killaura attack logic
-- ============================================================================
local consecutiveFireFailures = 0
local lastFailurePauseTime = 0
local function attackBatch(targets)
    if #targets == 0 or not isHoldingTool() then return 0 end
    local weapon = refreshWeapon() if not weapon then return 0 end
    local verifyHitRemote = weapon:FindFirstChild("VerifyHit")
    if not verifyHitRemote or not verifyHitRemote:IsA("RemoteEvent") or not verifyHitRemote.Parent then
        cachedWeapon = nil
        return 0
    end
    local swingToken = generateSwingToken()
    local counts, fired = {}, 0
    for i = 1, #targets do
        if not killauraActive then break end
        local entry = targets[i]
        local hum = entry.target
        if hum.Parent and hum.Health > 0 and entry.model.Parent then
            local success, err = pcall(function() verifyHitRemote:FireServer(hum, swingToken) end)
            if success then
                consecutiveFireFailures = 0
                local modelName = entry.model.Name
                counts[modelName] = (counts[modelName] or 0) + 1
                fired = fired + 1
            else
                consecutiveFireFailures = consecutiveFireFailures + 1
                if consecutiveFireFailures > 10 and tick() - lastFailurePauseTime > 2 then
                    lastFailurePauseTime = tick()
                    notifyThrottled("Killaura FireServer failing – pausing attacks for 2s", 10)
                    task.wait(2)
                    consecutiveFireFailures = 0
                end
            end
        end
    end
    if next(counts) then showHUD(counts) end
    return fired
end

-- ============================================================================
-- Damage multiplier hook
-- ============================================================================
local function resetBurstState() currentTargetHumanoid, targetLocked, isBursting = nil, false, false end

local function cleanupMultiplier()
    if not metatableModified then return end
    pcall(function()
        setreadonly(gameMetatable, false)
        if gameMetatable.__namecall == savedHook then gameMetatable.__namecall = originalNamecall end
        setreadonly(gameMetatable, true)
    end)
    resetBurstState()
    metatableModified = false
end

local function setupMultiplier()
    if metatableModified then cleanupMultiplier() end
    pcall(function()
        gameMetatable = getrawmetatable(game)
        setreadonly(gameMetatable, false)
        originalNamecall = gameMetatable.__namecall

        savedHook = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if _G.multiplier and method == "FireServer" and tostring(self) == "VerifyHit"
                and LocalPlayer.Character and self:IsDescendantOf(LocalPlayer.Character) then
                local targetHumanoid = ...
                if targetHumanoid and targetHumanoid:IsA("Humanoid") and (not isBursting or currentTargetHumanoid ~= targetHumanoid) then
                    local origArgs = { ... }
                    currentTargetHumanoid, targetLocked, isBursting = targetHumanoid, true, true
                    local jitteredArgs = {}
                    task.spawn(function()
                        local iteration = 1
                        local active = currentTargetHumanoid
                        while targetLocked and active == currentTargetHumanoid do
                            if not LocalPlayer.Character or not self:IsDescendantOf(LocalPlayer.Character) then
                                if active == currentTargetHumanoid then resetBurstState() end break
                            end
                            if not active.Parent or active.Health <= 0 then
                                if active == currentTargetHumanoid then resetBurstState() end break
                            end
                            iteration = iteration + 1
                            pcall(function()
                                local pos = origArgs[3]
                                if typeof(pos) == "Vector3" then
                                    local jitter = 0.01
                                    local jitteredPos = Vector3.new(
                                        pos.X + math.random()*jitter - jitter/2,
                                        pos.Y + math.random()*jitter - jitter/2,
                                        pos.Z + math.random()*jitter - jitter/2)
                                    table.clear(jitteredArgs)
                                    jitteredArgs[1] = origArgs[1]
                                    jitteredArgs[2] = origArgs[2]
                                    jitteredArgs[3] = jitteredPos
                                    for j = 4, #origArgs do
                                        jitteredArgs[j] = origArgs[j]
                                    end
                                    self.FireServer(self, unpack(jitteredArgs))
                                else
                                    self.FireServer(self, unpack(origArgs))
                                end
                            end)
                            if iteration > CONFIG.tuning.burstCap then
                                if active == currentTargetHumanoid then resetBurstState() end break
                            end
                            task.wait(CONFIG.tuning.burstDelay)
                        end
                    end)
                end
            end
            return originalNamecall(self, ...)
        end)
        gameMetatable.__namecall = savedHook
        setreadonly(gameMetatable, true)
        metatableModified = true
    end)
end

-- ============================================================================
-- PDC / Super weapons attribute loop
-- ============================================================================
getgenv()._pdcThread = task.spawn(function()
    if getgenv()._pdcLoopRunning then return end
    getgenv()._pdcLoopRunning = true
    while true do
        if config.isPDCChargesEnabled or config.isSuperWeaponsEnabled then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                if config.isPDCChargesEnabled and tool.Name == "PDC kit" then
                    tool:SetAttribute("Charges", 999); tool:SetAttribute("MaxCharges", 999)
                    tool:SetAttribute("Cooldown", 0.1); tool:SetAttribute("AutoReload", true)
                    tool:SetAttribute("ContinuousFire", true); tool:SetAttribute("Unlimited", true)
                elseif config.isSuperWeaponsEnabled and tool.Name ~= "RPG" and tool.Name ~= "Parabolic Hydra"
                    and tool.Name ~= "Grenade Launcher" and tool.Name ~= "PDC kit" then
                    tool:SetAttribute("Ammo", 999)
                end
            end
        end
        task.wait(CONFIG.tuning.attributeRefresh)
    end
end)

-- ============================================================================
-- Mercy Kill
-- ============================================================================
local function findMercyTool()
    return (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Mercy Kill"))
        or LocalPlayer.Backpack:FindFirstChild("Mercy Kill")
end

getgenv()._inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Semicolon then
        getgenv()._semiDown = true
        if config.isMercyKillEnabled and not config.isMercyKillMouseEnabled and not mercyBusy then
            local hrp, mercyTool = getLocalPlayerHRP(), findMercyTool()
            if hrp and mercyTool then
                mercyBusy = true
                task.spawn(function()
                    pcall(function()
                        for _ = 1, CONFIG.tuning.mercySwings do
                            if not getgenv()._semiDown then return end
                            mercyTool.VerifyHit:FireServer(nil, hrp.Position)
                            task.wait(CONFIG.tuning.mercyDelay)
                        end
                    end)
                    mercyBusy = false
                end)
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Q then getgenv()._qDown = true end
end)

getgenv()._inputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Semicolon then getgenv()._semiDown = false
    elseif input.KeyCode == Enum.KeyCode.Q then getgenv()._qDown = false end
end)

getgenv()._mercyMouseThread = task.spawn(function()
    if getgenv()._mercyMouseLoopRunning then return end
    getgenv()._mercyMouseLoopRunning = true
    while true do
        if config.isMercyKillMouseEnabled and getgenv()._semiDown then
            local pos, mercyTool = getMouseWorldPosition(), findMercyTool()
            if pos and mercyTool then mercyTool.VerifyHit:FireServer(nil, pos) end
        end
        task.wait(0.1)
    end
end)

-- ============================================================================
-- Bolter Coin Hit
-- ============================================================================
getgenv()._bolterThread = task.spawn(function()
    if getgenv()._bolterLoopRunning then return end
    getgenv()._bolterLoopRunning = true
    while true do
        if config.isBolterCoinHitEnabled and getgenv()._qDown then
            local pos = getMouseWorldPosition()
            local playerModel = workspace:FindFirstChild(LocalPlayer.Name)
            local bolter = playerModel and playerModel:FindFirstChild("Bolter")
            if pos and bolter and bolter:FindFirstChild("VerifyCoinHit") then
                bolter.VerifyCoinHit:FireServer(pos)
            end
        end
        task.wait(CONFIG.tuning.bolterDelay)
    end
end)

-- ============================================================================
-- Auto Vote Waves
-- ============================================================================
getgenv()._autoVoteThread = task.spawn(function()
    if getgenv()._autoVoteLoopRunning then return end
    getgenv()._autoVoteLoopRunning = true
    while true do
        if config.isAutoVoteEnabled then
            local found = false
            for i = 1, CONFIG.tuning.idleVoteDelay do
                if not config.isAutoVoteEnabled then break end
                local vote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                if vote then vote = vote:FindFirstChild("Waves") end
                if vote then vote = vote:FindFirstChild("Vote") end
                if vote then
                    pcall(function() vote:InvokeServer() end)
                    found = true
                    break
                end
                task.wait(1)
            end
            if found then
                task.wait(CONFIG.tuning.voteDelay)
            end
        else
            task.wait(1)
        end
    end
end)

-- ============================================================================
-- Heartbeat: teleport & landmine destruction
-- ============================================================================
local teleportTimer, landmineTimer = 0, 0
getgenv()._heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
    if config.isTeleportEnabled then
        teleportTimer = teleportTimer + deltaTime
        if teleportTimer >= CONFIG.tuning.teleportDelay then
            teleportTimer = 0
            bringNPCs()
        end
    end
    if config.shouldDestroyLandmines then
        landmineTimer = landmineTimer + deltaTime
        if landmineTimer >= CONFIG.tuning.landmineDelay then
            landmineTimer = 0
            destroyLandmines()
        end
    end
end)

-- ============================================================================
-- Fluent UI
-- ============================================================================
local Window = Fluent:CreateWindow({
    Title = "Dummies Versus Noobs | qcrylic - Premium", SubTitle = "@qcrylic", TabWidth = 160,
    Size = UDim2.fromOffset(580, 460), Acrylic = false, Theme = "Aqua",
    MinimizeKey = Enum.KeyCode.LeftControl,
})
local Tabs = {
    Main      = Window:AddTab({Title="Main",      Icon="list"}),
    Combat    = Window:AddTab({Title="Combat",    Icon="sword"}),
    Targeting = Window:AddTab({Title="Targeting", Icon="target"}),
    Utility   = Window:AddTab({Title="Utility",   Icon="plus-circle"}),
    Settings  = Window:AddTab({Title="Settings",  Icon="settings"}),
}
SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentScriptHub"); SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)

local function toggle(tab, name, title, cb)
    tab:AddToggle(name, {Title=title, Default=false}):OnChanged(cb)
end

toggle(Tabs.Main, "KillauraToggle", "Killaura", function(v)
    setKillauraActive(v)
    config.killauraEnabled = v
    if v then
        if killauraAttackThread then pcall(coroutine.close, killauraAttackThread); killauraAttackThread = nil end
        if killauraScanThread then pcall(coroutine.close, killauraScanThread); killauraScanThread = nil end

        killauraScanThread = coroutine.create(function()
            while killauraActive do
                scanNPCs(true)
                lastScanTime = tick()
                task.wait(CONFIG.tuning.forcedRescanInterval)
            end
        end)
        getgenv()._killauraScanThread = killauraScanThread
        coroutine.resume(killauraScanThread)

        killauraAttackThread = coroutine.create(function()
            while killauraActive do
                local fired = attackBatch(npcCache) or 0
                task.wait(calculateAttackInterval(fired))
            end
        end)
        getgenv()._killauraAttackThread = killauraAttackThread
        coroutine.resume(killauraAttackThread)
    else
        if killauraScanThread then pcall(coroutine.close, killauraScanThread); killauraScanThread = nil end
        if killauraAttackThread then pcall(coroutine.close, killauraAttackThread); killauraAttackThread = nil end
        getgenv()._killauraScanThread = nil; getgenv()._killauraAttackThread = nil
        npcCache, lastScanTime, cachedWeapon = {}, 0, nil
    end
end)

toggle(Tabs.Main, "BringNPCsToggle", "Bring NPCs", function(v) config.isTeleportEnabled = v end)

toggle(Tabs.Main, "AutoVoteToggle", "Auto Vote Waves", function(v) config.isAutoVoteEnabled = v end)

local mercyToggle = Tabs.Combat:AddToggle("MercyKillToggle", {Title="Mercy Kill", Default=false})
local mouseMercyToggle = Tabs.Combat:AddToggle("MouseMercyKillToggle", {Title="Mercy Kill (Mouse)", Default=false})

mercyToggle:OnChanged(function(v)
    config.isMercyKillEnabled = v
    if v and config.isMercyKillMouseEnabled then
        config.isMercyKillMouseEnabled = false
        mouseMercyToggle:SetValue(false)
    end
end)

mouseMercyToggle:OnChanged(function(v)
    config.isMercyKillMouseEnabled = v
    if v then
        if config.isMercyKillEnabled then
            config.isMercyKillEnabled = false
            mercyToggle:SetValue(false)
        end
        notify("Mercy Kill (Mouse)", "Hold semicolon to fire at mouse", 4)
    end
end)

toggle(Tabs.Combat, "DamageMultiplierToggle", "Damage Multiplier",
    function(v) _G.multiplier = v; if v then setupMultiplier() else cleanupMultiplier() end end)

toggle(Tabs.Combat, "PDCChargesToggle", "Infinite PDC", function(v) config.isPDCChargesEnabled = v end)

toggle(Tabs.Combat, "SuperWeaponsToggle", "Infinite Ammo", function(v) config.isSuperWeaponsEnabled = v end)

Tabs.Combat:AddParagraph({Title = "Shortcuts", Content = "Hold [;] for Mercy Kill (targeted)  |  Hold [Q] for Bolter Coin Hit"})

Tabs.Targeting:AddSection("NPC Management")
Tabs.Targeting:AddButton({Title="Refresh NPC Cache", Description="Force refresh the NPC detection cache", Callback=function()
    local npcCount = #scanNPCs(true)
    notify("System", "NPC cache refreshed (" .. npcCount .. " NPCs)", 3)
end})

Tabs.Targeting:AddButton({Title="Spawn Noob Units", Description="Spawns all standard noob units to workspace", Callback=function()
    local ex = {Dreadnought=1, ["Achilles(ht)"]=1, Sparchilles=1, APU=1, APU_Operator=1, Hermes=1, Achilles=1, Confidant=1, London=1, Tank=1, Platform=1, Man=1, MangleNether345=1, MegaJoe=1, Administrator=1}
    local count = 0
    for _, v in ipairs(game:GetService("ReplicatedStorage").Units.Noobs:GetChildren()) do
        if not ex[v.Name] then
            v.Parent = workspace
            count = count + 1
        end
    end
    notify("Spawn Noob Units", "Spawned " .. count .. " unit" .. (count==1 and "" or "s"), 4)
end})

toggle(Tabs.Utility, "LandmineToggle", "Destroy Landmines", function(v) config.shouldDestroyLandmines = v end)

toggle(Tabs.Utility, "BolterCoinToggle", "Bolter Coin Hit (Hold Q)", function(v) config.isBolterCoinHitEnabled = v end)

Tabs.Utility:AddSection("Teleportation")
Tabs.Utility:AddButton({Title="Teleport to Lobby", Description="Teleports to lobby ingame", Callback=function()
    local hrp = getLocalPlayerHRP()
    if hrp then hrp.CFrame = CFrame.new(-3, -101.5, -12.5); notify("System", "Teleported to lobby", 4) end
end})

Tabs.Utility:AddButton({Title="Teleport to Map", Description="Teleports player to map", Callback=function()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        local sp = workspace.Map and workspace.Map.PlayerSpawns and workspace.Map.PlayerSpawns.SpawnLocation
        if hrp and sp then hrp.CFrame = sp.CFrame + Vector3.new(0, 3, 0); notify("System", "Teleported to map", 4) end
    end)
end})

Tabs.Utility:AddSection("Developer Tools")
Tabs.Utility:AddButton({Title="Dev Tools", Description="Developer tools and utilities", Callback=function()
    Window:Dialog({Title="Developer Tools", Buttons={
        {Title="Dark Dex", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/aaaaaaaaaaaaaa/main/darkdex"))() end},
        {Title="Remote Spy", Callback=function() loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))() end},
        {Title="Close", Callback=function() end},
    }})
end})

Tabs.Utility:AddSection("Proximity Prompts")
for _, promptInfo in ipairs({{"Modifier","Fires the Modifier prompt"},{"Armoury","Fires the Armoury prompt"},{"Ammo Fabricator","Fires the Ammo Fabricator prompt"}}) do
    Tabs.Utility:AddButton({Title=promptInfo[1], Description=promptInfo[2], Callback=function() firePrompt(promptInfo[1]) end})
end

Tabs.Settings:AddSection("HUD Settings")
Tabs.Settings:AddToggle("HUDEnabledToggle", {Title="Show Killaura HUD", Default=config.hud.enabled}):OnChanged(function(v) config.hud.enabled = v end)
Tabs.Settings:AddSlider("HUDHoldDuration", {
    Title = "HUD Hold Duration (seconds)",
    Description = "How long the HUD stays before fading",
    Default = config.hud.holdDuration,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1
}):OnChanged(function(v)
    config.hud.holdDuration = v
    if hudShown and hudHideTask then
        task.cancel(hudHideTask)
        hudHideTask = task.delay(v, function()
            if not hudShown or not hudGui or not hudGui.Parent then return end
            hudFadeTween = TweenService:Create(hudBackground,
                TweenInfo.new(config.hud.fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {BackgroundTransparency = 1})
            hudFadeTween:Play()
            hudFadeTween.Completed:Once(function()
                hudShown = false
                hudBackground.Visible = false
                hudFadeTween = nil
            end)
        end)
    end
end)

Tabs.Settings:AddButton({Title = "Cycle HUD Position", Callback = function()
    local positions = {"top-right", "bottom-right", "top-left", "bottom-left"}
    local current = config.hud.position
    for i, pos in ipairs(positions) do
        if pos == current then
            local nextPos = positions[i%#positions + 1]
            config.hud.position = nextPos
            applyHUDPosition()
            notify("HUD Position", "Changed to " .. nextPos, 3)
            return
        end
    end
end})

Tabs.Settings:AddToggle("KAStatusIndicator", {Title="Show Killaura Status Indicator", Default=config.hud.showStatusIndicator}):OnChanged(function(v)
    config.hud.showStatusIndicator = v
    updateStatusIndicator()
end)

Tabs.Settings:AddParagraph({Title = "Keyboard Shortcuts", Content = "Press [Left Control] to minimize the UI  |  Hold [;] for Mercy Kill  |  Hold [Q] for Bolter Coin Hit"})

notify("Fluent", "Script loaded! (v2.2)", 8)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
