-- One exact SkinnedGrass variant. Pool meshes to avoid repeated skinning allocations.
local CS=game:GetService("CollectionService")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=game:GetService("Players").LocalPlayer
local touch=game:GetService("UserInputService").TouchEnabled
local folder=workspace:WaitForChild("SkinnedGrassCoverage")
local template=RS:WaitForChild("GrassWindTemplate"):WaitForChild("SkinnedGrass")
local MAX=touch and 96 or 240
local stepX,stepZ=folder:GetAttribute("StepX"),folder:GetAttribute("StepZ")
local footX,footZ=folder:GetAttribute("FootprintX"),folder:GetAttribute("FootprintZ")
local offset=Vector3.new(folder:GetAttribute("RootCenterX"),folder:GetAttribute("RootMinY"),folder:GetAttribute("RootCenterZ"))
local radius=math.sqrt(MAX/math.pi)*math.min(stepX,stepZ)*.94
local original=require(RS:WaitForChild("SkinnedGrassRuntimeModule"))
local simulation=original.new()
simulation:UpdateSettings({RenderDistanceEnabled=false,WindEnabled=true,CollisionsEnabled=true,
 WindDistanceInner=18,WindDistanceOuter=38,WindFramerateInner=1,WindFramerateOuter=.25,
 CollisionDistance=40,CollisionRadiusInner=1.5,CollisionRadiusOuter=4.5,CollisionAngle=75,
 CollisionReturnInfo=TweenInfo.new(1.1,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out)})
local function resetSimulation()
 table.clear(simulation.DisplaceBones) table.clear(simulation.ReturnBones)
 for _,nodes in pairs(simulation.PoolNodes or {}) do
  for bone in pairs(nodes.bones) do bone.Transform=CFrame.identity end
 end
end
player:GetAttributeChangedSignal("GrassInteraction"):Connect(resetSimulation)
player:GetAttributeChangedSignal("WindEnabled"):Connect(resetSimulation)
local alive,pool={},{ }
local created=0
local function count(length,step,foot) return math.max(1,math.ceil((length-foot)/step)+1) end
local function rootPosition()
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 return root and root.Position
end
local lastPosition=nil
local function refresh()
 local pos=rootPosition() if not pos then return end
 local green=CS:GetTagged("IslandGreenGround")
 local ray=RaycastParams.new()
 ray.FilterType=Enum.RaycastFilterType.Include
 local island=workspace:FindFirstChild("FloatingIsland")
 -- Raycast the ground only: the canopy must not suppress grass beneath it.
 ray.FilterDescendantsInstances={island}
 local candidates={}
 local reach=radius+math.max(stepX,stepZ)
 for _,surface in ipairs(green) do
  if not surface:IsA("BasePart") or not surface:IsDescendantOf(workspace) then continue end
  local lp=surface.CFrame:PointToObjectSpace(pos)
  if math.abs(lp.X)>surface.Size.X/2+reach or math.abs(lp.Z)>surface.Size.Z/2+reach then continue end
  local nx,nz=count(surface.Size.X,stepX,footX),count(surface.Size.Z,stepZ,footZ)
  local ox,oz=-(nx-1)*stepX/2,-(nz-1)*stepZ/2
  local ix,iz=math.floor((lp.X-ox)/stepX)+1,math.floor((lp.Z-oz)/stepZ)+1
  local pad=math.ceil(reach/math.min(stepX,stepZ))+1
  for x=math.max(1,ix-pad),math.min(nx,ix+pad) do
   for z=math.max(1,iz-pad),math.min(nz,iz+pad) do
    local p=surface.CFrame:PointToWorldSpace(Vector3.new(ox+(x-1)*stepX,surface.Size.Y/2,oz+(z-1)*stepZ))
    local d=(Vector2.new(p.X-pos.X,p.Z-pos.Z)).Magnitude
    if d<=radius then
     local hit=workspace:Raycast(p+Vector3.new(0,80,0),Vector3.new(0,-160,0),ray)
     if hit and hit.Instance==surface and hit.Normal.Y>.6 then
      local key=tostring(surface:GetAttribute("GrassSurfaceId"))..":"..x..":"..z
      candidates[#candidates+1]={key=key,surface=surface,pos=hit.Position,d=d}
     end
    end
   end
  end
 end
 table.sort(candidates,function(a,b) return a.d<b.d end)
 local wanted={}
 for i=1,math.min(MAX,#candidates) do wanted[candidates[i].key]=true end
 for key,entry in pairs(alive) do
  if not wanted[key] then
   simulation:MovePooledMesh(entry.model,CFrame.new(0,-10000,0),false)
   pool[#pool+1]=entry.model alive[key]=nil
  end
 end
 local budget=touch and 4 or 8
 for i=1,math.min(MAX,#candidates) do
  local item=candidates[i]
  if not alive[item.key] and budget>0 then
   local model=table.remove(pool)
   if not model and created<MAX then
    model=Instance.new("Model") model.Name="AnimatedGrassPatch"
    template:Clone().Parent=model model.Parent=folder
    simulation:AddMeshes({model}) created+=1
   end
   if model then
    local cf=(CFrame.new(item.pos)*item.surface.CFrame.Rotation)*CFrame.new(-offset+Vector3.new(0,-.08,0))
    simulation:MovePooledMesh(model,cf,true)
    alive[item.key]={model=model,pos=item.pos,surface=item.surface}
    budget-=1
   end
  end
 end
 local active=0 for _ in pairs(alive) do active+=1 end
 folder:SetAttribute("ClientGrassPlaced",active)
 folder:SetAttribute("ClientGrassAllocated",created)
 folder:SetAttribute("InitialGrassReady",active>=math.min(MAX,#candidates))
end
local elapsed,simElapsed=0,0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt simElapsed+=dt
 if elapsed>=.2 then elapsed=0 refresh() end
 if simElapsed<(touch and 1/20 or 1/30) then return end
 local delta=simElapsed simElapsed=0
 local pos=rootPosition() if not pos then return end
 local collisions={}
 if player:GetAttribute("GrassInteraction")~=false then
  for _,other in ipairs(game:GetService("Players"):GetPlayers()) do
   local char=other.Character local root=char and char:FindFirstChild("HumanoidRootPart")
   if root and (root.Position-pos).Magnitude<40 then
    -- Use actual feet rather than root/hip height so stepping always reaches the grass.
    for _,name in ipairs({"LeftFoot","RightFoot","Left Leg","Right Leg"}) do
     local foot=char:FindFirstChild(name)
     if foot then collisions[#collisions+1]=foot.Position-Vector3.new(0,foot.Size.Y*.45,0) end
    end
   end
  end
 end
 simulation:UpdateSettings({WindEnabled=player:GetAttribute("WindEnabled")~=false,CollisionsEnabled=player:GetAttribute("GrassInteraction")~=false})
 simulation:Step(delta,collisions,pos)
end)
