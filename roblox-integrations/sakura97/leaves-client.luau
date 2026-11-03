local player=game:GetService("Players").LocalPlayer
local RunService=game:GetService("RunService")
local tree=workspace:WaitForChild("BigCenterTree")
local host=tree:WaitForChild("FallingLeavesEmitter")
local folder=Instance.new("Folder") folder.Name="LocalFallingLeaves" folder.Parent=workspace
local rng=Random.new()
local leaves={}
for i=1,14 do
 local part=Instance.new("Part") part.Name="Leaf" part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false part.CastShadow=false
 part.Size=Vector3.new(.24,.035,.5) part.Color=Color3.fromRGB(105+rng:NextInteger(-15,15),145+rng:NextInteger(-15,15),66)
 part.Material=Enum.Material.SmoothPlastic
 local mesh=Instance.new("SpecialMesh") mesh.MeshType=Enum.MeshType.Sphere mesh.Parent=part
 part.Parent=folder
 leaves[i]={part=part,age=i*1.2,lifetime=16+rng:NextNumber(0,4),origin=Vector3.zero,phase=rng:NextNumber(0,6)}
end
local function restart(leaf)
 local half=host.Size*.5
 leaf.origin=host.CFrame:PointToWorldSpace(Vector3.new(rng:NextNumber(-half.X,half.X),rng:NextNumber(-half.Y,half.Y),rng:NextNumber(-half.Z,half.Z)))
 leaf.age=0
end
for _,leaf in ipairs(leaves) do restart(leaf) leaf.age=rng:NextNumber(0,leaf.lifetime) end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<1/30 then return end local step=elapsed elapsed=0
 local enabled=player:GetAttribute("LeavesEnabled")~=false
 local wind=player:GetAttribute("WindEnabled")~=false and workspace.GlobalWind*.14 or Vector3.zero
 for _,leaf in ipairs(leaves) do
  if not enabled then leaf.part.Transparency=1 continue end
  leaf.age+=step if leaf.age>leaf.lifetime then restart(leaf) end
  local t=leaf.age
  local p=leaf.origin+wind*t+Vector3.new(math.sin(t*1.5+leaf.phase)*1.2,-t*2.4,math.cos(t+leaf.phase)*.7)
  leaf.part.CFrame=CFrame.new(p)*CFrame.Angles(math.sin(t*2)*.6,t*.8+leaf.phase,math.cos(t)*.6)
  leaf.part.Transparency=math.clamp(math.max(1-t*2,(t-leaf.lifetime+2)/2),0,1)
 end
end)
