local UI={ScoreWidth=286,ScoreHeight=28}
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
 local screen=make('ScreenGui',parent,{Name='FalloutScoreboard',ResetOnSpawn=false,DisplayOrder=31,ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets,SafeAreaCompatibility=Enum.SafeAreaCompatibility.None})
 local safe=make('Frame',screen,{Name='SafeArea',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
 local root=make('Frame',safe,{Name='CompactScoreboard',AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,0),Size=UDim2.fromOffset(UI.ScoreWidth,UI.ScoreHeight),BackgroundColor3=Color3.fromRGB(17,23,26),BackgroundTransparency=.15,BorderSizePixel=0});round(root,6)
 local scale=make('UIScale',root,{Scale=1})
 local score=text(root,'Score','0  —  0',UDim2.fromOffset(80,17),UDim2.fromOffset(103,0),15);score.Font=Enum.Font.GothamBold
 local clock=text(root,'Clock','AGUARDANDO',UDim2.fromOffset(80,10),UDim2.fromOffset(103,17),8);clock.TextTruncate=Enum.TextTruncate.AtEnd
 local slots={{},{}}
 for team=1,2 do for i=1,5 do
  local x=team==1 and 5+(i-1)*20 or 183+(i-1)*20
  local frame=make('Frame',root,{Name='Team'..team..'Slot'..i,Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(x,5),BackgroundColor3=colors[team],BackgroundTransparency=.78,BorderSizePixel=0});round(frame,4)
  local portrait=make('ImageLabel',frame,{Name='Avatar',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=''});round(portrait,6)
  local line=make('Frame',frame,{Name='Status',Size=UDim2.new(1,-8,0,2),Position=UDim2.new(0,4,1,-2),BackgroundColor3=colors[team],BorderSizePixel=0,Visible=false})
  slots[team][i]={portrait=portrait,status=line}
 end end
 return {screen=screen,safe=safe,root=root,scale=scale,score=score,clock=clock,slots=slots}
end
function UI.fitScoreboard(board,viewport,topbarRect,deviceRect)
 -- Both rectangles come from GetInsetArea, so their coordinate origins agree.
 deviceRect=deviceRect or Rect.new(0,0,viewport.X,viewport.Y)
 local safeWidth=math.max(1,deviceRect.Width)
 local scale=math.min(viewport.Y<500 and .92 or 1,math.max(.1,(safeWidth-16)/UI.ScoreWidth))
 local width=UI.ScoreWidth*scale
 local left=math.max(0,topbarRect.Min.X-deviceRect.Min.X)+4
 local right=math.min(safeWidth,topbarRect.Max.X-deviceRect.Min.X)-4
 local centered=safeWidth/2
 local top=0
 board.fallback=right-left<width or topbarRect.Height<UI.ScoreHeight*scale
 if board.fallback then
  top=math.max(0,topbarRect.Max.Y-deviceRect.Min.Y)
 else
  -- Center on the screen; only move sideways when a Roblox control would overlap.
  centered=math.clamp(centered,left+width/2,right-width/2)
 end
 board.root.Position=UDim2.fromOffset(centered,top)
 board.scale.Scale=scale
end
function UI.wallet(parent)
 local root=make('Frame',parent,{Name='Wallet',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,6),Size=UDim2.fromOffset(64,26),BackgroundColor3=Color3.fromRGB(18,24,26),BackgroundTransparency=.14,BorderSizePixel=0})
 make('UICorner',root,{CornerRadius=UDim.new(1,0)})
 UI.coin(root,18,UDim2.fromOffset(5,4))
 local balance=text(root,'Balance','…',UDim2.new(1,-36,1,0),UDim2.fromOffset(28,0),14);balance.TextXAlignment=Enum.TextXAlignment.Right;balance.Font=Enum.Font.GothamBold
 return {root=root,balance=balance}
end
function UI.setBalance(wallet,value)
 wallet.balance.Text=value
 local bounds=game:GetService('TextService'):GetTextSize(value,14,Enum.Font.GothamBold,Vector2.new(200,26))
 wallet.root.Size=UDim2.fromOffset(math.clamp(math.ceil(bounds.X)+38,64,168),26)
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

