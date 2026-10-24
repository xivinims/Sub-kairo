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
local menuJason=nil
local menuHorrorDark=nil
local menuCameraCF=nil
local horrorToken=0
local firstMenuIntro=true
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
 if menuJason then menuJason:Destroy() menuJason=nil end
 if menuHorrorDark then menuHorrorDark:Destroy() menuHorrorDark=nil end
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
   for _,d in ipairs(menuAvatar:GetDescendants()) do
    if d:IsA("BasePart") then
     local accessory=d:FindFirstAncestorOfClass("Accessory")
     if d.Name~="Head" and not accessory then d.LocalTransparencyModifier=1 end
    end
   end
   if head then
    local key=Instance.new("PointLight",head) key.Color=Color3.fromRGB(255,175,158) key.Brightness=.65 key.Range=12 key.Shadows=false
   end
   menuAvatar.Parent=workspace
   menuAvatar:PivotTo(CFrame.lookAt(avatarPos,Vector3.new(cameraPos.X,avatarPos.Y,cameraPos.Z)))
   if head and menuCameraCF then
    local desired=menuCameraCF.Position+menuCameraCF.LookVector*1.55+menuCameraCF.RightVector*.52-menuCameraCF.UpVector*.08
    local delta=desired-head.Position
    menuAvatar:PivotTo(menuAvatar:GetPivot()+delta)
   end
   menuAvatar:SetAttribute("ClosePortrait",true)
   menuAvatar:SetAttribute("HorrorVisible",true)
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
 main.Logo.AnchorPoint=Vector2.new(.5,.5) main.Logo.Position=UDim2.fromScale(.5,.19) main.Logo.Size=UDim2.new(.42,0,.17,0)
 main.GameName.Visible=false
 local navW=math.clamp(w*.23,168,224) local navH=math.clamp(h*.072,28,38)
 local nav={main.Play,main.Shop,main.Inventory,main.Ajustes,main.Updates,creditsButton}
 local labels={"ENTRAR NO LOBBY","LOJA","INVENTÁRIO","AJUSTES","NOVIDADES","CRÉDITOS"}
 for i,b in ipairs(nav) do
  b.AnchorPoint=Vector2.new(.5,.5)
  b.Position=UDim2.new(.5,0,.44+(i-1)*.072,0)
  b.Size=UDim2.fromOffset(navW,navH)
  b.Text=labels[i]
  b.TextSize=math.clamp(w*.017,13,18)
  b.Font=Enum.Font.GothamMedium
  b.BackgroundTransparency=1
  b.TextTransparency=0
  b.UIStroke.Enabled=true
  b.UIStroke.Color=Color3.fromRGB(235,235,239)
  b.UIStroke.Thickness=1.2
  b.UIStroke.Transparency=i==1 and .22 or .82
  local inset=b:FindFirstChild("Inset") if inset then inset.Visible=false end
 end
 main.Guide.AnchorPoint=Vector2.new(.5,0) main.Guide.Position=UDim2.new(.5,0,.90,0) main.Guide.Size=UDim2.fromOffset(math.min(480,w*.72),20) main.Guide.TextXAlignment=Enum.TextXAlignment.Center
 main.Edition.Visible=false main.QuickHelp.Visible=false
 main.Profile.Position=UDim2.new(0,x,0,math.clamp(h*.13,58,92)) main.Profile.Size=UDim2.fromOffset(math.min(285,w*.30),72)
 returnButton.Position=UDim2.new(0,18,0,72) returnButton.Size=UDim2.fromOffset(42,42) returnButton.Text="⌂" returnButton.TextSize=23
 returnButton.BackgroundTransparency=1 returnButton.UIStroke.Enabled=false
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
local function avatarPreview()
 local old=main.Inventory:FindFirstChild("Preview") if old then old:Destroy() end
 local caption=main.Inventory:FindFirstChild("Caption") if caption then caption:Destroy() end
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
local function revealMenuJason()
 if menuJason then menuJason:Destroy() menuJason=nil end
 local template=RS:WaitForChild("Survival"):FindFirstChild("PresentationJason")
 if not template or not menuCameraCF or not menuScene then return end
 menuJason=template:Clone()
 menuJason.Name="LocalMenuJason"
 menuJason:SetAttribute("MenuHorrorJason",true)
 for _,d in ipairs(menuJason:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false d.CastShadow=true end
 end
 local _,jasonSize=menuJason:GetBoundingBox()
 local desired=menuCameraCF.Position+menuCameraCF.LookVector*9.5+menuCameraCF.RightVector*1.7
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={menuScene}
 local hit=workspace:Raycast(desired+Vector3.new(0,18,0),Vector3.new(0,-36,0),params)
 local ground=hit and hit.Position or desired
 local pos=ground+Vector3.new(0,jasonSize.Y*.5,0)
 local look=Vector3.new(menuCameraCF.Position.X,pos.Y,menuCameraCF.Position.Z)
 menuJason.Parent=workspace
 menuJason:PivotTo(CFrame.lookAt(pos,look))
 local head=menuJason:FindFirstChild("Head",true)
 if head and head:IsA("BasePart") then
  local glow=Instance.new("PointLight",head)
  glow.Name="MenuJasonGlow" glow.Color=Color3.fromRGB(118,18,22) glow.Brightness=.42 glow.Range=8 glow.Shadows=false
 end
 ui:SetAttribute("MenuJasonVisible",true)
end

local function startHorrorBeat()
 horrorToken+=1 local token=horrorToken
 ui:SetAttribute("HorrorMenuEffect",true)
 ui:SetAttribute("MenuJasonVisible",false)
 local lights={}
 if menuScene then
  for _,d in ipairs(menuScene:GetDescendants()) do
   if d:IsA("Light") then table.insert(lights,{light=d,enabled=d.Enabled,brightness=d.Brightness}) end
  end
 end
 local function lightsOn(on)
  for _,entry in ipairs(lights) do if entry.light.Parent then
   entry.light.Enabled=on and entry.enabled or false
   entry.light.Brightness=on and entry.brightness or 0
  end end
 end
 task.spawn(function()
  task.wait(ui:GetAttribute("HorrorDelaySeconds") or 12)
  if token~=horrorToken or not inMenu then return end

  if menuHorrorDark then menuHorrorDark:Destroy() end
  menuHorrorDark=Instance.new("ColorCorrectionEffect")
  menuHorrorDark.Name="SuviversMenuHorrorDark"
  menuHorrorDark.Brightness=0 menuHorrorDark.Contrast=0 menuHorrorDark.Saturation=0 menuHorrorDark.Parent=Lighting
  TweenService:Create(menuHorrorDark,TweenInfo.new(.9,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{
   Brightness=-.18,Contrast=.14,Saturation=-.36,TintColor=Color3.fromRGB(188,168,176)
  }):Play()

  for _,delay in ipairs({.07,.12,.05,.16,.08,.10,.06,.15}) do
   if token~=horrorToken or not inMenu then return end
   lightsOn(false) task.wait(delay)
   lightsOn(true) task.wait(.075)
  end
  if token~=horrorToken or not inMenu then return end

  lightsOn(false)
  task.wait(.13)
  if menuAvatar and menuAvatar.Parent then
   for _,d in ipairs(menuAvatar:GetDescendants()) do
    if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end
   end
   menuAvatar:SetAttribute("HorrorVisible",false)
  end

  task.wait(.18)
  if token~=horrorToken or not inMenu then return end
  revealMenuJason()
  lightsOn(true)

  local vignette=main:FindFirstChild("Vignette")
  if vignette then
   vignette.BackgroundColor3=Color3.new(0,0,0)
   vignette.BackgroundTransparency=.68
   local gradient=vignette:FindFirstChildOfClass("UIGradient")
   if gradient then gradient.Enabled=false end
  end
  ui:SetAttribute("HorrorBlackout",false)
  ui:SetAttribute("HorrorJasonReveal",true)
 end)
end

local function animateMenuIntro()
 if not firstMenuIntro and not player:GetAttribute("MenuIntroPending") then return end
 firstMenuIntro=false player:SetAttribute("MenuIntroPending",false)
 ui:SetAttribute("MenuIntroAnimated",true)
 local finalPos=main.Logo.Position local finalSize=main.Logo.Size
 main.Logo.Position=UDim2.fromScale(.5,.50) main.Logo.Size=UDim2.new(.68,0,.25,0)
 local nav={main.Play,main.Shop,main.Inventory,main.Ajustes,main.Updates,creditsButton}
 for _,b in ipairs(nav) do b.TextTransparency=1 b.UIStroke.Transparency=1 end
 TweenService:Create(main.Logo,TweenInfo.new(.7,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{Position=finalPos,Size=finalSize}):Play()
 task.delay(.42,function()
  for i,b in ipairs(nav) do task.delay((i-1)*.055,function()
   if not inMenu then return end
   TweenService:Create(b,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
   TweenService:Create(b.UIStroke,TweenInfo.new(.22),{Transparency=i==1 and .22 or .82}):Play()
  end) end
 end)
end

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
 ui:SetAttribute("HorrorBlackout",false)
 ui:SetAttribute("HorrorJasonReveal",false)
 ui:SetAttribute("MenuJasonVisible",false)
 if menuJason then menuJason:Destroy() menuJason=nil end
 if menuHorrorDark then menuHorrorDark:Destroy() menuHorrorDark=nil end
 local vignette=main:FindFirstChild("Vignette")
 if vignette then
  vignette.BackgroundTransparency=1
  local gradient=vignette:FindFirstChildOfClass("UIGradient")
  if gradient then gradient.Enabled=true end
 end
 if controls then controls:Disable() end
 local camera=workspace.CurrentCamera if camera then oldFov=camera.FieldOfView end
 avatarPreview() equipmentPreview()
 for _,card in ipairs({main.Play,main.Shop,main.Inventory,main.Ajustes,main.Updates}) do
  local preview=card:FindFirstChild("Preview") if preview then preview:Destroy() end
  local caption=card:FindFirstChild("Caption") if caption then caption:Destroy() end
  card.TextTransparency=0
 end
 buildPrivateScene()
 enableMenuLook()
 bindCamera()
 show("main")
 layout()
 animateMenuIntro()
 startHorrorBeat()
end

local function close()
 horrorToken+=1
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

