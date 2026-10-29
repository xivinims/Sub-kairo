local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local SS=game:GetService('ServerStorage')
local Residents=require(script.Parent.IslandResidents);local Chunks=require(script.Parent.IslandChunks)
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.3) end
local cache=Instance.new('Folder');cache.Name='ResidentCache';cache.Parent=SS
local world=Instance.new('Folder');world.Name='IslandResidents';world.Parent=workspace
local event=RS:WaitForChild('ResidentDialogue');local states={}
for _,def in ipairs(Residents.Definitions) do
 local ok,rig=pcall(Residents.Build,def)
 if not ok then warn('[Residents] '..def.id..': '..tostring(rig));workspace:SetAttribute('ResidentError_'..def.id,tostring(rig))
 else
  rig.Parent=cache;local spawn=workspace.IslandDestinations[def.island]
  table.insert(states,{def=def,rig=rig,origin=spawn.Position+def.offset,placed=false,nextMove=0})
 end
 task.wait(.1)
end
local function ground(state)
 Chunks.Warm(state.def.island,state.origin,64)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain,workspace.Islands[state.def.island]};rp.IgnoreWater=false
 local spawn=workspace.IslandDestinations[state.def.island]
 for ring=0,4 do for i=1,8 do
  local pos=state.origin+Vector3.new(math.cos(i*math.pi/4)*ring*5,0,math.sin(i*math.pi/4)*ring*5)
  local hit=workspace:Raycast(pos+Vector3.new(0,14,0),Vector3.new(0,-32,0),rp)
  if hit and hit.Material~=Enum.Material.Water and hit.Normal.Y>.85 and math.abs(hit.Position.Y-spawn.Position.Y)<10 then
   local probe=Instance.new('Part');probe.Size=Vector3.new(3,5.5,3);probe.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0));probe.Anchored=true;probe.Transparency=1;probe.CanCollide=false;probe.Parent=workspace
   local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={workspace.Islands[state.def.island]};op.RespectCanCollide=true
   local clear=#workspace:GetPartsInPart(probe,op)==0;probe:Destroy()
   if clear then return hit.Position end
  end
 end end
end
for _,s in ipairs(states) do
 local pos=ground(s)
 if pos then
  s.origin=pos;local root=s.rig.HumanoidRootPart;local hum=s.rig.Humanoid
  s.rig:PivotTo(CFrame.new(pos+Vector3.new(0,hum.HipHeight+root.Size.Y/2,0)));s.placed=true
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Conversar';prompt.ObjectText=s.def.name..' · '..s.def.role;prompt.MaxActivationDistance=9;prompt.RequiresLineOfSight=false;prompt.Parent=s.rig.Head
  local last={}
  prompt.Triggered:Connect(function(p)
   local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   if r and (r.Position-root.Position).Magnitude<12 and os.clock()-(last[p.UserId] or 0)>2 then last[p.UserId]=os.clock();event:FireClient(p,s.rig,s.def.line) end
  end)
 else warn('[Residents] No safe placement for '..s.def.id);workspace:SetAttribute('ResidentError_'..s.def.id,'No safe placement') end
end
while task.wait(1) do
 local active=0
 for _,s in ipairs(states) do if s.placed then
  local nearby=false
  for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if r and p:GetAttribute('IslandDestination')==s.def.island and (r.Position-s.origin).Magnitude<140 then nearby=true;break end end
  s.rig.Parent=nearby and world or cache
  if nearby then active+=1 end
 end end
 workspace:SetAttribute('ResidentsActive',active)
end
