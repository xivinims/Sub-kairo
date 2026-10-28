-- Native, inspectable GUI factory. Reference proportions are 736 x 414.
local V={}
function V.Create(parent)
 local function make(class,props,p) local v=Instance.new(class);for k,value in pairs(props) do v[k]=value end;v.Parent=p;return v end
 local root=make("Frame",{Name="ReferenceMenu",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(35,3,4),BackgroundTransparency=.5,BorderSizePixel=0},parent)
 local shade=make("Frame",{Name="LeftVignette",Size=UDim2.fromScale(.65,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0},root)
 make("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.6,.3),NumberSequenceKeypoint.new(1,1)})},shade)
 local bar=make("Frame",{Name="ChapterGlow",Position=UDim2.fromScale(0,.095),Size=UDim2.new(.44,0,0,5),BackgroundColor3=Color3.fromRGB(137,192,255),BackgroundTransparency=.3,BorderSizePixel=0},root)
 make("UIGradient",{Transparency=NumberSequence.new(0,1)},bar)
 local function text(name,value,pos,size,fontSize)
  return make("TextLabel",{Name=name,Text=value,Position=pos,Size=size,Font=Enum.Font.Michroma,TextSize=fontSize,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1},root)
 end
 local chapter=text("Chapter","CHAPTER 1",UDim2.fromScale(.042,.09),UDim2.fromScale(.4,.06),14)
 local title=text("Title","'THE ATRIUM'",UDim2.fromScale(.042,.15),UDim2.fromScale(.5,.1),28)
 make("Frame",{Name="Divider",Position=UDim2.fromScale(0,.255),Size=UDim2.new(.442,0,0,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.45,BorderSizePixel=0},root)
 local desc=text("Description","Light still reaches the garden.\nBeyond the empty galleries,\nsomething remains unfinished.",UDim2.fromScale(.043,.304),UDim2.fromScale(.37,.14),11);desc.TextWrapped=true
 local buttons={}
 for i,name in ipairs({"CONTINUE","NEW GAME","SETTINGS","CREDITS","QUIT"}) do
  local b=make("TextButton",{Name=name,Text=name,Font=Enum.Font.Michroma,TextSize=13,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.55,BorderSizePixel=0,AutoButtonColor=false,SelectionOrder=i},root)
  make("UIPadding",{PaddingLeft=UDim.new(0,8)},b)
  make("UIStroke",{Color=Color3.new(1,1,1),Thickness=1,Transparency=.35,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
  buttons[i]=b
 end
 local scan=make("Frame",{Name="Scanlines",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,ZIndex=4},root)
 for i=0,103 do make("Frame",{Position=UDim2.fromScale(0,i/104),Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.88,BorderSizePixel=0,Active=false},scan) end
 local function resize(w,h,touch)
  local unit=math.clamp(h/414,.8,1.8)
  local bh=touch and 44 or math.max(22,22*unit)
  local gap=touch and 4 or 3*unit
  local top=math.min(h*.611,h-5*(bh+gap)-12)
  local width=touch and math.max(168,w*.225) or w*.225
  for i,b in ipairs(buttons) do b.Size=UDim2.fromOffset(math.min(width,w-32),bh);b.Position=UDim2.fromOffset(w*.048,top+(i-1)*(bh+gap));b.TextSize=touch and 13 or 13*unit end
  chapter.TextSize=14*unit;title.TextSize=28*unit;desc.TextSize=11*unit
  desc.Visible=top>h*.45
 end
 return {Root=root,Buttons=buttons,Scanlines=scan,Resize=resize,Chapter=chapter,Title=title,Description=desc}
end
return V
