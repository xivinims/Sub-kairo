local Players=game:GetService('Players');local Run=game:GetService('RunService');local CAS=game:GetService('ContextActionService');local UIS=game:GetService('UserInputService');local Collection=game:GetService('CollectionService')
local player=Players.LocalPlayer;local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local hud=require(package:WaitForChild('HudControls'));local Layout=require(package:WaitForChild('HudLayout'))
local emotes=require(package.EmoteCatalog);local byId={};for _,e in ipairs(emotes)do byId[e.id]=e end
local function new(class,parent,props)local v=Instance.new(class);for k,val in pairs(props or {})do v[k]=val end;v.Parent=parent;return v end
local gui=new('ScreenGui',player:WaitForChild('PlayerGui'),{Name='MatchHUD',ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=10,Enabled=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local canvas=new('Frame',gui,{Size=UDim2.fromOffset(1536,709),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1})
local scale=new('UIScale',canvas)
local layout
local function fitBase()local size=Layout.Compute(gui.AbsoluteSize.X,gui.AbsoluteSize.Y).size;scale.Scale=size/95;canvas.Size=UDim2.fromOffset(gui.AbsoluteSize.X/scale.Scale,gui.AbsoluteSize.Y/scale.Scale)end
fitBase()
local function text(parent,value,x,y,w,h,size)
 return new('TextLabel',parent,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Font=Enum.Font.GothamBold,TextSize=size or 22,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=.2,BackgroundTransparency=1})
end
local function circle(value,x,y,w,callback)
 local b=new('TextButton',canvas,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,w),Font=Enum.Font.GothamBold,TextSize=19,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(24,24,27),BackgroundTransparency=.5,AutoButtonColor=true})
 new('UICorner',b,{CornerRadius=UDim.new(1,0)});new('UIStroke',b,{Thickness=4,Color=Color3.fromRGB(160,160,160),Transparency=.25})
 local ring=new('Frame',b,{BackgroundTransparency=1,Position=UDim2.fromOffset(7,7),Size=UDim2.new(1,-14,1,-14)});new('UICorner',ring,{CornerRadius=UDim.new(1,0)});new('UIStroke',ring,{Thickness=2,Color=Color3.fromRGB(190,190,190),Transparency=.4})
 b.Activated:Connect(callback);return b
end
local sprint,crouch=false,false
local function setSprint(on)sprint=on;package.Movement:FireServer('Sprint',on)end
local function setCrouch(on)crouch=on;package.Movement:FireServer('Crouch',on)end
local menuButton=hud.Circle(canvas,'Menu',function()package.MatchAction:FireServer('Lobby')end)
local povButton=hud.Circle(canvas,'POV',function()player:SetAttribute('NBFirstPerson',not player:GetAttribute('NBFirstPerson'))end)
local crouchButton=hud.Circle(canvas,'Crouch',function()setCrouch(not crouch)end)
local sprintButton=circle('CORRER',1280,414,90,function()setSprint(not sprint)end)
local drop=circle('SOLTAR',1250,272,88,function()package.Rescue:FireServer('Drop')end)
local wheel=require(package:WaitForChild('EmoteWheel')).new(gui,player,package)
local function showWheel()if gui.Enabled then wheel:Toggle()end end
local emoteButton=hud.Circle(canvas,'Emote',showWheel)
local inventory=new('Frame',canvas,{ZIndex=40,Visible=false,Position=UDim2.fromOffset(1010,140),Size=UDim2.fromOffset(340,340),BackgroundColor3=Color3.fromRGB(24,25,30),BackgroundTransparency=.1})
new('UICorner',inventory,{CornerRadius=UDim.new(0,12)});local invText=text(inventory,'',14,10,312,140,18);invText.TextWrapped=true;invText.TextTruncate=Enum.TextTruncate.AtEnd
for i=1,4 do local use=new('TextButton',inventory,{Position=UDim2.fromOffset(12+(i-1)%2*162,165+math.floor((i-1)/2)*78),Size=UDim2.fromOffset(152,68),BackgroundColor3=Color3.fromRGB(60,70,87),TextColor3=Color3.new(1,1,1),Name='Usable'..i,Text='VAZIO',TextSize=17,Font=Enum.Font.GothamBold});new('UICorner',use,{CornerRadius=UDim.new(0,8)});use.Activated:Connect(function()local id=player:GetAttribute('NBUsable'..i);if id and id~=''then package.Equipment:FireServer('Use',id)end end)end
local bagButton=hud.Circle(canvas,'Bag',function()
 inventory.Visible=not inventory.Visible
 player:SetAttribute('NBOverlay',inventory.Visible and 'Inventory'or '')
 local equipped={};for i=1,4 do equipped[i]=player:GetAttribute('NBUsable'..i)end
 local lines={'EQUIPAMENTO'};local shown={};for _,key in ipairs({'NBLightID','NBPowerID','NBUtility'})do local id=player:GetAttribute(key);if id and not shown[id]then for _,item in ipairs(require(package.Config).Catalog)do if item.id==id then table.insert(lines,item.name);shown[id]=true end end end end
 invText.Text=table.concat(lines,'\n');for i=1,4 do local b=inventory:FindFirstChild('Usable'..i);local found;for _,item in ipairs(require(package.Config).Catalog)do if item.id==equipped[i]then found=item end end;b.Text=found and found.name or 'VAZIO';b.Active=found~=nil;b.BackgroundTransparency=found and 0 or .65 end
end)
local healthPanel=new('Frame',canvas,{Position=UDim2.fromOffset(128,592),Size=UDim2.fromOffset(192,72),BackgroundColor3=Color3.fromRGB(24,28,22),BackgroundTransparency=.45});new('UICorner',healthPanel,{CornerRadius=UDim.new(0,7)});new('UIStroke',healthPanel,{Color=Color3.fromRGB(110,159,78),Thickness=3})
new('ImageLabel',healthPanel,{Name='HealthIcon',Image='rbxassetid://18788900977',BackgroundTransparency=1,Position=UDim2.fromOffset(12,18),Size=UDim2.fromOffset(45,42)})
local health=text(healthPanel,'100',70,0,118,72,34);health.TextColor3=Color3.fromRGB(100,226,64)
new('ImageLabel',canvas,{Name='SpeedIcon',Image='rbxassetid://13492318225',BackgroundTransparency=1,Position=UDim2.fromOffset(339,598),Size=UDim2.fromOffset(36,36)})
local cash=text(canvas,'',380,590,90,52,26);cash.TextColor3=Color3.fromRGB(244,185,77);cash.TextXAlignment=Enum.TextXAlignment.Left
local phase=text(canvas,'',458,45,620,36,23)
local mapLabel=text(canvas,'',458,78,620,26,16)
local notice=text(canvas,'',408,112,720,46,18);notice.TextWrapped=true
for _,entry in ipairs({{phase,15},{mapLabel,12},{notice,12}})do entry[1].TextScaled=true;new('UITextSizeConstraint',entry[1],{MinTextSize=10,MaxTextSize=entry[2]})end
local dot=text(canvas,'·',758,340,20,20,28)
local spectate=text(canvas,'',458,575,620,40,24)
local previous=circle('‹',530,622,60,function()
 local candidates={};for _,p in ipairs(Players:GetPlayers())do if p~=player and p:GetAttribute('NBInRound')then table.insert(candidates,p)end end
 local current=player:GetAttribute('NBSpectateTarget');local index=1;for i,p in ipairs(candidates)do if p.UserId==current then index=i end end
 if #candidates>0 then player:SetAttribute('NBSpectateTarget',candidates[(index-2)%#candidates+1].UserId)end
end)
local nextButton=circle('›',946,622,60,function()
 local candidates={};for _,p in ipairs(Players:GetPlayers())do if p~=player and p:GetAttribute('NBInRound')then table.insert(candidates,p)end end
 local current=player:GetAttribute('NBSpectateTarget');local index=0;for i,p in ipairs(candidates)do if p.UserId==current then index=i end end
 if #candidates>0 then player:SetAttribute('NBSpectateTarget',candidates[index%#candidates+1].UserId)end
end)
local stopWatch=circle('SAIR',738,622,60,function()package.MatchAction:FireServer('Spectate')end)
local danger=new('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=0})
local edges={}
for i=1,4 do
 local edge=new('Frame',danger,{BackgroundColor3=Color3.fromRGB(160,12,20),BorderSizePixel=0,Size=i<=2 and UDim2.new(.15,0,1,0)or UDim2.new(1,0,.18,0),Position=i==2 and UDim2.fromScale(.85,0)or i==4 and UDim2.fromScale(0,.82)or UDim2.new(),BackgroundTransparency=1})
 new('UIGradient',edge,{Rotation=({0,180,90,270})[i],Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})});edges[i]=edge
end
CAS:BindAction('NBSprint',function(_,state)if UIS:GetFocusedTextBox()or not gui.Enabled then return Enum.ContextActionResult.Pass end;if state==Enum.UserInputState.Begin then setSprint(true)elseif state==Enum.UserInputState.End then setSprint(false)end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3)
CAS:BindAction('NBCrouch',function(_,state)if UIS:GetFocusedTextBox()or not gui.Enabled then return Enum.ContextActionResult.Pass end;if state==Enum.UserInputState.Begin then setCrouch(not crouch)end;return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.C,Enum.KeyCode.LeftControl,Enum.KeyCode.ButtonB)
CAS:BindAction('NBEmoteWheel',function(_,state)if UIS:GetFocusedTextBox()or not gui.Enabled then return Enum.ContextActionResult.Pass end;if state==Enum.UserInputState.Begin then showWheel()end;return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.G,Enum.KeyCode.DPadDown)
CAS:BindAction('NBDrop',function(_,state)if UIS:GetFocusedTextBox()or not gui.Enabled then return Enum.ContextActionResult.Pass end;if state==Enum.UserInputState.Begin then package.Rescue:FireServer('Drop')end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.Q)
local tags={}
local function tag(p)
 local function attach(c)
  local head=c:WaitForChild('Head',10);local h=c:WaitForChild('Humanoid',10);if not head or not h then return end
  h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
  local old=tags[p];if old then old:Destroy()end
  local b=new('BillboardGui',head,{Name='NBNameTag',Size=UDim2.fromOffset(240,65),StudsOffset=Vector3.new(0,2,0),AlwaysOnTop=true,MaxDistance=120})
  local l=text(b,p.DisplayName,0,0,240,65,17);tags[p]=b
  local function refresh()l.Text=p.DisplayName..'\n'..(p:GetAttribute('NBDowned')and '✚ PRECISA DE AJUDA'or 'NÍVEL '..tostring(p:GetAttribute('NBLevel')or 1));l.TextColor3=p:GetAttribute('NBDowned')and Color3.fromRGB(255,93,104)or Color3.fromRGB(220,226,255);b.Enabled=p~=player and p:GetAttribute('NBInArena')==true end
  refresh();for _,key in ipairs({'NBDowned','NBLevel','NBInArena'})do p:GetAttributeChangedSignal(key):Connect(function()if b.Parent then refresh()end end)end
 end
 p.CharacterAdded:Connect(attach);if p.Character then task.spawn(attach,p.Character)end
end
Players.PlayerAdded:Connect(tag);Players.PlayerRemoving:Connect(function(p)if tags[p]then tags[p]:Destroy();tags[p]=nil end end);for _,p in ipairs(Players:GetPlayers())do tag(p)end

player:GetAttributeChangedSignal('NBOverlay'):Connect(function()
 local overlay=player:GetAttribute('NBOverlay');if overlay~='Inventory'then inventory.Visible=false end;
end)
local jumpOriginal;local jumpButton
local function placeJump()
 local touch=player.PlayerGui:FindFirstChild('TouchGui');local controls=touch and touch:FindFirstChild('TouchControlFrame')
 local jump=controls and controls:FindFirstChild('JumpButton')
 if not jump then return end
 if jumpButton~=jump then jumpButton=jump;jumpOriginal={Size=jump.Size,Position=jump.Position,AnchorPoint=jump.AnchorPoint}end
 if gui.Enabled then
  local origin=jump.Parent.AbsolutePosition
  local point=canvas.AbsolutePosition+Vector2.new(layout.Jump[1],layout.Jump[2])-origin
  jump.AnchorPoint=Vector2.zero;jump.Size=UDim2.fromOffset(layout.size,layout.size);jump.Position=UDim2.fromOffset(point.X,point.Y)
 elseif jumpOriginal then jump.Size=jumpOriginal.Size;jump.Position=jumpOriginal.Position;jump.AnchorPoint=jumpOriginal.AnchorPoint end
end

local function place(object,r)
 object.Position=UDim2.fromOffset(r[1]/scale.Scale,r[2]/scale.Scale);object.Size=UDim2.fromOffset(r[3]/scale.Scale,r[4]/scale.Scale)
end
local function fit()
 fitBase();layout=Layout.Compute(gui.AbsoluteSize.X,gui.AbsoluteSize.Y)
 for kind,button in pairs({Menu=menuButton,POV=povButton,Bag=bagButton,Emote=emoteButton,Sprint=sprintButton,Crouch=crouchButton,Drop=drop})do place(button,layout[kind])end
 place(healthPanel,layout.Health);place(cash,layout.Speed)
 health.Size=UDim2.new(1,-58,1,0);health.Position=UDim2.fromOffset(54,0);health.TextSize=24/scale.Scale
 local hi=healthPanel:FindFirstChild('HealthIcon');hi.Size=UDim2.fromOffset(28/scale.Scale,26/scale.Scale);hi.Position=UDim2.fromOffset(8/scale.Scale,10/scale.Scale)
 cash.TextSize=16/scale.Scale;cash.TextXAlignment=Enum.TextXAlignment.Center
 local si=canvas:FindFirstChild('SpeedIcon');si.Visible=false
 local r=layout.Header
 place(phase,{r[1],r[2],r[3],24});phase.TextSize=15/scale.Scale
 place(mapLabel,{r[1],r[2]+26,r[3],18});mapLabel.TextSize=12/scale.Scale
 place(notice,{r[1],r[2]+46,r[3],36});notice.TextSize=12/scale.Scale
 place(dot,{gui.AbsoluteSize.X/2-8,gui.AbsoluteSize.Y/2-8,16,16})
 local iw=math.min(360,gui.AbsoluteSize.X-24);local ih=math.min(340,gui.AbsoluteSize.Y-24)
 place(inventory,{(gui.AbsoluteSize.X-iw)/2,(gui.AbsoluteSize.Y-ih)/2,iw,ih})
 invText.Position=UDim2.fromOffset(12/scale.Scale,12/scale.Scale);invText.Size=UDim2.new(1,-24/scale.Scale,0,math.min(ih*.44,130)/scale.Scale);invText.TextSize=14/scale.Scale
 local i=0;for _,child in ipairs(inventory:GetChildren())do if child:IsA('TextButton')then i+=1;local bw=(iw-36)/2;local bh=math.min(56,(ih-150)/2);child.Position=UDim2.fromOffset((12+(i-1)%2*(bw+12))/scale.Scale,(ih-2*bh-24+math.floor((i-1)/2)*(bh+8))/scale.Scale);child.Size=UDim2.fromOffset(bw/scale.Scale,bh/scale.Scale);child.TextSize=12/scale.Scale end end
 place(spectate,{gui.AbsoluteSize.X*.24,gui.AbsoluteSize.Y-120,gui.AbsoluteSize.X*.52,36});spectate.TextSize=14/scale.Scale
 for i,b in ipairs({previous,stopWatch,nextButton})do place(b,{gui.AbsoluteSize.X/2-94+(i-1)*68,gui.AbsoluteSize.Y-64,52,48});b.TextSize=16/scale.Scale end
end
fit();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
local function resetToggles()sprint=false;crouch=false;wheel:Close();inventory.Visible=false end
player.CharacterAdded:Connect(resetToggles)
player:GetAttributeChangedSignal('NBInArena'):Connect(function()if not player:GetAttribute('NBInArena')then resetToggles()end end)
local elapsed=0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local active=player:GetAttribute('NBInArena');local watching=player:GetAttribute('NBSpectating');local enabled=player.PlayerGui:GetAttribute('NBLoadComplete')==true and package:GetAttribute('VotingOpen')~=true and (active==true or watching==true);if gui.Enabled and not enabled then wheel:Close();inventory.Visible=false end;gui.Enabled=enabled;placeJump()
 previous.Visible=watching==true;nextButton.Visible=watching==true;stopWatch.Visible=watching==true;spectate.Visible=watching==true
 if watching then local target=Players:GetPlayerByUserId(player:GetAttribute('NBSpectateTarget')or 0);spectate.Text=target and 'ASSISTINDO '..target.DisplayName or 'ASSISTINDO A RODADA'end
 local overlay=player:GetAttribute('NBOverlay')or '';local clear=overlay==''
 for _,b in ipairs({menuButton,povButton,emoteButton,bagButton,crouchButton,sprintButton})do b.Visible=active==true and clear end
 bagButton.Visible=active==true and (clear or overlay=='Inventory');emoteButton.Visible=active==true and (clear or overlay=='Emotes')
 healthPanel.Visible=active==true and clear;cash.Visible=active==true and clear;phase.Visible=clear;mapLabel.Visible=clear;notice.Visible=clear;dot.Visible=active==true and clear and (player:GetAttribute('NBPlayingEmote')or '')==''
 drop.Visible=active==true and clear and (player:GetAttribute('NBCarrying')or 0)>0
 local char=player.Character;local h=char and char:FindFirstChildOfClass('Humanoid');local root=char and char:FindFirstChild('HumanoidRootPart')
 health.Text=tostring(math.ceil(h and h.Health or 0));cash.Text=tostring(math.floor(root and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude or 0))
 local remaining=math.max(0,math.ceil((package:GetAttribute('Deadline')or 0)-workspace:GetServerTimeNow()))
 phase.Text=string.format('%s   %d:%02d',package:GetAttribute('Phase')=='Round'and 'SOBREVIVA'or 'INTERVALO',math.floor(remaining/60),remaining%60)
 mapLabel.Text=(package:GetAttribute('MapName')or '')..'   •   RODADA '..tostring(package:GetAttribute('Round')or 0)
 crouchButton.BackgroundTransparency=player:GetAttribute('NBMobility')=='Crouch'and .1 or .5;sprintButton.BackgroundTransparency=player:GetAttribute('NBMobility')=='Sprint'and .1 or .5
 if player:GetAttribute('NBDowned')then
  local t=math.max(0,math.ceil((player:GetAttribute('NBDownUntil')or 0)-workspace:GetServerTimeNow()));local progress=player:GetAttribute('NBReviveProgress')or 0
  notice.Text=progress>0 and 'REANIMANDO '..math.floor(progress*100)..'%'or 'VOCÊ CAIU • '..t..'s • AGUARDE AJUDA'
 else notice.Text=package:GetAttribute('ModeNotice')or (package:GetAttribute('Phase')=='Intermission'and 'Explore o mapa. A perseguição começa em breve.'or '')end
 local nearest=math.huge
 if root then for _,bot in ipairs(Collection:GetTagged('NBNextbot'))do local br=bot:FindFirstChild('HumanoidRootPart');if br then nearest=math.min(nearest,(br.Position-root.Position).Magnitude)end end end
 local opacity=active and player:GetAttribute('NBSetting_NextbotVignette')~=false and math.clamp(1-nearest/70,0,.75)or 0
 for _,edge in ipairs(edges)do edge.BackgroundTransparency=1-opacity end
end)
