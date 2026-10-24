local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local ui=script.Parent
local main=ui:WaitForChild("MenuPrincipal")
local scenes=ui:WaitForChild("Escenarios")
local credits=scenes:WaitForChild("MenuCreditos")
local settings=scenes:WaitForChild("MenuAjustes")
local transition=ui:WaitForChild("FrameDeTransicion")
local config=RS:WaitForChild("SweanMenuConfig")
local returnButton=ui:WaitForChild("ReturnToMenu")
local creditsButton=ui:WaitForChild("CreditsButton")
local settingsModule=require(RS:WaitForChild("Survival"):WaitForChild("SettingsPanel"))
settingsModule.initialize(player)
local low=player:GetAttribute("LowGraphics")==true
local shop=scenes:WaitForChild("MenuShop") local inventory=scenes:WaitForChild("MenuInventory") local updates=scenes:WaitForChild("MenuUpdates")
local settingsControl
local controls=nil
local inMenu=true
local busy=false
local menuScene=nil
local menuAvatar=nil
local menuCameraCF=nil
local oldFov=70
local MENU_ORIGIN=config:GetAttribute("MenuOrigin") or Vector3.new(10000,2500,10000)
local menuGrade=nil local menuGlow=nil
local function enableMenuLook()
 if not menuGrade then menuGrade=Instance.new("ColorCorrectionEffect") menuGrade.Name="SuviversMenuGrade" menuGrade.Brightness=.035 menuGrade.Contrast=.1 menuGrade.Saturation=-.12 menuGrade.TintColor=Color3.fromRGB(255,232,232) menuGrade.Enabled=not low menuGrade.Parent=Lighting end
 if not menuGlow then menuGlow=Instance.new("BloomEffect") menuGlow.Name="SuviversMenuBloom" menuGlow.Intensity=.18 menuGlow.Size=18 menuGlow.Threshold=1.2 menuGlow.Enabled=not low menuGlow.Parent=Lighting end
end
local function disableMenuLook() if menuGrade then menuGrade:Destroy() menuGrade=nil end if menuGlow then menuGlow:Destroy() menuGlow=nil end end

player:SetAttribute("InMenu",true)

local function clearPrivateScene()
 if menuAvatar then menuAvatar:Destroy() menuAvatar=nil end
 if menuScene then menuScene:Destroy() menuScene=nil end
 menuCameraCF=nil
end

local function horizontal(v)
 local h=Vector3.new(v.X,0,v.Z)
 return h.Magnitude>.01 and h.Unit or Vector3.new(0,0,-1)
end

local function chooseFloor(scene)
 local cf,size=scene:GetBoundingBox()
 local bottom=cf.Position.Y-size.Y/2
 local best,bestScore=nil,-math.huge
 for _,p in ipairs(scene:GetDescendants()) do
  if p:IsA("BasePart") and p.Transparency<.98 and p.CFrame.UpVector.Y>.82 and p.Size.X>=7 and p.Size.Z>=7 then
   local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
   local height=top.Y-bottom
   if height<size.Y*.62 then
    local score=p.Size.X*p.Size.Z-height*2-(Vector2.new(top.X-cf.Position.X,top.Z-cf.Position.Z).Magnitude*.4)
    if score>bestScore then best,bestScore=p,score end
   end
  end
 end
 return best,cf,size
end

local function buildPrivateScene()
 clearPrivateScene()
 local template=RS:WaitForChild("MenuSceneTemplate")
 menuScene=template:Clone()
 menuScene.Name="LocalMenuScene"
 for _,d in ipairs(menuScene:GetDescendants()) do if d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then d:Destroy() end end
 menuScene.Parent=workspace
 local rotation=menuScene:GetPivot().Rotation
 menuScene:PivotTo(CFrame.new(MENU_ORIGIN)*rotation)

 local floor,cf,size=chooseFloor(menuScene)
 local base
 local forward
 local right
 if floor then
  base=floor.CFrame:PointToWorldSpace(Vector3.new(0,floor.Size.Y/2+.08,0))
  forward=horizontal(floor.CFrame.LookVector)
  right=horizontal(floor.CFrame.RightVector)
 else
  base=Vector3.new(cf.Position.X,cf.Position.Y-size.Y*.35,cf.Position.Z)
  forward=horizontal(rotation.LookVector)
  right=horizontal(rotation.RightVector)
 end

 local forwardRoom=floor and math.max(6,floor.Size.Z*.5-2) or math.max(8,size.Z*.25)
 local rightRoom=floor and math.max(6,floor.Size.X*.5-2) or math.max(8,size.X*.25)
 local cameraPos=base-forward*math.min(7.5,forwardRoom*.42)-right*math.min(1.5,rightRoom*.10)+Vector3.new(0,4.4,0)
 local focus=base+forward*math.min(3.4,forwardRoom*.20)+Vector3.new(0,3.0,0)
 menuCameraCF=CFrame.lookAt(cameraPos,focus)

 local candidate=base+forward*math.min(2.8,forwardRoom*.18)+right*math.min(4.2,rightRoom*.32)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={menuScene}
 local hit=workspace:Raycast(candidate+Vector3.new(0,18,0),Vector3.new(0,-36,0),params)
 local avatarFloor=hit and hit.Position or candidate
 local avatarPos=avatarFloor+Vector3.new(0,3.05,0)

 local char=player.Character
 if char then
  local archivable=char.Archivable char.Archivable=true
  menuAvatar=char:Clone() char.Archivable=archivable
  if menuAvatar then
   menuAvatar.Name="LocalMenuAvatar"
   for _,d in ipairs(menuAvatar:GetDescendants()) do
    if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
    elseif d:IsA("BasePart") then d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false end
   end
   local hum=menuAvatar:FindFirstChildOfClass("Humanoid")
   if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false end
   local head=menuAvatar:FindFirstChild("Head")
   if head then
    local key=Instance.new("PointLight",head) key.Color=Color3.fromRGB(255,175,158) key.Brightness=.65 key.Range=12 key.Shadows=false
   end
   menuAvatar.Parent=workspace
   menuAvatar:PivotTo(CFrame.lookAt(avatarPos,Vector3.new(cameraPos.X,avatarPos.Y,cameraPos.Z)))
  end
 end
end

local effectDefaults=setmetatable({},{__mode="k"})
local function qualityEffect(e)
 if e:IsA("PostEffect") then
  if effectDefaults[e]==nil then effectDefaults[e]=e.Name=="SuviversMenuGrade" or e.Name=="SuviversMenuBloom" or e.Enabled end
  e.Enabled=not low and effectDefaults[e]
 end
end
Lighting.ChildAdded:Connect(qualityEffect)
local function setQuality()
 player:SetAttribute("LowGraphics",low)
 for _,e in ipairs(Lighting:GetChildren()) do
  qualityEffect(e)
 end
end
player:GetAttributeChangedSignal("LowGraphics"):Connect(function() low=player:GetAttribute("LowGraphics")==true setQuality() end)

for _,b in ipairs(ui:GetDescendants()) do
 if b:IsA("TextButton") then
  local scale=Instance.new("UIScale") scale.Parent=b
  local tween
  local function pulse(v)
   if tween then tween:Cancel() end
   tween=TweenService:Create(scale,TweenInfo.new(.09,Enum.EasingStyle.Quad),{Scale=v}) tween:Play()
  end
  b.MouseEnter:Connect(function() pulse(1.018) end)
  b.MouseLeave:Connect(function() pulse(1) end)
  b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pulse(.965) end end)
  b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pulse(1) end end)
  b.Activated:Connect(function()
   local click=ui.Sonidos:FindFirstChild("Click")
   if click and player:GetAttribute("MenuSounds")~=false then click:Stop() click:Play() end
  end)
 end
end

local function layout()
 local camera=workspace.CurrentCamera if not camera then return end
 local v=camera.ViewportSize local w,h=v.X,v.Y
 local x=math.clamp(w*.035,14,42)
 main.LeftPanel.Visible=false
 main.Logo.AnchorPoint=Vector2.new(.5,.5) main.Logo.Position=UDim2.fromScale(.5,.34) main.Logo.Size=UDim2.new(.52,0,.22,0)
 main.GameName.AnchorPoint=Vector2.new(.5,0) main.GameName.Position=UDim2.fromScale(.5,.43) main.GameName.Size=UDim2.fromOffset(160,24) main.GameName.Text="[ALFA]" main.GameName.TextSize=14
 local cardW=math.min(240,w*.235) local cardH=math.clamp(h*.20,75,132) local gap=10
 for i,card in ipairs({main.Shop,main.Play,main.Inventory}) do
  card.AnchorPoint=Vector2.new(.5,.5) card.Position=UDim2.new(.5,(i-2)*(cardW+gap),.62,0) card.Size=UDim2.fromOffset(cardW,cardH) card.TextSize=math.clamp(w*.018,12,19)
 end
 main.Play.Text="ENTRAR NO LOBBY"
 main.Play.UIStroke.Color=Color3.fromRGB(142,180,105) main.Shop.UIStroke.Color=Color3.fromRGB(193,157,93) main.Inventory.UIStroke.Color=Color3.fromRGB(143,126,185)
 main.Guide.Position=UDim2.new(.5,-math.min(280,w*.40),.62,cardH/2+8) main.Guide.Size=UDim2.fromOffset(math.min(560,w*.8),22) main.Guide.TextXAlignment=Enum.TextXAlignment.Center
 main.Edition.Visible=false main.QuickHelp.Visible=false
 main.Updates.AnchorPoint=Vector2.new(.5,1) main.Updates.Position=UDim2.new(.5,0,1,-24) main.Updates.Size=UDim2.fromOffset(math.min(260,w*.4),34) main.Updates.TextSize=12
 main.Profile.Position=UDim2.new(0,x,0,math.clamp(h*.15,65,108)) main.Profile.Size=UDim2.fromOffset(math.min(300,w*.28),78)
 main.Ajustes.Position=UDim2.new(1,-118,0,22) main.Ajustes.Size=UDim2.fromOffset(44,44)
 creditsButton.Position=UDim2.new(1,-64,0,22) creditsButton.Size=UDim2.fromOffset(44,44) creditsButton.Text="i" creditsButton.TextSize=24
 returnButton.Position=UDim2.new(1,-64,0,122) returnButton.Size=UDim2.fromOffset(46,46) returnButton.Text="⌂" returnButton.TextSize=23
 for _,scene in ipairs({credits,shop,inventory,updates}) do
  local body=scene:FindFirstChild("AjustesFrame") or scene:FindFirstChild("CreditosFrame")
  local title=scene.Tittle
  local pw=math.min(600,w-44) local ph=math.min(390,h-120)
  body.Position=UDim2.new(.5,-pw/2,.5,-ph/2+18) body.Size=UDim2.fromOffset(pw,ph)
  title.Position=UDim2.new(.5,-pw/2,.5,-ph/2-28) title.Size=UDim2.fromOffset(pw-54,42)
  title.TittleText.Size=UDim2.fromScale(1,1)
  scene.Close.Position=UDim2.new(.5,pw/2-44,.5,-ph/2-28) scene.Close.Size=UDim2.fromOffset(44,42)
 end

 credits.CreditosFrame.TextCreditos.Size=UDim2.fromScale(1,1)
end

local function show(name)
 main.Visible=name=="main"
 settings.Visible=name=="settings"
 credits.Visible=name=="credits"
 shop.Visible=name=="shop" inventory.Visible=name=="inventory" updates.Visible=name=="updates"
 creditsButton.Visible=inMenu and name=="main"
 returnButton.Visible=not inMenu and not player:GetAttribute("InRound") and not player:GetAttribute("Spectating")
end

settings.AjustesFrame.Visible=false settings.Tittle.Visible=false settings.Close.Visible=false
settingsControl=settingsModule.build(settings,player,function() show("main") end)
local function profileDisplay()
 local stats=player:FindFirstChild("leaderstats")
 local xp=stats and stats:FindFirstChild("XP") local level=stats and stats:FindFirstChild("Nível") local points=stats and stats:FindFirstChild("Pontos")
 local n=level and level.Value or 1 local value=xp and xp.Value or 0
 local floorXP=15*(n-1)^2+35*(n-1) local nextXP=15*n^2+35*n
 main.Profile.XPBar.Fill.Size=UDim2.fromScale(n>=1000 and 1 or math.clamp((value-floorXP)/(nextXP-floorXP),0,1),1)
 main.Profile.XPBar.Value.Text="NÍVEL "..n.."  •  "..(n>=1000 and "MÁXIMO" or tostring(math.max(0,value-floorXP)).."/"..tostring(nextXP-floorXP))
 main.Profile.Coins.Text="◉  "..tostring(points and points.Value or 0)
 local purchase=shop.CreditosFrame.Purchase
 purchase.Text=player:GetAttribute("Cantor") and "✓ MUSIC DESBLOQUEADO" or "DESBLOQUEAR MUSIC • 20 PONTOS"
 purchase.Active=not player:GetAttribute("Cantor")
end
shop.CreditosFrame.Purchase.Activated:Connect(function()
 if not player:GetAttribute("Cantor") then RS.Survival.Action:FireServer("musicBuy") end
end)
player:GetAttributeChangedSignal("Cantor"):Connect(profileDisplay)
task.spawn(function()
 local stats=player:WaitForChild("leaderstats",25)
 if stats then for _,v in ipairs(stats:GetChildren()) do if v:IsA("IntValue") then v.Changed:Connect(profileDisplay) end end end
 profileDisplay()
end)
local function cardPreview(card,model)
 if not model then return end
 local view=Instance.new("ViewportFrame",card) view.Name="Preview" view.BackgroundTransparency=1 view.Position=UDim2.fromOffset(6,6) view.Size=UDim2.new(1,-12,1,-12) view.ZIndex=1 view.Ambient=Color3.fromRGB(125,112,116) view.LightColor=Color3.fromRGB(255,216,198) view.LightDirection=Vector3.new(-1,-.6,-1)
 local world=Instance.new("WorldModel",view)
 for _,d in ipairs(model:GetDescendants()) do if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") then d:Destroy() elseif d:IsA("BasePart") then d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Anchored=d.Name=="HumanoidRootPart" end end
 model.Parent=world model:PivotTo(CFrame.identity)
 local camera=Instance.new("Camera",view) camera.FieldOfView=35 view.CurrentCamera=camera
 local cf,size=model:GetBoundingBox() local focus=cf.Position+Vector3.new(0,size.Y*.12,0)
 local forward=model.PrimaryPart and model.PrimaryPart.CFrame.LookVector or Vector3.new(0,0,-1)
 camera.CFrame=CFrame.lookAt(focus+forward*math.max(size.Y,size.X)*1.65,focus)
 local caption=Instance.new("TextLabel",card) caption.Name="Caption" caption.Size=UDim2.new(1,-8,0,30) caption.Position=UDim2.new(0,4,1,-34) caption.BackgroundColor3=Color3.fromRGB(10,10,14) caption.BackgroundTransparency=.25 caption.BorderSizePixel=0 caption.Text=card.Text caption.TextColor3=Color3.fromRGB(245,244,245) caption.TextStrokeTransparency=.2 caption.Font=Enum.Font.GothamBold caption.TextScaled=true caption.ZIndex=3
 local cap=Instance.new("UITextSizeConstraint",caption) cap.MaxTextSize=18 cap.MinTextSize=10
 card.TextTransparency=1
end
local jason=RS.Survival:FindFirstChild("PresentationJason")
if jason then local clone=jason:Clone() clone:SetAttribute("PresentationPursuer",true) cardPreview(main.Play,clone) end
local function avatarPreview()
 local old=main.Inventory:FindFirstChild("Preview") if old then old:Destroy() end
 local caption=main.Inventory:FindFirstChild("Caption") if caption then caption:Destroy() end
 if player.Character then local oldA=player.Character.Archivable player.Character.Archivable=true local clone=player.Character:Clone() player.Character.Archivable=oldA cardPreview(main.Inventory,clone) end
end
local function equipmentPreview()
 local body=inventory.CreditosFrame body.Info.Visible=false
 local old=body:FindFirstChild("Avatar") if old then old:Destroy() end
 if not player.Character then return end
 local a=player.Character.Archivable player.Character.Archivable=true local clone=player.Character:Clone() player.Character.Archivable=a
 local holder=Instance.new("TextButton",body) holder.Name="Avatar" holder.Text="" holder.BackgroundTransparency=1 holder.Position=UDim2.fromScale(.3,.04) holder.Size=UDim2.fromScale(.4,.92) holder.Active=false
 cardPreview(holder,clone)
 local cap=holder:FindFirstChild("Caption") if cap then cap.Text="SEU AVATAR" cap.BackgroundTransparency=1 cap.TextSize=12 end
end
for i,item in ipairs({{"LANTERNA","☼","Ilumine o caminho",.03,.12},{"IMPULSO","↑","1 por rodada",.71,.12},{"KIT MÉDICO","+","1 por rodada",.71,.55}}) do
 local slot=Instance.new("Frame",inventory.CreditosFrame) slot.Name="Equipment"..i slot.Position=UDim2.fromScale(item[4],item[5]) slot.Size=UDim2.fromScale(.26,.34) slot.BackgroundColor3=Color3.fromRGB(27,28,34) slot.BackgroundTransparency=.3 slot.BorderSizePixel=0
 local corner=Instance.new("UICorner",slot) corner.CornerRadius=UDim.new(0,9)
 local stroke=Instance.new("UIStroke",slot) stroke.Color=Color3.fromRGB(151,149,166) stroke.Thickness=2 stroke.Transparency=.4
 local icon=Instance.new("TextLabel",slot) icon.Size=UDim2.fromScale(1,.6) icon.BackgroundTransparency=1 icon.Text=item[2] icon.TextColor3=Color3.fromRGB(218,216,227) icon.TextScaled=true icon.Font=Enum.Font.GothamBold
 local title=Instance.new("TextLabel",slot) title.Size=UDim2.fromScale(1,.2) title.Position=UDim2.fromScale(0,.59) title.BackgroundTransparency=1 title.Text=item[1] title.TextColor3=Color3.new(1,1,1) title.TextScaled=true title.Font=Enum.Font.GothamBold local limit=Instance.new("UITextSizeConstraint",title) limit.MaxTextSize=13
 local desc=Instance.new("TextLabel",slot) desc.Size=UDim2.fromScale(1,.18) desc.Position=UDim2.fromScale(0,.8) desc.BackgroundTransparency=1 desc.Text=item[3] desc.TextColor3=Color3.fromRGB(166,165,178) desc.TextScaled=true desc.Font=Enum.Font.Gotham local cap=Instance.new("UITextSizeConstraint",desc) cap.MaxTextSize=11
end
avatarPreview() equipmentPreview()
player.CharacterAdded:Connect(function() if inMenu then avatarPreview() equipmentPreview() end end)
local musicIcon=Instance.new("TextLabel",main.Shop) musicIcon.BackgroundTransparency=1 musicIcon.Text="♫" musicIcon.TextColor3=Color3.fromRGB(215,185,124) musicIcon.TextSize=45 musicIcon.Size=UDim2.fromScale(1,.65) musicIcon.Position=UDim2.fromScale(0,0)
main.Shop.TextYAlignment=Enum.TextYAlignment.Bottom
local function bindCamera()
 RunService:UnbindFromRenderStep("SurviversMenuCamera")
 RunService:BindToRenderStep("SurviversMenuCamera",Enum.RenderPriority.Camera.Value+2,function()
  if not inMenu or player:GetAttribute("VoidActive") then return end
  local camera=workspace.CurrentCamera if not camera then return end
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=56
  if menuCameraCF then
   local t=os.clock()
   camera.CFrame=(low or player:GetAttribute("ReducedMotion")) and menuCameraCF or menuCameraCF*CFrame.Angles(math.sin(t*.18)*.006,math.sin(t*.13)*.012,0)
  end
 end)
end

local function open()
 if player:GetAttribute("InRound") or player:GetAttribute("Spectating") then return end
 inMenu=true player:SetAttribute("InMenu",true)
 if controls then controls:Disable() end
 local camera=workspace.CurrentCamera if camera then oldFov=camera.FieldOfView end
 avatarPreview() equipmentPreview()
 if not main.Play:FindFirstChild("Preview") and jason then local clone=jason:Clone() clone:SetAttribute("PresentationPursuer",true) cardPreview(main.Play,clone) end
 buildPrivateScene()
 enableMenuLook()
 bindCamera()
 show("main")
 layout()
end

local function close()
 inMenu=false player:SetAttribute("InMenu",false)
 disableMenuLook()
 RunService:UnbindFromRenderStep("SurviversMenuCamera")
 clearPrivateScene()
 for _,card in ipairs({main.Play,main.Inventory}) do
  for _,name in ipairs({"Preview","Caption"}) do local v=card:FindFirstChild(name) if v then v:Destroy() end end
 end
 local portrait=inventory.CreditosFrame:FindFirstChild("Avatar") if portrait then portrait:Destroy() end
 local camera=workspace.CurrentCamera
 if camera then
  camera.CameraType=Enum.CameraType.Custom camera.FieldOfView=oldFov
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then camera.CameraSubject=hum end
 end
 if controls and not player:GetAttribute("VoidActive") then controls:Enable() end
 show("playing")
end

local function navigate(fn)
 if busy then return end busy=true
 transition.Visible=true
 local a=TweenService:Create(transition,TweenInfo.new(.12),{BackgroundTransparency=0}) a:Play() a.Completed:Wait()
 fn()
 local b=TweenService:Create(transition,TweenInfo.new(.16),{BackgroundTransparency=1}) b:Play() b.Completed:Wait()
 transition.Visible=false busy=false
end

main.Play.Activated:Connect(function() navigate(close) end)
main.Ajustes.Activated:Connect(function() navigate(function() show("settings") end) end)
main.Shop.Activated:Connect(function() navigate(function() show("shop") end) end)
main.Inventory.Activated:Connect(function() navigate(function() show("inventory") end) end)
main.Updates.Activated:Connect(function() navigate(function() show("updates") end) end)
for _,scene in ipairs({shop,inventory,updates}) do scene.Close.Activated:Connect(function() navigate(function() show("main") end) end) end
creditsButton.Activated:Connect(function() navigate(function() show("credits") end) end)
settings.Close.Activated:Connect(function() navigate(function() show("main") end) end)
credits.Close.Activated:Connect(function() navigate(function() show("main") end) end)
returnButton.Activated:Connect(function() navigate(open) end)

player.CharacterAdded:Connect(function(char)
 if inMenu then task.defer(buildPrivateScene) end
end)

local cameraConn
local function watchCamera()
 if cameraConn then cameraConn:Disconnect() end
 if workspace.CurrentCamera then cameraConn=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
 layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
setQuality()
show("loading")
bindCamera()

task.spawn(function()
 local ps=player:WaitForChild("PlayerScripts",10)
 local pm=ps and ps:WaitForChild("PlayerModule",10)
 if pm then
  local ok,m=pcall(require,pm)
  if ok then controls=m:GetControls() if inMenu then controls:Disable() end end
 end
end)

while not player:GetAttribute("SweanLoadingDone") do task.wait(.1) end
open()

local function refreshReturn()
 returnButton.Visible=not inMenu and not player:GetAttribute("InRound") and not player:GetAttribute("Spectating")
end
player:GetAttributeChangedSignal("InRound"):Connect(refreshReturn)
player:GetAttributeChangedSignal("Spectating"):Connect(refreshReturn)

