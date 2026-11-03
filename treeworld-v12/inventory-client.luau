local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local player=Players.LocalPlayer
local runtime=RS:WaitForChild('LivingForest')
local bag=player:WaitForChild('ForestInventory')
local gui=player.PlayerGui:WaitForChild('Custom Inventory')
gui.ResetOnSpawn=false;gui.DisplayOrder=35;gui.IgnoreGuiInset=false
local panel=gui:WaitForChild('Inventory');local hotbar=gui:WaitForChild('hotBar');local open=gui:WaitForChild('openButton')
local content=panel:WaitForChild('Frame');local search=panel:FindFirstChild('SearchBox')
local template=runtime:WaitForChild('InventorySlotTemplate')
local locale=player.LocaleId:sub(1,2)
local labels=locale=='pt'and{Apple='Maçã',Orange='Laranja',open='Mochila',close='Fechar',search='Procurar fruta'}or locale=='es'and{Apple='Manzana',Orange='Naranja',open='Mochila',close='Cerrar',search='Buscar fruta'}or{Apple='Apple',Orange='Orange',open='Backpack',close='Close',search='Search fruit'}
panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(.82,0,0,260);panel.Visible=false
local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(460,320);limit.MinSize=Vector2.new(250,220);limit.Parent=panel
hotbar.AnchorPoint=Vector2.new(.5,1);hotbar.Position=UDim2.new(.5,0,1,-18);hotbar.Size=UDim2.fromOffset(132,58)
local grid=hotbar:FindFirstChildWhichIsA('UIGridLayout');if grid then grid.CellSize=UDim2.fromOffset(58,58);grid.CellPadding=UDim2.fromOffset(8,8)end
grid=content:FindFirstChildWhichIsA('UIGridLayout');if grid then grid.CellSize=UDim2.fromOffset(78,78);grid.CellPadding=UDim2.fromOffset(10,10)end
open.AnchorPoint=Vector2.new(.5,1);open.Position=UDim2.new(.5,0,1,-82);open.Size=UDim2.fromOffset(112,32)
local info=open:FindFirstChild('info');if info then info.Text=labels.open;info.TextSize=14 end
if search then search.PlaceholderText=labels.search;search.Text=''end
local slots={}
local function icon(button,kind)
 local old=button:FindFirstChild('toolIcon');if old then old.Visible=false end
 local view=Instance.new('ViewportFrame');view.Name='FruitPreview';view.BackgroundTransparency=1;view.Size=UDim2.new(1,-12,1,-20);view.Position=UDim2.fromOffset(6,0);view.Ambient=Color3.new(.8,.8,.8);view.LightColor=Color3.new(1,1,1);view.Parent=button
 local fruit=runtime.Meshes[kind]:Clone();fruit.CFrame=CFrame.new();fruit.Parent=view
 local camera=Instance.new('Camera');camera.CFrame=CFrame.new(Vector3.new(1.1,.8,1.8),Vector3.zero);camera.FieldOfView=36;camera.Parent=view;view.CurrentCamera=camera
end
local function slot(parent,kind,count)
 local b=template:Clone();b.Name='Fruit_'..kind;b.Visible=true;b.Parent=parent
 for _,p in ipairs(b:GetDescendants())do if p:IsA('LuaSourceContainer')then p:Destroy()end end
 local name=b:FindFirstChild('toolName');if name then name.Text=labels[kind];name.TextSize=12;name.TextWrapped=true;name.ZIndex=4 end
 local amount=b:FindFirstChild('toolAmount');if amount then amount.Text=count>1 and'x'..count or'';amount.TextSize=11;amount.TextScaled=false;amount.Size=UDim2.fromOffset(30,16);amount.Position=UDim2.new(1,-32,0,2);amount.ZIndex=5 end
 local number=b:FindFirstChild('toolNumber');if number then number.Visible=false end
 icon(b,kind);return b
end
local function refresh()
 for _,s in ipairs(slots)do s:Destroy()end;slots={}
 local filter=search and string.lower(search.Text)or''
 for _,kind in ipairs({'Apple','Orange'})do
  local value=bag:FindFirstChild(kind);local count=value and value.Value or 0
  if count>0 then
   table.insert(slots,slot(hotbar,kind,count))
   if filter==''or string.find(string.lower(labels[kind]),filter,1,true)then table.insert(slots,slot(content,kind,count))end
  end
 end
 hotbar.Visible=#slots>0 and not panel.Visible
end
local function toggle()panel.Visible=not panel.Visible;if info then info.Text=panel.Visible and labels.close or labels.open end;refresh()end
open.Activated:Connect(toggle)
Input.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.B then toggle()end end)
for _,value in ipairs(bag:GetChildren())do if value:IsA('IntValue')then value.Changed:Connect(refresh)end end
bag.ChildAdded:Connect(function(value)if value:IsA('IntValue')then value.Changed:Connect(refresh)end;refresh()end)
if search then search:GetPropertyChangedSignal('Text'):Connect(refresh)end
refresh()
