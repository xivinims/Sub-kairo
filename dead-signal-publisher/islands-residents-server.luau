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

for _,s in ipairs(states) do
 local pos=Residents.FindGround(s.def)
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
