local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local runtime=RS:WaitForChild('LivingForest')
local UI=require(runtime:WaitForChild('ForestInterface'))
local bag=player:WaitForChild('ForestInventory')
-- Retire the imported, oversized skin. Inventory data stays server-owned.
for _,name in ipairs({'Custom Inventory','ForestInventory'}) do
 local old=playerGui:FindFirstChild(name);if old then old:Destroy() end
end
local locale=game:GetService('LocalizationService').RobloxLocaleId:sub(1,2)
local labels=locale=='pt' and {Apple='Maçã',Orange='Laranja',title='Mochila',subtitle='Frutas da floresta',empty='Pegue frutas pelo caminho para guardá-las aqui.'}
 or locale=='es' and {Apple='Manzana',Orange='Naranja',title='Mochila',subtitle='Frutas del bosque',empty='Recoge frutas por el camino para guardarlas aquí.'}
 or {Apple='Apple',Orange='Orange',title='Backpack',subtitle='Forest fruit',empty='Collect fruit along the trail to keep it here.'}
local view=UI.inventory(labels);view.gui.Parent=playerGui
local connections={};local values={}
local function connect(signal,callback) local c=signal:Connect(callback);table.insert(connections,c);return c end
local function refresh()
 for _,slot in ipairs(view.content:GetChildren()) do if slot:IsA('GuiObject') then slot:Destroy() end end
 local total=0
 for i,kind in ipairs({'Apple','Orange'}) do
  local value=bag:FindFirstChild(kind);local count=value and value.Value or 0
  if count>0 then
   total+=count
   local mesh=runtime:FindFirstChild('Meshes') and runtime.Meshes:FindFirstChild(kind)
   local slot=UI.fruitSlot(view.content,kind,labels[kind],count,mesh);slot.LayoutOrder=i
  end
 end
 view.badge.Visible=total>0;view.empty.Visible=total==0
end
local function watch(value)
 if not value:IsA('IntValue') or values[value] then return end
 values[value]=connect(value.Changed,refresh)
end
local function toggle() view.setOpen(not view.panel.Visible) end
connect(view.open.Activated,toggle)
connect(view.close.Activated,function() view.setOpen(false) end)
connect(Input.InputBegan,function(input,processed)
 if not processed and not Input:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.B then toggle() end
end)
for _,value in ipairs(bag:GetChildren()) do watch(value) end
connect(bag.ChildAdded,function(value) watch(value);refresh() end)
connect(bag.ChildRemoved,function(value) if values[value] then values[value]:Disconnect();values[value]=nil end;refresh() end)
connect(player.CharacterAdded,function() view.setOpen(false) end)
-- Fit on small phones without a full-screen input surface or camera changes.
local cameraConnection
local function layout()
 local camera=workspace.CurrentCamera;if not camera then return end
 local size=camera.ViewportSize
 view.panel.Size=UDim2.fromOffset(math.min(292,math.max(200,size.X-28)),math.min(222,math.max(196,size.Y-130)))
end
local function cameraChanged()
 if cameraConnection then cameraConnection:Disconnect() end
 local camera=workspace.CurrentCamera
 if camera then cameraConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(layout) end
 layout()
end
connect(workspace:GetPropertyChangedSignal('CurrentCamera'),cameraChanged)
cameraChanged();refresh()
script.Destroying:Connect(function()
 for _,c in ipairs(connections) do c:Disconnect() end
 if cameraConnection then cameraConnection:Disconnect() end
 view.gui:Destroy()
end)
