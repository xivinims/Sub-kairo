-- Dead Signal | original live 3D menu, aligned to the supplied 736 x 414 reference.
-- Native Roblox buttons, not a static screenshot. Touch targets grow without breaking desktop proportions.
local V={}
function V.Create(parent)
 local function make(class,props,p)
  local v=Instance.new(class)
  for k,value in pairs(props) do v[k]=value end
  v.Parent=p
  return v
 end
 local root=make("Frame",{Name="ReferenceMenu",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(28,2,4),BackgroundTransparency=.77,BorderSizePixel=0,Active=false},parent)
 local shade=make("Frame",{Name="LeftVignette",Size=UDim2.fromScale(.72,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Active=false},root)
 make("UIGradient",{Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.09),NumberSequenceKeypoint.new(.48,.27),
  NumberSequenceKeypoint.new(1,1)
 })},shade)
 local bottom=make("Frame",{Name="LowerVignette",Position=UDim2.fromScale(0,.7),Size=UDim2.fromScale(1,.3),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0},root)
 make("UIGradient",{Transparency=NumberSequence.new(1,.5),Rotation=90},bottom)
 local glow=make("Frame",{Name="ChapterBlueSoftGlow",Position=UDim2.fromScale(0,.091),Size=UDim2.new(.48,0,0,16),BackgroundColor3=Color3.fromRGB(77,136,221),BackgroundTransparency=.83,BorderSizePixel=0},root)
 make("UIGradient",{Transparency=NumberSequence.new(0,1)},glow)
 local bar=make("Frame",{Name="ChapterBlueLine",Position=UDim2.fromScale(0,.101),Size=UDim2.new(.40,0,0,3),BackgroundColor3=Color3.fromRGB(119,168,231),BackgroundTransparency=.25,BorderSizePixel=0},root)
 make("UIGradient",{Transparency=NumberSequence.new(0,1)},bar)
 local function label(name,value,pos,size,font,sz)
  return make("TextLabel",{
   Name=name,Text=value,Position=pos,Size=size,Font=font,TextSize=sz,
   TextColor3=Color3.fromRGB(244,243,243),TextXAlignment=Enum.TextXAlignment.Left,
   TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1,TextWrapped=false,
   TextStrokeTransparency=1
  },root)
 end
 local chapter=label("Chapter","CHAPTER 1",UDim2.fromScale(.041,.098),UDim2.fromScale(.42,.065),Enum.Font.Code,16)
 local title=label("Title","'THE ATRIUM'",UDim2.fromScale(.041,.157),UDim2.fromScale(.60,.10),Enum.Font.Code,31)
 local divider=make("Frame",{Name="Divider",Position=UDim2.fromScale(0,.258),Size=UDim2.new(.442,0,0,1),BackgroundColor3=Color3.fromRGB(241,235,235),BackgroundTransparency=.35,BorderSizePixel=0},root)
 local desc=label("Description","Light still reaches the garden.\nBeyond the empty galleries,\nsomething remains unfinished.",UDim2.fromScale(.043,.307),UDim2.fromScale(.38,.19),Enum.Font.Code,13)
 desc.TextWrapped=true
 local buttons={}
 for i,name in ipairs({"CONTINUE","NEW GAME","SETTINGS","CREDITS","QUIT"}) do
  local b=make("TextButton",{
   Name=name,Text=name,Font=Enum.Font.Code,TextSize=14,
   TextColor3=Color3.fromRGB(248,247,247),TextXAlignment=Enum.TextXAlignment.Left,
   BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.28,
   BorderSizePixel=0,AutoButtonColor=false,SelectionOrder=i,ZIndex=15,
   Size=UDim2.fromOffset(170,28),Position=UDim2.new(.048,0,.57+(i-1)*.065,0),Visible=true
  },root)
  make("UIPadding",{PaddingLeft=UDim.new(0,9)},b)
  make("UIStroke",{Name="ThinWhiteOutline",Color=Color3.fromRGB(226,223,223),Thickness=1,Transparency=.26,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
  buttons[i]=b
 end
 local scan=make("Frame",{Name="Scanlines",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,ZIndex=8},root)
 for i=0,103 do
  make("Frame",{Position=UDim2.fromScale(0,i/104),Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.9,BorderSizePixel=0,Active=false},scan)
 end
 local function resize(w,h,touch)
  w=math.max(w,320);h=math.max(h,240)
  local unit=math.clamp(math.min(h/414,w/736),.82,1.6)
  local bh=touch and 44 or math.max(23,22*unit)
  local gap=touch and 3 or 3*unit
  local compact=touch or h<460
  local top
  if compact then
   -- Five touch-sized buttons fit below the title, not underneath it.
   local free=h-92-5*bh-4*gap
   if free<0 then
    bh=math.max(34,math.floor((h-102-4*gap)/5))
   end
   top=math.max(92,h-5*bh-4*gap-10)
  else
   top=h*.611
  end
  local width=math.clamp(w*.225,166,335)
  for index,b in ipairs(buttons) do
   b.Size=UDim2.fromOffset(math.min(width,w-32),bh)
   b.Position=UDim2.fromOffset(math.floor(w*.048),math.floor(top+(index-1)*(bh+gap)))
   b.TextSize=compact and 14 or 14*unit
   b.Visible=true
  end
  chapter.TextSize=compact and 14 or 16*unit
  title.TextSize=compact and 26 or 31*unit
  desc.TextSize=compact and 12 or 13*unit
  desc.Visible=not compact and top>h*.48
  divider.Visible=not compact and top>h*.3
  glow.Visible=true
 end
 -- Bootstrap layout IMMEDIATELY: if optional client effects fail later, the
 -- UI is not left with zero-sized invisible buttons.
 local initialCamera=workspace.CurrentCamera
 local initial=initialCamera and initialCamera.ViewportSize or Vector2.new(736,414)
 resize(initial.X,initial.Y,game:GetService("UserInputService").TouchEnabled)

 return {Root=root,Buttons=buttons,Scanlines=scan,Resize=resize,Chapter=chapter,Title=title,Description=desc}
end
return V
