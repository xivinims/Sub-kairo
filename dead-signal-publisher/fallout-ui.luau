local UI={ScoreWidth=334,ScoreHeight=32}
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local function round(parent,radius)make('UICorner',parent,{CornerRadius=UDim.new(0,radius)})end
local function text(parent,name,value,size,pos,fontSize)
 return make('TextLabel',parent,{Name=name,Text=value,Size=size,Position=pos,BackgroundTransparency=1,TextColor3=Color3.fromRGB(236,240,239),Font=Enum.Font.GothamMedium,TextSize=fontSize,TextWrapped=false})
end
function UI.integer(value)
 if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return 0 end
 return math.max(0,math.floor(value))
end
function UI.money(value)
 local result=tostring(UI.integer(value)):reverse():gsub('(%d%d%d)','%1.'):reverse()
 return (result:gsub('^%.',''))
end
function UI.coin(parent,size,pos)
 local coin=make('Frame',parent,{Name='CoinIcon',Size=UDim2.fromOffset(size,size),Position=pos,BackgroundColor3=Color3.fromRGB(226,185,91),BorderSizePixel=0});round(coin,size)
 local inner=make('Frame',coin,{Size=UDim2.new(1,-6,1,-6),Position=UDim2.fromOffset(3,3),BackgroundTransparency=1});round(inner,size)
 make('UIStroke',inner,{Color=Color3.fromRGB(127,89,32),Thickness=1.2,Transparency=.1})
 local center=text(coin,'Stamp','C',UDim2.fromScale(1,1),UDim2.new(),math.floor(size*.6));center.Font=Enum.Font.GothamBold;center.TextColor3=Color3.fromRGB(100,71,31)
 return coin
end
function UI.scoreboard(parent,colors)
 local screen=make('ScreenGui',parent,{Name='FalloutScoreboard',ResetOnSpawn=false,DisplayOrder=31,ScreenInsets=Enum.ScreenInsets.None,SafeAreaCompatibility=Enum.SafeAreaCompatibility.None})
 local safe=make('Frame',screen,{Name='SafeArea',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
 local root=make('Frame',safe,{Name='CompactScoreboard',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,2),Size=UDim2.fromOffset(UI.ScoreWidth,UI.ScoreHeight),BackgroundColor3=Color3.fromRGB(17,23,26),BackgroundTransparency=.15,BorderSizePixel=0});round(root,7)
 local scale=make('UIScale',root,{Scale=1})
 local score=text(root,'Score','0  —  0',UDim2.fromOffset(98,18),UDim2.fromOffset(118,0),17);score.Font=Enum.Font.GothamBold
 local clock=text(root,'Clock','AGUARDANDO',UDim2.fromOffset(144,12),UDim2.fromOffset(95,20),9)
 local slots={{},{}}
 for team=1,2 do for i=1,5 do
  local x=team==1 and 8+(i-1)*22 or 218+(i-1)*22
  local frame=make('Frame',root,{Name='Team'..team..'Slot'..i,Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(x,6),BackgroundColor3=colors[team],BackgroundTransparency=.78,BorderSizePixel=0});round(frame,4)
  local portrait=make('ImageLabel',frame,{Name='Avatar',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=''});round(portrait,4)
  local line=make('Frame',frame,{Name='Status',Size=UDim2.new(1,-8,0,2),Position=UDim2.new(0,4,1,-2),BackgroundColor3=colors[team],BorderSizePixel=0,Visible=false})
  slots[team][i]={portrait=portrait,status=line}
 end end
 return {screen=screen,safe=safe,root=root,scale=scale,score=score,clock=clock,slots=slots}
end
-- Narrow and flush with the top edge on landscape, below native buttons on portrait.
function UI.fitScoreboard(board,viewport,topbarRect)
 local available=viewport.X>0 and viewport.X or 820
 board.fallback=available<620
 board.screen.ScreenInsets=Enum.ScreenInsets.None
 board.root.AnchorPoint=Vector2.new(.5,0)
 board.root.Position=UDim2.new(.5,0,0,board.fallback and 54 or 2)
 board.scale.Scale=math.min(1,math.max(.6,(available-16)/UI.ScoreWidth))
end
function UI.wallet(parent)
 local root=make('Frame',parent,{Name='Wallet',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,6),Size=UDim2.fromOffset(100,34),BackgroundColor3=Color3.fromRGB(14,20,24),BackgroundTransparency=.12,BorderSizePixel=0})
 round(root,17)
 make('UIStroke',root,{Color=Color3.fromRGB(150,157,162),Thickness=1,Transparency=.78})
 UI.coin(root,22,UDim2.fromOffset(7,6))
 local balance=text(root,'Balance','…',UDim2.new(1,-37,1,0),UDim2.fromOffset(36,0),16)
 balance.TextXAlignment=Enum.TextXAlignment.Left
 balance.Font=Enum.Font.GothamBold
 local progress=text(root,'Progress','',UDim2.fromOffset(1,1),UDim2.new(),1)
 progress.Visible=false -- The pill contains only a coin and the balance.
 return {root=root,balance=balance,progress=progress}
end
function UI.matchHUD(parent)
 local root=make('Frame',parent,{Name='MatchHUD',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
 local function panel(name,size,pos,anchor,radius)
  local frame=make('Frame',root,{Name=name,AnchorPoint=anchor or Vector2.new(),Size=size,Position=pos,BackgroundColor3=Color3.fromRGB(18,23,27),BackgroundTransparency=.26,BorderSizePixel=0})
  round(frame,radius or 4)
  make('UIStroke',frame,{Color=Color3.fromRGB(207,215,214),Transparency=.83,Thickness=1})
  return frame
 end
 local healthPanel=panel('Health',UDim2.fromOffset(220,30),UDim2.new(.5,0,1,-22),Vector2.new(.5,1),3)
 local healthBg=make('Frame',healthPanel,{Name='MeterBackground',Size=UDim2.fromOffset(146,5),Position=UDim2.fromOffset(62,14),BackgroundColor3=Color3.fromRGB(69,78,79),BorderSizePixel=0})
 local healthFill=make('Frame',healthBg,{Name='Meter',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(190,214,205),BorderSizePixel=0})
 local hp=text(healthPanel,'HealthText','100',UDim2.fromOffset(48,30),UDim2.fromOffset(8,0),18);hp.Font=Enum.Font.GothamBold
 local ammoPanel=panel('Ammo',UDim2.fromOffset(172,70),UDim2.new(1,-16,1,-18),Vector2.new(1,1),3)
 local ammoBig=text(ammoPanel,'Magazine','030',UDim2.fromOffset(69,37),UDim2.fromOffset(9,10),30);ammoBig.Font=Enum.Font.GothamBold
 local ammoReserve=text(ammoPanel,'Reserve','/ 090',UDim2.fromOffset(60,16),UDim2.fromOffset(73,29),11)
 ammoReserve.TextColor3=Color3.fromRGB(165,177,182)
 local weaponName=text(ammoPanel,'Weapon','',UDim2.new(1,-16,0,12),UDim2.fromOffset(8,55),9)
 weaponName.TextXAlignment=Enum.TextXAlignment.Right;weaponName.TextTruncate=Enum.TextTruncate.AtEnd
 local radar=panel('Radar',UDim2.fromOffset(124,124),UDim2.new(0,14,1,-18),Vector2.new(0,1),1)
 for i=1,3 do
  make('Frame',radar,{Name='VerticalGrid'..i,Size=UDim2.new(0,1,1,-12),Position=UDim2.new(i/4,0,0,6),BackgroundColor3=Color3.fromRGB(111,131,140),BackgroundTransparency=.77,BorderSizePixel=0})
  make('Frame',radar,{Name='HorizontalGrid'..i,Size=UDim2.new(1,-12,0,1),Position=UDim2.new(0,6,i/4,0),BackgroundColor3=Color3.fromRGB(111,131,140),BackgroundTransparency=.77,BorderSizePixel=0})
 end
 local north=text(radar,'North','N',UDim2.fromOffset(15,14),UDim2.new(.5,-8,0,1),10);north.TextColor3=Color3.fromRGB(198,210,215)
 local localDot=make('Frame',radar,{Name='LocalPlayer',Size=UDim2.fromOffset(7,7),Position=UDim2.new(.5,-3,.5,-3),BackgroundColor3=Color3.fromRGB(235,239,236),BorderSizePixel=0})
 round(localDot,4)
 local dots={}
 for i=1,9 do
  local dot=make('Frame',radar,{Name='Teammate'..i,Size=UDim2.fromOffset(5,5),BackgroundColor3=Color3.fromRGB(77,172,228),BorderSizePixel=0,Visible=false})
  round(dot,3);dots[i]=dot
 end
 local reticle=make('Frame',root,{Name='Reticle',Size=UDim2.fromOffset(28,28),Position=UDim2.new(.5,-14,.5,-14),BackgroundTransparency=1})
 for _,segment in ipairs({
  {'Top',UDim2.fromOffset(2,7),UDim2.fromOffset(13,0)},
  {'Bottom',UDim2.fromOffset(2,7),UDim2.fromOffset(13,21)},
  {'Left',UDim2.fromOffset(7,2),UDim2.fromOffset(0,13)},
  {'Right',UDim2.fromOffset(7,2),UDim2.fromOffset(21,13)},
  {'Center',UDim2.fromOffset(2,2),UDim2.fromOffset(13,13)}
 }) do
  make('Frame',reticle,{Name=segment[1],Size=segment[2],Position=segment[3],BackgroundColor3=Color3.fromRGB(230,237,239),BackgroundTransparency=.12,BorderSizePixel=0})
 end
 local feed=panel('Eliminations',UDim2.fromOffset(240,30),UDim2.new(1,-16,0,64),Vector2.new(1,0),3)
 local feedLabel=text(feed,'FeedText','',UDim2.new(1,-12,1,0),UDim2.fromOffset(6,0),12)
 feedLabel.TextXAlignment=Enum.TextXAlignment.Right;feed.Visible=false
 return {root=root,healthFill=healthFill,hp=hp,ammoBig=ammoBig,ammoReserve=ammoReserve,weaponName=weaponName,radar=radar,dots=dots,feed=feed,feedLabel=feedLabel}
end
-- Code-drawn silhouettes stay visible even if a model's external mesh is unavailable.
function UI.itemIcon(parent,item)
 local root=make('Frame',parent,{Name='ItemIcon',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
 local color=Color3.fromRGB(208,217,214)
 local function shape(name,x,y,w,h,rotation,radius,shade)
  local p=make('Frame',root,{Name=name,Size=UDim2.fromScale(w,h),Position=UDim2.fromScale(x,y),Rotation=rotation or 0,BackgroundColor3=shade or color,BorderSizePixel=0});if radius then round(p,radius)end;return p
 end
 if item.kind=='Gun' then
  local long=item.id=='suppressed' or item.id=='longslide';local short=item.id=='subcompact'
  shape('Slide',.14,.30,long and .64 or short and .43 or .54,.15,0,3)
  shape('Frame',.20,.43,.38,.09,0,2)
  shape('Grip',.29,.49,.16,item.id=='machine' and .31 or .23,16,3,Color3.fromRGB(134,155,148))
  shape('Trigger',.47,.49,.12,.09,0,3)
  shape('TriggerCutout',.49,.49,.07,.05,0,1,Color3.fromRGB(28,36,34))
  shape('Sight',.18,.27,.045,.04,0,1)
  if item.id=='suppressed' then shape('Suppressor',.70,.30,.18,.16,0,4) end
  if item.id=='heavy' then shape('HeavyBarrel',.20,.27,.48,.05,0,1) end
  if item.id=='smart' then shape('Display',.27,.33,.18,.055,0,1,Color3.fromRGB(145,198,170)) end
 elseif item.id=='knife' then
  shape('Blade',.47,.16,.085,.43,35,2);shape('Guard',.34,.51,.22,.045,35,1)
  shape('Handle',.31,.58,.10,.25,35,3,Color3.fromRGB(134,155,148))
 elseif item.id=='axe' then
  shape('Handle',.48,.22,.065,.60,18,3,Color3.fromRGB(173,146,100));shape('Blade',.29,.22,.32,.20,18,5)
 elseif item.kind=='Grenade' then
  shape('Body',.34,.35,.32,.42,0,10,Color3.fromRGB(165,182,144));shape('Neck',.43,.24,.14,.15,0,2)
  shape('Lever',.54,.26,.055,.39,-12,2)
 elseif item.kind=='Mine' then
  shape('Base',.20,.48,.60,.18,0,12,Color3.fromRGB(165,182,144));shape('Top',.30,.37,.40,.17,0,8);shape('Fuse',.46,.28,.08,.13,0,2)
 elseif item.id=='medkit' then
  shape('Case',.22,.35,.56,.40,0,6,Color3.fromRGB(158,189,164));shape('Handle',.39,.25,.22,.10,0,3)
  shape('CrossVertical',.46,.41,.08,.26,0,1);shape('CrossHorizontal',.37,.50,.26,.08,0,1)
 else
  shape('Barrel',.43,.29,.13,.39,35,2);shape('Plunger',.56,.18,.065,.18,35,1)
  shape('Top',.53,.15,.18,.04,35,1);shape('Needle',.34,.63,.025,.21,35,0)
 end
 return root
end
function UI.preview(viewport,visual,item)
 local world=make('WorldModel',viewport,{Name='PreviewWorld'})
 local clone=visual:Clone();clone.Name='Item';clone.Anchored=true;clone.CanCollide=false;clone.CanQuery=false;clone.CanTouch=false;clone.LocalTransparencyModifier=0;clone.Transparency=0
 for _,child in ipairs(clone:GetChildren()) do if child:IsA('Attachment') then child:Destroy() end end
 -- Imported guns are long on local X. Keep the icon broadside instead of facing its muzzle.
 local rotation=item.id=='syringe' and CFrame.Angles(0,math.pi/2,math.rad(-25)) or item.kind=='Melee' and CFrame.Angles(0,0,math.rad(-24)) or CFrame.identity
 clone.CFrame=rotation;clone.Parent=world
 local camera=make('Camera',viewport,{Name='PreviewCamera',FieldOfView=32})
 local direction=Vector3.new(.10,.12,1).Unit
 local basis=CFrame.lookAt(Vector3.zero,-direction)
 local tan=math.tan(math.rad(camera.FieldOfView/2));local aspect=1.16
 local distance=0
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
  local point=clone.CFrame:PointToWorldSpace(Vector3.new(x*clone.Size.X/2,y*clone.Size.Y/2,z*clone.Size.Z/2))
  local localPoint=basis:PointToObjectSpace(point)
  distance=math.max(distance,localPoint.Z+math.abs(localPoint.X)/(tan*aspect),localPoint.Z+math.abs(localPoint.Y)/tan)
 end end end
 distance=math.max(.5,distance*1.14)
 camera.CFrame=CFrame.lookAt(direction*distance,Vector3.zero);viewport.CurrentCamera=camera
 viewport.Ambient=Color3.fromRGB(215,222,217);viewport.LightColor=Color3.fromRGB(255,246,224);viewport.LightDirection=Vector3.new(-1,-1,-2)
 viewport:SetAttribute('FitDistance',distance);viewport:SetAttribute('FitAspect',aspect)
 return clone
end
function UI.catalogPreview(parent,visual,item)
 local viewport=make('ViewportFrame',parent,{Name='ModelPreview',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=true})
 local clone=UI.preview(viewport,visual,item)
 viewport:SetAttribute('SourceItemId',item.id)
 return viewport,clone
end
return UI
