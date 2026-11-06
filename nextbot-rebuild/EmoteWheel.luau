-- Adapted from the supplied Advanced Emote Wheel System's actual EmotesUI.
-- Keep its wheel artwork, four radial slots, avatar previews and searchable equip list.
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local M={}
local function create(class,parent,props)
 local v=Instance.new(class);for key,value in pairs(props)do v[key]=value end;v.Parent=parent;return v
end
function M.new(parent,player,package)
 local Pose=require(package:WaitForChild('PosePlayer'))
 local items=require(package:WaitForChild('EmoteCatalog'));local byId={}
 for _,item in ipairs(items)do byId[item.id]=item end
 local bindings=Pose.Bindings(package:WaitForChild('EmoteSourceRig'))
 local template=package:WaitForChild('EmoteWheelTemplate'):Clone()
 local frame=create('Frame',parent,{Name='EmotesOverlay',Visible=false,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=50})
 local backdrop=create('TextButton',frame,{Name='Dismiss',Size=UDim2.fromScale(1,1),Text='',BackgroundColor3=Color3.fromRGB(8,10,16),BackgroundTransparency=.28,AutoButtonColor=false,ZIndex=50})
 local wheel=template:WaitForChild('EmoteWheel');wheel.Parent=frame
 local menu=template:WaitForChild('EmoteMenu');menu.Parent=frame;template:Destroy()
 wheel.AnchorPoint=Vector2.new(.5,.5);wheel.Position=UDim2.fromScale(.5,.5);wheel.Visible=true
 menu.AnchorPoint=Vector2.new(.5,.5);menu.Position=UDim2.fromScale(.5,.52);menu.Visible=false
 for _,v in ipairs(frame:GetDescendants())do
  if v~=backdrop and v:IsA('GuiObject')then v.ZIndex+=51 end
  if v:IsA('UIAspectRatioConstraint')and (v.Parent==wheel or v.Parent==menu)then v:Destroy()end
 end
 wheel.ZIndex=51;menu.ZIndex=60
 for _,v in ipairs(menu:GetDescendants())do if v:IsA('GuiObject')then v.ZIndex+=20 end end
 local title=create('TextLabel',frame,{Text='EMOTES',Size=UDim2.new(1,-112,0,30),Position=UDim2.fromOffset(56,8),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=20,BackgroundTransparency=1,ZIndex=80})
 local hint=create('TextLabel',frame,{Text='Toque para usar • Segure para equipar',Size=UDim2.new(1,-32,0,22),Position=UDim2.new(0,16,1,-58),TextColor3=Color3.fromRGB(221,226,237),Font=Enum.Font.Gotham,TextSize=12,TextWrapped=true,BackgroundTransparency=1,ZIndex=80})
 local function button(value,x,callback)
  local b=create('TextButton',frame,{Text=value,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,x,1,-12),Size=UDim2.fromOffset(86,32),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=13,BackgroundColor3=Color3.fromRGB(36,42,55),ZIndex=81})
  create('UICorner',b,{CornerRadius=UDim.new(0,7)});b.Activated:Connect(callback);return b
 end
 local close=create('TextButton',frame,{Name='Close',Text='×',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,8),Size=UDim2.fromOffset(40,32),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=25,BackgroundTransparency=1,ZIndex=81})
 local page,assigning,open=1,nil,false
 local slots,previews,connections,menuButtons={},{},{},{}
 local controller={}
 local function connect(signal,callback)local c=signal:Connect(callback);table.insert(connections,c);return c end
 local function clearPreviews()
  for _,state in pairs(previews)do state.world:Destroy();state.camera:Destroy()end;table.clear(previews)
 end
 local function preview(slot,item)
  local viewport=slot:FindFirstChild('EmoteViewport')
  if not viewport then return end
  for _,child in ipairs(viewport:GetChildren())do child:Destroy()end
  viewport.Active=false;viewport.Visible=item~=nil
  if not item or not player.Character then return end
  local char=player.Character;local original=char.Archivable;char.Archivable=true;local clone=char:Clone();char.Archivable=original
  if not clone then return end
  for _,v in ipairs(clone:GetDescendants())do
   if v:IsA('LuaSourceContainer')or v:IsA('Tool')or v:IsA('Sound')or v:IsA('ForceField')or v:IsA('BillboardGui')or v:IsA('ProximityPrompt')then v:Destroy()
   elseif v:IsA('BasePart')then v.Anchored=v.Name=='HumanoidRootPart';v.CanCollide=false;v.LocalTransparencyModifier=0 end
  end
  local h=clone:FindFirstChildOfClass('Humanoid');if h then h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
  local world=create('WorldModel',viewport,{Name='PreviewWorld'});clone:PivotTo(CFrame.new());clone.Parent=world
  local camera=create('Camera',viewport,{FieldOfView=42,CFrame=CFrame.lookAt(Vector3.new(0,1,-9),Vector3.new(0,.2,0))});viewport.CurrentCamera=camera
  viewport.Ambient=Color3.fromRGB(207,207,207);viewport.LightColor=Color3.new(1,1,1)
  local sequence=package.EmoteClips:FindFirstChild(item.id)
  if sequence then previews[slot]={world=world,camera=camera,clone=clone,data=Pose.Decode(sequence),motors=Pose.Motors(clone),start=os.clock()}else world:Destroy();camera:Destroy()end
 end
 local function refresh()
  clearPreviews()
  for i,slot in ipairs(slots)do
   local index=(page-1)*4+i;local item=byId[player:GetAttribute('NBEmoteSlot'..index)]
   slot.Visible=index<=6 and not assigning
   local label=slot:FindFirstChild('EmoteName');if label then label.Text=item and item.name or 'SLOT '..index;label.TextScaled=true;label.TextWrapped=true end
   local add=slot:FindFirstChild('AddEmoteButton',true);if add then add.Visible=not item end
   local shadow=slot:FindFirstChild('Shadow');if shadow then shadow.Visible=item~=nil end
   if slot.Visible then preview(slot,item)end
  end
 end
 local search=menu:WaitForChild('EmoteSearch');local searchBox=search:WaitForChild('TextBox')
 local list=menu:WaitForChild('EmoteList');local rowTemplate=list:WaitForChild('EmoteTemplate');rowTemplate.Visible=false
 search.Position=UDim2.fromOffset(12,12);search.Size=UDim2.new(1,-24,0,38);search.AnchorPoint=Vector2.zero
 searchBox.PlaceholderText='Buscar nos seus emotes';searchBox.Text=''
 list.Position=UDim2.fromOffset(0,62);list.Size=UDim2.new(1,0,1,-74);list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.ScrollBarThickness=5
 local layout=list:FindFirstChildOfClass('UIListLayout')or create('UIListLayout',list,{})
 layout.Padding=UDim.new(0,7);layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder
 local empty=create('TextLabel',list,{Name='Empty',Visible=false,Text='Você ainda não tem emotes.\nCompre os emotes R6 na loja do menu.',Size=UDim2.new(1,-24,0,78),TextColor3=Color3.fromRGB(225,230,240),TextSize=14,TextWrapped=true,Font=Enum.Font.Gotham,BackgroundTransparency=1,ZIndex=80})
 local function populate()
  for _,b in ipairs(menuButtons)do b:Destroy()end;table.clear(menuButtons)
  local filter=searchBox.Text:lower();local count=0
  for _,item in ipairs(items)do
   if player:GetAttribute('NBEmoteOwned_'..item.id)==true and (filter==''or item.name:lower():find(filter,1,true))then
    count+=1;local b=rowTemplate:Clone();b.Name=item.id;b.Visible=true;b.Size=UDim2.new(1,-24,0,48);b.LayoutOrder=count;b.Parent=list
    local label=b:FindFirstChild('EmoteName');if label then label.Text=item.name;label.TextSize=14;label.TextScaled=false end
    local add=b:FindFirstChild('AddEmoteButton',true);if add then add.Visible=false end
    b.Activated:Connect(function()if assigning then package.Emotes:FireServer('Equip',item.id,assigning)end;assigning=nil;menu.Visible=false;wheel.Visible=true;title.Text='EMOTES';refresh()end)
    table.insert(menuButtons,b)
   end
  end
  empty.Visible=count==0
 end
 local function assign(index)
  assigning=index;clearPreviews();wheel.Visible=false;menu.Visible=true;title.Text='EQUIPAR NO SLOT '..index;searchBox.Text='';populate()
 end
 for i=1,4 do
  local slot=wheel:WaitForChild('Slot'..i);slots[i]=slot
  local token=0;local held=false
  connect(slot.InputBegan,function(input)
   if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
   token+=1;local current=token;held=false
   task.delay(.5,function()if open and not assigning and token==current then held=true;assign((page-1)*4+i)end end)
  end)
  connect(slot.InputEnded,function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then token+=1 end end)
  connect(slot.Activated,function()
   if held or assigning then return end
   local index=(page-1)*4+i;local id=player:GetAttribute('NBEmoteSlot'..index)
   if byId[id]then package.Emotes:FireServer('Play',id);controller:Close()else assign(index)end
  end)
  local add=slot:FindFirstChild('AddEmoteButton',true);if add then connect(add.Activated,function()assign((page-1)*4+i)end)end
 end
 local pageButton=button('SLOTS 1–4',0,function()if assigning then assigning=nil;menu.Visible=false;wheel.Visible=true;title.Text='EMOTES'else page=page==1 and 2 or 1 end;refresh()end)
 button('PARAR',-98,function()package.Emotes:FireServer('Stop','');controller:Close()end)
 button('FECHAR',98,function()controller:Close()end)
 local function fit()
  local size=frame.AbsoluteSize;local d=math.max(80,math.min(360,(size.X-28)/1.24,(size.Y-112)/1.4))
  wheel.Size=UDim2.fromOffset(d,d);wheel.Position=UDim2.new(.5,0,.5,-5)
  menu.Size=UDim2.fromOffset(math.max(180,math.min(420,size.X-32)),math.max(120,math.min(460,size.Y-112)))
  hint.TextSize=size.X<380 and 11 or 12
 end
 connect(frame:GetPropertyChangedSignal('AbsoluteSize'),fit);fit()
 function controller:IsOpen()return open end
 function controller:Close()
  open=false;assigning=nil;frame.Visible=false;menu.Visible=false;clearPreviews()
  if player:GetAttribute('NBOverlay')=='Emotes'then player:SetAttribute('NBOverlay','')end
 end
 function controller:Toggle()
  if open then self:Close();return end
  if not parent.Enabled or player:GetAttribute('NBDowned')or not player:GetAttribute('NBInArena')then return end
  open=true;assigning=nil;frame.Visible=true;wheel.Visible=true;menu.Visible=false;title.Text='EMOTES';player:SetAttribute('NBOverlay','Emotes');refresh();fit()
  local rest=wheel.Position;wheel.Position=rest+UDim2.fromOffset(0,12);Tween:Create(wheel,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=rest}):Play()
 end
 function controller:Destroy()self:Close();for _,c in ipairs(connections)do c:Disconnect()end;frame:Destroy()end
 connect(backdrop.Activated,function()controller:Close()end);connect(close.Activated,function()controller:Close()end)
 connect(searchBox:GetPropertyChangedSignal('Text'),populate)
 connect(player:GetAttributeChangedSignal('NBOverlay'),function()if player:GetAttribute('NBOverlay')~='Emotes'then controller:Close()end end)
 connect(parent:GetPropertyChangedSignal('Enabled'),function()if not parent.Enabled then controller:Close()end end)
 connect(player.CharacterRemoving,function()controller:Close()end)
 for i=1,6 do connect(player:GetAttributeChangedSignal('NBEmoteSlot'..i),function()if open and not assigning then refresh()end end)end
 connect(Run.PreSimulation,function()
  if not open then return end
  pageButton.Text=assigning and 'VOLTAR'or page==1 and 'SLOTS 1–4'or 'SLOTS 5–6'
  for _,state in pairs(previews)do if state.clone.Parent then Pose.Apply(state.data,state.motors,os.clock()-state.start,1,bindings)end end
 end)
 connect(UIS.InputBegan,function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape and open then controller:Close()end end)
 return controller
end
return M
