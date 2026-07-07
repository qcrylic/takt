if not game:IsLoaded()then game.Loaded:Wait()end
local GE=getgenv()
local K={
mtMod="\95\109\116\77\111\100\105\102\105\101\100",
orig="\95\111\114\105\103\78\97\109\101\99\97\108\108",
hook="\95\115\97\118\101\100\72\111\111\107",
tgt="\95\99\117\114\114\101\110\116\84\97\114\103\101\116",
lk="\95\108\111\99\107\101\100",
bs="\95\98\117\114\115\116\105\110\103",
thread="\95\107\105\108\108\97\117\114\97\84\104\114\101\97\100",
hbc="\95\104\101\97\114\116\98\101\97\116\67\111\110\110",
ibc="\95\105\110\112\117\116\66\101\103\97\110\67\111\110\110",
iec="\95\105\110\112\117\116\69\110\100\101\100\67\111\110\110",
ac="\95\119\115\67\104\105\108\100\65\100\100\101\100\67\111\110\110",
rc="\95\119\115\67\104\105\108\100\82\101\109\111\118\101\100\67\111\110\110",
hg="\95\104\117\100\71\117\105",
mg="\95\109\111\98\105\108\101\71\117\105",
sd="\95\115\101\109\105\68\111\119\110",
qd="\95\113\68\111\119\110",
pl="\95\112\100\99\76\111\111\112\82\117\110\110\105\110\103",
ml="\95\109\101\114\99\121\77\111\117\115\101\76\111\111\112\82\117\110\110\105\110\103",
kl="\95\109\101\114\99\121\75\101\121\98\111\97\114\100\76\111\111\112\82\117\110\110\105\110\103",
bl="\95\98\111\108\116\101\114\76\111\111\112\82\117\110\110\105\110\103",
av="\95\97\117\116\111\86\111\116\101\76\111\111\112\82\117\110\110\105\110\103",
cfg="\99\111\110\102\105\103",
}
local S={
G="\104\116\116\112\115\58\47\47\114\97\119\46\103\105\116\104\117\98\117\115\101\114\99\111\110\116\101\110\116\46\99\111\109\47",
SM="\83\97\118\101\77\97\110\97\103\101\114",
IM="\73\110\116\101\114\102\97\99\101\77\97\110\97\103\101\114",
SH="\70\108\117\101\110\116\83\99\114\105\112\116\72\117\98",
sfl="\115\107\101\112\116\105\99\97\52\47\70\108\117\101\110\116\118\118\47\114\101\102\115\47\104\101\97\100\115\47\109\97\105\110\47\102\108\117\101\110\116\46\108\117\97",
dsf="\100\97\119\105\100\45\115\99\114\105\112\116\115\47\70\108\117\101\110\116\47\109\97\115\116\101\114\47\65\100\100\111\110\115\47",
DX="\115\107\101\112\116\105\99\97\52\47\97\97\97\97\97\97\97\97\97\97\97\97\97\97\97\47\109\97\105\110\47\100\97\114\107\100\101\120",
SP="\55\56\110\47\83\105\109\112\108\101\83\112\121\47\109\97\105\110\47\83\105\109\112\108\101\83\112\121\66\101\116\97\46\108\117\97",
}
if GE[K.thread]then pcall(task.cancel,GE[K.thread])end
for _,k in ipairs({K.hbc,K.ibc,K.iec,K.ac,K.rc})do local c=GE[k]if c then pcall(c.Disconnect,c)end end
for _,k in ipairs({K.hg,K.mg})do local g=GE[k]if g then pcall(g.Destroy,g)end end
if GE[K.mtMod]then pcall(function()local m=getrawmetatable(game)setreadonly(m,false)if m.__namecall==GE[K.hook]then m.__namecall=GE[K.orig]end setreadonly(m,true)end)GE[K.mtMod]=false end
local Fluent=loadstring(game:HttpGet(S.G..S.sfl))()
if not Fluent then return end
local SaveManager=loadstring(game:HttpGet(S.G..S.dsf..S.SM..".lua"))()
local InterfaceManager=loadstring(game:HttpGet(S.G..S.dsf..S.IM..".lua"))()
local P,U,RU,T,X=game.Players,game.UserInputService,game.RunService,game.TweenService,game.TextService
local LP,cam=P.LocalPlayer,workspace.CurrentCamera
local RS,E=game.ReplicatedStorage,Enum
local function I(c,p,pr)local o=Instance.new(c)if pr then for k,v in next,pr do o[k]=v end end o.Parent=p return o end
local function R(r,g,b)return Color3.fromRGB(r,g,b)end
local N3,U2,U1,V2=Color3.new,UDim2.new,UDim.new,Vector2.new
local tw,F=task.wait,math.floor
local npcOut={}
local cachedHTML,cachedW="",""
if U.TouchEnabled then
local VIM=game.VirtualInputManager
local cl=I("ScreenGui",game.CoreGui,{Name="ClickButton",ZIndexBehavior=E.ZIndexBehavior.Sibling})
GE[K.mg]=cl
local mf=I("Frame",cl,{Name="MainFrame",AnchorPoint=V2(1,0),BackgroundTransparency=.8,BackgroundColor3=R(38,38,38),BorderSizePixel=0,Position=U2(1,-60,0,10),Size=U2(0,45,0,45)})
I("UICorner",mf,{CornerRadius=U1(1,0)})
local il=I("ImageLabel",mf,{AnchorPoint=V2(.5,.5),BackgroundColor3=N3(0,0,0),BorderSizePixel=0,Position=U2(.5,0,.5,0),Size=U2(0,45,0,45),Image="rbxassetid://"})
I("UICorner",il,{CornerRadius=U1(0,10)})
I("TextButton",mf,{BackgroundColor3=N3(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Size=U2(0,45,0,45),AutoButtonColor=false,Font=E.Font.SourceSans,Text="Open",TextColor3=N3(220,125,255),TextSize=20}).MouseButton1Click:Connect(function()
VIM:SendKeyEvent(true,"LeftControl",false,game)VIM:SendKeyEvent(false,"LeftControl",false,game)
end)
end
local TD,DD=13,5.7
local AB,AM,RI,TH,TL,FR=.18,.07,.3,8,2,2
local BC,BD,AI=150,.01,.025
local MN,MD,BL,VD,MI,TP_d=3,.17,.08,1,.5,.1
local HF,HL,HW,HX,HY=1.2,.4,.34,.55,.86
local EX={Landmine=1,Man=1,Turret=1,Stonehenge=1,Sprayer=1,Sentinel=1,Refugee=1,PDC=1,MADS=1,Lifeline=1,Hallucinator=1,Governor=1,FAST_point=1,Barrier=1,Administrator=1,Nuke=1}
for i=1,11 do if i~=8 then EX["dead guy "..i]=1 end end
local NTP={Platform=1,Hermes=1}
local cfg=GE[K.cfg]or{killauraEnabled=false,isTeleportEnabled=false,shouldDestroyLandmines=false,isMercyKillEnabled=false,isMercyKillMouseEnabled=false,isBolterCoinHitEnabled=false,isAutoVoteEnabled=false,isPDCChargesEnabled=false,isSuperWeaponsEnabled=false}
GE[K.cfg]=cfg
GE[K.sd],GE[K.qd]=false,false
GE[K.mtMod],GE[K.orig],GE[K.hook]=false,nil,nil
GE[K.tgt],GE[K.lk],GE[K.bs]=nil,false,false
local cachedWpn,lastFind,kaOn,kaThread,swingN=nil,0,false,nil,0
local npcStale,npcCache=true,{}
local rayP=RaycastParams.new()
rayP.FilterType=E.RaycastFilterType.Exclude
rayP.FilterDescendantsInstances={cam}
local function notify(t,c,d)Fluent:Notify({Title=t,Content=c,Duration=d or 5})end
local function getHRP()return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")end
local function holdingTool()local c=LP.Character return c and c:FindFirstChildOfClass("Tool")~=nil end
local function mousePos()
local m=U:GetMouseLocation()local r=cam:ViewportPointToRay(m.X,m.Y)
local h=workspace:Raycast(cam.CFrame.Position,r.Direction*1000,rayP)return h and h.Position
end
local function token()swingN=swingN+1 return"sweep_"..swingN.."_"..math.random(1000,9999)end
local function liveHum(m)local h=m:FindFirstChildOfClass("Humanoid")if h and h.Health>0 then return h end end
GE[K.ac]=workspace.ChildAdded:Connect(function(c)if c:IsA("Model")then npcStale=true end end)
GE[K.rc]=workspace.ChildRemoved:Connect(function(c)if c:IsA("Model")then npcStale=true end end)
local function cacheAdd(out,m,h)
if not h then return false end h.Died:Once(function()npcStale=true end)out[#out+1]={model=m,target=h}return true
end
local function scanChildren(out,parent,model,pat)
local fd=false
for _,v in ipairs(parent:GetChildren())do
if v:IsA("Model")and string.match(v.Name,pat)and cacheAdd(out,model,liveHum(v))then fd=true end
end return fd
end
local function scanNPCs(force)
if not force and not npcStale then return npcCache end
table.clear(npcOut)
local out,chs=npcOut,workspace:GetChildren()
for _,m in ipairs(chs)do
if m:IsA("Model")and m.Name=="Hermes"then
if not scanChildren(out,m,m,"^Launcher%d+$")then cacheAdd(out,m,liveHum(m))end
end
end
for _,m in ipairs(chs)do
if m:IsA("Model")and m.Name=="Drone"then cacheAdd(out,m,liveHum(m))end
end
for _,m in ipairs(chs)do
if m:IsA("Model")and not P:GetPlayerFromCharacter(m)and m.Name~="Model"and m.Name~="Folder"and m.Name~="Hermes"and not EX[m.Name]then
if m.Name=="Platform"then
local fd2=false
for _,v in ipairs(m:GetDescendants())do
if v:IsA("Model")and string.match(v.Name,"^Emplacement%d+$")then
if cacheAdd(out,m,liveHum(v))then fd2=true end
end
end
if not fd2 then cacheAdd(out,m,liveHum(m))end
elseif m.Name=="Tank"then
if not scanChildren(out,m,m,"^PropaneTank$")then cacheAdd(out,m,liveHum(m))end
elseif m.Name=="APU"then
cacheAdd(out,m,liveHum(m:FindFirstChild("Pilot"))or liveHum(m))
else cacheAdd(out,m,liveHum(m))end
end
end
npcCache,npcStale=out,false
if _G.killauraDebug then
local n={}for _,e in ipairs(out)do n[#n+1]=e.model.Name end
print("[killaura] cache ("..#out.."): "..table.concat(n,", "))
end return out
end
local function bringNPCs()
local h=getHRP()if not h then return end
local fwd,yaw=h.CFrame.LookVector,h.Orientation.Y
for _,e in ipairs(scanNPCs(false))do
if e.target.Parent and e.target.Health>0 and not NTP[e.model.Name]then
local pp=e.model.PrimaryPart or e.model:FindFirstChild("HumanoidRootPart")
if pp then
local d=e.model.Name=="Tank"and TD or DD
e.model:PivotTo(CFrame.new(h.Position+fwd*d)*CFrame.Angles(0,math.rad(yaw),0))
end
end
end
end
local function destroyLandmines()
local any for _,o in ipairs(workspace:GetChildren())do if o.Name=="Landmine"then o:Destroy()any=true end end
if any then notify("System","Landmine cleared",4)end
end
local function firePrompt(name)
for _,o in ipairs(workspace:GetDescendants())do
if o:IsA("ProximityPrompt")and string.find(o.ObjectText or"",name,1,true)then
pcall(fireproximityprompt,o)return
end
end notify("Automation Error","Prompt not found: "..name,4)
end
local function refreshWeapon()
if cachedWpn and cachedWpn.Parent and cachedWpn.Parent==LP.Character then return cachedWpn end
local function find(c)
if not c then return end
for _,t in ipairs(c:GetChildren())do
if t:IsA("Tool")and(t:GetAttribute("Class")=="Melee"or t.Name=="Shovel")then
local v=t:FindFirstChild("VerifyHit")if v and v:IsA("RemoteEvent")then return t end
end
end
end
cachedWpn=find(LP.Character)or find(LP:FindFirstChild("Backpack"))return cachedWpn
end
local function atkInterval(n)
if n==0 then return RI end if n<=TL then return AM end if n>=TH then return AB end
return AM+(AB-AM)*((n-TL)/(TH-TL))
end
local DISPLAY={Man="Infantry",Launcher1="Launcher I",Launcher2="Launcher II",Launcher3="Launcher III",Launcher4="Launcher IV",Emplacement1="Emplacement",PropaneTank="Propane Weakpoint"}
local c1,c2,c3,c4=R(255,70,70),R(255,140,50),R(255,200,80),R(220,220,230)
local COLORS={Launcher1=c1,Launcher2=c1,Launcher3=c1,Launcher4=c1,Hermes=c1,APU=c2,Drone=c3,Emplacement1=c3,Tank=c4,Platform=c4}
local DCOL=N3(1,1,1)
local ORDER={"Launcher1","Launcher2","Launcher3","Launcher4","Hermes","APU","Drone","Emplacement1","Tank","Platform","Man","Turret","PropaneTank"}
local ORDSET={}for _,t in ipairs(ORDER)do ORDSET[t]=true end
local hudGui,hudCont,hudBg,hudLabel,hudHide,hudShown,hudTw
local function initHUD()
hudGui=I("ScreenGui",game.CoreGui,{Name="KillauraHUD",ResetOnSpawn=false,DisplayOrder=100})GE[K.hg]=hudGui
hudCont=I("Frame",hudGui,{AnchorPoint=V2(1,0),BackgroundTransparency=1,Size=U2(HW,0,0,0),AutomaticSize=E.AutomaticSize.Y,Position=U2(1,0,HY,0)})
hudBg=I("Frame",hudCont,{BackgroundColor3=R(12,12,18),BorderSizePixel=0,AutomaticSize=E.AutomaticSize.Y,Size=U2(1,0,0,0)})
I("UICorner",hudBg,{CornerRadius=U1(0,6)})
I("UIPadding",hudBg,{PaddingTop=U1(0,8),PaddingBottom=U1(0,8),PaddingLeft=U1(0,12),PaddingRight=U1(0,12)})
hudLabel=I("TextLabel",hudBg,{BackgroundTransparency=1,Font=E.Font.GothamMedium,TextSize=14,TextXAlignment=E.TextXAlignment.Right,RichText=true,Text="",AutomaticSize=E.AutomaticSize.Y,Size=U2(1,0,0,0)})
end
local function showHUD(counts)
if not hudGui then initHUD()end
local total,lines=0,{"<font size='12' face='GothamBold' color='rgb(160,160,180)'>KILLAURA</font>"}
for _,t in ipairs(ORDER)do local c=counts[t]if c and c>0 then total=total+c local cl=COLORS[t]or DCOL lines[#lines+1]="<font color='rgb("..F(cl.R*255)..","..F(cl.G*255)..","..F(cl.B*255)..")'>"..(DISPLAY[t]or t).."  x"..c.."</font>" end end
for t,c in pairs(counts)do if not ORDSET[t]and c>0 then total=total+c local cl=COLORS[t]or DCOL lines[#lines+1]="<font color='rgb("..F(cl.R*255)..","..F(cl.G*255)..","..F(cl.B*255)..")'>"..(DISPLAY[t]or t).."  x"..c.."</font>" end end
lines[#lines+1]=string.format("<font size='13' face='GothamBold'>Total: %d target%s</font>",total,total==1 and""or"s")
local txt=table.concat(lines,"\n")
if txt~=cachedHTML then
cachedHTML=txt
hudLabel.Text=txt
local stripped=txt:gsub("<[^>]+>","")
cachedW=X:GetTextSize(stripped,hudLabel.TextSize,hudLabel.Font,V2(math.huge,math.huge)).X
end
local vp=cam.ViewportSize
hudCont.Size=U2(math.clamp((cachedW+32)/vp.X,HW,HX),0,0,0)
if hudHide then task.cancel(hudHide)hudHide=nil end
if hudTw then hudTw:Cancel()hudTw=nil end
if not hudShown then hudShown=true hudBg.Visible=true end
hudBg.BackgroundTransparency=.2
hudHide=task.delay(HL,function()
if not hudShown or not hudGui or not hudGui.Parent then return end
hudTw=T:Create(hudBg,TweenInfo.new(HF,E.EasingStyle.Quad,E.EasingDirection.In),{BackgroundTransparency=1})
hudTw:Play()hudTw.Completed:Once(function()hudShown=false hudBg.Visible=false hudTw=nil end)
end)
end
local function attackBatch(targets)
if #targets==0 or not holdingTool()then return 0 end
local w=refreshWeapon()if not w then return 0 end
local vh=w:FindFirstChild("VerifyHit")
if not vh or not vh:IsA("RemoteEvent")or not vh.Parent then cachedWpn=nil return 0 end
local tk,counts,fired=token(),{},0
for i=1,#targets do
if not kaOn then break end local e=targets[i]local h=e.target
if h.Parent and h.Health>0 and e.model.Parent then
pcall(function()vh:FireServer(h,tk)end)local n=e.model.Name counts[n]=(counts[n]or 0)+1 fired=fired+1
end
end
if next(counts)then showHUD(counts)end return fired
end
local function resetBurst()GE[K.tgt]=nil GE[K.lk]=false GE[K.bs]=false end
local function cleanupMultiplier()
if not GE[K.mtMod]then return end
pcall(function()local m=getrawmetatable(game)setreadonly(m,false)
if m.__namecall==GE[K.hook]then m.__namecall=GE[K.orig]end setreadonly(m,true)
end)resetBurst()GE[K.mtMod]=false
end
local function setupMultiplier()
if GE[K.mtMod]then cleanupMultiplier()end
pcall(function()
local m=getrawmetatable(game)setreadonly(m,false)
GE[K.orig]=m.__namecall
GE[K.hook]=newcclosure(function(self,...)
local method,args=getnamecallmethod(),{...}
if _G.multiplier and method=="FireServer"and tostring(self)=="VerifyHit"
and LP.Character and self:IsDescendantOf(LP.Character)then
local tgt=args[1]
if tgt and tgt:IsA("Humanoid")and(not GE[K.bs]or GE[K.tgt]~=tgt)then
GE[K.tgt]=tgt GE[K.lk]=true GE[K.bs]=true
task.spawn(function()
local n,active=1,GE[K.tgt]
while GE[K.lk]and active==GE[K.tgt]do
if not LP.Character or not self:IsDescendantOf(LP.Character)then
if active==GE[K.tgt]then resetBurst()end break end
if not active.Parent or active.Health<=0 then
if active==GE[K.tgt]then resetBurst()end break end
n=n+1
pcall(function()
local pos=args[3]
if typeof(pos)=="Vector3"then local v=.01
local na={args[1],args[2],Vector3.new(pos.X+math.random()*v-v/2,pos.Y+math.random()*v-v/2,pos.Z+math.random()*v-v/2)}
for j=4,#args do na[j]=args[j]end self.FireServer(self,unpack(na))
else self.FireServer(self,unpack(args))end
end)
if n>BC then if active==GE[K.tgt]then resetBurst()end break end
tw(BD)
end
end)
end
end return GE[K.orig](self,...)
end)
m.__namecall=GE[K.hook]setreadonly(m,true)GE[K.mtMod]=true
end)
end
local function spawnGuard(key,fn)if GE[key]then return end GE[key]=true task.spawn(fn)end
spawnGuard(K.pl,function()
while true do
if cfg.isPDCChargesEnabled or cfg.isSuperWeaponsEnabled then
local t=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
if t then
if cfg.isPDCChargesEnabled and t.Name=="PDC kit"then
t:SetAttribute("Charges",999)t:SetAttribute("MaxCharges",999)
t:SetAttribute("Cooldown",.1)t:SetAttribute("AutoReload",true)
t:SetAttribute("ContinuousFire",true)t:SetAttribute("Unlimited",true)
elseif cfg.isSuperWeaponsEnabled and t.Name~="RPG"and t.Name~="Parabolic Hydra"
and t.Name~="Grenade Launcher"and t.Name~="PDC kit"then
t:SetAttribute("Ammo",999)
end
end
end tw(AI)
end
end)
local function findMercy()
return(LP.Character and LP.Character:FindFirstChild("Mercy Kill"))or LP.Backpack:FindFirstChild("Mercy Kill")
end
GE[K.ibc]=U.InputBegan:Connect(function(inp,gp)
if gp then return end
if inp.KeyCode==E.KeyCode.Semicolon then GE[K.sd]=true
elseif inp.KeyCode==E.KeyCode.Q then GE[K.qd]=true end
end)
GE[K.iec]=U.InputEnded:Connect(function(inp)
if inp.KeyCode==E.KeyCode.Semicolon then GE[K.sd]=false
elseif inp.KeyCode==E.KeyCode.Q then GE[K.qd]=false end
end)
spawnGuard(K.ml,function()
while true do
if cfg.isMercyKillMouseEnabled and GE[K.sd]then
local pos,mk=mousePos(),findMercy()
if pos and mk then mk.VerifyHit:FireServer(nil,pos)end
end tw(.1)
end
end)
spawnGuard(K.kl,function()
while true do
if cfg.isMercyKillEnabled and not cfg.isMercyKillMouseEnabled and GE[K.sd]then
local hrp,mk=getHRP(),findMercy()
if hrp and mk then mk.VerifyHit:FireServer(nil,hrp.Position)end
end tw(MD)
end
end)
spawnGuard(K.bl,function()
while true do
if cfg.isBolterCoinHitEnabled and GE[K.qd]then
local pos=mousePos()local pm=workspace:FindFirstChild(LP.Name)
local b=pm and pm:FindFirstChild("Bolter")
if pos and b and b:FindFirstChild("VerifyCoinHit")then b.VerifyCoinHit:FireServer(pos)end
end tw(BL)
end
end)
spawnGuard(K.av,function()
while true do
if cfg.isAutoVoteEnabled then pcall(function()
local r=RS:FindFirstChild("Remotes")local w=r and r:FindFirstChild("Waves")
local v=w and w:FindFirstChild("Vote")if v then v:InvokeServer()end
end)end tw(VD)
end
end)
local tpTh,mineTh=0,0
GE[K.hbc]=RU.Heartbeat:Connect(function(dt)
if cfg.isTeleportEnabled then tpTh=tpTh+dt if tpTh>=TP_d then tpTh=0 bringNPCs()end end
if cfg.shouldDestroyLandmines then mineTh=mineTh+dt if mineTh>=MI then mineTh=0 destroyLandmines()end end
end)
local Win=Fluent:CreateWindow({
Title="Dummies Versus Noobs | qcrylic - Premium",SubTitle="@qcrylic",TabWidth=160,
Size=UDim2.fromOffset(580,460),Acrylic=false,Theme="Aqua",MinimizeKey=E.KeyCode.LeftControl,
})
local Tab={
Main=Win:AddTab({Title="Main",Icon="list"}),Combat=Win:AddTab({Title="Combat",Icon="sword"}),
Targeting=Win:AddTab({Title="Targeting",Icon="target"}),
Utility=Win:AddTab({Title="Utility",Icon="plus-circle"}),Settings=Win:AddTab({Title="Settings",Icon="settings"}),
}
SaveManager:SetLibrary(Fluent)InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder(S.SH)SaveManager:SetFolder(S.SH.."/specific-game")
InterfaceManager:BuildInterfaceSection(Tab.Settings)SaveManager:BuildConfigSection(Tab.Settings)
local function addT(tab,key,title,cb)tab:AddToggle(key,{Title=title,Default=false}):OnChanged(cb)end
addT(Tab.Main,"KillauraToggle","Killaura",function(v)
kaOn=v cfg.killauraEnabled=v
if kaThread then task.cancel(kaThread)kaThread=nil end
if kaOn then
kaThread=task.spawn(function()
while kaOn do
if os.clock()-lastFind>FR then scanNPCs(true)lastFind=os.clock()end
tw(atkInterval(attackBatch(npcCache)or 0))
end
end)GE[K.thread]=kaThread
else GE[K.thread]=nil npcStale,lastFind,cachedWpn=true,0,nil end
end)
addT(Tab.Main,"BringNPCsToggle","Bring NPCs",function(v)cfg.isTeleportEnabled=v end)
addT(Tab.Main,"AutoVoteToggle","Auto Vote Waves",function(v)cfg.isAutoVoteEnabled=v end)
local mercyTgl=Tab.Combat:AddToggle("MercyKillToggle",{Title="Mercy Kill",Default=false})
local mmTgl=Tab.Combat:AddToggle("MouseMercyKillToggle",{Title="Mercy Kill (Mouse)",Default=false})
mercyTgl:OnChanged(function(v)
cfg.isMercyKillEnabled=v
if v and cfg.isMercyKillMouseEnabled then cfg.isMercyKillMouseEnabled=false mmTgl:SetValue(false)end
end)
mmTgl:OnChanged(function(v)
cfg.isMercyKillMouseEnabled=v
if v then
if cfg.isMercyKillEnabled then cfg.isMercyKillEnabled=false mercyTgl:SetValue(false)end
notify("Mercy Kill (Mouse)","Hold semicolon to fire at mouse",4)
end
end)
addT(Tab.Combat,"DamageMultiplierToggle","Damage Multiplier",function(v)
_G.multiplier=v if v then setupMultiplier()else cleanupMultiplier()end
end)
addT(Tab.Combat,"PDCChargesToggle","Infinite PDC",function(v)cfg.isPDCChargesEnabled=v end)
addT(Tab.Combat,"SuperWeaponsToggle","Infinite Ammo",function(v)cfg.isSuperWeaponsEnabled=v end)
Tab.Targeting:AddSection("NPC Management")
Tab.Targeting:AddButton({Title="Refresh NPC Cache",Description="Force refresh the NPC detection cache",Callback=function()
scanNPCs(true)notify("System","NPC cache refreshed",3)
end})
Tab.Targeting:AddButton({Title="Spawn Noob Units",Description="Spawns all standard noob units to workspace",Callback=function()
local ex={Dreadnought=1,["Achilles(ht)"]=1,Sparchilles=1,APU=1,APU_Operator=1,Hermes=1,Achilles=1,Confidant=1,London=1,Tank=1,Platform=1,Man=1,MangleNether345=1,MegaJoe=1,Administrator=1}
local c=0 pcall(function()for _,v in ipairs(RS.Units.Noobs:GetChildren())do if not ex[v.Name]then v.Parent=workspace c=c+1 end end end)
notify("Spawn Noob Units","Spawned "..c.." unit"..(c==1 and""or"s"),4)
end})
addT(Tab.Utility,"LandmineToggle","Destroy Landmines",function(v)cfg.shouldDestroyLandmines=v end)
addT(Tab.Utility,"BolterCoinToggle","Bolter Coin Hit (Hold Q)",function(v)cfg.isBolterCoinHitEnabled=v end)
Tab.Utility:AddSection("Teleportation")
Tab.Utility:AddButton({Title="Teleport to Lobby",Description="Teleports to lobby ingame",Callback=function()
local h=getHRP()if h then h.CFrame=CFrame.new(-3,-101.5,-12.5)notify("System","Teleported to lobby",4)end
end})
Tab.Utility:AddButton({Title="Teleport to Map",Description="Teleports player to map",Callback=function()
pcall(function()
local h=LP.Character and LP.Character:WaitForChild("HumanoidRootPart")
local m=workspace.Map local s=m and m.PlayerSpawns and m.PlayerSpawns.SpawnLocation
if h and s then h.CFrame=s.CFrame+Vector3.new(0,3,0)notify("System","Teleported to map",4)end
end)
end})
Tab.Utility:AddSection("Developer Tools")
Tab.Utility:AddButton({Title="Dev Tools",Description="Developer tools and utilities",Callback=function()
Win:Dialog({Title="Developer Tools",Buttons={
{Title="Dark Dex",Callback=function()loadstring(game:HttpGet(S.G..S.DX))()end},
{Title="Remote Spy",Callback=function()loadstring(game:HttpGetAsync(S.G..S.SP))()end},
{Title="Close",Callback=function()end},
}})
end})
Tab.Utility:AddSection("Proximity Prompts")
for _,name in ipairs({"Modifier","Armoury","Ammo Fabricator"})do
Tab.Utility:AddButton({Title=name,Description="Fires the "..name.." prompt",Callback=function()firePrompt(name)end})
end
notify("Fluent","Script loaded!",8)Win:SelectTab(1)SaveManager:LoadAutoloadConfig()
