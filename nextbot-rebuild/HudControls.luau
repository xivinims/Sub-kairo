-- Native GUI layout measured from the supplied 1624 x 750 mobile reference.
-- Icons are interface drawings; this module is not Evade's source code.
local M={}
M.Layout={Menu={92,227,95},POV={92,329,95},Crouch={1140,591,117},Bag={1252,106,121},Emote={1312,234,95},Jump={1274,541,130},Power={655,557,102},Light={783,557,102}}
local ink=Color3.fromRGB(214,212,208)
local function new(class,parent,props)local v=Instance.new(class);for k,value in pairs(props)do v[k]=value end;v.Parent=parent;return v end
local function block(parent,x,y,w,h,radius,rotation)
 local v=new('Frame',parent,{Position=UDim2.fromScale(x/100,y/100),Size=UDim2.fromScale(w/100,h/100),BorderSizePixel=0,BackgroundColor3=ink,BackgroundTransparency=.15,Rotation=rotation or 0})
 if radius then new('UICorner',v,{CornerRadius=UDim.new(radius,0)})end;return v
end
local function outline(parent,x,y,w,h,radius)
 local v=block(parent,x,y,w,h,radius);v.BackgroundTransparency=1;new('UIStroke',v,{Thickness=3,Color=ink,Transparency=.15});return v
end
function M.Icon(parent,kind)
 local icon=new('Frame',parent,{Name='Icon',Position=UDim2.fromScale(.17,.17),Size=UDim2.fromScale(.66,.66),BackgroundTransparency=1})
 if kind=='Bag'then
  outline(icon,32,12,27,28,.45);outline(icon,24,28,49,58,.22);outline(icon,29,53,38,30,.2);outline(icon,71,32,14,50,.35)
 elseif kind=='Crouch'then
  block(icon,42,13,27,27,1);block(icon,34,38,34,37,.12,-8);block(icon,16,55,20,33,.12,19);block(icon,57,64,25,28,.08);block(icon,36,74,28,16,.12)
 elseif kind=='POV'then
  block(icon,15,21,49,39,.18);block(icon,66,27,22,27,.03)
  new('TextLabel',icon,{Text='POV',BackgroundTransparency=1,Position=UDim2.fromScale(0,.65),Size=UDim2.fromScale(1,.3),Font=Enum.Font.GothamBold,TextSize=21,TextColor3=ink})
 elseif kind=='Emote'then
  local face=block(icon,23,23,54,54,1)
  for _,x in ipairs({34,61})do local eye=block(face,x,34,5,7,1);eye.BackgroundColor3=Color3.fromRGB(60,60,60)end
  local smile=outline(face,34,48,32,22,.5);smile.ClipsDescendants=false;smile:FindFirstChildOfClass('UIStroke').Color=Color3.fromRGB(60,60,60);smile:FindFirstChildOfClass('UIStroke').Thickness=1
 elseif kind=='Light'then
  local shaft=block(icon,20,45,60,17,.2,26);block(icon,12,32,20,28,.25,26);block(icon,77,58,10,16,.2,26)
 elseif kind=='Power'then
  block(icon,45,11,12,80,.3,35);block(icon,25,59,11,25,.25,35)
 end
 return icon
end
function M.Circle(parent,kind,callback)
 local d=assert(M.Layout[kind],'Unknown control '..kind)
 local b=new('TextButton',parent,{Name=kind,Text=kind=='Menu'and 'MENU'or '',Position=UDim2.fromOffset(d[1],d[2]),Size=UDim2.fromOffset(d[3],d[3]),Font=Enum.Font.GothamBold,TextSize=19,TextColor3=ink,BackgroundColor3=Color3.fromRGB(32,32,32),BackgroundTransparency=.52,AutoButtonColor=true})
 new('UICorner',b,{CornerRadius=UDim.new(1,0)});new('UIStroke',b,{Thickness=4,Color=Color3.fromRGB(110,109,106),Transparency=.15})
 local ring=new('Frame',b,{BackgroundTransparency=1,Position=UDim2.fromOffset(6,6),Size=UDim2.new(1,-12,1,-12)});new('UICorner',ring,{CornerRadius=UDim.new(1,0)});new('UIStroke',ring,{Thickness=2,Color=ink,Transparency=.2})
 if kind=='Jump'then
  b.Text='';new('ImageLabel',b,{Name='JumpIcon',BackgroundTransparency=1,Image='rbxasset://textures/ui/TouchControlsSheet.png',ImageRectOffset=Vector2.new(1,146),ImageRectSize=Vector2.new(144,144),Size=UDim2.fromScale(1,1)})
 else M.Icon(b,kind)end
 if callback then b.Activated:Connect(callback)end;return b
end
return M
