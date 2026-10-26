local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer local net=RS:WaitForChild("Survival") local event=net.Action
local config=require(net.Config)
local Lighting=game:GetService("Lighting")
local Settings=require(net:WaitForChild("SettingsPanel"))
Settings.initialize(player)
local function english() return player:GetAttribute("GameLanguage")=="en" end
local function L(pt,en) return english() and (en or pt) or pt end

local roundMusic=SoundService:FindFirstChild("SuviversMatchMusic")
if not roundMusic then
 roundMusic=Instance.new("Sound")
 roundMusic.Name="SuviversMatchMusic"
 roundMusic.SoundId="rbxassetid://108879410219148"
 roundMusic.Volume=.35
 roundMusic.Looped=true
 roundMusic.Parent=SoundService
end
roundMusic.SoundId="rbxassetid://108879410219148"
roundMusic.Volume=.35
roundMusic.Looped=true
local roundMusicActive=false
local function updateRoundMusic(forceStop)
 local shouldPlay=not forceStop
  and player:GetAttribute("InRound")==true
  and player:GetAttribute("InMenu")~=true
  and player:GetAttribute("VoidActive")~=true
  and player:GetAttribute("Spectating")~=true
  and player:GetAttribute("RoundStatus")~="eliminated"
  and player:GetAttribute("SweanLoadingDone")==true
 if shouldPlay then
  if not roundMusicActive then
   roundMusicActive=true
   if not roundMusic.IsPlaying then roundMusic:Play() end
  end
 elseif roundMusicActive or forceStop or roundMusic.IsPlaying then
  roundMusicActive=false
  roundMusic:Stop()
  roundMusic.TimePosition=0
 end
end
for _,attr in ipairs({"InRound","InMenu","VoidActive","Spectating","RoundStatus","SweanLoadingDone"}) do
 player:GetAttributeChangedSignal(attr):Connect(function() updateRoundMusic(false) end)
end

local gui=Instance.new("ScreenGui") gui.Name="SurvivalHUD" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=30 gui.Parent=player:WaitForChild("PlayerGui")
local function panel(name,size,pos)
 local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=Color3.fromRGB(12,12,15) f.BackgroundTransparency=.22 f.BorderSizePixel=0 f.Parent=gui
 local c=Instance.new("UICorner",f) c.CornerRadius=UDim.new(0,16)
 local s=Instance.new("UIStroke",f) s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Color=Color3.fromRGB(142,142,150) s.Transparency=.4 s.Thickness=2
 return f
end
local function text(parent,name,value,size,pos)
 local l=Instance.new("TextLabel") l.Name=name l.Text=value l.Size=size l.Position=pos l.BackgroundTransparency=1 l.Font=Enum.Font.GothamMedium l.TextSize=15 l.TextColor3=Color3.fromRGB(224,228,232) l.TextStrokeColor3=Color3.new(0,0,0) l.TextStrokeTransparency=.55 l.TextWrapped=true l.Parent=parent return l
end
local function button(parent,name,label,size,pos,callback)
 local b=Instance.new("TextButton") b.Name=name b.Text=label b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(18,18,22) b.BackgroundTransparency=.12 b.TextColor3=Color3.fromRGB(239,239,242) b.Font=Enum.Font.GothamSemibold b.TextSize=14 b.BorderSizePixel=0 b.Parent=parent
 local c=Instance.new("UICorner",b) c.CornerRadius=UDim.new(0,12)
 b.AutoButtonColor=false
 local scale=Instance.new("UIScale",b)
 local feedback
 local function pulse(value)
  if feedback then feedback:Cancel() end
  feedback=TweenService:Create(scale,TweenInfo.new(.1),{Scale=value}) feedback:Play()
 end
 b.MouseEnter:Connect(function() pulse(1.04) end)
 b.MouseLeave:Connect(function() pulse(1) end)
 b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pulse(.92) end end)
 b.InputEnded:Connect(function() pulse(1) end)
 local stroke=Instance.new("UIStroke",b) stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border stroke.Color=Color3.fromRGB(150,150,158) stroke.Transparency=.72
 b.Activated:Connect(function()
  if player:GetAttribute("MenuSounds")~=false then local s=RS.XNMedia.MenuClick:Clone() s.Parent=b s:Play() game:GetService("Debris"):AddItem(s,3) end
  callback()
 end) return b
end
-- Native vector icons stay crisp without emoji/font or image-loading dependencies.
local function iconCanvas(parent,name,size,pos)
 local f=Instance.new("Frame",parent) f.Name=name f.Size=size f.Position=pos f.BackgroundTransparency=1 f.Active=false return f
end
local function iconLine(parent,name,x1,y1,x2,y2,width)
 local dx,dy=x2-x1,y2-y1
 local f=Instance.new("Frame",parent) f.Name=name f.AnchorPoint=Vector2.new(.5,.5)
 f.Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2) f.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),width or 2)
 f.Rotation=math.deg(math.atan2(dy,dx)) f.BackgroundColor3=Color3.fromRGB(238,238,241) f.BorderSizePixel=0
 Instance.new("UICorner",f).CornerRadius=UDim.new(1,0) return f
end
local countdown=panel("Countdown",UDim2.fromOffset(280,40),UDim2.new(.5,-140,0,10))
countdown.BackgroundTransparency=1 countdown.UIStroke.Enabled=false countdown.Visible=false
local countdownIcon=iconCanvas(countdown,"Icon",UDim2.fromOffset(24,24),UDim2.fromOffset(3,8))
local ring=iconCanvas(countdownIcon,"ClockFace",UDim2.fromOffset(22,22),UDim2.fromOffset(1,1))
Instance.new("UICorner",ring).CornerRadius=UDim.new(1,0)
local clockStroke=Instance.new("UIStroke",ring) clockStroke.Thickness=2 clockStroke.Color=Color3.fromRGB(238,238,241)
iconLine(countdownIcon,"HourHand",12,12,12,6,2)
iconLine(countdownIcon,"MinuteHand",12,12,17,15,2)
local countdownText=text(countdown,"Time",L("Aguardando jogadores","Waiting for players"),UDim2.new(1,-38,1,0),UDim2.fromOffset(36,0))
countdownText.TextSize=14 countdownText.Font=Enum.Font.GothamBold countdownText.TextXAlignment=Enum.TextXAlignment.Left countdownText.TextWrapped=false
local top=panel("Round",UDim2.fromOffset(130,38),UDim2.new(.5,-65,0,8))
top.BackgroundTransparency=1 top.UIStroke.Enabled=false
local timer=text(top,"Timer","0:00",UDim2.fromScale(1,1),UDim2.new()) timer.Font=Enum.Font.GothamBold timer.TextSize=17
local detail=text(top,"Detail","",UDim2.new(),UDim2.new()) detail.Visible=false
local mode="walk"
local topActions=Instance.new("Frame",gui) topActions.Name="TopActions" topActions.BackgroundTransparency=1
topActions.AnchorPoint=Vector2.new(1,1) topActions.Size=UDim2.fromOffset(208,64) topActions.Position=UDim2.new(1,-24,1,-30)
local bar=Instance.new("Frame",gui) bar.Name="Actions" bar.BackgroundTransparency=1
bar.AnchorPoint=Vector2.new(1,1) bar.Size=UDim2.fromOffset(150,74) bar.Position=UDim2.new(1,-24,1,-110)
local actionRects={Run={373,78,253,258},RunActive={658,71,258,263},Crouch={952,77,258,262},Attack={42,62,294,294},ReviveNearby={642,386,257,257},CarryNearby={1289,720,217,215}}
local function setActionArt(b,key)
 local art=b:FindFirstChild("ReferenceActionArt") if not art then return end
 local r=actionRects[key] if not r then return end
 art.ImageRectOffset=Vector2.new(r[1],r[2]) art.ImageRectSize=Vector2.new(r[3],r[4])
 b.Text=""
end
local function cleanAction(parent,name,label,size,pos,callback)
 local b=button(parent,name,label,size,pos,callback)
 b:SetAttribute("ReferenceActionButton",true)
 b.BackgroundTransparency=1 b.TextSize=24 b.TextStrokeTransparency=.38
 local texture=net:GetAttribute("ActionAtlasTexture")
 if texture and texture~="" and actionRects[name] then
  local art=Instance.new("ImageLabel") art.Name="ReferenceActionArt" art.BackgroundTransparency=1 art.Size=UDim2.fromScale(1,1) art.Image=texture art.Active=false
  local corner=Instance.new("UICorner",art) corner.CornerRadius=UDim.new(1,0)
  art.Parent=b setActionArt(b,name)
 end
 b.UIStroke.Enabled=false b.UICorner.CornerRadius=UDim.new(1,0)
 return b
end
local lantern=cleanAction(topActions,"Lantern",L("LANTERNA","LANTERN"),UDim2.fromOffset(64,64),UDim2.fromOffset(0,0),function()
 if player:GetAttribute("Downed") or player:GetAttribute("IsJason") then return end
 event:FireServer("flashlight")
end)
lantern.TextSize=9
lantern.BackgroundTransparency=.34
lantern.BackgroundColor3=Color3.fromRGB(25,26,30)
lantern:SetAttribute("LanternAssetId",11906391298)
lantern:SetAttribute("CrackleSoundAssetId",112352139435056)

local crouch=cleanAction(topActions,"Crouch",L("AGACHAR","CROUCH"),UDim2.fromOffset(64,64),UDim2.fromOffset(72,0),function()
 if player:GetAttribute("Downed") or player:GetAttribute("IsJason") then return end
 local nextMode=(player:GetAttribute("MoveMode")=="crouch") and "walk" or "crouch"
 mode=nextMode event:FireServer("mode",nextMode)
end)
crouch.TextSize=10 crouch.BackgroundTransparency=.4 crouch.BackgroundColor3=Color3.fromRGB(25,26,30)

local run=cleanAction(topActions,"Run",L("CORRER","RUN"),UDim2.fromOffset(64,64),UDim2.fromOffset(144,0),function() end)
run.TextSize=11 run.BackgroundTransparency=.35 run.BackgroundColor3=Color3.fromRGB(25,26,30)
local heldRunInput=nil
local function stopHeldRun(input)
 if heldRunInput and (not input or input==heldRunInput) then
  heldRunInput=nil
  mode="walk"
  event:FireServer("mode","walk")
 end
end
run.InputBegan:Connect(function(input)
 if player:GetAttribute("Downed") then return end
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  heldRunInput=input
  if mode~="run" then mode="run" event:FireServer("mode","run") end
 end
end)
run.InputEnded:Connect(function(input) stopHeldRun(input) end)
local reviveNearby=cleanAction(bar,"ReviveNearby","+",UDim2.fromOffset(66,66),UDim2.fromOffset(4,4),function()
 event:FireServer("revive")
end)
reviveNearby.TextSize=38 reviveNearby.Visible=false
local carryNearby=cleanAction(bar,"CarryNearby","CARREGAR",UDim2.fromOffset(66,66),UDim2.fromOffset(80,4),function()
 event:FireServer("carry")
end)
carryNearby.TextSize=9 carryNearby.Visible=false
local attackButton=cleanAction(bar,"Attack",L("ATACAR","ATTACK"),UDim2.fromOffset(66,66),UDim2.fromOffset(80,4),function()
 event:FireServer("attack")
end)
attackButton.TextSize=10 attackButton.Visible=false

local function hideDefaultJump()
 local pg=player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
 for _,d in ipairs(pg:GetDescendants()) do
  if d.Name=="JumpButton" and d:IsA("GuiButton") and not d:IsDescendantOf(gui) then d.Visible=false end
 end
end
hideDefaultJump()
player:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
 if d.Name=="JumpButton" and d:IsA("GuiButton") and not d:IsDescendantOf(gui) then d.Visible=false end
end)
local function actionLayout()
 local cam=workspace.CurrentCamera if not cam then return end
 local scale=math.clamp(cam.ViewportSize.Y/650,.76,1)*math.clamp((player:GetAttribute("ControlScale") or 100)/100,.8,1.2)
 local bottomScale=bar:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",bar) bottomScale.Scale=scale
 local topScale=topActions:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",topActions) topScale.Scale=math.min(scale,.96)
 topActions.Position=UDim2.new(1,-24,1,-30)
 bar.Position=UDim2.new(1,-24,1,-110)
end
local notice=text(gui,"Notice","",UDim2.new(.72,0,0,46),UDim2.new(.14,0,1,-132)) notice.TextSize=15
local settingsOverlay=Instance.new("Frame",gui) settingsOverlay.Name="SettingsOverlay" settingsOverlay.Size=UDim2.fromScale(1,1) settingsOverlay.BackgroundColor3=Color3.new(0,0,0) settingsOverlay.BackgroundTransparency=.82 settingsOverlay.ZIndex=40 settingsOverlay.Visible=false
local settingsUI=Settings.build(settingsOverlay,player,function() settingsOverlay.Visible=false end)
local settingsButton=button(gui,"SettingsButton","⚙",UDim2.fromOffset(44,44),UDim2.new(1,-52,0,2),function() settingsOverlay.Visible=not settingsOverlay.Visible end) settingsButton.TextSize=27 settingsButton.BackgroundTransparency=1 settingsButton.UIStroke.Enabled=false
local shopOverlay=Instance.new("Frame",gui)
shopOverlay.Name="KillerShop"
shopOverlay.Size=UDim2.fromScale(1,1)
shopOverlay.BackgroundColor3=Color3.fromRGB(0,0,0)
shopOverlay.BackgroundTransparency=.48
shopOverlay.ZIndex=115
shopOverlay.Visible=false

-- Large distressed black/white store window inspired by the supplied reference.
local shopPanel=panel("ShopPanel",UDim2.new(.88,0,.76,0),UDim2.new(.06,0,.12,0))
shopPanel.Parent=shopOverlay
shopPanel.ZIndex=116
shopPanel.BackgroundTransparency=.08
shopPanel.BackgroundColor3=Color3.fromRGB(5,5,6)
shopPanel:SetAttribute("Style","DistressedStore")
shopPanel.UIStroke.Color=Color3.fromRGB(238,238,232)
shopPanel.UIStroke.Transparency=.10
shopPanel.UIStroke.Thickness=2
local shopLimit=Instance.new("UISizeConstraint",shopPanel)
shopLimit.MaxSize=Vector2.new(1020,590)
shopLimit.MinSize=Vector2.new(650,390)

local innerBorder=Instance.new("Frame",shopPanel)
innerBorder.Name="InnerBorder"
innerBorder.Position=UDim2.fromOffset(8,8)
innerBorder.Size=UDim2.new(1,-16,1,-16)
innerBorder.BackgroundTransparency=1
innerBorder.ZIndex=116
local innerStroke=Instance.new("UIStroke",innerBorder)
innerStroke.Color=Color3.fromRGB(215,215,210)
innerStroke.Transparency=.48
innerStroke.Thickness=1

local function scratch(parent,name,pos,size,rotation,alpha)
 local line=Instance.new("Frame",parent)
 line.Name=name
 line.Position=pos
 line.Size=size
 line.Rotation=rotation or 0
 line.BorderSizePixel=0
 line.BackgroundColor3=Color3.fromRGB(232,232,226)
 line.BackgroundTransparency=alpha or .62
 line.ZIndex=117
 return line
end
scratch(shopPanel,"ScratchTopA",UDim2.new(.14,0,0,7),UDim2.new(.23,0,0,1),-1,.50)
scratch(shopPanel,"ScratchTopB",UDim2.new(.51,0,0,10),UDim2.new(.18,0,0,1),1,.63)
scratch(shopPanel,"ScratchBottomA",UDim2.new(.21,0,1,-10),UDim2.new(.30,0,0,1),1,.56)
scratch(shopPanel,"ScratchLeftA",UDim2.new(0,10,.34,0),UDim2.fromOffset(1,82),-1,.56)
scratch(shopPanel,"ScratchRightA",UDim2.new(1,-11,.18,0),UDim2.fromOffset(1,110),1,.60)

-- Left vertical rail.
local shopRail=Instance.new("Frame",shopPanel)
shopRail.Name="SideRail"
shopRail.Position=UDim2.fromOffset(14,54)
shopRail.Size=UDim2.new(0,48,1,-72)
shopRail.BackgroundTransparency=1
shopRail.ZIndex=118
local railLayout=Instance.new("UIListLayout",shopRail)
railLayout.Padding=UDim.new(0,8)
railLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function railButton(name,label,order,callback)
 local b=button(shopRail,name,label,UDim2.fromOffset(44,44),UDim2.new(),callback)
 b.LayoutOrder=order
 b.ZIndex=119
 b.Font=Enum.Font.GothamBlack
 b.TextSize=18
 b.BackgroundColor3=Color3.fromRGB(8,8,9)
 b.BackgroundTransparency=.05
 b.UIStroke.Color=Color3.fromRGB(224,224,218)
 b.UIStroke.Transparency=.22
 b.UIStroke.Thickness=1
 b:SetAttribute("RailStyle",true)
 return b
end

-- Top tabs.
local tabBar=Instance.new("Frame",shopPanel)
tabBar.Name="Tabs"
tabBar.Position=UDim2.fromOffset(72,14)
tabBar.Size=UDim2.new(.62,-90,0,34)
tabBar.BackgroundTransparency=1
tabBar.ZIndex=118
local tabLayout=Instance.new("UIListLayout",tabBar)
tabLayout.FillDirection=Enum.FillDirection.Horizontal
tabLayout.Padding=UDim.new(0,2)
tabLayout.SortOrder=Enum.SortOrder.LayoutOrder

local shopTabs={}
local activeShopTab="Killers"
local shopPlaceholder

local function styleTab(b,active)
 b.BackgroundTransparency=active and 0 or 1
 b.BackgroundColor3=Color3.fromRGB(238,238,232)
 b.TextColor3=active and Color3.fromRGB(8,8,9) or Color3.fromRGB(224,224,218)
 b.UIStroke.Color=Color3.fromRGB(225,225,220)
 b.UIStroke.Transparency=active and .10 or .55
 b.Font=Enum.Font.Garamond
end

local shopTitle=text(shopPanel,"Title","",UDim2.fromOffset(1,1),UDim2.fromOffset(-10,-10))
shopTitle.Visible=false
local shopSubtitle=text(shopPanel,"Subtitle","",UDim2.fromOffset(1,1),UDim2.fromOffset(-10,-10))
shopSubtitle.Visible=false

local shopBalance=text(shopPanel,"Balance",L("0 PONTOS","0 POINTS"),UDim2.fromOffset(140,28),UDim2.new(0,74,1,-42))
shopBalance.TextSize=12
shopBalance.Font=Enum.Font.Garamond
shopBalance.ZIndex=119
shopBalance.TextXAlignment=Enum.TextXAlignment.Left
shopBalance.TextColor3=Color3.fromRGB(235,235,229)

local shopClose=button(shopPanel,"Close","×",UDim2.fromOffset(34,30),UDim2.new(1,-43,0,12),function()
 shopOverlay.Visible=false
end)
shopClose.ZIndex=122
shopClose.TextSize=22
shopClose.Font=Enum.Font.GothamBold
shopClose.BackgroundTransparency=1
shopClose.UIStroke.Transparency=1

-- Search field in the reference-style top bar.
local searchWrap=Instance.new("Frame",shopPanel)
searchWrap.Name="SearchWrap"
searchWrap.Position=UDim2.new(.58,0,0,14)
searchWrap.Size=UDim2.new(.20,0,0,34)
searchWrap.BackgroundTransparency=1
searchWrap.ZIndex=118
local searchIcon=text(searchWrap,"Icon","⌕",UDim2.fromOffset(24,30),UDim2.fromOffset(0,2))
searchIcon.Font=Enum.Font.Garamond
searchIcon.TextSize=18
searchIcon.TextColor3=Color3.fromRGB(210,210,205)
searchIcon.ZIndex=119
local shopSearch=Instance.new("TextBox",searchWrap)
shopSearch.Name="Search"
shopSearch.Position=UDim2.fromOffset(25,0)
shopSearch.Size=UDim2.new(1,-25,1,0)
shopSearch.BackgroundTransparency=1
shopSearch.BorderSizePixel=0
shopSearch.ClearTextOnFocus=false
shopSearch.Font=Enum.Font.Garamond
shopSearch.Text=""
shopSearch.PlaceholderText=L("PESQUISAR","SEARCH")
shopSearch.PlaceholderColor3=Color3.fromRGB(115,115,118)
shopSearch.TextColor3=Color3.fromRGB(235,235,230)
shopSearch.TextSize=13
shopSearch.TextXAlignment=Enum.TextXAlignment.Left
shopSearch.ZIndex=119
scratch(searchWrap,"SearchLine",UDim2.new(0,0,1,-2),UDim2.new(1,0,0,1),0,.35)

-- Main center grid.
local shopList=Instance.new("ScrollingFrame",shopPanel)
shopList.Name="Items"
shopList.Position=UDim2.fromOffset(74,58)
shopList.Size=UDim2.new(.66,-80,1,-112)
shopList.BackgroundColor3=Color3.fromRGB(7,7,8)
shopList.BackgroundTransparency=.34
shopList.BorderSizePixel=0
shopList.AutomaticCanvasSize=Enum.AutomaticSize.Y
shopList.CanvasSize=UDim2.new()
shopList.ScrollBarThickness=2
shopList.ScrollBarImageColor3=Color3.fromRGB(220,220,214)
shopList.ZIndex=117
local gridPad=Instance.new("UIPadding",shopList)
gridPad.PaddingTop=UDim.new(0,8)
gridPad.PaddingLeft=UDim.new(0,8)
gridPad.PaddingRight=UDim.new(0,8)
gridPad.PaddingBottom=UDim.new(0,8)
local shopLayout=Instance.new("UIGridLayout",shopList)
shopLayout.CellPadding=UDim2.fromOffset(8,8)
shopLayout.CellSize=UDim2.new(.25,-8,0,176)
shopLayout.FillDirectionMaxCells=4
shopLayout.SortOrder=Enum.SortOrder.LayoutOrder

-- Right selected-character panel.
local detailPanel=Instance.new("Frame",shopPanel)
detailPanel.Name="DetailPanel"
detailPanel.Position=UDim2.new(.67,0,0,58)
detailPanel.Size=UDim2.new(.32,-12,1,-112)
detailPanel.BackgroundColor3=Color3.fromRGB(4,4,5)
detailPanel.BackgroundTransparency=.12
detailPanel.BorderSizePixel=0
detailPanel.ZIndex=118
local detailStroke=Instance.new("UIStroke",detailPanel)
detailStroke.Color=Color3.fromRGB(226,226,220)
detailStroke.Transparency=.28
detailStroke.Thickness=1

local detailPortrait=Instance.new("ViewportFrame",detailPanel)
detailPortrait.Name="SelectedPortrait"
detailPortrait.Position=UDim2.fromOffset(8,8)
detailPortrait.Size=UDim2.new(1,-16,.58,-8)
detailPortrait.BackgroundColor3=Color3.fromRGB(3,3,4)
detailPortrait.BackgroundTransparency=0
detailPortrait.BorderSizePixel=0
detailPortrait.Ambient=Color3.fromRGB(95,95,100)
detailPortrait.LightColor=Color3.fromRGB(240,235,224)
detailPortrait.LightDirection=Vector3.new(-.7,-1,-.4)
detailPortrait.ZIndex=119
local detailPortraitStroke=Instance.new("UIStroke",detailPortrait)
detailPortraitStroke.Color=Color3.fromRGB(218,218,212)
detailPortraitStroke.Transparency=.50

local detailName=text(detailPanel,"SelectedName","",UDim2.new(1,-18,0,30),UDim2.new(0,9,.59,2))
detailName.Font=Enum.Font.Garamond
detailName.TextSize=22
detailName.TextXAlignment=Enum.TextXAlignment.Center
detailName.ZIndex=120

local detailTip=text(detailPanel,"SelectedTip","",UDim2.new(1,-22,0,42),UDim2.new(0,11,.59,34))
detailTip.Font=Enum.Font.Garamond
detailTip.TextSize=11
detailTip.TextColor3=Color3.fromRGB(164,164,160)
detailTip.TextWrapped=true
detailTip.TextXAlignment=Enum.TextXAlignment.Center
detailTip.TextYAlignment=Enum.TextYAlignment.Top
detailTip.ZIndex=120

local detailPrice=text(detailPanel,"SelectedPrice","",UDim2.new(1,-20,0,20),UDim2.new(0,10,1,-70))
detailPrice.Font=Enum.Font.Garamond
detailPrice.TextSize=12
detailPrice.TextColor3=Color3.fromRGB(226,226,220)
detailPrice.TextXAlignment=Enum.TextXAlignment.Center
detailPrice.ZIndex=120

local detailAction
local selectedKiller="Jason"
local shopButtons={}
local shopCards={}
local shopCardStrokes={}
local shopCardStatus={}
local killerOrder={"Jason","JohnDoe","Chucky","Piggy","Krampus"}
local previews=net:FindFirstChild("KillerPreviews")

local function ownedKillers()
 local raw=player:GetAttribute("OwnedKillersJson")
 if type(raw)~="string" or raw=="" then return {Jason=true} end
 local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
 return ok and type(data)=="table" and data or {Jason=true}
end

local function clearViewport(viewport)
 for _,child in ipairs(viewport:GetChildren()) do
  if child:IsA("WorldModel") or child:IsA("Camera") then child:Destroy() end
 end
 viewport.CurrentCamera=nil
end

local function populateShopViewport(viewport,killerName,wide)
 clearViewport(viewport)
 local world=Instance.new("WorldModel",viewport)
 world.Name="PreviewWorld"
 local source=previews and previews:FindFirstChild(killerName)
 if not source then return end

 local model=source:Clone()
 model.Name=killerName
 model.Parent=world

 local cf,size=model:GetBoundingBox()
 local center=cf.Position+Vector3.new(0,size.Y*(wide and .02 or .06),0)
 local root=model:FindFirstChild("HumanoidRootPart",true) or model.PrimaryPart
 local forward=root and root.CFrame.LookVector or Vector3.new(0,0,-1)
 forward=Vector3.new(forward.X,0,forward.Z)
 if forward.Magnitude<.1 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
 local distance=wide and math.max(5,size.Y*.82,size.Z*1.45) or math.max(5.2,size.Y*.92,size.Z*1.65)

 local camera=Instance.new("Camera",viewport)
 camera.Name="PreviewCamera"
 camera.FieldOfView=wide and 27 or 30
 camera.CFrame=CFrame.lookAt(center+forward*distance,center)
 viewport.CurrentCamera=camera
end

local function buildShopPortrait(card,killerName)
 local portrait=Instance.new("ViewportFrame",card)
 portrait.Name="Portrait"
 portrait.BackgroundColor3=Color3.fromRGB(12,12,13)
 portrait.BackgroundTransparency=0
 portrait.BorderSizePixel=0
 portrait.Position=UDim2.fromOffset(5,5)
 portrait.Size=UDim2.new(1,-10,1,-39)
 portrait.Ambient=Color3.fromRGB(100,100,106)
 portrait.LightColor=Color3.fromRGB(238,233,222)
 portrait.LightDirection=Vector3.new(-.6,-1,-.5)
 portrait.ZIndex=119
 populateShopViewport(portrait,killerName,false)
 return portrait
end

local function refreshSelectedKiller()
 local spec=config.Killers[selectedKiller]
 if not spec then return end
 detailName.Text=selectedKiller
 detailTip.Text=spec.tip or ""
 populateShopViewport(detailPortrait,selectedKiller,true)

 local owned=ownedKillers()
 if owned[selectedKiller] then
  detailPrice.Text=L("DESBLOQUEADO","UNLOCKED")
  detailAction.Text=L("ADQUIRIDO","OWNED")
  detailAction.Active=false
  detailAction.AutoButtonColor=false
  detailAction.BackgroundTransparency=.68
 else
  detailPrice.Text=L("PREÇO  ","PRICE  ")..tostring(spec.cost or 0)
  detailAction.Text=L("COMPRAR","BUY")
  detailAction.Active=true
  detailAction.AutoButtonColor=true
  detailAction.BackgroundTransparency=.12
 end

 for name,stroke in pairs(shopCardStrokes) do
  local active=name==selectedKiller
  stroke.Thickness=active and 2 or 1
  stroke.Transparency=active and .02 or .52
  stroke.Color=active and Color3.fromRGB(245,245,238) or Color3.fromRGB(190,190,186)
 end
end

detailAction=button(detailPanel,"Action",L("COMPRAR","BUY"),UDim2.new(1,-20,0,36),UDim2.new(0,10,1,-43),function()
 local owned=ownedKillers()
 if owned[selectedKiller] then return end
 event:FireServer("buyKiller",selectedKiller)
end)
detailAction.ZIndex=121
detailAction.Font=Enum.Font.Garamond
detailAction.TextSize=15
detailAction.UIStroke.Color=Color3.fromRGB(228,228,222)
detailAction.UIStroke.Transparency=.16

for i,name in ipairs(killerOrder) do
 local killerName=name
 local spec=config.Killers[killerName]
 if spec then
  local card=Instance.new("Frame",shopList)
  card.Name=killerName
  card.LayoutOrder=i
  card.BackgroundColor3=Color3.fromRGB(7,7,8)
  card.BackgroundTransparency=.05
  card.BorderSizePixel=0
  card.ZIndex=118
  shopCards[killerName]=card

  local stroke=Instance.new("UIStroke",card)
  stroke.Color=Color3.fromRGB(190,190,186)
  stroke.Transparency=.52
  stroke.Thickness=1
  shopCardStrokes[killerName]=stroke

  buildShopPortrait(card,killerName)

  local nameLabel=text(card,"Name",killerName,UDim2.new(1,-10,0,26),UDim2.new(0,5,1,-31))
  nameLabel.Font=Enum.Font.Garamond
  nameLabel.TextSize=14
  nameLabel.TextXAlignment=Enum.TextXAlignment.Center
  nameLabel.ZIndex=120

  local status=text(card,"Status","",UDim2.new(1,-10,0,16),UDim2.new(0,5,0,7))
  status.Font=Enum.Font.Garamond
  status.TextSize=9
  status.TextXAlignment=Enum.TextXAlignment.Right
  status.TextColor3=Color3.fromRGB(205,205,198)
  status.ZIndex=121
  shopCardStatus[killerName]=status

  local hit=Instance.new("TextButton",card)
  hit.Name="Select"
  hit.Size=UDim2.fromScale(1,1)
  hit.BackgroundTransparency=1
  hit.Text=""
  hit.AutoButtonColor=false
  hit.ZIndex=122
  hit.MouseButton1Click:Connect(function()
   selectedKiller=killerName
   refreshSelectedKiller()
  end)
 end
end

shopPlaceholder=Instance.new("Frame",shopPanel)
shopPlaceholder.Name="CategoryPlaceholder"
shopPlaceholder.Position=shopList.Position
shopPlaceholder.Size=UDim2.new(.66,-80,1,-112)
shopPlaceholder.BackgroundTransparency=1
shopPlaceholder.Visible=false
shopPlaceholder.ZIndex=118
local placeholderText=text(shopPlaceholder,"Text",L("EM BREVE","COMING SOON"),UDim2.fromScale(1,1),UDim2.new())
placeholderText.Font=Enum.Font.Garamond
placeholderText.TextSize=22
placeholderText.TextColor3=Color3.fromRGB(155,155,150)
placeholderText.TextXAlignment=Enum.TextXAlignment.Center
placeholderText.TextYAlignment=Enum.TextYAlignment.Center
placeholderText.ZIndex=119

local itemsPanel=Instance.new("Frame",shopPanel)
itemsPanel.Name="ItemsPanel"
itemsPanel.Position=shopList.Position
itemsPanel.Size=UDim2.new(.98,-82,1,-112)
itemsPanel.BackgroundTransparency=1
itemsPanel.Visible=false
itemsPanel.ZIndex=118

local lanternCard=Instance.new("Frame",itemsPanel)
lanternCard.Name="LanternUpgrade"
lanternCard.Position=UDim2.fromOffset(8,8)
lanternCard.Size=UDim2.new(1,-16,0,212)
lanternCard.BackgroundColor3=Color3.fromRGB(7,7,8)
lanternCard.BackgroundTransparency=.05
lanternCard.BorderSizePixel=0
lanternCard.ZIndex=119
local lanternStroke=Instance.new("UIStroke",lanternCard)
lanternStroke.Color=Color3.fromRGB(220,220,214)
lanternStroke.Transparency=.30
lanternStroke.Thickness=1

local lanternTitle=text(lanternCard,"Title",L("LANTERNA","LANTERN"),UDim2.new(1,-24,0,32),UDim2.fromOffset(12,10))
lanternTitle.Font=Enum.Font.Garamond
lanternTitle.TextSize=24
lanternTitle.TextXAlignment=Enum.TextXAlignment.Left
lanternTitle.ZIndex=120

local lanternAsset=text(lanternCard,"Asset","Doors Second Lantern  •  11906391298",UDim2.new(1,-24,0,20),UDim2.fromOffset(12,42))
lanternAsset.Font=Enum.Font.Garamond
lanternAsset.TextSize=11
lanternAsset.TextColor3=Color3.fromRGB(150,150,148)
lanternAsset.TextXAlignment=Enum.TextXAlignment.Left
lanternAsset.ZIndex=120

local lanternDuration=text(lanternCard,"Duration","",UDim2.new(.46,0,0,28),UDim2.fromOffset(12,72))
lanternDuration.Font=Enum.Font.Garamond
lanternDuration.TextSize=16
lanternDuration.TextXAlignment=Enum.TextXAlignment.Left
lanternDuration.ZIndex=120

local lanternLevel=text(lanternCard,"Level","",UDim2.new(.46,0,0,22),UDim2.fromOffset(12,102))
lanternLevel.Font=Enum.Font.Garamond
lanternLevel.TextSize=12
lanternLevel.TextColor3=Color3.fromRGB(185,185,180)
lanternLevel.TextXAlignment=Enum.TextXAlignment.Left
lanternLevel.ZIndex=120

local ladder=text(lanternCard,"Ladder","1:10  >  1:20  >  1:30  >  1:45  >  2:00  >  2:20  >  2:50",UDim2.new(1,-24,0,28),UDim2.fromOffset(12,132))
ladder.Font=Enum.Font.Garamond
ladder.TextSize=11
ladder.TextColor3=Color3.fromRGB(205,205,199)
ladder.TextXAlignment=Enum.TextXAlignment.Left
ladder.TextWrapped=true
ladder.ZIndex=120

local lanternUpgrade=button(lanternCard,"Upgrade","",UDim2.fromOffset(184,40),UDim2.new(1,-196,1,-52),function()
 event:FireServer("buyLanternUpgrade")
end)
lanternUpgrade.ZIndex=121
lanternUpgrade.Font=Enum.Font.Garamond
lanternUpgrade.TextSize=14
lanternUpgrade.UIStroke.Color=Color3.fromRGB(225,225,218)

local lanternCosts=text(lanternCard,"Costs","10  •  30  •  50  •  80  •  100  •  170  •  MAX",UDim2.new(.62,0,0,22),UDim2.fromOffset(12,174))
lanternCosts.Font=Enum.Font.Garamond
lanternCosts.TextSize=10
lanternCosts.TextColor3=Color3.fromRGB(145,145,142)
lanternCosts.TextXAlignment=Enum.TextXAlignment.Left
lanternCosts.ZIndex=120

local itemDurations=(config.Lantern and config.Lantern.Durations) or {70}
local itemCosts=(config.Lantern and config.Lantern.UpgradeCosts) or {}
local function formatSeconds(seconds)
 seconds=math.max(0,math.floor((tonumber(seconds) or 0)+.5))
 return string.format("%d:%02d",math.floor(seconds/60),seconds%60)
end
local function refreshItemShop()
 local tier=math.clamp(tonumber(player:GetAttribute("LanternDurabilityTier")) or 0,0,#itemDurations-1)
 local seconds=itemDurations[tier+1] or itemDurations[1] or 70
 lanternDuration.Text=L("DURAÇÃO  ","DURATION  ")..formatSeconds(seconds)
 lanternLevel.Text=L("NÍVEL DE DURABILIDADE  ","DURABILITY LEVEL  ")..tostring(tier).."/"..tostring(#itemDurations-1)
 local cost=itemCosts[tier+1]
 if cost then
  lanternUpgrade.Text=L("MELHORAR  ","UPGRADE  ")..tostring(cost)
  lanternUpgrade.Active=true
  lanternUpgrade.AutoButtonColor=true
  lanternUpgrade.BackgroundTransparency=.12
 else
  lanternUpgrade.Text="MAX"
  lanternUpgrade.Active=false
  lanternUpgrade.AutoButtonColor=false
  lanternUpgrade.BackgroundTransparency=.62
 end
end

local function setShopTab(tab)
 activeShopTab=tab
 for name,b in pairs(shopTabs) do styleTab(b,name==tab) end
 local killersActive=tab=="Killers"
 local itemsActive=tab=="Items"
 shopList.Visible=killersActive
 detailPanel.Visible=killersActive
 itemsPanel.Visible=itemsActive
 shopPlaceholder.Visible=not killersActive and not itemsActive
 shopSearch.Visible=killersActive
 searchIcon.Visible=killersActive
 if not killersActive and not itemsActive then
  placeholderText.Text=L("EMOTES • EM BREVE","EMOTES • COMING SOON")
 end
 if itemsActive then refreshItemShop() end
end

local tabSpecs={
 {"Killers",L("PERSEGUIDORES","KILLERS")},
 {"Items",L("ITENS","ITEMS")},
 {"Emotes","EMOTES"},
}
for i,item in ipairs(tabSpecs) do
 local key,label=item[1],item[2]
 local tab=button(tabBar,key,label,UDim2.fromOffset(i==1 and 116 or 124,30),UDim2.new(),function()
  setShopTab(key)
 end)
 tab.LayoutOrder=i
 tab.ZIndex=119
 tab.TextSize=13
 tab.UIStroke.Thickness=1
 shopTabs[key]=tab
end

railButton("Killers","K",1,function() setShopTab("Killers") end)
railButton("Items","I",2,function() setShopTab("Items") end)
railButton("Emotes","E",3,function() setShopTab("Emotes") end)
railButton("Inventory","◇",4,function() setShopTab("Items") end)
railButton("Settings","⚙",5,function()
 shopOverlay.Visible=false
 settingsOverlay.Visible=true
end)

local function refreshShopSearch()
 local query=string.lower(shopSearch.Text or "")
 for name,card in pairs(shopCards) do
  card.Visible=query=="" or string.find(string.lower(name),query,1,true)~=nil
 end
end
shopSearch:GetPropertyChangedSignal("Text"):Connect(refreshShopSearch)

local function refreshShop()
 local owned=ownedKillers()
 local stats=player:FindFirstChild("leaderstats")
 local pts=stats and stats:FindFirstChild("Pontos")
 shopBalance.Text=tostring(pts and pts.Value or 0)..L(" PONTOS"," POINTS")

 for name,status in pairs(shopCardStatus) do
  local spec=config.Killers[name]
  if owned[name] then
   status.Text=name=="Jason" and L("PADRÃO","DEFAULT") or L("ADQUIRIDO","OWNED")
  else
   status.Text=tostring(spec and spec.cost or 0)
  end
 end
 refreshSelectedKiller()
 refreshItemShop()
end

setShopTab("Killers")
refreshSelectedKiller()

local shopButton=button(gui,"ShopButton","",UDim2.fromOffset(44,44),UDim2.new(1,-110,0,6),function()
 if player:GetAttribute("InRound") or player:GetAttribute("Spectating") then return end
 refreshShop() shopOverlay.Visible=not shopOverlay.Visible
end) shopButton.BackgroundTransparency=1 shopButton.UIStroke.Enabled=false
shopButton:SetAttribute("AccessibleLabel",L("Loja de perseguidores","Killer shop"))
local cart=iconCanvas(shopButton,"CartIcon",UDim2.fromOffset(30,30),UDim2.fromOffset(7,7))
iconLine(cart,"Handle",2,4,7,4) iconLine(cart,"Stem",7,4,11,21)
iconLine(cart,"BasketTop",8,8,28,8) iconLine(cart,"BasketFront",28,8,25,17)
iconLine(cart,"BasketBottom",10,17,25,17) iconLine(cart,"Base",11,21,25,21)
for i,x in ipairs({13,23}) do
 local wheel=Instance.new("Frame",cart) wheel.Name="Wheel"..i wheel.Position=UDim2.fromOffset(x-2,24) wheel.Size=UDim2.fromOffset(4,4) wheel.BorderSizePixel=0 wheel.BackgroundColor3=Color3.fromRGB(238,238,241)
 Instance.new("UICorner",wheel).CornerRadius=UDim.new(1,0)
end
player:GetAttributeChangedSignal("OwnedKillersJson"):Connect(refreshShop)
player:GetAttributeChangedSignal("LanternDurabilityTier"):Connect(refreshItemShop)
task.spawn(function()
 local stats=player:WaitForChild("leaderstats",20)
 local pts=stats and stats:FindFirstChild("Pontos")
 if pts then pts.Changed:Connect(refreshShop) end
 refreshShop()
end)

RunService.RenderStepped:Connect(function()
 local blocked=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("Spectating") or player:GetAttribute("SweanLoadingDone")~=true
 if blocked then return end
 player.CameraMode=Enum.CameraMode.Classic
 player.CameraMaxZoomDistance=player:GetAttribute("InRound") and 10 or 24
 player.CameraMinZoomDistance=player:GetAttribute("InRound") and 10 or 4
end)
local profileHUD=panel("Profile",UDim2.fromOffset(190,58),UDim2.fromOffset(18,132)) profileHUD.BackgroundTransparency=1 profileHUD.UIStroke.Enabled=false
local xpTrack=Instance.new("Frame",profileHUD) xpTrack.Name="XP" xpTrack.Size=UDim2.new(1,0,0,8) xpTrack.BackgroundColor3=Color3.fromRGB(22,23,32) xpTrack.BackgroundTransparency=.3 xpTrack.BorderSizePixel=0 Instance.new("UICorner",xpTrack).CornerRadius=UDim.new(0,5)
local xpFill=Instance.new("Frame",xpTrack) xpFill.Name="Fill" xpFill.Size=UDim2.fromScale(0,1) xpFill.BackgroundColor3=Color3.fromRGB(96,118,205) xpFill.BorderSizePixel=0 Instance.new("UICorner",xpFill).CornerRadius=UDim.new(0,5)
local levelText=text(xpTrack,"Level",L("NÍVEL 1","LEVEL 1"),UDim2.new(1,-12,0,18),UDim2.fromOffset(6,-20)) levelText.TextSize=11 levelText.Font=Enum.Font.GothamBold levelText.TextXAlignment=Enum.TextXAlignment.Left
local pointsText=text(profileHUD,"Points","0",UDim2.new(1,0,0,28),UDim2.fromOffset(0,26)) pointsText.TextSize=19 pointsText.Position=UDim2.fromOffset(34,26) pointsText.TextColor3=Color3.fromRGB(231,209,155) pointsText.TextXAlignment=Enum.TextXAlignment.Left
local coinView=Instance.new("ViewportFrame",profileHUD) coinView.Name="Coin" coinView.Size=UDim2.fromOffset(28,28) coinView.Position=UDim2.fromOffset(0,26) coinView.BackgroundTransparency=1 coinView.Ambient=Color3.fromRGB(200,200,200)
local coinTemplate=net:FindFirstChild("CoinDisplay")
if coinTemplate then
 local model=coinTemplate:Clone() model.Parent=coinView
 local cf,size=model:GetBoundingBox()
 local cam=Instance.new("Camera",coinView) cam.FieldOfView=35 cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,size.Magnitude*.18,size.Magnitude*1.7),cf.Position) coinView.CurrentCamera=cam
end
local healthHUD=panel("Condition",UDim2.fromOffset(148,38),UDim2.new(0,18,1,-52)) healthHUD.UIStroke.Color=Color3.fromRGB(106,150,91)
local condition=text(healthHUD,"Value","♥  100",UDim2.fromScale(1,1),UDim2.new()) condition.Font=Enum.Font.GothamBold condition.TextSize=22 condition.TextColor3=Color3.fromRGB(144,223,111)
local staminaTrack=Instance.new("Frame",gui) staminaTrack.Name="Stamina" staminaTrack.Size=UDim2.fromOffset(148,7) staminaTrack.Position=UDim2.new(0,18,1,-64)
staminaTrack.BackgroundColor3=Color3.fromRGB(20,21,25) staminaTrack.BackgroundTransparency=.2 staminaTrack.BorderSizePixel=0 Instance.new("UICorner",staminaTrack).CornerRadius=UDim.new(1,0)
local staminaFill=Instance.new("Frame",staminaTrack) staminaFill.Name="Fill" staminaFill.Size=UDim2.fromScale(1,1) staminaFill.BackgroundColor3=Color3.fromRGB(190,194,205) staminaFill.BorderSizePixel=0 Instance.new("UICorner",staminaFill).CornerRadius=UDim.new(1,0)
local mission=panel("Mission",UDim2.fromOffset(360,48),UDim2.new(.5,-180,0,48)) mission.BackgroundTransparency=.42 mission.UIStroke.Transparency=.82
local missionTitle=text(mission,"Title",L("MISSÃO","MISSION"),UDim2.fromOffset(68,16),UDim2.fromOffset(10,5)) missionTitle.TextSize=9 missionTitle.Font=Enum.Font.GothamBold missionTitle.TextColor3=Color3.fromRGB(165,168,178) missionTitle.TextXAlignment=Enum.TextXAlignment.Left
local missionText=text(mission,"Text","",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,20)) missionText.TextSize=12 missionText.Font=Enum.Font.GothamBold missionText.TextXAlignment=Enum.TextXAlignment.Left
local inventory=panel("ObjectiveInventory",UDim2.fromOffset(82,82),UDim2.new(0,18,1,-148)) inventory.BackgroundTransparency=.28 inventory.UIStroke.Transparency=.7
inventory:SetAttribute("SourceAssetId",net:GetAttribute("InventoryAssetId") or 73852738603629)
local inventoryIcon=text(inventory,"Icon","🔑",UDim2.fromScale(1,.62),UDim2.new()) inventoryIcon.TextSize=29
local inventoryLabel=text(inventory,"Label",L("VAZIO","EMPTY"),UDim2.fromScale(1,.32),UDim2.new(0,0,.64,0)) inventoryLabel.TextSize=9 inventoryLabel.Font=Enum.Font.GothamBold
local escapeBanner=panel("EscapeBanner",UDim2.fromOffset(360,30),UDim2.new(.5,-180,0,12)) escapeBanner.BackgroundTransparency=.28 escapeBanner.Visible=false escapeBanner.UIStroke.Transparency=.8 escapeBanner.ZIndex=95
local escapeText=text(escapeBanner,"Text","",UDim2.fromScale(1,1),UDim2.new()) escapeText.TextSize=11 escapeText.Font=Enum.Font.GothamBold escapeText.ZIndex=96
local missionBanner=panel("MissionBanner",UDim2.fromOffset(420,34),UDim2.new(.5,-210,0,104)) missionBanner.BackgroundTransparency=.18 missionBanner.Visible=false missionBanner.ZIndex=96
local missionBannerText=text(missionBanner,"Text",L("NOVA MISSÃO","NEW MISSION"),UDim2.fromScale(1,1),UDim2.new()) missionBannerText.TextSize=12 missionBannerText.Font=Enum.Font.GothamBlack missionBannerText.ZIndex=97
local hitFlash=Instance.new("Frame",gui) hitFlash.Name="HitFlash" hitFlash.Size=UDim2.fromScale(1,1) hitFlash.BackgroundColor3=Color3.fromRGB(150,0,12) hitFlash.BackgroundTransparency=1 hitFlash.BorderSizePixel=0 hitFlash.ZIndex=200
local hitGradient=Instance.new("UIGradient",hitFlash) hitGradient.Rotation=90 hitGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.18,.76),NumberSequenceKeypoint.new(.5,.92),NumberSequenceKeypoint.new(.82,.76),NumberSequenceKeypoint.new(1,.05)})
local exitHighlight=Instance.new("Highlight") exitHighlight.Name="ObjectiveExitHighlight" exitHighlight.FillColor=Color3.fromRGB(242,211,79) exitHighlight.OutlineColor=Color3.fromRGB(255,243,170) exitHighlight.FillTransparency=.72 exitHighlight.OutlineTransparency=.08 exitHighlight.Enabled=false exitHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop exitHighlight.Parent=gui
local function missionCopy(stage)
 local done=net:GetAttribute("ComputersDone") or 0 local required=net:GetAttribute("ComputersRequired") or 3
 if stage=="Hack" then return L("HACKEIE OS COMPUTADORES  ","HACK THE COMPUTERS  ")..done.."/"..required end
 if stage=="Key" then return player:GetAttribute("HasKey") and L("ABRA A SAÍDA COM SUA CHAVE","OPEN THE EXIT WITH YOUR KEY") or L("ENCONTRE UMA CHAVE ESCONDIDA","FIND A HIDDEN KEY") end
 if stage=="Exit" then return L("ABRA A SAÍDA COM SUA CHAVE","OPEN THE EXIT WITH YOUR KEY") end
 return ""
end
local missionPulse=0
local function announceMission(stage)
 missionText.Text=missionCopy(stage)
 missionBannerText.Text=L("NOVA MISSÃO:  ","NEW MISSION:  ")..missionText.Text
 missionBanner.Visible=missionText.Text~=""
 missionPulse+=1 local token=missionPulse
 task.delay(2.2,function() if token==missionPulse then missionBanner.Visible=false end end)
end
local roster=Instance.new("Frame",gui)
roster.Name="PlayerRoster" roster.BackgroundTransparency=1 roster.Position=UDim2.fromOffset(12,172) roster.Size=UDim2.fromOffset(190,306)
local rosterList=Instance.new("UIListLayout",roster) rosterList.Padding=UDim.new(0,5) rosterList.SortOrder=Enum.SortOrder.LayoutOrder
local rosterRows={}
local function rosterRow(p)
 local row=Instance.new("Frame",roster)
 row.Name="Player_"..p.UserId row.Size=UDim2.fromOffset(184,40) row.BorderSizePixel=0
 row.BackgroundColor3=Color3.fromRGB(53,54,59) row.BackgroundTransparency=.14 row.LayoutOrder=p.UserId
 local corner=Instance.new("UICorner",row) corner.CornerRadius=UDim.new(1,0)
 local gradient=Instance.new("UIGradient",row)
 gradient.Rotation=0
 gradient.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.28),
  NumberSequenceKeypoint.new(.35,.18),
  NumberSequenceKeypoint.new(1,.06)
 })
 local name=text(row,"Name",p.DisplayName or p.Name,UDim2.new(1,-67,0,18),UDim2.fromOffset(43,3))
 name.Font=Enum.Font.GothamBold name.TextSize=11 name.TextXAlignment=Enum.TextXAlignment.Left name.TextTruncate=Enum.TextTruncate.AtEnd name.TextWrapped=false name.ZIndex=3
 local track=Instance.new("Frame",row)
 track.Name="Health" track.Size=UDim2.new(1,-82,0,6) track.Position=UDim2.fromOffset(43,27)
 track.BackgroundColor3=Color3.fromRGB(50,51,54) track.BackgroundTransparency=.12 track.BorderSizePixel=0 track.ZIndex=3
 Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
 local fill=Instance.new("Frame",track)
 fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.fromRGB(130,193,74) fill.BorderSizePixel=0 fill.ZIndex=4
 Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
 local heart=text(row,"Heart","♥",UDim2.fromOffset(20,20),UDim2.new(1,-27,0,18))
 heart.TextSize=15 heart.TextColor3=Color3.fromRGB(228,91,91) heart.ZIndex=4
 local avatar=Instance.new("ImageLabel",row)
 avatar.Name="Avatar" avatar.AnchorPoint=Vector2.new(0,.5) avatar.Position=UDim2.new(0,4,.5,0) avatar.Size=UDim2.fromOffset(32,32)
 avatar.BackgroundColor3=Color3.fromRGB(82,83,89) avatar.BackgroundTransparency=.02 avatar.BorderSizePixel=0 avatar.ZIndex=4
 Instance.new("UICorner",avatar).CornerRadius=UDim.new(1,0)
 task.spawn(function()
  local ok,image=pcall(function() return Players:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
  if ok and row.Parent then avatar.Image=image end
 end)
 rosterRows[p.UserId]={frame=row,player=p,fill=fill,name=name,heart=heart}
 return row
end
local function updateRoster()
 local wanted={}
 for _,p in ipairs(Players:GetPlayers()) do
  if p:GetAttribute("InRound")==true and p:GetAttribute("IsJason")~=true then
   wanted[p.UserId]=true
   if not rosterRows[p.UserId] then rosterRow(p) end
  end
 end
 for id,data in pairs(rosterRows) do
  if not wanted[id] or not data.player.Parent then data.frame:Destroy() rosterRows[id]=nil
  else
   local p=data.player
   local down=p:GetAttribute("Downed")==true or p:GetAttribute("RoundStatus")=="eliminated"
   local ratio=down and .08 or p:GetAttribute("Injured") and .5 or 1
   data.fill.Size=UDim2.fromScale(ratio,1)
   data.name.Text=p.DisplayName or p.Name
   data.fill.BackgroundColor3=down and Color3.fromRGB(190,77,77) or p:GetAttribute("Injured") and Color3.fromRGB(216,170,72) or Color3.fromRGB(130,193,74)
   data.heart.TextTransparency=down and .45 or 0
  end
 end
end
local function createObjectiveUI()
local hackPanel=panel("HackPanel",UDim2.new(.54,0,0,94),UDim2.new(.23,0,1,-132))
hackPanel.BackgroundColor3=Color3.new(0,0,0) hackPanel.BackgroundTransparency=.18 hackPanel.Visible=false hackPanel.ZIndex=90
local hackLabel=text(hackPanel,"Label","HACKEANDO",UDim2.new(1,-54,0,24),UDim2.fromOffset(12,5)) hackLabel.TextSize=11 hackLabel.ZIndex=91
local hackRail=Instance.new("Frame",hackPanel) hackRail.Name="Progress" hackRail.Size=UDim2.new(1,-24,0,5) hackRail.Position=UDim2.fromOffset(12,34) hackRail.BackgroundColor3=Color3.fromRGB(45,45,45) hackRail.BorderSizePixel=0 hackRail.ZIndex=91
local hackFill=Instance.new("Frame",hackRail) hackFill.Size=UDim2.fromScale(0,1) hackFill.BackgroundColor3=Color3.fromRGB(215,215,215) hackFill.BorderSizePixel=0 hackFill.ZIndex=92
local skillButton=button(hackPanel,"SkillCheck","AGUARDE",UDim2.new(1,-24,0,36),UDim2.fromOffset(12,48),function() end) skillButton.ZIndex=92
local targetZone=Instance.new("Frame",skillButton) targetZone.Name="Target" targetZone.Position=UDim2.fromScale(.32,0) targetZone.Size=UDim2.fromScale(.46,1) targetZone.BackgroundColor3=Color3.fromRGB(80,145,95) targetZone.BackgroundTransparency=.48 targetZone.BorderSizePixel=0 targetZone.ZIndex=93 targetZone.Visible=false
local cursor=Instance.new("Frame",skillButton) cursor.Name="Cursor" cursor.Size=UDim2.new(0,3,1,0) cursor.BackgroundColor3=Color3.new(1,1,1) cursor.BorderSizePixel=0 cursor.ZIndex=94 cursor.Visible=false
local checkId=nil local checkAt=0
local function clickHack()
 if hackPanel.Visible and checkId then event:FireServer("hackTap",checkId) checkId=nil cursor.Visible=false targetZone.Visible=false end
end
skillButton.Activated:Connect(clickHack)
local cancel=button(hackPanel,"Cancel","SAIR",UDim2.fromOffset(48,24),UDim2.new(1,-52,0,4),function() event:FireServer("hackCancel") end) cancel.ZIndex=94 cancel.TextSize=10
local hackingPc=nil
local function hackEvent(action,a,b)
 if action=="hackStart" then hackingPc=a hackPanel.Visible=true hackFill.Size=UDim2.fromScale(b or 0,1) hackLabel.Text="HACKEANDO • FIQUE PERTO DO COMPUTADOR" skillButton.Text="AGUARDE"
 elseif action=="hackEnd" then hackingPc=nil hackPanel.Visible=false checkId=nil
 elseif action=="hackProgress" then hackFill.Size=UDim2.fromScale(a,1) hackLabel.Text="HACKEANDO • "..math.floor(a*100).."%"
 elseif action=="hackCheck" then checkId=a checkAt=b cursor.Visible=true targetZone.Visible=true skillButton.Text=L("CLIQUE NA ÁREA VERDE • Q","CLICK THE GREEN AREA • Q")
 elseif action=="hackCheckResult" then checkId=nil cursor.Visible=false targetZone.Visible=false skillButton.Text=a and L("ACERTOU","HIT") or L("ERRO • TENTE O PRÓXIMO","MISS • TRY THE NEXT ONE")
 elseif action=="pcComplete" and player:GetAttribute("IsJason") and typeof(a)=="Instance" then
  local h=Instance.new("Highlight") h.Name="CompletedComputer" h.Adornee=a h.FillColor=Color3.fromRGB(65,230,115) h.OutlineColor=Color3.new(1,1,1) h.FillTransparency=.45 h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Parent=a Debris:AddItem(h,10)
 end
end
RunService.RenderStepped:Connect(function()
 if checkId then cursor.Position=UDim2.fromScale(math.clamp((workspace:GetServerTimeNow()-checkAt)/1.6,0,1),0) end
 if hackPanel.Visible and (not hackingPc or not hackingPc.Parent or not player:GetAttribute("InRound") or player:GetAttribute("Downed")) then event:FireServer("hackCancel") hackPanel.Visible=false end
end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.Q and hackPanel.Visible then clickHack() end
end)

-- Detection is local to the killer: forward cone + raycast, never through walls.
local spotted={} local detectionElapsed=0
local chase=Instance.new("Sound") chase.Name="LocalChasePulse" chase.SoundId="rbxassetid://135029802046345" chase.Volume=0 chase.Parent=game:GetService("SoundService")
local nextPulse=0
RunService.RenderStepped:Connect(function(dt)
 detectionElapsed+=dt if detectionElapsed<.12 then return end detectionElapsed=0
 local me=player.Character local myRoot=me and me:FindFirstChild("HumanoidRootPart")
 local killer=nil
 for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("IsJason") and p:GetAttribute("InRound") then killer=p break end end
 local kr=killer and killer.Character and killer.Character:FindFirstChild("HumanoidRootPart")
 local wanted={}
 if killer==player and kr then
  for _,p in ipairs(Players:GetPlayers()) do
   local char=p.Character local r=char and char:FindFirstChild("HumanoidRootPart")
   if p~=player and r and p:GetAttribute("InRound") then
    local delta=r.Position-kr.Position
    if delta.Magnitude<70 and delta.Magnitude>.01 and kr.CFrame.LookVector:Dot(delta.Unit)>.45 then
     local param=RaycastParams.new() param.FilterType=Enum.RaycastFilterType.Exclude param.FilterDescendantsInstances={me} param.RespectCanCollide=true
     local hit=workspace:Raycast(kr.Position,delta,param)
     if not hit or hit.Instance:IsDescendantOf(char) then
      wanted[p.UserId]=true
      local h=spotted[p.UserId]
      if not h then h=Instance.new("Highlight") h.Name="VisibleSurvivor" h.FillColor=Color3.fromRGB(220,45,45) h.OutlineColor=h.FillColor h.FillTransparency=.65 h.DepthMode=Enum.HighlightDepthMode.Occluded h.Parent=workspace spotted[p.UserId]=h end
      h.Adornee=char
     end
    end
   end
  end
 end
 for id,h in pairs(spotted) do if not wanted[id] then h:Destroy() spotted[id]=nil end end
 if killer and killer~=player and kr and myRoot and player:GetAttribute("InRound") and not player:GetAttribute("VoidActive") then
  local distance=(kr.Position-myRoot.Position).Magnitude
  if distance<35 and os.clock()>nextPulse then
   local danger=1-math.clamp(distance/35,0,1)
   chase.Volume=(.08+danger*.22)*(player:GetAttribute("EffectsVolume") or 80)/100
   chase.PlaybackSpeed=.6 chase.TimePosition=0 chase:Play() nextPulse=os.clock()+1.2-danger*.65
  end
 else chase:Stop() end
end)

return hackEvent
end
local hackEvent=createObjectiveUI()

local result=Instance.new("Frame",gui)
result.Name="RoundResult" result.Size=UDim2.fromScale(1,1) result.Position=UDim2.new()
result.BackgroundColor3=Color3.new(0,0,0) result.BackgroundTransparency=1 result.BorderSizePixel=0
result.Visible=false result.ZIndex=70 result.ClipsDescendants=true
local resultView=Instance.new("ViewportFrame",result)
resultView.Name="WinnerPortrait" resultView.BackgroundColor3=Color3.new(0,0,0) resultView.BackgroundTransparency=0
resultView.Size=UDim2.fromScale(1,1) resultView.Position=UDim2.new() resultView.ZIndex=71 resultView.Visible=false
resultView.Ambient=Color3.fromRGB(92,77,82) resultView.LightColor=Color3.fromRGB(222,173,162) resultView.LightDirection=Vector3.new(-1,-.35,-1)
local resultWorld=Instance.new("WorldModel",resultView)
local resultCamera=Instance.new("Camera",resultView) resultCamera.FieldOfView=50 resultView.CurrentCamera=resultCamera
local resultShade=Instance.new("Frame",result)
resultShade.Name="Shade" resultShade.Size=UDim2.fromScale(1,1) resultShade.BackgroundColor3=Color3.new(0,0,0) resultShade.BackgroundTransparency=.64 resultShade.BorderSizePixel=0 resultShade.ZIndex=72
local shadeGradient=Instance.new("UIGradient",resultShade)
shadeGradient.Rotation=0 shadeGradient.Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.42,.62),NumberSequenceKeypoint.new(1,.34)
})
local resultHeader=text(result,"Header",L("FIM DA PARTIDA","MATCH OVER"),UDim2.new(.92,0,0,42),UDim2.new(.025,0,.045,0))
resultHeader.Font=Enum.Font.GothamBlack resultHeader.TextSize=24 resultHeader.TextXAlignment=Enum.TextXAlignment.Left resultHeader.ZIndex=76
local resultSubtitle=text(result,"Subtitle","",UDim2.new(.7,0,0,26),UDim2.new(.025,0,.10,0))
resultSubtitle.TextSize=11 resultSubtitle.TextXAlignment=Enum.TextXAlignment.Left resultSubtitle.TextColor3=Color3.fromRGB(190,190,196) resultSubtitle.ZIndex=76
local resultRows=Instance.new("ScrollingFrame",result)
resultRows.Name="Ranking" resultRows.BackgroundTransparency=1 resultRows.BorderSizePixel=0
resultRows.Position=UDim2.new(.025,0,.18,0) resultRows.Size=UDim2.new(.34,0,.58,0) resultRows.ZIndex=76
resultRows.AutomaticCanvasSize=Enum.AutomaticSize.Y resultRows.CanvasSize=UDim2.new() resultRows.ScrollBarThickness=0
local resultList=Instance.new("UIListLayout",resultRows) resultList.Padding=UDim.new(0,5) resultList.SortOrder=Enum.SortOrder.LayoutOrder
local resultWinner=text(result,"Winner","",UDim2.new(.92,0,0,32),UDim2.new(.025,0,.82,0))
resultWinner.Font=Enum.Font.GothamBold resultWinner.TextSize=13 resultWinner.TextXAlignment=Enum.TextXAlignment.Left resultWinner.ZIndex=76
local resultUntil=0 local resultGeneration=0
local resultCameraState=nil
local resultCameraConn=nil
local resultScene=nil
local resultActor=nil
local function stopResultCamera()
 if resultCameraConn then resultCameraConn:Disconnect() resultCameraConn=nil end
end
local function captureResultCamera()
 local camera=workspace.CurrentCamera
 if not camera or resultCameraState then return end
 resultCameraState={
  camera=camera,
  cameraType=camera.CameraType,
  cameraSubject=camera.CameraSubject,
  cframe=camera.CFrame,
  fieldOfView=camera.FieldOfView,
 }
 camera.CameraType=Enum.CameraType.Scriptable
end
local function clearResultScene()
 if resultActor then resultActor:Destroy() resultActor=nil end
 if resultScene then resultScene:Destroy() resultScene=nil end
end
local function resultFloor(scene)
 local cf,size=scene:GetBoundingBox()
 local best,bestScore=nil,-math.huge
 for _,p in ipairs(scene:GetDescendants()) do
  if p:IsA("BasePart") and p.Transparency<.98 and p.CanCollide and p.CFrame.UpVector.Y>.82 and p.Size.X>=6 and p.Size.Z>=6 then
   local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
   local score=p.Size.X*p.Size.Z-(top.Y-(cf.Position.Y-size.Y/2))*2
   if score>bestScore then bestScore=score best=p end
  end
 end
 return best,cf,size
end
local function buildResultScene(source,pose)
 clearResultScene()
 local template=RS:FindFirstChild("MenuSceneTemplate") or workspace:FindFirstChild("JediLibrary")
 if not template or not source then return source end
 local oldArch=template.Archivable template.Archivable=true
 resultScene=template:Clone()
 template.Archivable=oldArch
 resultScene.Name="LocalWinnerScene"
 for _,d in ipairs(resultScene:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=true d.CanTouch=false d.CanQuery=false end
 end
 resultScene.Parent=workspace
 local sceneCF,sceneSize=resultScene:GetBoundingBox()
 resultScene:PivotTo(resultScene:GetPivot()+Vector3.new(12000-sceneCF.X,2600-(sceneCF.Y-sceneSize.Y/2),12000-sceneCF.Z))
 local floor=select(1,resultFloor(resultScene))
 local base
 if floor then base=floor.CFrame:PointToWorldSpace(Vector3.new(0,floor.Size.Y/2+.06,0))
 else
  local cf,size=resultScene:GetBoundingBox() base=Vector3.new(cf.X,cf.Y-size.Y/2+.1,cf.Z)
 end

 local was=source.Archivable source.Archivable=true
 resultActor=source:Clone()
 source.Archivable=was
 resultActor.Name="WinnerPursuer"
 for _,d in ipairs(resultActor:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=d==resultActor.PrimaryPart d.CanCollide=false d.CanTouch=false d.CanQuery=false end
 end
 resultActor:SetAttribute("PresentationPursuer",true)
 resultActor.Parent=workspace
 resultActor:SetAttribute("ActivePursuer",false)
 resultActor:SetAttribute("PresentationState","RoundVictory")
 resultActor:SetAttribute("PresentationFrozen",false)
 resultActor:SetAttribute("PresentationFreezeTime",pose=="Jason Slash" and .28 or .35)
 resultActor:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
 local _,size=resultActor:GetBoundingBox()
 if size.Y>8 then pcall(function() resultActor:ScaleTo(resultActor:GetScale()*8/size.Y) end) _,size=resultActor:GetBoundingBox() end
 local position=base+Vector3.new(2.8,size.Y/2,3.6)
 local look=base+Vector3.new(-2.2,size.Y*.35,-3)
 resultActor:PivotTo(CFrame.lookAt(position,look))
 return resultActor
end
local function startResultCamera(primary,secondary)
 stopResultCamera()
 local started=os.clock()
 resultCameraConn=RunService.RenderStepped:Connect(function()
  if not result.Visible then return end
  local camera=workspace.CurrentCamera
  if not camera or not primary or not primary.Parent then return end
  local cf,size=primary:GetBoundingBox()
  local center=cf.Position+Vector3.new(0,math.clamp(size.Y*.10,.5,2.4),0)
  if secondary and secondary.Parent then
   local secondaryRoot=secondary:FindFirstChild("HumanoidRootPart") or secondary.PrimaryPart
   if secondaryRoot then center=center:Lerp(secondaryRoot.Position+Vector3.new(0,1.7,0),.22) end
  end
  local forward=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
  if forward.Magnitude<.05 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
  local right=Vector3.new(-forward.Z,0,forward.X)
  local distance=math.clamp(math.max(size.Y*1.45,size.Z*2.6),10,20)
  local sway=math.sin((os.clock()-started)*.32)*1.05
  local cameraPos=center+forward*distance+right*(2.8+sway)+Vector3.new(0,math.max(2.8,size.Y*.30),0)
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(cameraPos,center)
  camera.FieldOfView=52
 end)
end
local function restoreResultCamera()
 stopResultCamera()
 local state=resultCameraState
 resultCameraState=nil
 if not state then return end
 local camera=workspace.CurrentCamera or state.camera
 if not camera then return end
 local subject=state.cameraSubject
 if not subject or not subject.Parent then
  subject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 end
 if subject then
  camera.CameraSubject=subject
  camera.CameraType=subject==state.cameraSubject and state.cameraType or Enum.CameraType.Custom
 else
  camera.CameraType=Enum.CameraType.Custom
 end
 camera.FieldOfView=player:GetAttribute("CameraFOV") or state.fieldOfView or 48
 if camera.CameraType==Enum.CameraType.Scriptable and state.cframe then camera.CFrame=state.cframe end
end
local function hideResult()
 result.Visible=false resultGeneration+=1 resultWorld:ClearAllChildren() clearResultScene()
 for _,candidate in ipairs(workspace:GetChildren()) do
  if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then
   candidate:SetAttribute("PresentationFrozen",false)
   candidate:SetAttribute("PresentationState",nil)
  end
 end
 restoreResultCamera()
end
local resultClose=button(result,"Close","SAÍDA",UDim2.fromOffset(88,36),UDim2.new(.025,0,.77,0),hideResult)
resultClose.ZIndex=77 resultClose.TextSize=12 resultClose.BackgroundTransparency=.18 resultClose.UIStroke.Enabled=false
result:GetPropertyChangedSignal("Visible"):Connect(function()
 if not result.Visible then clearResultScene() restoreResultCamera() end
end)

local function showResult(data)
 hideResult()
 captureResultCamera()
 local generation=resultGeneration
 for _,old in ipairs(resultRows:GetChildren()) do if old:IsA("Frame") then old:Destroy() end end
 resultRows.CanvasPosition=Vector2.zero
 local winnerName=data.killerWinnerName or data.killer or L("Perseguidor","Killer")
 resultHeader.Text=string.upper(data.jasonWon and (winnerName..L(" • GANHADOR"," • WINNER")) or L("SOBREVIVENTES • GANHADORES","SURVIVORS • WINNERS"))
 resultHeader.TextColor3=data.jasonWon and Color3.fromRGB(225,104,109) or Color3.fromRGB(235,235,239)
 resultSubtitle.Text=(data.map or "").."  •  +"..tostring(data.xp or 0).." XP"
 resultWinner.Text=data.jasonWon and (L("GANHADOR  •  ","WINNER  •  ")..winnerName.."  •  "..string.upper(data.killer or L("PERSEGUIDOR","KILLER"))) or (data.winnerText or L("SOBREVIVENTES ESCAPARAM","SURVIVORS ESCAPED"))
 resultView.Visible=false
 resultShade.BackgroundTransparency=data.jasonWon and .58 or .46

 if data.jasonWon then
  local target=nil
  for _,candidate in ipairs(workspace:GetChildren()) do
   if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then target=candidate break end
  end
  local victimId=tonumber(data.lastVictimUserId) or 0
  if victimId<=0 then
   local fallback=(data.board or {})[1]
   victimId=fallback and fallback.userId or 0
  end
  local victimPlayer=victimId>0 and Players:GetPlayerByUserId(victimId) or nil
  local victimCharacter=victimPlayer and victimPlayer.Character or nil
  if target then
   target:SetAttribute("PresentationState","Jason Idle")
   target:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
   target:SetAttribute("PresentationFrozen",true)
   target:SetAttribute("PresentationFreezeTime",.35)
   local cinematic=buildResultScene(target,"Jason Idle")
   startResultCamera(cinematic,nil)
  else
   local own=player.Character
   if own then startResultCamera(own,nil) end
  end
 else
  local target=nil
  for _,candidate in ipairs(workspace:GetChildren()) do
   if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then target=candidate break end
  end
  if target then
   target:SetAttribute("PresentationState","Jason Slash")
   target:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
   target:SetAttribute("PresentationFrozen",true)
   target:SetAttribute("PresentationFreezeTime",.28)
   local cinematic=buildResultScene(target,"Jason Slash")
   startResultCamera(cinematic,nil)
  else
   target=player.Character
   if target then startResultCamera(target,nil) end
  end
 end

 for i,row in ipairs(data.board or {}) do if i>8 then break end
  local card=Instance.new("Frame",resultRows)
  card.Name="Rank"..i card.Size=UDim2.new(1,-4,0,43) card.LayoutOrder=i card.BorderSizePixel=0 card.ZIndex=76
  card.BackgroundColor3=Color3.new(0,0,0) card.BackgroundTransparency=row.userId==player.UserId and .24 or .36
  Instance.new("UICorner",card).CornerRadius=UDim.new(0,7)
  local fade=Instance.new("UIGradient",card)
  fade.Rotation=0 fade.Transparency=NumberSequence.new({
   NumberSequenceKeypoint.new(0,.06),NumberSequenceKeypoint.new(.72,.20),NumberSequenceKeypoint.new(1,.62)
  })
  local avatar=Instance.new("ImageLabel",card)
  avatar.Name="Avatar" avatar.Size=UDim2.fromOffset(35,35) avatar.Position=UDim2.fromOffset(4,4)
  avatar.BackgroundColor3=Color3.fromRGB(35,35,38) avatar.BackgroundTransparency=.08 avatar.BorderSizePixel=0 avatar.ZIndex=78
  Instance.new("UICorner",avatar).CornerRadius=UDim.new(1,0)
  task.spawn(function()
   local ok,image=pcall(function() return Players:GetUserThumbnailAsync(row.userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
   if ok and avatar.Parent then avatar.Image=image end
  end)
  local name=text(card,"Name",row.name or "Jogador",UDim2.new(1,-118,1,0),UDim2.fromOffset(47,0))
  name.Font=Enum.Font.GothamBold name.TextSize=12 name.TextXAlignment=Enum.TextXAlignment.Left name.TextTruncate=Enum.TextTruncate.AtEnd name.TextWrapped=false name.ZIndex=78
  local seconds=math.max(0,row.time or 0)
  local time=text(card,"Time",string.format("%d:%02d",math.floor(seconds/60),seconds%60),UDim2.fromOffset(58,43),UDim2.new(1,-64,0,0))
  time.Font=Enum.Font.GothamMedium time.TextSize=11 time.TextXAlignment=Enum.TextXAlignment.Right time.TextColor3=Color3.fromRGB(206,206,211) time.ZIndex=78
 end

 result.Position=UDim2.new()
 result.Size=UDim2.fromScale(1,1)
 resultView.Position=UDim2.new() resultView.Size=UDim2.fromScale(1,1)
 resultRows.Position=UDim2.new(.025,0,.18,0) resultRows.Size=UDim2.new(.34,0,.58,0)
 result.Visible=true resultUntil=os.clock()+8.8
 task.delay(8.8,function() if generation==resultGeneration then hideResult() end end)
end

local spectate=panel("Spectate",UDim2.fromOffset(330,74),UDim2.new(.5,-165,1,-102))
spectate.BackgroundTransparency=.28
local spectatorName=text(spectate,"Player","JOGADOR",UDim2.fromOffset(190,32),UDim2.fromOffset(70,3)) spectatorName.Font=Enum.Font.GothamBold spectatorName.TextSize=12
local index=1 local watching=false local watchedId=nil
button(spectate,"Previous","<<",UDim2.fromOffset(54,32),UDim2.fromOffset(8,3),function() index-=1 watchedId=nil end)
button(spectate,"Next",">>",UDim2.fromOffset(54,32),UDim2.fromOffset(268,3),function() index+=1 watchedId=nil end)
button(spectate,"Exit","LOBBY",UDim2.fromOffset(120,28),UDim2.fromOffset(105,40),function() event:FireServer("spectateExit") end)
local loading=panel("ArenaLoading",UDim2.fromScale(1,1),UDim2.new())
loading.BackgroundColor3=Color3.fromRGB(4,4,6) loading.BackgroundTransparency=.28 loading.ZIndex=80 loading.Visible=false loading.ClipsDescendants=true
loading.UIStroke.Enabled=false loading.UICorner.CornerRadius=UDim.new()
local loadingText=text(loading,"Status","CARREGANDO MAPA",UDim2.new(.8,0,0,32),UDim2.new(.1,0,.78,0))
loadingText.ZIndex=82 loadingText.TextSize=11 loadingText.TextTransparency=.28 loadingText.Font=Enum.Font.GothamMedium
local goodLuck=text(loading,"GoodLuck","GOOD LUCK",UDim2.new(.92,0,.18,0),UDim2.new(.04,0,.43,0))
goodLuck.ZIndex=81 goodLuck.Font=Enum.Font.GothamBlack goodLuck.TextScaled=true goodLuck.TextTransparency=.68 goodLuck.Visible=false
local goodLuckLimit=Instance.new("UITextSizeConstraint",goodLuck) goodLuckLimit.MinTextSize=28 goodLuckLimit.MaxTextSize=92


-- Match loading uses the same old television as the initial cinematic, but without
-- stretching the 3D model. The screen overlay carries the static/roster reveal.
local gameCornerTitle=text(loading,"GameCornerTitle","SUVIVERS",UDim2.fromOffset(180,32),UDim2.new(1,-196,0,18))
gameCornerTitle.ZIndex=92
gameCornerTitle.Font=Enum.Font.Garamond
gameCornerTitle.TextSize=20
gameCornerTitle.TextXAlignment=Enum.TextXAlignment.Right
gameCornerTitle.TextColor3=Color3.fromRGB(224,224,219)

local matchTV=Instance.new("ViewportFrame",loading)
matchTV.Name="MatchLoadingTelevision"
matchTV.Size=UDim2.fromScale(1,1)
matchTV.BackgroundColor3=Color3.fromRGB(2,2,3)
matchTV.BackgroundTransparency=0
matchTV.BorderSizePixel=0
matchTV.Ambient=Color3.fromRGB(12,12,14)
matchTV.LightColor=Color3.fromRGB(116,108,101)
matchTV.LightDirection=Vector3.new(-.7,-1,-.45)
matchTV.ZIndex=80
local matchTVWorld=Instance.new("WorldModel",matchTV)
local matchTVCamera=Instance.new("Camera",matchTV)
matchTVCamera.FieldOfView=31
matchTV.CurrentCamera=matchTVCamera

local function moveModelBox(model,targetCF)
 local cf=model:GetBoundingBox()
 model:PivotTo(targetCF*cf:Inverse()*model:GetPivot())
end

local matchTVScreenPart=nil
do
 local cinematicAssets=ReplicatedFirst:FindFirstChild("LoadingCinematicAssets")
 if cinematicAssets and cinematicAssets:FindFirstChild("TV") and cinematicAssets:FindFirstChild("Mesa") then
  local tvModel=cinematicAssets.TV:Clone()
  local mesa=cinematicAssets.Mesa:Clone()
  tvModel.Name="MatchTV"
  mesa.Name="MatchTable"
  tvModel.Parent=matchTVWorld
  mesa.Parent=matchTVWorld
  pcall(function() tvModel:ScaleTo(1.04) end)
  pcall(function() mesa:ScaleTo(.82) end)

  moveModelBox(mesa,CFrame.new(0,-1.72,0))
  local tableCF,tableSize=mesa:GetBoundingBox()
  local tableTop=tableCF.Position.Y+tableSize.Y/2
  local scr=tvModel:FindFirstChild("Screen",true)
  if scr and scr:IsA("BasePart") then
   local desired=CFrame.fromMatrix(Vector3.new(0,tableTop+1.58,0),Vector3.new(0,0,1),Vector3.new(0,1,0))
   tvModel:PivotTo(desired*scr.CFrame:Inverse()*tvModel:GetPivot())
   local tvCF,tvSize=tvModel:GetBoundingBox()
   local bottom=tvCF.Position.Y-tvSize.Y/2
   tvModel:PivotTo(CFrame.new(0,tableTop-bottom+.035,0)*tvModel:GetPivot())
   tvCF,tvSize=tvModel:GetBoundingBox()
   matchTVScreenPart=tvModel:FindFirstChild("Screen",true)
   if matchTVScreenPart then
    matchTVScreenPart.Material=Enum.Material.Neon
    matchTVScreenPart.Color=Color3.fromRGB(90,104,110)
    matchTVScreenPart.Transparency=.34
   end
   local mesaCF,mesaSize=mesa:GetBoundingBox()
   local top=math.max(tvCF.Position.Y+tvSize.Y/2,mesaCF.Position.Y+mesaSize.Y/2)
   local bottomY=math.min(tvCF.Position.Y-tvSize.Y/2,mesaCF.Position.Y-mesaSize.Y/2)
   local height=math.max(3,top-bottomY)
   local centerY=(top+bottomY)/2
   local distance=math.clamp((height*.5)/math.tan(math.rad(matchTVCamera.FieldOfView*.5))*1.18,7.2,12)
   matchTVCamera.CFrame=CFrame.lookAt(Vector3.new(0,centerY+.08,distance),Vector3.new(0,centerY,0))
  end
  for _,obj in ipairs(matchTVWorld:GetDescendants()) do
   if obj:IsA("BasePart") then
    obj.Anchored=true obj.CanCollide=false obj.CanTouch=false obj.CanQuery=false
   end
  end
 end
end

local tvStatic=Instance.new("Frame",loading)
tvStatic.Name="TVStatic"
tvStatic.AnchorPoint=Vector2.new(.5,.5)
tvStatic.Position=UDim2.fromScale(.5,.43)
tvStatic.Size=UDim2.new(.235,0,.285,0)
tvStatic.BackgroundColor3=Color3.fromRGB(74,82,86)
tvStatic.BackgroundTransparency=.18
tvStatic.BorderSizePixel=0
tvStatic.ClipsDescendants=true
tvStatic.ZIndex=86
local staticAspect=Instance.new("UIAspectRatioConstraint",tvStatic)
staticAspect.AspectRatio=.846
staticAspect.DominantAxis=Enum.DominantAxis.Height

local staticLines={}
for i=1,24 do
 local line=Instance.new("Frame",tvStatic)
 line.Name="Noise"..i
 line.BorderSizePixel=0
 line.BackgroundColor3=i%3==0 and Color3.fromRGB(235,235,230) or Color3.fromRGB(18,18,20)
 line.BackgroundTransparency=.55
 line.Size=UDim2.new(1,0,0,i%4==0 and 2 or 1)
 line.Position=UDim2.new(0,0,(i-1)/24,0)
 line.ZIndex=87
 table.insert(staticLines,line)
end

local killerOnTV=text(tvStatic,"KillerName","",UDim2.new(1,-12,0,58),UDim2.new(0,6,.5,-29))
killerOnTV.Font=Enum.Font.Garamond
killerOnTV.TextSize=16
killerOnTV.TextWrapped=true
killerOnTV.TextXAlignment=Enum.TextXAlignment.Center
killerOnTV.TextYAlignment=Enum.TextYAlignment.Center
killerOnTV.TextColor3=Color3.fromRGB(238,238,231)
killerOnTV.TextStrokeTransparency=.35
killerOnTV.ZIndex=90
killerOnTV.Visible=false

local loadingRoster=text(loading,"LoadingRoster","",UDim2.new(.72,0,0,76),UDim2.new(.14,0,.62,0))
loadingRoster.Font=Enum.Font.Garamond
loadingRoster.TextSize=16
loadingRoster.TextWrapped=true
loadingRoster.TextColor3=Color3.fromRGB(226,226,220)
loadingRoster.TextStrokeTransparency=.48
loadingRoster.TextXAlignment=Enum.TextXAlignment.Center
loadingRoster.TextYAlignment=Enum.TextYAlignment.Center
loadingRoster.ZIndex=91
loadingRoster.Visible=false

local matchTVNoiseToken=0
local function startMatchTVNoise(token)
 matchTVNoiseToken+=1
 local noiseToken=matchTVNoiseToken
 killerOnTV.Visible=false
 loadingRoster.Visible=false
 task.spawn(function()
  local n=0
  while noiseToken==matchTVNoiseToken and token==loadToken and loading.Visible do
   n+=1
   for i,line in ipairs(staticLines) do
    local wave=(math.sin(n*.83+i*1.71)+1)*.5
    line.Position=UDim2.new(0,0,(i*0.041+n*.017)%1,0)
    line.BackgroundTransparency=.38+wave*.46
   end
   tvStatic.BackgroundTransparency=.12+((n%4)*.035)
   matchTV.Ambient=(n%5==0) and Color3.fromRGB(17,16,19) or Color3.fromRGB(10,10,12)
   task.wait(.055)
  end
 end)
 task.delay(5,function()
  if token~=loadToken or not loading.Visible then return end
  local killerPlayer=tostring(net:GetAttribute("KillerPlayerName") or net:GetAttribute("Killer") or "?")
  killerOnTV.Text=L("PERSEGUIDOR\n","KILLER\n")..killerPlayer
  killerOnTV.Visible=true
  local roster={}
  local raw=net:GetAttribute("LoadingRoster")
  if type(raw)=="string" then pcall(function() roster=HttpService:JSONDecode(raw) end) end
  if type(roster)~="table" or #roster==0 then
   roster={}
   for _,p in ipairs(Players:GetPlayers()) do table.insert(roster,p.DisplayName or p.Name) end
  end
  loadingRoster.Text=table.concat(roster,"   •   ")
  loadingRoster.Visible=true
 end)
end


local loadingAvatar=Instance.new("ViewportFrame",loading)
loadingAvatar.Name="ArenaAvatar"
loadingAvatar.BackgroundTransparency=1
loadingAvatar.AnchorPoint=Vector2.new(.5,1)
loadingAvatar.Position=UDim2.new(.5,0,1.14,0)
loadingAvatar.Size=UDim2.new(.72,0,.88,0)
loadingAvatar.Ambient=Color3.fromRGB(70,72,80)
loadingAvatar.LightColor=Color3.fromRGB(224,219,222)
loadingAvatar.LightDirection=Vector3.new(-.7,-.8,-.45)
loadingAvatar.ZIndex=82 loadingAvatar.Visible=false
loadingAvatar:SetAttribute("LegacyHidden",true)
local loadingAvatarWorld=Instance.new("WorldModel",loadingAvatar)
local loadingAvatarCamera=Instance.new("Camera",loadingAvatar) loadingAvatarCamera.FieldOfView=34 loadingAvatar.CurrentCamera=loadingAvatarCamera
local loadingAvatarClone=nil local loadingAvatarRoot=nil local loadingAvatarBase=nil local loadingAvatarConn=nil local loadingAvatarJoints={}

local function clearArenaLoadingAvatar()
 if loadingAvatarConn then loadingAvatarConn:Disconnect() loadingAvatarConn=nil end
 if loadingAvatarClone then loadingAvatarClone:Destroy() loadingAvatarClone=nil end
 loadingAvatarRoot=nil loadingAvatarBase=nil table.clear(loadingAvatarJoints)
end

local function buildArenaLoadingAvatar()
 clearArenaLoadingAvatar()
 local char=player.Character
 if not char then return end
 local archivable=char.Archivable char.Archivable=true
 local ok,clone=pcall(function() return char:Clone() end)
 char.Archivable=archivable
 if not ok or not clone then return end
 loadingAvatarClone=clone clone.Name="ArenaLoadingCharacter"
 for _,d in ipairs(clone:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.CastShadow=false
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=false end
 end
 local root=clone:FindFirstChild("HumanoidRootPart")
 local hum=clone:FindFirstChildOfClass("Humanoid")
 if not root then clone:Destroy() loadingAvatarClone=nil return end
 if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false end
 clone.PrimaryPart=root root.Anchored=true clone.Parent=loadingAvatarWorld clone:PivotTo(CFrame.new())
 loadingAvatarRoot=root loadingAvatarBase=CFrame.new(0,-.4,0)*CFrame.Angles(0,math.rad(-6),0) root.CFrame=loadingAvatarBase
 for _,j in ipairs(clone:GetDescendants()) do if j:IsA("Motor6D") then loadingAvatarJoints[j]=j.Transform end end
 local head=clone:FindFirstChild("Head") local torso=clone:FindFirstChild("Torso") or clone:FindFirstChild("UpperTorso")
 local focus=(head and head.Position or Vector3.new(0,2.6,0)):Lerp(torso and torso.Position or Vector3.new(0,1.6,0),.34)
 local _,size=clone:GetBoundingBox()
 loadingAvatarCamera.CFrame=CFrame.lookAt(focus+Vector3.new(.15,.08,math.max(5.2,size.Y*.82)),focus)
 local started=os.clock()
 loadingAvatarConn=RunService.RenderStepped:Connect(function()
  if not loading.Visible or not loadingAvatarRoot or not loadingAvatarRoot.Parent then return end
  local t=os.clock()-started
  loadingAvatarRoot.CFrame=loadingAvatarBase*CFrame.new(math.sin(t*.55)*.025,math.sin(t*1.3)*.05,0)*CFrame.Angles(0,math.sin(t*.45)*.025,0)
  for joint,base in pairs(loadingAvatarJoints) do if joint.Parent then
   local name=joint.Name:lower()
   if name:find("neck") then joint.Transform=base*CFrame.Angles(math.sin(t*.7)*.022,math.sin(t*.48)*.03,0)
   elseif name:find("shoulder") then
    local side=name:find("left") and -1 or 1
    joint.Transform=base*CFrame.Angles(math.rad(-22)+math.sin(t*1.1+side)*.16,0,side*(.3+math.sin(t*.8)*.08))
   end
  end end
 end)
end
local progressTrack=Instance.new("Frame",loading)
progressTrack.Name="MapProgress" progressTrack.AnchorPoint=Vector2.new(0,1) progressTrack.Position=UDim2.new(0,0,1,0)
progressTrack.Size=UDim2.new(1,0,0,7) progressTrack.BorderSizePixel=0 progressTrack.BackgroundColor3=Color3.fromRGB(21,21,25) progressTrack.ZIndex=84
local progressFill=Instance.new("Frame",progressTrack)
progressFill.Name="Fill" progressFill.Size=UDim2.fromScale(0,1) progressFill.BorderSizePixel=0 progressFill.BackgroundColor3=Color3.fromRGB(222,222,226) progressFill.ZIndex=85
local progressGlow=Instance.new("Frame",progressFill)
progressGlow.Name="Tip" progressGlow.AnchorPoint=Vector2.new(1,.5) progressGlow.Position=UDim2.new(1,0,.5,0) progressGlow.Size=UDim2.fromOffset(18,16)
progressGlow.BackgroundColor3=Color3.fromRGB(245,245,248) progressGlow.BackgroundTransparency=.35 progressGlow.BorderSizePixel=0 progressGlow.ZIndex=86
local loadToken=0
local loadingCameraState=nil
local loadingCameraConn=nil
local function restoreLoadingCamera()
 if loadingCameraConn then loadingCameraConn:Disconnect() loadingCameraConn=nil end
 local state=loadingCameraState
 loadingCameraState=nil
 if not state then return end
 local camera=workspace.CurrentCamera or state.camera
 if not camera then return end
 local subject=state.cameraSubject
 if not subject or not subject.Parent then subject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
 if subject then
  camera.CameraSubject=subject
  camera.CameraType=Enum.CameraType.Custom
 else
  camera.CameraType=state.cameraType or Enum.CameraType.Custom
  if camera.CameraType==Enum.CameraType.Scriptable and state.cframe then camera.CFrame=state.cframe end
 end
 camera.FieldOfView=player:GetAttribute("CameraFOV") or state.fieldOfView or 48
end
local function captureLoadingCamera(map,token)
 restoreLoadingCamera()
 local camera=workspace.CurrentCamera
 if not camera then return end
 loadingCameraState={camera=camera,cameraType=camera.CameraType,cameraSubject=camera.CameraSubject,cframe=camera.CFrame,fieldOfView=camera.FieldOfView}
 camera.CameraType=Enum.CameraType.Scriptable
 local started=os.clock()
 local cachedCenter=nil local cachedSize=nil local nextMeasure=0
 loadingCameraConn=RunService.RenderStepped:Connect(function()
  if token~=loadToken or not loading.Visible then return end
  local current=workspace.CurrentCamera
  local arena=map and map.Parent and map or workspace:FindFirstChild("ActiveArena")
  if not current or not arena then return end
  local t=os.clock()
  if not cachedCenter or t>=nextMeasure then
   local cf,size=arena:GetBoundingBox()
   cachedCenter=cf.Position+Vector3.new(0,math.clamp(size.Y*.08,1,6),0)
   cachedSize=size
   nextMeasure=t+.45
  end
  local size=cachedSize or Vector3.new(40,15,40)
  local radius=math.clamp(math.max(size.X,size.Z)*.22,24,60)
  local angle=(t-started)*.11
  local height=math.clamp(size.Y*.32+10,14,30)
  local pos=cachedCenter+Vector3.new(math.cos(angle)*radius,height,math.sin(angle)*radius)
  current.CameraType=Enum.CameraType.Scriptable
  current.CFrame=CFrame.lookAt(pos,cachedCenter)
  current.FieldOfView=60
 end)
end

local function setMapProgress(value,duration)
 value=math.clamp(value,0,1)
 TweenService:Create(progressFill,TweenInfo.new(duration or .16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(value,1)}):Play()
end

local function playGoodLuckVoice(token)
 if token~=loadToken or not loading.Visible then return end
 -- No spoken Good Luck or stacked voices.
 task.wait(.24)
 if token~=loadToken or not loading.Visible then return end
 goodLuck.Visible=true
 TweenService:Create(goodLuck,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=.05}):Play()

end

local function preload(roundId,map)
 loadToken+=1 local token=loadToken
 local loadingStarted=os.clock()
 loading.Visible=true goodLuck.Visible=false goodLuck.TextTransparency=.68
 loadingAvatar.Visible=false
 restoreLoadingCamera()
 loadingRoster.Visible=false killerOnTV.Visible=false
 startMatchTVNoise(token)
 progressFill.Size=UDim2.fromScale(0,1) loadingText.Text=L("CARREGANDO MAPA","LOADING MAP")
 setMapProgress(.04,.05)
 task.spawn(function()
  local deadline=os.clock()+18 local geometryReady=false
  while os.clock()<deadline and token==loadToken do
   map=map and map.Parent and map or workspace:FindFirstChild("ActiveArena")
   if map and map:GetAttribute("RoundId")==roundId and map:FindFirstChild("SafePoints") then
    local count=0 for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then count+=1 end end
    local expected=math.max(1,map:GetAttribute("PartCount") or count)
    local ratio=math.clamp(count/expected,0,1)
    loadingText.Text=L("CARREGANDO MAPA  ","LOADING MAP  ")..math.floor(ratio*100).."%"
    setMapProgress(.06+ratio*.68,.12)
    if count>=expected then geometryReady=true break end
   end
   task.wait(.1)
  end
  if token~=loadToken then return end
  if not geometryReady then
   loading.Visible=false clearArenaLoadingAvatar() restoreLoadingCamera() event:FireServer("loadFailed",roundId)
   notice.Text=L("A conexão está lenta. A arena continua carregando.","Your connection is slow. The arena is still loading.") return
  end
  local done=false local mediaDeadline=os.clock()+8
  loadingText.Text=L("PREPARANDO O AMBIENTE","PREPARING ENVIRONMENT")
  setMapProgress(.82,.22)
  task.spawn(function()
   pcall(function() game:GetService("ContentProvider"):PreloadAsync({map}) end)
   done=true
  end)
  while not done and os.clock()<mediaDeadline and token==loadToken do task.wait(.1) end
  if token~=loadToken then return end
  setMapProgress(.96,.22)
  loadingText.Text=""
  goodLuck.Visible=false
  local minimumRemaining=loadingStarted+10-os.clock()
  if minimumRemaining>0 then task.wait(minimumRemaining) end
  if token~=loadToken then return end
  setMapProgress(1,.15)
  task.wait(.18)
  matchTVNoiseToken+=1
  loading.Visible=false
  goodLuck.Visible=false
  loadingRoster.Visible=false killerOnTV.Visible=false
  clearArenaLoadingAvatar()
  restoreLoadingCamera()
  -- Geometry gates readiness; optional unavailable audio/decals must not eject a player.
  if map and map.Parent and map:GetAttribute("RoundId")==roundId then event:FireServer("ready",roundId) end
 end)
end
local noticeUntil=0
local shakeToken=0
local function shakeCamera(duration,intensity)
 shakeToken+=1 local token=shakeToken
 task.spawn(function()
  local char=player.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not hum then return end
  local reduced=player:GetAttribute("ReducedMotion")==true
  local strength=intensity*(reduced and .25 or 1)
  local start=os.clock()
  while token==shakeToken and hum.Parent and os.clock()-start<duration do
   local t=(os.clock()-start)/duration
   local fade=1-math.clamp(t,0,1)
   hum.CameraOffset=Vector3.new(
    math.sin(os.clock()*47)*strength*fade,
    math.cos(os.clock()*61)*strength*.7*fade,
    0
   )
   RunService.RenderStepped:Wait()
  end
  if hum.Parent then hum.CameraOffset=Vector3.zero end
 end)
end

local hitReactionToken=0
local function caughtAnimation(killer,killerCF)
 hitReactionToken+=1 local token=hitReactionToken
 local char=player.Character
 if not char then return end
 local downed=player:GetAttribute("Downed")==true
 shakeCamera(downed and .42 or .28,downed and .36 or .22)
 if downed or player:GetAttribute("ReducedMotion") then return end
 local joints={}
 for _,joint in ipairs(char:GetDescendants()) do
  if joint:IsA("Motor6D") then joints[joint.Name:lower()]=joint end
 end
 local neck=joints.neck
 local left=joints["left shoulder"] or joints.leftshoulder
 local right=joints["right shoulder"] or joints.rightshoulder
 local originals={}
 for _,j in ipairs({neck,left,right}) do if j then originals[j]=j.Transform end end
 if neck then TweenService:Create(neck,TweenInfo.new(.08),{Transform=originals[neck]*CFrame.Angles(math.rad(-7),0,math.rad(4))}):Play() end
 if left then TweenService:Create(left,TweenInfo.new(.08),{Transform=originals[left]*CFrame.Angles(math.rad(10),0,math.rad(-12))}):Play() end
 if right then TweenService:Create(right,TweenInfo.new(.08),{Transform=originals[right]*CFrame.Angles(math.rad(14),0,math.rad(12))}):Play() end
 task.wait(.13)
 if token~=hitReactionToken or player.Character~=char then return end
 for joint,cf in pairs(originals) do if joint.Parent then TweenService:Create(joint,TweenInfo.new(.12),{Transform=cf}):Play() end end
end

player:GetAttributeChangedSignal("Downed"):Connect(function()
 if player:GetAttribute("Downed")==true then shakeCamera(.42,.34) end
end)

net.Update.OnClientEvent:Connect(function(action,a,b)
 hackEvent(action,a,b)
 if action=="reset" then
  hackEvent("hackEnd") hideResult()
  loadToken+=1 matchTVNoiseToken+=1 loading.Visible=false goodLuck.Visible=false loadingRoster.Visible=false killerOnTV.Visible=false clearArenaLoadingAvatar() restoreLoadingCamera() progressFill.Size=UDim2.fromScale(0,1)
 elseif action=="notice" then
  notice.Text=a noticeUntil=os.clock()+5
 elseif action=="shopResult" then
  refreshShop()
  notice.Text=tostring(b or (a and L("Compra concluída.","Purchase complete.") or L("Compra não concluída.","Purchase failed."))) noticeUntil=os.clock()+5
 elseif action=="itemResult" then
  refreshItemShop()
  refreshShop()
  notice.Text=tostring(b or (a and L("Item melhorado.","Item upgraded.") or L("Melhoria não concluída.","Upgrade failed.")))
  noticeUntil=os.clock()+5
 elseif action=="mission" then
  announceMission(a)
 elseif action=="objectiveDone" then
  announceMission(net:GetAttribute("MissionStage") or "Hack")
 elseif action=="escape" then
  escapeText.Text=tostring(a)..L(" ESCAPOU"," ESCAPED")
  escapeBanner.Visible=true
  task.delay(2.4,function() escapeBanner.Visible=false end)
 elseif action=="achievement" then
  missionBannerText.Text=tostring(a).."  •  "..tostring(b or "")
  missionBanner.Visible=true missionPulse+=1 local token=missionPulse
  task.delay(3,function() if token==missionPulse then missionBanner.Visible=false end end)
 elseif action=="hitFlash" then
  local strength=tonumber(a) or .45
  hitFlash.BackgroundTransparency=math.clamp(.78-strength*.35,.42,.82)
  TweenService:Create(hitFlash,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
 elseif action=="load" then
  preload(a,b)
 elseif action=="caught" or action=="executed" then
  task.spawn(caughtAnimation,a,b)
 elseif action=="roundResult" and type(a)=="table" then
  updateRoundMusic(true)
  showResult(a)
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsOverlay.Visible or result.Visible or not player:GetAttribute("InRound") then return end
 if input.KeyCode==Enum.KeyCode.LeftShift then mode="run" event:FireServer("mode",mode)
 elseif input.KeyCode==Enum.KeyCode.C or input.KeyCode==Enum.KeyCode.LeftControl then
  if not player:GetAttribute("IsJason") then mode=(player:GetAttribute("MoveMode")=="crouch") and "walk" or "crouch" event:FireServer("mode",mode) end
 elseif input.KeyCode==Enum.KeyCode.E and not player:GetAttribute("IsJason") then event:FireServer("carry")
 elseif input.UserInputType==Enum.UserInputType.MouseButton1 and player:GetAttribute("IsJason") then event:FireServer("attack")
 elseif input.KeyCode==Enum.KeyCode.F then event:FireServer("flashlight") end
end)
UIS.InputEnded:Connect(function(input)
 if input==heldRunInput then stopHeldRun(input) end
 if input.KeyCode==Enum.KeyCode.LeftShift and mode=="run" then mode="walk" event:FireServer("mode",mode) end
end)
local highlight=Instance.new("Highlight") highlight.Name="PursuerTarget" highlight.FillColor=Color3.fromRGB(200,35,43) highlight.OutlineColor=Color3.fromRGB(242,80,85) highlight.FillTransparency=.8 highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Enabled=false highlight.Parent=gui

local jasonPresentationFov=70
updateRoundMusic(false)
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera
 if not camera then return end
 local baseFov=player:GetAttribute("CameraFOV") or 70
 local isJason=player:GetAttribute("IsJason")==true
 local active=isJason and player:GetAttribute("InRound")==true and player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true
 if active then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local targetFov=player:GetAttribute("ReducedMotion") and baseFov or math.min(100,baseFov+(speed>4 and 14 or 8))
  jasonPresentationFov+=(targetFov-jasonPresentationFov)*math.min(1,dt*6)
  if camera.CameraType~=Enum.CameraType.Scriptable then camera.FieldOfView=jasonPresentationFov end
 else
  jasonPresentationFov+=(baseFov-jasonPresentationFov)*math.min(1,dt*6)
  if player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true and camera.CameraType~=Enum.CameraType.Scriptable then
   camera.FieldOfView=jasonPresentationFov
  end
 end
end)

local votePanel=panel("MapVoting",UDim2.new(.92,0,.46,0),UDim2.new(.04,0,.27,0))
votePanel.BackgroundColor3=Color3.fromRGB(7,7,10) votePanel.BackgroundTransparency=.08 votePanel.Visible=false votePanel.ZIndex=60
local voteTitle=text(votePanel,"Title",L("ESCOLHA O PRÓXIMO MAPA","CHOOSE THE NEXT MAP"),UDim2.new(1,-24,0,40),UDim2.fromOffset(12,8)) voteTitle.Font=Enum.Font.GothamBlack voteTitle.TextSize=20 voteTitle.TextXAlignment=Enum.TextXAlignment.Left voteTitle.ZIndex=62
local voteHint=text(votePanel,"Hint",L("4 NA VOTAÇÃO  •  RANDOM  •  7 MAPAS TOTAIS","4 IN VOTE  •  RANDOM  •  7 MAPS TOTAL"),UDim2.new(1,-24,0,20),UDim2.fromOffset(12,42)) voteHint.TextSize=10 voteHint.TextColor3=Color3.fromRGB(150,150,160) voteHint.TextXAlignment=Enum.TextXAlignment.Left voteHint.ZIndex=62
local voteTimer=text(votePanel,"Timer","6",UDim2.fromOffset(54,48),UDim2.new(1,-68,0,8)) voteTimer.Font=Enum.Font.GothamBlack voteTimer.TextSize=28 voteTimer.ZIndex=63
local mapNames={
 DoomspireBrickbattle="DOOMSPIRE",
 JuggernautFightArena="JUGGERNAUT",
 PirateBayIsland="PIRATE BAY",
 NaturalDisasterSurvival="NATURAL DISASTER",
 RocketArena="ROCKET ARENA",
 PiggySewers="PIGGY SEWERS",
 PiggyMappleDonut="MAPPLE DONUT",
 RANDOM="RANDOM",
}
local mapByName={}
for _,map in ipairs(config.Maps) do mapByName[map.name]=map end
local voteCards={}
for i=1,5 do
 local width=.188
 local x=.018+(i-1)*.196
 local cardIndex=i
 local b=button(votePanel,"VoteCard"..i,"",UDim2.new(width,0,.70,0),UDim2.new(x,0,.20,0),function()
  local card=voteCards[cardIndex]
  local value=card and card:GetAttribute("VoteValue")
  if value then event:FireServer("voteMap",value) end
 end)
 b.Text="" b.BackgroundColor3=Color3.fromRGB(16,16,21) b.BackgroundTransparency=.06 b.ZIndex=62
 local preview=Instance.new("ImageLabel",b) preview.Name="Preview" preview.Size=UDim2.new(1,-6,.72,-4) preview.Position=UDim2.fromOffset(3,3) preview.BackgroundTransparency=1 preview.ScaleType=Enum.ScaleType.Crop preview.ZIndex=63
 Instance.new("UICorner",preview).CornerRadius=UDim.new(0,9)
 local shade=Instance.new("UIGradient",preview) shade.Rotation=90 shade.Color=ColorSequence.new(Color3.fromRGB(210,210,215),Color3.fromRGB(90,90,100))
 local randomMark=text(b,"RandomMark","?",UDim2.new(1,-6,.72,-4),UDim2.fromOffset(3,3)) randomMark.TextSize=46 randomMark.Font=Enum.Font.GothamBlack randomMark.TextColor3=Color3.fromRGB(205,208,220) randomMark.TextStrokeTransparency=.2 randomMark.Visible=false randomMark.ZIndex=64
 local caption=text(b,"Caption","",UDim2.new(1,-8,0,28),UDim2.new(0,4,.73,0)) caption.TextSize=10 caption.Font=Enum.Font.GothamBlack caption.ZIndex=64 caption.TextStrokeTransparency=.35
 local votes=text(b,"Votes","0 VOTOS",UDim2.new(1,-8,0,20),UDim2.new(0,4,.86,0)) votes.TextSize=9 votes.Font=Enum.Font.GothamBold votes.TextColor3=Color3.fromRGB(170,170,180) votes.ZIndex=64
 voteCards[i]=b
end
local function refreshVoteCards()
 local okOptions,options=pcall(function() return game:GetService("HttpService"):JSONDecode(net:GetAttribute("MapVoteOptions") or "[]") end)
 if not okOptions or type(options)~="table" then options={} end
 local values={options[1],options[2],options[3],options[4],"RANDOM"}
 local okCounts,counts=pcall(function() return game:GetService("HttpService"):JSONDecode(net:GetAttribute("MapVotes") or "{}") end)
 if not okCounts or type(counts)~="table" then counts={} end
 for i,b in ipairs(voteCards) do
  local value=values[i]
  b.Visible=value~=nil
  b:SetAttribute("VoteValue",value)
  if value then
   local spec=mapByName[value]
   b.Caption.Text=mapNames[value] or value
   b.Votes.Text=tostring(counts[value] or 0)..L(" VOTOS"," VOTES")
   b.RandomMark.Visible=value=="RANDOM"
   b.Preview.Visible=value~="RANDOM"
   b.Preview.Image=spec and ("rbxthumb://type=Asset&id="..spec.id.."&w=420&h=420") or ""
   local selected=player:GetAttribute("MapVote")==value
   b.BackgroundColor3=selected and Color3.fromRGB(58,72,105) or Color3.fromRGB(16,16,21)
   b.UIStroke.Color=selected and Color3.fromRGB(190,205,255) or Color3.fromRGB(150,150,158)
   b.UIStroke.Transparency=selected and .12 or .72
  end
 end
end
local killerPanel=panel("KillerSelection",UDim2.new(.66,0,.45,0),UDim2.fromScale(.17,.25))
killerPanel.Visible=false
local killerTitle=text(killerPanel,"Title",L("VOCÊ É O PERSEGUIDOR • ESCOLHA","YOU ARE THE KILLER • CHOOSE"),UDim2.new(1,0,0,44),UDim2.new())
local names={} for name in pairs(config.Killers) do table.insert(names,name) end table.sort(names)
local killerChoiceButtons={}
for i,name in ipairs(names) do
 local killerName=name
 local b=button(killerPanel,killerName,killerName,UDim2.new(.3,0,.28,0),UDim2.new(.025+((i-1)%3)*.325,0,.25+math.floor((i-1)/3)*.34,0),function()
  if ownedKillers()[killerName] then event:FireServer("chooseKiller",killerName) else notice.Text=L("Compre ","Buy ")..killerName..L(" na LOJA primeiro."," in the SHOP first.") noticeUntil=os.clock()+4 end
 end)
 killerChoiceButtons[killerName]=b
end
local function refreshKillerChoices()
 local owned=ownedKillers()
 for name,b in pairs(killerChoiceButtons) do
  b.Text=owned[name] and name or (name.."\n"..L("BLOQUEADO","LOCKED"))
  b.TextTransparency=owned[name] and 0 or .38
  b.BackgroundTransparency=owned[name] and .18 or .58
 end
end
player:GetAttributeChangedSignal("OwnedKillersJson"):Connect(refreshKillerChoices)
refreshKillerChoices()

local function refreshLanguage()
 countdownText.Text=L("Aguardando jogadores","Waiting for players")
 shopTitle.Text=L("PERSEGUIDORES","KILLERS")
 shopSubtitle.Text=""
 shopClose.Text="×"
 shopSearch.PlaceholderText=L("PESQUISAR","SEARCH")
 shopTabs.Killers.Text=L("PERSEGUIDORES","KILLERS")
 shopTabs.Items.Text=L("ITENS","ITEMS")
 placeholderText.Text=activeShopTab=="Emotes" and L("EMOTES • EM BREVE","EMOTES • COMING SOON") or ""
 lanternTitle.Text=L("LANTERNA","LANTERN")
 refreshItemShop()
 shopButton:SetAttribute("AccessibleLabel",L("Loja de perseguidores","Killer shop"))
 missionTitle.Text=L("MISSÃO","MISSION")
 missionBannerText.Text=L("NOVA MISSÃO","NEW MISSION")
 if not result.Visible then resultHeader.Text=L("FIM DA PARTIDA","MATCH OVER") end
 voteTitle.Text=L("ESCOLHA O PRÓXIMO MAPA","CHOOSE THE NEXT MAP")
 voteHint.Text=L("4 NA VOTAÇÃO  •  RANDOM  •  7 MAPAS TOTAIS","4 IN VOTE  •  RANDOM  •  7 MAPS TOTAL")
 killerTitle.Text=L("VOCÊ É O PERSEGUIDOR • ESCOLHA","YOU ARE THE KILLER • CHOOSE")
 missionText.Text=missionCopy(net:GetAttribute("MissionStage") or "Waiting")
 refreshShop()
 refreshKillerChoices()
 refreshVoteCards()
end
player:GetAttributeChangedSignal("GameLanguage"):Connect(refreshLanguage)
refreshLanguage()
local voteElapsed=0
RunService.RenderStepped:Connect(function(dt)
 voteElapsed+=dt if voteElapsed<.15 then return end voteElapsed=0
 killerPanel.Visible=net:GetAttribute("Phase")=="Escolha" and player:GetAttribute("ChoosingKiller")==true and not player:GetAttribute("InMenu") and not loading.Visible
 if killerPanel.Visible then refreshKillerChoices() end
 votePanel.Visible=net:GetAttribute("Phase")=="Votação" and player:GetAttribute("MapVote")==nil and not player:GetAttribute("InMenu") and not player:GetAttribute("AFK") and not settingsOverlay.Visible and not loading.Visible
 if not votePanel.Visible then return end
 local seconds=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 voteTimer.Text=tostring(seconds)
 refreshVoteCards()
end)

local dtSum=0
RunService.RenderStepped:Connect(function(dt)
 dtSum+=dt if dtSum<.1 then return end dtSum=0
 local hidden=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("SweanLoadingDone")~=true
 if result.Visible and os.clock()>=resultUntil then hideResult() end
 settingsButton.Visible=not hidden and not result.Visible
 shopButton.Visible=not hidden and not result.Visible and not player:GetAttribute("InRound") and not player:GetAttribute("Spectating")
 settingsOverlay.Visible=settingsOverlay.Visible and not hidden
 if hidden or player:GetAttribute("InRound") or player:GetAttribute("Spectating") then shopOverlay.Visible=false end
 profileHUD.Visible=not hidden and not result.Visible
 roster.Visible=not hidden and not result.Visible and player:GetAttribute("InRound")==true and player:GetAttribute("IsJason")~=true and player:GetAttribute("Spectating")~=true
 updateRoster()
 local controlsVisible=not settingsOverlay.Visible and not result.Visible and player:GetAttribute("InMenu")~=true and player:GetAttribute("VoidActive")~=true and player:GetAttribute("SweanLoadingDone")==true and player:GetAttribute("Spectating")~=true
 local inRound=player:GetAttribute("InRound") local down=player:GetAttribute("Downed") local status=player:GetAttribute("RoundStatus")
 healthHUD.Visible=not hidden and inRound and not result.Visible
 local healthHumanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 condition.Text="♥  "..tostring(math.floor(healthHumanoid and healthHumanoid.Health or 0))
 condition.TextColor3=down and Color3.fromRGB(231,101,107) or player:GetAttribute("Injured") and Color3.fromRGB(229,186,100) or Color3.fromRGB(144,223,111)
 healthHUD.UIStroke.Color=condition.TextColor3
 local stats=player:FindFirstChild("leaderstats") local xp=stats and stats:FindFirstChild("XP") local lv=stats and stats:FindFirstChild("Nível") local pts=stats and stats:FindFirstChild("Pontos")
 local n=lv and lv.Value or 1 local total=xp and xp.Value or 0 local minimum=15*(n-1)^2+35*(n-1) local nextLevel=15*n^2+35*n
 xpFill.Size=UDim2.fromScale(n>=1000 and 1 or math.clamp((total-minimum)/(nextLevel-minimum),0,1),1)
 levelText.Text=L("NÍVEL ","LEVEL ")..n.."   •   "..(n>=1000 and L("MÁXIMO","MAX") or math.max(0,total-minimum).."/"..(nextLevel-minimum)) pointsText.Text=""..(pts and pts.Value or 0)
 local phase=net:GetAttribute("Phase") or "Aguardando"
 local left=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 countdown.Visible=not hidden and (phase=="Intervalo" or phase=="Escolha" or phase=="Aguardando")
 actionLayout()
 if phase=="Escolha" then countdownText.Text=L("Escolhendo perseguidor • ","Choosing killer • ")..left.."s"
 elseif phase=="Aguardando" or (left==0 and phase=="Intervalo") then countdownText.Text=player:GetAttribute("AFK") and L("AFK ativado","AFK enabled") or L("Aguardando jogadores","Waiting for players") else countdownText.Text=string.format("%02d:%02d • %d/%d",math.floor(left/60),left%60,net:GetAttribute("Waiting") or 0,net:GetAttribute("MaxPlayers") or 8) end
 top.Visible=not hidden and phase=="Partida" and (inRound or player:GetAttribute("Spectating")==true)
 local isJason=player:GetAttribute("IsJason")
 topActions.Visible=controlsVisible and inRound and not down
 bar.Visible=controlsVisible and inRound
 run.Visible=controlsVisible and inRound and not down
 crouch.Visible=controlsVisible and inRound and not down and not isJason
 lantern.Visible=controlsVisible and inRound and not down and not isJason
 local lanternSeconds=math.max(0,tonumber(player:GetAttribute("LanternSeconds")) or tonumber(player:GetAttribute("LanternMaxSeconds")) or 70)
 local lanternCharged=lanternSeconds>.05
 lantern.Active=lantern.Visible and lanternCharged
 if not lanternCharged then
  lantern.Text=L("SEM CARGA","EMPTY")
 elseif player:GetAttribute("FlashlightOn")==true then
  lantern.Text=L("APAGAR ","OFF ")..formatSeconds(lanternSeconds)
 else
  lantern.Text=L("LANTERNA ","LANTERN ")..formatSeconds(lanternSeconds)
 end
 lantern.BackgroundColor3=player:GetAttribute("FlashlightOn")==true and Color3.fromRGB(92,67,34) or lanternCharged and Color3.fromRGB(25,26,30) or Color3.fromRGB(44,31,31)
 attackButton.Visible=controlsVisible and inRound and not down and isJason
 if heldRunInput and not down then mode="run" else mode=player:GetAttribute("MoveMode") or "walk" end
 if run:FindFirstChild("ReferenceActionArt") then setActionArt(run,mode=="run" and "RunActive" or "Run") else run.Text="CORRER" end
 run.TextTransparency=mode=="run" and 0 or .12
 if crouch:FindFirstChild("ReferenceActionArt") then crouch.Text="" crouch.ReferenceActionArt.ImageColor3=mode=="crouch" and Color3.fromRGB(255,197,125) or Color3.new(1,1,1) else crouch.Text=mode=="crouch" and "LEVANTAR" or "AGACHAR" end
 local stamina=player:GetAttribute("Stamina") or 0 local maxStamina=math.max(1,player:GetAttribute("MaxStamina") or 100)
 staminaFill.Size=UDim2.fromScale(math.clamp(stamina/maxStamina,0,1),1)
 staminaTrack.Visible=not hidden and inRound and not down
 local reviveTarget=nil local reviveDistance=8.5
 if controlsVisible and inRound and not down and not isJason then
  local myRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if myRoot then
   for _,other in ipairs(Players:GetPlayers()) do
    if other~=player and other:GetAttribute("InRound") and other:GetAttribute("Downed") then
     local rr=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
     if rr then
      local distance=(rr.Position-myRoot.Position).Magnitude
      if distance<reviveDistance then reviveDistance=distance reviveTarget=other end
     end
    end
   end
  end
 end
 reviveNearby.Visible=reviveTarget~=nil and (player:GetAttribute("ReviveAt") or 0)<=workspace:GetServerTimeNow() and (player:GetAttribute("CarryingUserId") or 0)==0
 reviveNearby.Active=reviveNearby.Visible
 carryNearby.Visible=controlsVisible and inRound and not isJason and (reviveTarget~=nil or (player:GetAttribute("CarryingUserId") or 0)>0)
 carryNearby.Text=(player:GetAttribute("CarryingUserId") or 0)>0 and "SOLTAR" or "CARREGAR"
 bar.Visible=controlsVisible and inRound and (isJason or reviveNearby.Visible or carryNearby.Visible)
 timer.Text=string.format("%d:%02d",math.floor(left/60),left%60)
 local stage=net:GetAttribute("ExitUnlocked") and "Exit" or player:GetAttribute("HasKey") and "Key" or net:GetAttribute("MissionStage") or "Waiting"
 mission.Visible=not hidden and phase=="Partida" and not isJason and (inRound or player:GetAttribute("Spectating"))
 missionText.Text=missionCopy(stage)
 inventory.Visible=not hidden and inRound and not isJason
 inventoryIcon.Text=player:GetAttribute("HasKey") and "🔑" or "—"
 inventoryLabel.Text=player:GetAttribute("HasKey") and L("CHAVE  1/1","KEY  1/1") or L("VAZIO  0/1","EMPTY  0/1")
 exitHighlight.Enabled=false
 if player:GetAttribute("HasKey") and phase=="Partida" then
  local activeArena=workspace:FindFirstChild("ActiveArena")
  local objectives=activeArena and activeArena:FindFirstChild("RoundObjectives")
  local exit=objectives and objectives:FindFirstChild("EscapeExit")
  if exit then exitHighlight.Adornee=exit exitHighlight.Enabled=true end
 end
 local killer=net:GetAttribute("Killer") local stats=player:FindFirstChild("leaderstats") local score=stats and stats:FindFirstChild("Pontos")
 detail.Text=""
 local reviveLeft=(player:GetAttribute("ReviveAt") or 0)-workspace:GetServerTimeNow()
 local protected=(player:GetAttribute("ProtectedUntil") or 0)-workspace:GetServerTimeNow()
 if reviveLeft>0 then notice.Text=string.format("Reanimando • %.1fs",reviveLeft)
 elseif down then notice.Text=L("Caído • ","Downed • ")..math.max(0,math.ceil((player:GetAttribute("BleedoutAt") or 0)-workspace:GetServerTimeNow())).."s"
 elseif protected>0 and inRound then notice.Text=""
 elseif os.clock()>noticeUntil then notice.Text="" end
 notice.Visible=not hidden and notice.Text~=""
 local spec=player:GetAttribute("Spectating") and not hidden and not result.Visible
 spectate.Visible=spec or false
 local camera=workspace.CurrentCamera
 if spec and camera then
  local targets={}
  for _,p in ipairs(Players:GetPlayers()) do
   local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if p~=player and p:GetAttribute("InRound") and not p:GetAttribute("VoidActive") and hum and hum.Health>0 then table.insert(targets,p) end
  end
  table.sort(targets,function(a,b) return a.UserId<b.UserId end)
  if #targets>0 then
   if watchedId then for i,p in ipairs(targets) do if p.UserId==watchedId then index=i break end end end
   index=((index-1)%#targets)+1 local p=targets[index] watchedId=p.UserId
   camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=p.Character:FindFirstChildOfClass("Humanoid") camera.FieldOfView=player:GetAttribute("CameraFOV") or 48
   spectatorName.Text=p.DisplayName watching=true
  else
   watchedId=nil
   spectate.Visible=false
   spectatorName.Text=""
   if not watching then camera.CameraType=Enum.CameraType.Scriptable end
   watching=true
  end
 elseif watching and not hidden and camera then watching=false watchedId=nil camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") camera.FieldOfView=player:GetAttribute("CameraFOV") or 48 end
 if camera and not spec and not hidden and not result.Visible and not loading.Visible then
  local ownHumanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if ownHumanoid and ownHumanoid.Health>0 then
   if camera.CameraSubject~=ownHumanoid then camera.CameraSubject=ownHumanoid end
   if camera.CameraType==Enum.CameraType.Scriptable then camera.CameraType=Enum.CameraType.Custom end
  end
 end
 highlight.Enabled=false
 if inRound and not hidden then
  for _,m in ipairs(workspace:GetChildren()) do if m:GetAttribute("ActivePursuer") and (m:GetAttribute("TargetUserId") or 0)>0 then
   local p=Players:GetPlayerByUserId(m:GetAttribute("TargetUserId")) highlight.Adornee=p and p.Character highlight.Enabled=p~=nil break
  end end
 end
 -- Downed poses are applied with locomotion in PreSimulation, after the Animator.

end)
-- Use only an input Roblox already created for this player. Never unmute or capture audio.
task.spawn(function()
 local analyzer,wire,input
 while gui.Parent do
  local current=player:FindFirstChildWhichIsA("AudioDeviceInput")
  if current~=input then
   if analyzer then analyzer:Destroy() end if wire then wire:Destroy() end input=current
   if input then analyzer=Instance.new("AudioAnalyzer") analyzer.SpectrumEnabled=false analyzer.Parent=gui wire=Instance.new("Wire") wire.SourceInstance=input wire.TargetInstance=analyzer wire.Parent=analyzer end
  end
  if input and analyzer and player:GetAttribute("InRound") and not input.Muted then
   local level=analyzer.RmsLevel if level>.015 then event:FireServer("voice",math.clamp(level,0,1)) end
  end
  task.wait(.35)
 end
end)



if player.GetAttributeChangedSignal then
 player:GetAttributeChangedSignal("VoidActive"):Connect(function()
  if player:GetAttribute("VoidActive") then loading.Visible=false goodLuck.Visible=false clearArenaLoadingAvatar() restoreLoadingCamera() end
 end)
end

local function squareHud(obj)
 if obj.Name=="ReferenceActionArt" or (obj.Parent and (obj.Parent.Name=="ReferenceActionArt" or obj.Parent:GetAttribute("ReferenceActionButton"))) then return end
 if obj:IsA("UICorner") then obj.CornerRadius=UDim.new(0,0)
 elseif obj:IsA("TextButton") then obj.BackgroundColor3=Color3.new(0,0,0)
 elseif obj:IsA("Frame") and (obj.Name=="SettingsOverlay" or obj.Name=="Mission" or obj.Name=="Card") then obj.BackgroundColor3=Color3.new(0,0,0) end
end
for _,obj in ipairs(gui:GetDescendants()) do squareHud(obj) end
gui.DescendantAdded:Connect(function(obj) task.defer(function() if obj.Parent then squareHud(obj) end end) end)


