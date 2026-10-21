local UI={}
local ink=Color3.fromRGB(241,236,218)
local muted=Color3.fromRGB(164,183,166)
local function round(parent,radius)
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,radius);c.Parent=parent
end
local function outline(parent,transparency)
 local s=Instance.new('UIStroke');s.Color=ink;s.Thickness=1;s.Transparency=transparency;s.Parent=parent
end
local function label(parent,name,value,position,size,textSize,color)
 local t=Instance.new('TextLabel');t.Name=name;t.Text=value;t.Position=position;t.Size=size
 t.BackgroundTransparency=1;t.BorderSizePixel=0;t.Active=false;t.Selectable=false
 t.TextColor3=color or ink;t.TextSize=textSize;t.Font=Enum.Font.GothamMedium;t.RichText=false;t.Parent=parent
 return t
end
local function frame(parent,name,position,size)
 local f=Instance.new('Frame');f.Name=name;f.Position=position;f.Size=size
 f.BackgroundTransparency=1;f.BorderSizePixel=0;f.Active=false;f.Selectable=false;f.Parent=parent
 return f
end

function UI.inventory(labels)
 local gui=Instance.new('ScreenGui');gui.Name='ForestInventory';gui.ResetOnSpawn=false;gui.DisplayOrder=35
 gui.IgnoreGuiInset=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui:SetAttribute('InterfaceRevision','voice-touch-v13')
 local open=Instance.new('TextButton');open.Name='OpenBackpack';open.Text=''
 open.Position=UDim2.fromOffset(14,16);open.Size=UDim2.fromOffset(44,44)
 open.BackgroundColor3=Color3.fromRGB(24,39,31);open.BackgroundTransparency=.18;open.BorderSizePixel=0
 open.Active=true;open.Modal=false;open.AutoButtonColor=true;open.Parent=gui;round(open,14);outline(open,.7)
 -- A small outlined backpack, drawn from noninteractive shapes.
 local handle=frame(open,'Handle',UDim2.fromOffset(17,10),UDim2.fromOffset(10,8));round(handle,3);outline(handle,.12)
 local body=frame(open,'Bag',UDim2.fromOffset(12,15),UDim2.fromOffset(20,21));body.BackgroundColor3=open.BackgroundColor3;body.BackgroundTransparency=0;round(body,5);outline(body,.08)
 local pocket=frame(body,'Pocket',UDim2.fromOffset(4,10),UDim2.fromOffset(12,7));round(pocket,2);outline(pocket,.26)
 local seam=frame(body,'Seam',UDim2.fromOffset(3,6),UDim2.fromOffset(14,1));seam.BackgroundTransparency=.25;seam.BackgroundColor3=ink
 local badge=frame(open,'HasFruit',UDim2.fromOffset(33,3),UDim2.fromOffset(7,7));badge.BackgroundTransparency=0;badge.BackgroundColor3=Color3.fromRGB(179,211,137);badge.Visible=false;round(badge,4)
 local panel=frame(gui,'Inventory',UDim2.fromOffset(14,70),UDim2.fromOffset(292,222))
 panel.BackgroundColor3=Color3.fromRGB(23,34,28);panel.BackgroundTransparency=.08;panel.Visible=false;panel.Active=false;round(panel,16);outline(panel,.8)
 local title=label(panel,'Title',labels.title,UDim2.fromOffset(18,16),UDim2.new(1,-70,0,25),18);title.TextXAlignment=Enum.TextXAlignment.Left
 local subtitle=label(panel,'Subtitle',labels.subtitle,UDim2.fromOffset(18,45),UDim2.new(1,-36,0,24),12,muted);subtitle.TextXAlignment=Enum.TextXAlignment.Left
 local close=Instance.new('TextButton');close.Name='Close';close.Text='×';close.TextSize=26;close.TextColor3=ink;close.Font=Enum.Font.Gotham
 close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-4,0,4);close.Size=UDim2.fromOffset(44,44)
 close.BackgroundTransparency=1;close.BorderSizePixel=0;close.Modal=false;close.Active=true;close.Parent=panel
 local content=frame(panel,'FruitSlots',UDim2.fromOffset(18,84),UDim2.new(1,-36,0,108))
 local layout=Instance.new('UIListLayout');layout.FillDirection=Enum.FillDirection.Horizontal;layout.Padding=UDim.new(0,10);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=content
 local empty=label(panel,'Empty',labels.empty,UDim2.fromOffset(18,84),UDim2.new(1,-36,0,90),14,muted);empty.TextWrapped=true
 local view={gui=gui,open=open,panel=panel,close=close,content=content,empty=empty,badge=badge}
 function view.setOpen(value)
  panel.Visible=value;panel.Active=value;gui:SetAttribute('Open',value)
  open.BackgroundTransparency=value and .02 or .18
 end
 view.setOpen(false)
 return view
end

function UI.fruitSlot(parent,kind,name,count,mesh)
 local slot=frame(parent,'Fruit_'..kind,UDim2.new(),UDim2.fromOffset(84,106))
 slot.BackgroundColor3=Color3.fromRGB(45,59,45);slot.BackgroundTransparency=.15;round(slot,10)
 local view=Instance.new('ViewportFrame');view.Name='FruitPreview';view.BackgroundTransparency=1
 view.Position=UDim2.fromOffset(7,3);view.Size=UDim2.fromOffset(70,70);view.Active=false;view.Selectable=false
 view.Ambient=Color3.fromRGB(215,221,201);view.LightColor=Color3.new(1,1,1);view.Parent=slot
 if mesh then
  local fruit=mesh:Clone();fruit.CFrame=CFrame.new();fruit.Parent=view
  local camera=Instance.new('Camera');camera.CFrame=CFrame.new(Vector3.new(1.1,.8,1.8),Vector3.zero);camera.FieldOfView=36;camera.Parent=view;view.CurrentCamera=camera
 end
 label(slot,'FruitName',name,UDim2.fromOffset(4,77),UDim2.fromOffset(76,22),12)
 local amount=label(slot,'Amount',count>1 and 'x'..count or '',UDim2.new(1,-33,0,4),UDim2.fromOffset(28,16),11)
 amount.TextXAlignment=Enum.TextXAlignment.Right;amount.ZIndex=3
 return slot
end

function UI.choices(screen)
 local frame=Instance.new('ScrollingFrame');frame.Name='Choices';frame.BackgroundTransparency=1;frame.BorderSizePixel=0
 frame.AnchorPoint=Vector2.new(.5,1);frame.Position=UDim2.fromScale(.5,.87);frame.Size=UDim2.new(.72,0,0,0)
 frame.AutomaticCanvasSize=Enum.AutomaticSize.Y;frame.CanvasSize=UDim2.new();frame.ScrollBarThickness=3
 frame.ScrollingDirection=Enum.ScrollingDirection.Y;frame.Visible=false;frame.Active=false;frame.ScrollingEnabled=false;frame.Parent=screen
 local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(420,235);limit.Parent=frame
 local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,7);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=frame
 local view={frame=frame}
 function view.hide()
  frame.Visible=false;frame.Active=false;frame.ScrollingEnabled=false;frame.CanvasPosition=Vector2.zero
  for _,p in ipairs(frame:GetChildren()) do if p:IsA('GuiObject') then p:Destroy() end end
  frame.Size=UDim2.new(.72,0,0,0)
 end
 function view.show(count)
  if count==0 then view.hide();return end
  local camera=workspace.CurrentCamera
  local maxHeight=camera and math.max(90,camera.ViewportSize.Y*.44) or 235
  frame.Size=UDim2.new(.72,0,0,math.min(235,maxHeight,count*49-7))
  frame.Visible=true;frame.Active=true;frame.ScrollingEnabled=true
 end
 function view.button(name,value,order,callback)
  local b=Instance.new('TextButton');b.Name=name;b.Text=value;b.LayoutOrder=order
  b.Size=UDim2.new(1,-6,0,42);b.BackgroundColor3=Color3.fromRGB(30,43,33);b.BackgroundTransparency=.08;b.BorderSizePixel=0
  b.TextColor3=ink;b.Font=Enum.Font.GothamMedium;b.TextSize=14;b.TextWrapped=true;b.RichText=false
  b.Active=true;b.Modal=false;b.Parent=frame;round(b,10)
  local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12);pad.Parent=b
  b.Activated:Connect(callback);return b
 end
 return view
end

return UI
