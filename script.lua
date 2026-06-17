if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/Fluentvv/refs/heads/main/fluent.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Players, UIS, RunService, TweenService, TextService =
    game:GetService("Players"), game:GetService("UserInputService"),
    game:GetService("RunService"), game:GetService("TweenService"), game:GetService("TextService")
local LP, camera = Players.LocalPlayer, workspace.CurrentCamera

local DeviceType = game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC"
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

local TANK_DIST, DEFAULT_DIST = 13, 5.7
local ATK_BASE, ATK_MIN, RESCAN_INT, THRESH_HI, THRESH_LO = 0.18, 0.07, 0.3, 8, 2
local BURST_CAP, BURST_DELAY, ATTR_INT = 150, 0.01, 0.1
local MERCY_N, MERCY_DLY, BOLTER_DLY, VOTE_DLY, MINE_DLY, TP_DLY = 3, 0.17, 0.08, 1, 0.5, 0.1
local HUD_FADE, HUD_LINGER, HUD_SLIDE, HUD_OFF = 1.2, 0.4, 0.25, 50
local HUD_W, HUD_WMAX, HUD_Y = 0.34, 0.55, 0.86

local EXCLUDED = { Landmine=1, Man=1, Turret=1, Stonehenge=1, Sprayer=1, Sentinel=1, Refugee=1,
    PDC=1, MADS=1, Lifeline=1, Hallucinator=1, Governor=1, FAST_point=1, Barrier=1, Administrator=1, Nuke=1 }
local NOT_TELEPORTABLE = { Platform=1, Hermes=1 }
for i = 1, 11 do if i ~= 8 then EXCLUDED["dead guy " .. i] = 1 end end

local config = getgenv().config or {
    killauraEnabled=false, isTeleportEnabled=false, shouldDestroyLandmines=false, isMercyKillEnabled=false,
    isMercyKillMouseEnabled=false, isBolterCoinHitEnabled=false, isAutoVoteEnabled=false,
    isPDCChargesEnabled=false, isSuperWeaponsEnabled=false,
}
getgenv().config = config

local cachedWeapon, lastFind, killauraOn, killauraThread = nil, 0, false, nil
local swingN, semiDown, qDown, mercyBusy = 0, false, false, false
local mtModified, mt, origNamecall = false, nil, nil
local currentTarget, locked, bursting = nil, false, false
local npcCache, npcStale = {}, true

local function notify(t, c, d) Fluent:Notify({Title=t, Content=c, Duration=d or 5}) end
local function getHRP() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function holdingTool() local c = LP.Character return c and c:FindFirstChildOfClass("Tool") ~= nil end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function mousePos()
    local m = UIS:GetMouseLocation()
    local r = camera:ViewportPointToRay(m.X, m.Y)
    local hit = workspace:Raycast(camera.CFrame.Position, r.Direction * 1000, rayParams)
    return hit and hit.Position
end

local function token() swingN = swingN + 1 return "sweep_" .. swingN .. "_" .. math.random(1000, 9999) end
local function liveHumanoid(model)
    local h = model:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then return h end
end

-- Cache invalidation: model add/remove or humanoid death triggers a rescan
workspace.ChildAdded:Connect(function(c) if c:IsA("Model") then npcStale = true end end)
workspace.ChildRemoved:Connect(function(c) if c:IsA("Model") then npcStale = true end end)

-- Adds a live humanoid entry to the cache with death-listener invalidation.
-- Returns true if an entry was actually added (humanoid was alive).
local function cacheAdd(out, model, h)
    if not h then return false end
    h.Died:Once(function() npcStale = true end)
    out[#out+1] = {model=model, target=h}
    return true
end

-- Scans a model's direct children matching name pattern `^pat$` for live humanoids.
-- Returns true if at least one was cached.
local function scanChildren(out, parent, model, pat)
    local found = false
    for _, m in ipairs(parent:GetChildren()) do
        if m:IsA("Model") and string.match(m.Name, pat) and cacheAdd(out, model, liveHumanoid(m)) then
            found = true
        end
    end
    return found
end

local function scanNPCs(force)
    if not force and not npcStale then return npcCache end
    local out, children = {}, workspace:GetChildren()

    -- Pass 1: Hermes units — target individual launchers when alive,
    -- fall back to the Hermes body itself when all launchers are dead.
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name == "Hermes" then
            if not scanChildren(out, d, d, "^Launcher%d+$") then
                cacheAdd(out, d, liveHumanoid(d))
            end
        end
    end

    -- Pass 2: Drones
    for _, m in ipairs(children) do
        if m:IsA("Model") and m.Name == "Drone" then
            cacheAdd(out, m, liveHumanoid(m))
        end
    end

    -- Pass 3: Standard ground combat (tanks, APU, platforms, etc.)
    for _, m in ipairs(children) do
        if m:IsA("Model") and not Players:GetPlayerFromCharacter(m)
            and m.Name ~= "Model" and m.Name ~= "Folder" and not EXCLUDED[m.Name] then

            if m.Name == "Platform" then
                local found = false
                for _, ch in ipairs(m:GetDescendants()) do
                    if ch:IsA("Model") and string.match(ch.Name, "^Emplacement%d+$") then
                        if cacheAdd(out, m, liveHumanoid(ch)) then found = true end
                    end
                end
                if not found then cacheAdd(out, m, liveHumanoid(m)) end

            elseif m.Name == "Tank" then
                if not scanChildren(out, m, m, "^PropaneTank$") then
                    cacheAdd(out, m, liveHumanoid(m))
                end

            elseif m.Name == "APU" then
                cacheAdd(out, m, liveHumanoid(m:FindFirstChild("Pilot")) or liveHumanoid(m))

            else
                cacheAdd(out, m, liveHumanoid(m))
            end
        end
    end

    npcCache, npcStale = out, false
    if _G.killauraDebug then
        local names = {}
        for _, e in ipairs(out) do names[#names+1] = e.model.Name end
        print("[killaura] cache (" .. #out .. "): " .. table.concat(names, ", "))
    end
    return out
end

local function bringNPCs()
    local hrp = getHRP() if not hrp then return end
    local fwd, yaw = hrp.CFrame.LookVector, hrp.Orientation.Y
    for _, e in ipairs(scanNPCs(false)) do
        if e.target.Parent and e.target.Health > 0 and not NOT_TELEPORTABLE[e.model.Name] then
            local pp = e.model.PrimaryPart or e.model:FindFirstChild("HumanoidRootPart")
            if pp then
                local d = e.model.Name == "Tank" and TANK_DIST or DEFAULT_DIST
                e.model:PivotTo(CFrame.new(hrp.Position + fwd * d) * CFrame.Angles(0, math.rad(yaw), 0))
            end
        end
    end
end

local function destroyLandmines()
    local any; for _, o in ipairs(workspace:GetChildren()) do if o.Name == "Landmine" then o:Destroy(); any = true end end
    if any then notify("System", "All nearby landmines cleared", 4) end
end

local function firePrompt(name)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ProximityPrompt") and string.find(o.ObjectText or "", name, 1, true) then
            pcall(fireproximityprompt, o); return
        end
    end
    notify("Automation Error", "Prompt not found: " .. name, 4)
end

local function refreshWeapon()
    if cachedWeapon and cachedWeapon.Parent then return cachedWeapon end
    local function findIn(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and (t:GetAttribute("Class") == "Melee" or t.Name == "Shovel") then
                local vh = t:FindFirstChild("VerifyHit")
                if vh and vh:IsA("RemoteEvent") then return t end
            end
        end
    end
    cachedWeapon = findIn(LP.Character) or findIn(LP:FindFirstChild("Backpack"))
    return cachedWeapon
end

local function atkInterval(n)
    if n <= THRESH_LO then return ATK_MIN end
    if n >= THRESH_HI then return ATK_BASE end
    return ATK_MIN + (ATK_BASE - ATK_MIN) * ((n - THRESH_LO) / (THRESH_HI - THRESH_LO))
end

-- HUD
local DISPLAY = { Tank="Tank", Drone="Drone", Hermes="Hermes", APU="APU", Platform="Platform", Man="Infantry",
    Turret="Turret", Launcher1="Launcher I", Launcher2="Launcher II", Launcher3="Launcher III",
    Launcher4="Launcher IV", Emplacement1="Emplacement", PropaneTank="Propane Weakpoint" }
local COLORS = {
    Launcher1=Color3.fromRGB(255,70,70), Launcher2=Color3.fromRGB(255,70,70),
    Launcher3=Color3.fromRGB(255,70,70), Launcher4=Color3.fromRGB(255,70,70),
    Hermes=Color3.fromRGB(255,70,70), APU=Color3.fromRGB(255,140,50),
    Drone=Color3.fromRGB(255,200,80), Emplacement1=Color3.fromRGB(255,200,80),
    Tank=Color3.fromRGB(220,220,230), Platform=Color3.fromRGB(220,220,230) }
local DEF_COL = Color3.fromRGB(255,255,255)
local ORDER = { "Launcher1","Launcher2","Launcher3","Launcher4","Hermes","APU","Drone",
    "Emplacement1","Tank","Platform","Man","Turret","PropaneTank" }
local orderSet = {} for _, t in ipairs(ORDER) do orderSet[t] = true end

local hudGui, hudCont, hudBg, hudStroke, hudLabel, hudHide, hudShown

local function initHUD()
    hudGui = Instance.new("ScreenGui")
    hudGui.Name, hudGui.ResetOnSpawn, hudGui.DisplayOrder, hudGui.Parent = "KillauraHUD", false, 100, game:GetService("CoreGui")
    hudCont = Instance.new("Frame")
    hudCont.AnchorPoint, hudCont.BackgroundTransparency = Vector2.new(1,0), 1
    hudCont.Size, hudCont.AutomaticSize = UDim2.new(HUD_W,0,0,0), Enum.AutomaticSize.Y
    hudCont.Position, hudCont.Parent = UDim2.new(1,HUD_OFF,HUD_Y,0), hudGui
    hudBg = Instance.new("Frame")
    hudBg.BackgroundColor3, hudBg.BackgroundTransparency, hudBg.BorderSizePixel = Color3.fromRGB(12,12,18), 1, 0
    hudBg.AutomaticSize, hudBg.Size, hudBg.Parent = Enum.AutomaticSize.Y, UDim2.new(1,0,0,0), hudCont
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = hudBg
    hudStroke = Instance.new("UIStroke")
    hudStroke.Color, hudStroke.Thickness, hudStroke.Transparency, hudStroke.Parent = Color3.fromRGB(70,70,95), 1, 1, hudBg
    local p = Instance.new("UIPadding")
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0,8), UDim.new(0,8), UDim.new(0,12), UDim.new(0,12)
    p.Parent = hudBg
    hudLabel = Instance.new("TextLabel")
    hudLabel.BackgroundTransparency, hudLabel.Font, hudLabel.TextSize = 1, Enum.Font.GothamMedium, 14
    hudLabel.TextXAlignment, hudLabel.RichText, hudLabel.Text = Enum.TextXAlignment.Right, true, ""
    hudLabel.TextTransparency, hudLabel.AutomaticSize = 1, Enum.AutomaticSize.Y
    hudLabel.Size, hudLabel.Parent = UDim2.new(1,0,0,0), hudBg
end

local function fmtLine(t, count)
    local col = COLORS[t] or DEF_COL
    return string.format("<font color='rgb(%d,%d,%d)'>%s  x%d</font>",
        math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255), DISPLAY[t] or t, count)
end

local function tweenProp(inst, info, props)
    for k, v in pairs(props) do TweenService:Create(inst, info, {[k]=v}):Play() end
end

local function showHUD(counts)
    if not hudGui then initHUD() end
    local total, lines = 0, { "<font size='12' face='GothamBold' color='rgb(160,160,180)'>KILLAURA</font>" }
    for _, t in ipairs(ORDER) do
        local c = counts[t]
        if c and c > 0 then total = total + c; lines[#lines+1] = fmtLine(t, c) end
    end
    for t, c in pairs(counts) do
        if not orderSet[t] and c > 0 then total = total + c; lines[#lines+1] = fmtLine(t, c) end
    end
    lines[#lines+1] = string.format("<font size='13' face='GothamBold'>Total: %d target%s</font>", total, total==1 and "" or "s")
    hudLabel.Text = table.concat(lines, "\n")

    local vp = workspace.CurrentCamera.ViewportSize
    local tw = TextService:GetTextSize(hudLabel.Text, hudLabel.TextSize, hudLabel.Font, Vector2.new(math.huge, math.huge)).X
    hudCont.Size = UDim2.new(0, math.clamp(tw + 32, HUD_W * vp.X, HUD_WMAX * vp.X), 0, 0)

    if hudHide then task.cancel(hudHide); hudHide = nil end
    if not hudShown then
        hudCont.Position = UDim2.new(1, HUD_OFF, HUD_Y, 0)
        hudBg.BackgroundTransparency, hudStroke.Transparency, hudLabel.TextTransparency = 1, 1, 1
        local si = TweenInfo.new(HUD_SLIDE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenProp(hudCont, si, {Position=UDim2.new(1,0,HUD_Y,0)})
        tweenProp(hudBg, si, {BackgroundTransparency=0.2})
        tweenProp(hudStroke, si, {Transparency=0.4})
        tweenProp(hudLabel, si, {TextTransparency=0})
        hudShown = true
    end
    hudHide = task.delay(HUD_LINGER, function()
        if not hudShown then return end
        local fi = TweenInfo.new(HUD_FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tweenProp(hudCont, fi, {Position=UDim2.new(1,HUD_OFF,HUD_Y,0)})
        tweenProp(hudBg, fi, {BackgroundTransparency=1})
        tweenProp(hudStroke, fi, {Transparency=1})
        tweenProp(hudLabel, fi, {TextTransparency=1})
        hudHide = task.delay(HUD_FADE, function() hudShown = false end)
    end)
end

local function attackBatch(targets)
    if #targets == 0 or not holdingTool() then return 0 end
    local w = refreshWeapon() if not w then return 0 end
    local vh = w:FindFirstChild("VerifyHit")
    if not vh or not vh:IsA("RemoteEvent") or not vh.Parent then cachedWeapon = nil return 0 end
    local tok, counts, fired = token(), {}, 0
    for i = 1, #targets do
        if not killauraOn then break end
        local e = targets[i]
        local h = e.target
        if h.Parent and h.Health > 0 and e.model.Parent == workspace then
            pcall(function() vh:FireServer(h, tok) end)
            local n = e.model.Name
            counts[n] = (counts[n] or 0) + 1
            fired = fired + 1
        end
    end
    if next(counts) then showHUD(counts) end
    return fired
end

-- Damage multiplier
local function resetBurst() currentTarget, locked, bursting = nil, false, false end

local function cleanupMultiplier()
    if not mtModified then return end
    pcall(function() setreadonly(mt, false); mt.__namecall = origNamecall; setreadonly(mt, true) end)
    resetBurst(); mtModified = false
end

local function setupMultiplier()
    if mtModified then cleanupMultiplier() end
    pcall(function()
        mt = getrawmetatable(game); setreadonly(mt, false); origNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method, args = getnamecallmethod(), {...}
            if _G.multiplier and method == "FireServer" and tostring(self) == "VerifyHit"
                and LP.Character and self:IsDescendantOf(LP.Character) then
                local t = args[1]
                if t and t:IsA("Humanoid") and (not bursting or currentTarget ~= t) then
                    currentTarget, locked, bursting = t, true, true
                    task.spawn(function()
                        local n, active = 1, currentTarget
                        while locked and active == currentTarget do
                            if not active.Parent or active.Health <= 0 then
                                if active == currentTarget then resetBurst() end break
                            end
                            n = n + 1
                            pcall(function()
                                local pos = args[3]
                                if typeof(pos) == "Vector3" then
                                    local v = 0.01
                                    local na = {args[1], args[2], Vector3.new(
                                        pos.X + math.random()*v - v/2,
                                        pos.Y + math.random()*v - v/2,
                                        pos.Z + math.random()*v - v/2)}
                                    for j = 4, #args do na[j] = args[j] end
                                    self.FireServer(self, unpack(na))
                                else self.FireServer(self, unpack(args)) end
                            end)
                            if n > BURST_CAP then if active == currentTarget then resetBurst() end break end
                            task.wait(BURST_DELAY)
                        end
                    end)
                end
            end
            return origNamecall(self, ...)
        end)
        setreadonly(mt, true); mtModified = true
    end)
end

-- PDC / Super weapons loop
task.spawn(function()
    while true do
        if config.isPDCChargesEnabled or config.isSuperWeaponsEnabled then
            local t = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
            if t then
                if config.isPDCChargesEnabled and t.Name == "PDC kit" then
                    t:SetAttribute("Charges", 999); t:SetAttribute("MaxCharges", 999)
                    t:SetAttribute("Cooldown", 0.1); t:SetAttribute("AutoReload", true)
                    t:SetAttribute("ContinuousFire", true); t:SetAttribute("Unlimited", true)
                elseif config.isSuperWeaponsEnabled and t.Name ~= "RPG" and t.Name ~= "Parabolic Hydra"
                    and t.Name ~= "Grenade Launcher" and t.Name ~= "PDC kit" then
                    t:SetAttribute("Ammo", 999)
                end
            end
        end
        task.wait(ATTR_INT)
    end
end)

local function findMercy()
    return LP.Backpack:FindFirstChild("Mercy Kill")
        or (LP.Character and LP.Character:FindFirstChild("Mercy Kill"))
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Semicolon then
        semiDown = true
        if config.isMercyKillEnabled and not config.isMercyKillMouseEnabled and not mercyBusy then
            local hrp, mk = getHRP(), findMercy()
            if hrp and mk then
                mercyBusy = true
                task.spawn(function()
                    pcall(function()
                        for _ = 1, MERCY_N do
                            if not semiDown then return end
                            mk.VerifyHit:FireServer(nil, hrp.Position)
                            task.wait(MERCY_DLY)
                        end
                    end)
                    mercyBusy = false
                end)
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Q then qDown = true end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Semicolon then semiDown = false
    elseif input.KeyCode == Enum.KeyCode.Q then qDown = false end
end)

task.spawn(function()
    while true do
        if config.isMercyKillMouseEnabled and semiDown then
            local pos, mk = mousePos(), findMercy()
            if pos and mk then mk.VerifyHit:FireServer(nil, pos) end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if config.isBolterCoinHitEnabled and qDown then
            local pos = mousePos()
            local pm = workspace:FindFirstChild(LP.Name)
            local b = pm and pm:FindFirstChild("Bolter")
            if pos and b and b:FindFirstChild("VerifyCoinHit") then b.VerifyCoinHit:FireServer(pos) end
        end
        task.wait(BOLTER_DLY)
    end
end)

task.spawn(function()
    while true do
        if config.isAutoVoteEnabled then
            pcall(function() game:GetService("ReplicatedStorage").Remotes.Waves.Vote:InvokeServer() end)
        end
        task.wait(VOTE_DLY)
    end
end)

-- Main loop
local tpTh, mineTh = 0, 0
RunService.Heartbeat:Connect(function(dt)
    if config.isTeleportEnabled then
        tpTh = tpTh + dt
        if tpTh >= TP_DLY then tpTh = 0; bringNPCs() end
    end
    if config.shouldDestroyLandmines then
        mineTh = mineTh + dt
        if mineTh >= MINE_DLY then mineTh = 0; destroyLandmines() end
    end
end)

-- UI
local Window = Fluent:CreateWindow({
    Title = game:GetService("MarketplaceService"):GetProductInfo(16732694052).Name .." | qcrylic - Premium", SubTitle = "@qcrylic", TabWidth = 160,
    Size = UDim2.fromOffset(580, 460), Acrylic = false, Theme = "Aqua",
    MinimizeKey = Enum.KeyCode.LeftControl,
})
local Tabs = { -- https://lucide.dev/icons/
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

-- MAIN TAB: Core toggle features
toggle(Tabs.Main, "KillauraToggle", "Killaura", function(v)
    killauraOn = v
    config.killauraEnabled = v
    if killauraOn then
        if killauraThread then coroutine.close(killauraThread); killauraThread = nil end
        killauraThread = coroutine.create(function()
            while killauraOn do
                if tick() - lastFind > RESCAN_INT then scanNPCs(true); lastFind = tick() end
                local t = npcCache
                local fired = attackBatch(t) or 0
                task.wait(atkInterval(fired))
            end
        end)
        coroutine.resume(killauraThread)
    else
        if killauraThread then coroutine.close(killauraThread); killauraThread = nil end
        npcCache, lastFind, cachedWeapon = {}, 0, nil
    end
end)

toggle(Tabs.Main, "BringNPCsToggle", "Bring NPCs", function(v) config.isTeleportEnabled = v end)

toggle(Tabs.Main, "AutoVoteToggle", "Auto Vote Waves", function(v) config.isAutoVoteEnabled = v end)

-- COMBAT TAB: Weapon/damage mechanics
toggle(Tabs.Combat, "MercyKillToggle", "Mercy Kill", function(v)
    config.isMercyKillEnabled = v
    if v and config.isMercyKillMouseEnabled then config.isMercyKillMouseEnabled = false; Tabs.Combat:SetValue("MouseMercyKillToggle", false) end
end)

toggle(Tabs.Combat, "MouseMercyKillToggle", "Mercy Kill (Mouse)", function(v)
    config.isMercyKillMouseEnabled = v
    if v then
        if config.isMercyKillEnabled then config.isMercyKillEnabled = false; Tabs.Combat:SetValue("MercyKillToggle", false) end
        notify("Mercy Kill (Mouse)", "Hold semicolon to fire at mouse", 4)
    end
end)

toggle(Tabs.Combat, "DamageMultiplierToggle", "Damage Multiplier",
    function(v) _G.multiplier = v; if v then setupMultiplier() else cleanupMultiplier() end end)

toggle(Tabs.Combat, "PDCChargesToggle", "Infinite PDC", function(v) config.isPDCChargesEnabled = v end)

toggle(Tabs.Combat, "SuperWeaponsToggle", "Infinite Ammo", function(v) config.isSuperWeaponsEnabled = v end)

-- TARGETING TAB: Enemy detection & management
Tabs.Targeting:AddSection("NPC Management")
Tabs.Targeting:AddButton({Title="Refresh NPC Cache", Description="Force refresh the NPC detection cache", Callback=function()
    scanNPCs(true)
    notify("System", "NPC cache refreshed", 3)
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

-- UTILITY TAB: One-off actions & tools
toggle(Tabs.Utility, "LandmineToggle", "Destroy Landmines", function(v) config.shouldDestroyLandmines = v end)

toggle(Tabs.Utility, "BolterCoinToggle", "Bolter Coin Hit (Hold Q)", function(v) config.isBolterCoinHitEnabled = v end)

Tabs.Utility:AddSection("Teleportation")
Tabs.Utility:AddButton({Title="Teleport to Lobby", Description="Teleports to lobby ingame", Callback=function()
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(-3, -101.5, -12.5); notify("System", "Teleported to lobby", 4) end
end})

Tabs.Utility:AddButton({Title="Teleport to Map", Description="Teleports player to map", Callback=function()
    pcall(function()
        local hrp = LP.Character and LP.Character:WaitForChild("HumanoidRootPart")
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
for _, a in ipairs({{"Modifier","Fires the Modifier prompt"},{"Armoury","Fires the Armoury prompt"},{"Ammo Fabricator","Fires the Ammo Fabricator prompt"}}) do
    Tabs.Utility:AddButton({Title=a[1], Description=a[2], Callback=function() firePrompt(a[1]) end})
end

notify("Fluent", "Script loaded!", 8)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
