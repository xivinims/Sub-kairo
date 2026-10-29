while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local SS=game:GetService('ServerStorage');local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService')
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.2) end
local Chunks=require(script.Parent.MansionChunks);Chunks.Start()
local event=RS:WaitForChild('MansionEvent');local spawn=workspace.IslandDestinations.forestCurrent
local function added(p)
 p.RespawnLocation=spawn
 local function character(char)
  local root=char:WaitForChild('HumanoidRootPart',15);if not root then return end
  root.Anchored=true;Chunks.Warm(spawn.Position,150);char:PivotTo(spawn.CFrame+Vector3.new(0,4,0));p:SetAttribute('IslandDestination','forestCurrent');p:SetAttribute('HasIslandArrival',true);root.Anchored=false
 end
 p.CharacterAdded:Connect(character);if p.Character then task.spawn(character,p.Character) end
end
Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers()) do added(p) end
task.spawn(function() while task.wait(2) do for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if r and r.Position.Y< -450 then p:LoadCharacterAsync() end end end end)
local mounted=setmetatable({},{__mode='k'});local frontDoor
local function mount(part)
 if not part:IsA('BasePart') or not part:GetAttribute('MansionDoor') or mounted[part] then return end;mounted[part]=true
 local group=part:GetAttribute('MansionDoorId')
 if group then for _,other in ipairs(part.Parent:GetDescendants()) do if other:IsA('BasePart') and other~=part and other:GetAttribute('MansionDoorId')==group then
  other.Anchored=false;other.CanCollide=false;local weld=Instance.new('WeldConstraint');weld.Part0=part;weld.Part1=other;weld.Parent=part
 end end end
 local original=part.CFrame;local open,busy=false,false
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Abrir / fechar';prompt.ObjectText='Porta';prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=false;prompt.Parent=part
 if part:GetAttribute('FrontEntrance') then
 frontDoor=part
 local record=Instance.new('ProximityPrompt');record.ActionText='Consultar registro';record.ObjectText='Antiga proprietária';record.KeyboardKeyCode=Enum.KeyCode.F;record.MaxActivationDistance=7;record.RequiresLineOfSight=false;record.Parent=part
 record.Triggered:Connect(function(p) local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if root and (root.Position-part.Position).Magnitude<10 then event:FireClient(p,'record') end end)
 end
 prompt.Triggered:Connect(function(p)
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if not root or (root.Position-part.Position).Magnitude>12 or busy then return end
  busy=true;open=not open;part.CanCollide=false
  local hinge=original*CFrame.new(-part.Size.X*.5,0,0)
  local target=open and hinge*CFrame.Angles(0,math.rad(95),0)*CFrame.new(part.Size.X*.5,0,0) or original
  local tween=Tween:Create(part,TweenInfo.new(1.05,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=target});tween:Play();tween.Completed:Wait()
  if part.Parent then part.CanCollide=not open;part:SetAttribute('DoorOpen',open) end;busy=false
 end)
end
for _,part in ipairs(workspace.Islands.mansion:GetDescendants()) do mount(part) end
workspace.Islands.mansion.DescendantAdded:Connect(mount)
-- One creature, changing its borrowed identity; never multiple simultaneous visitors.
local builder=require(script.Parent.ResidentAppearance)
local faces={
 {id='Visitor',name='Visitante',role='',male=false,hair=62724852,shirt=144076436,pants=398633812,height=1.03,width=.8,skin=Color3.fromRGB(169,140,119)},
 {id='Visitor',name='Visitante',role='',male=true,hair=62234425,shirt=144076358,pants=144076760,height=1.1,width=.88,skin=Color3.fromRGB(177,139,108)},
 {id='Visitor',name='Visitante',role='',male=false,hair=63690008,shirt=398633584,pants=398633812,height=.95,width=.76,skin=Color3.fromRGB(126,106,92)},
}
local visitor;local index=0
while true do
 task.wait(math.random(35,55))
 if #Players:GetPlayers()==0 then continue end
 index=index%#faces+1
 local ok,rig=pcall(builder.Build,faces[index])
 if not ok then warn('[VisitorAppearance] '..tostring(rig));continue end
 if visitor then visitor:Destroy() end;visitor=rig;rig.Name='TheFormerOwner';rig:SetAttribute('OriginalIdentity','Amélia Duarte — falecida');rig:SetAttribute('BorrowedFace',index)
 local entrance=workspace:GetAttribute('EntrancePosition') or spawn.Position
 local outside=entrance+Vector3.new(0,0,12)
 Chunks.Warm(outside,96)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain,workspace.Islands.mansion};rp.IgnoreWater=true
 local ground=workspace:Raycast(outside+Vector3.new(0,20,0),Vector3.new(0,-50,0),rp)
 local position=(ground and ground.Position or outside)+Vector3.new(0,rig.Humanoid.HipHeight+1,0)
 rig:PivotTo(CFrame.lookAt(position,Vector3.new(entrance.X,position.Y,entrance.Z)));rig.Parent=workspace;rig.HumanoidRootPart.Anchored=true
 for knock=1,3 do event:FireAllClients('knock',entrance);task.wait(.6) end
 event:FireAllClients('visitor',rig,'Oi, aqui é minha casa. O que vocês fazem aqui???')
 local start=os.clock()
 while rig.Parent and os.clock()-start<24 do
  local root=rig.HumanoidRootPart
  for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   if r and hum and hum.Health>0 and not Chunks.Inside(r.Position) and (r.Position-root.Position).Magnitude<80 then
    local direction=Vector3.new(r.Position.X-root.Position.X,0,r.Position.Z-root.Position.Z)
    if direction.Magnitude>4 then
     local step=direction.Unit*1.8
     local nextPos=root.Position+step;local floor=workspace:Raycast(nextPos+Vector3.new(0,20,0),Vector3.new(0,-55,0),rp);if floor and not workspace:Raycast(root.Position,step*2,rp) then nextPos=Vector3.new(nextPos.X,floor.Position.Y+rig.Humanoid.HipHeight+1,nextPos.Z);rig:PivotTo(CFrame.lookAt(nextPos,Vector3.new(r.Position.X,nextPos.Y,r.Position.Z))) end
    else hum:TakeDamage(6) end
   end
  end
  task.wait(.2)
 end
 if rig.Parent then
  -- Fade before changing identity so the swap never happens visibly.
  for _,part in ipairs(rig:GetDescendants()) do if part:IsA('BasePart') then Tween:Create(part,TweenInfo.new(2),{Transparency=1}):Play() end end
  task.wait(2);rig:Destroy()
 end
end
