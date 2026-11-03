-- Dead Signal: reference-composed, live Roblox UI (original text and menu functionality).
-- Coordinates are authored against the user's 736x414 screenshot, not guessed from screen percentages.
local V={}
function V.Create(screen)
 local function make(class,props,parent)
  local obj=Instance.new(class)
  for k,v in pairs(props) do obj[k]=v end
  obj.Parent=parent
  return obj
 end
 local root=make("Frame",{Name="ReferenceMenu",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,Active=false},screen)
 local shading=make("Frame",{Name="DarkLeftGradient",Size=UDim2.fromScale(.72,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0,BorderSizePixel=0,ZIndex=1},root)
 make("UIGradient",{Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.03),NumberSequenceKeypoint.new(.40,.28),NumberSequenceKeypoint.new(1,1)
 })},shading)
 local bottom=make("Frame",{Name="BottomVignette",Position=UDim2.fromScale(0,.82),Size=UDim2.fromScale(1,.18),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.5,BorderSizePixel=0,ZIndex=1},root)
 make("UIGradient",{Transparency=NumberSequence.new(1,.4),Rotation=90},bottom)
 local canvas=make("Frame",{Name="ChapterCanvas736x414",Size=UDim2.fromOffset(736,414),Position=UDim2.fromOffset(0,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3},root)
 local scale=make("UIScale",{Name="ReferenceScale",Scale=1},canvas)
 local bar=make("Frame",{Name="BlueBeam",Position=UDim2.fromOffset(0,39),Size=UDim2.fromOffset(365,9),BackgroundColor3=Color3.fromRGB(95,157,239),BackgroundTransparency=.72,BorderSizePixel=0,ZIndex=4},canvas)
 make("UIGradient",{Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.36),NumberSequenceKeypoint.new(.65,.82),NumberSequenceKeypoint.new(1,1)
 })},bar)
 local barLine=make("Frame",{Name="BlueCore",Position=UDim2.fromOffset(0,44),Size=UDim2.fromOffset(280,2),BackgroundColor3=Color3.fromRGB(158,194,246),BackgroundTransparency=.38,BorderSizePixel=0,ZIndex=5},canvas)
 make("UIGradient",{Transparency=NumberSequence.new(0,1)},barLine)
 local function text(name,value,x,y,w,h,sz)
  return make("TextLabel",{Name=name,Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),TextColor3=Color3.fromRGB(245,243,242),Font=Enum.Font.Code,TextSize=sz,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=false,BackgroundTransparency=1,ZIndex=6},canvas)
 end
 local chapter=text("Chapter","CHAPTER 1",30,40,276,25,15)
 local title=text("Title","'THE ATRIUM'",29,67,440,38,31)
 local rule=make("Frame",{Name="WhiteHairline",Position=UDim2.fromOffset(0,106),Size=UDim2.fromOffset(326,1),BackgroundColor3=Color3.fromRGB(238,238,238),BackgroundTransparency=.42,BorderSizePixel=0,ZIndex=5},canvas)
 local desc=text("Description","Light still reaches the garden.\nBeyond the empty galleries,\nsomething remains unfinished.",31,126,275,62,12)
 desc.TextWrapped=true
 local buttons={}
 for i,name in ipairs({"CONTINUE","NEW GAME","SETTINGS","CREDITS","QUIT"}) do
  local b=make("TextButton",{Name=name,Text=name,Position=UDim2.fromOffset(34,252+(i-1)*24),Size=UDim2.fromOffset(167,22),BackgroundColor3=Color3.fromRGB(5,5,7),BackgroundTransparency=.25,TextColor3=Color3.fromRGB(247,245,243),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Font=Enum.Font.Code,TextSize=14,AutoButtonColor=false,BorderSizePixel=0,SelectionOrder=i,ZIndex=15},canvas)
  make("UIPadding",{PaddingLeft=UDim.new(0,9)},b)
  make("UIStroke",{Name="ThinWhiteOutline",ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(211,210,208),Thickness=1,Transparency=.22},b)
  buttons[i]=b
 end
 local scan=make("Frame",{Name="Scanlines",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,ZIndex=21},root)
 for i=0,74 do
  make("Frame",{Name="FilmLine",Position=UDim2.fromScale(0,i/75),Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.93,BorderSizePixel=0,Active=false,ZIndex=21},scan)
 end
 local function resize(w,h,touch)
  if w<=0 or h<=0 then return end
  local s=math.min(w/736,h/414)
  -- Preserve cinematic proportions on landscape. No stretched text or nonuniform layout.
  s=math.max(.4,math.min(s,2.5))
  scale.Scale=s
  canvas.Position=UDim2.fromOffset(0,math.floor(math.max(0,(h-414*s)*.5)))
  chapter.Position=UDim2.fromOffset(30,40)
  title.Position=UDim2.fromOffset(29,67)
  rule.Position=UDim2.fromOffset(0,106)
  desc.Position=UDim2.fromOffset(31,126)
  desc.Visible=true
  local compact=touch and h<520
  local portrait=touch and h>w
  if portrait then
   -- At portrait widths the chapter remains readable and touch controls stay >=44px.
   local actualWidth=math.min(306,w-30)
   local rowHeight=46/s
   local rowStep=50/s
   local top=(h-5*50-28)/s
   title.TextSize=math.max(31,27/s)
   title.Size=UDim2.fromOffset(math.min(650,w/s-20),62)
   desc.Visible=false
   for i,b in ipairs(buttons) do
    b.Position=UDim2.fromOffset(16/s,top+(i-1)*rowStep)
    b.Size=UDim2.fromOffset(actualWidth/s,rowHeight)
    b.TextSize=math.max(14,14/s)
   end
  elseif compact then
   -- Landscape mobile has a virtual 736x414 composition but 40px tapping targets.
   title.TextSize=31
   title.Size=UDim2.fromOffset(490,40)
   desc.Visible=false
   local rowHeight=math.max(22,44/s)
   local step=math.max(26,48/s)
   local top=math.min(252,(h-5*rowHeight*s-4*(step-rowHeight)*s-8)/s)
   for i,b in ipairs(buttons) do
    b.Position=UDim2.fromOffset(34,top+(i-1)*step)
    b.Size=UDim2.fromOffset(math.max(167,185/s),rowHeight)
    b.TextSize=math.max(14,13/s)
   end
  else
   title.TextSize=31;title.Size=UDim2.fromOffset(440,38)
   for i,b in ipairs(buttons) do
    b.Position=UDim2.fromOffset(34,252+(i-1)*24)
    b.Size=UDim2.fromOffset(167,22)
    b.TextSize=14
   end
  end
 end
 local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(736,414)
 resize(viewport.X,viewport.Y,game:GetService("UserInputService").TouchEnabled)
 return {Root=root,Buttons=buttons,Scanlines=scan,Resize=resize,Chapter=chapter,Title=title,Description=desc,Canvas=canvas,Scale=scale}
end
return V
