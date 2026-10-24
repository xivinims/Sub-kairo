local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("ForestRuntime")local player=Players.LocalPlayer local world=workspace:WaitForChild("ForestWorld")
local Field=require(runtime:WaitForChild("Scene"))local Skinned=require(runtime:WaitForChild("SkinnedGrass"))
local sampler=require(runtime:WaitForChild("GrassSampler")).new(world)
local field={around=function(_,p,r)return Field.around(p,r)end,regionCount=1}
local template=runtime.SkinnedGrassTemplates.GrassCard local templateMesh=template:FindFirstChildOfClass("MeshPart")local sourceBones={}local offsets={}
for _,b in ipairs(templateMesh:GetChildren())do if b:IsA("Bone")then sourceBones[#sourceBones+1]=b end end
table.sort(sourceBones,function(a,b)return a.Name<b.Name end)
for i,b in ipairs(sourceBones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local visible=Instance.new("Folder")visible.Name="ForestInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="ForestGrassLocalStorage"storage.Parent=RS
local touch=UIS.TouchEnabled local radius=touch and 52 or 84
local maxActive=touch and 160 or 360 local keep=radius+6
local grass=Skinned.new({RenderDistanceEnabled=false,MeshStorage=storage,CollisionDistance=30,
 CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionAngle=68,CollisionReturnDelay=.08,
 CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=touch and 12 or 18,WindDistanceOuter=touch and 28 or 42,
 WindFramerateInner=1,WindFramerateOuter=.25,UseGlobalWind=true,WindStrengthScale=.82})
local active={}local empty={}local count=0 local queue={}local cursor=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if h and h.Health>0 and r then return r,h end end
local function add(cell)
 local heights,anchor,valid=sampler:sample(cell,offsets)
 if not anchor then empty[cell.key]=os.clock()+2 return end
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center.X,anchor,cell.center.Z))model.Parent=visible
 local mesh=model:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=heights[i]
  local point=height and Vector3.new(original.X,height-.045,original.Z)or(original-Vector3.new(0,240,0))
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 grass:AddMeshes({model})active[cell.key]={model=model,cell=cell,roots=valid}count+=1
end
local function remove(key)local entry=active[key]if not entry then return end grass:RemoveMeshes({entry.model})entry.model:Destroy()active[key]=nil count-=1 end
local stream=world.DescendantAdded:Connect(function(p)if p:IsA("BasePart")then refresh=1 table.clear(empty)end end)
player:SetAttribute("SerenaGrassCoverageRegions",field.regionCount)player:SetAttribute("SerenaWholeMapGrassReady",true)
local heartbeat=Run.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end refresh+=dt
 if refresh>=.25 then
  refresh=0
  for k,entry in pairs(active)do local dx,dz=entry.cell.center.X-root.Position.X,entry.cell.center.Z-root.Position.Z if dx*dx+dz*dz>keep*keep then remove(k)end end
  queue={}cursor=1 local now=os.clock()
  for _,cell in ipairs(field:around(root.Position,radius))do if not active[cell.key]and(not empty[cell.key]or empty[cell.key]<now)then queue[#queue+1]=cell end end
  for k,t in pairs(empty)do if now>t+4 then empty[k]=nil end end
 end
 local started=os.clock()local budget=touch and 4 or 8
 for _=1,budget do
  local cell=queue[cursor]if not cell or count>=maxActive then break end cursor+=1
  if not active[cell.key]then add(cell)end
  if os.clock()-started>(touch and .003 or .005)then break end
 end
 player:SetAttribute("SerenaGrassLoadedPatches",count)player:SetAttribute("SerenaGrassNearbyReady",cursor>#queue)
end)
local rendered=Run.RenderStepped:Connect(function(dt)
 if destroyed then return end stepTime+=dt if stepTime<(touch and 1/24 or 1/30)then return end local step=math.min(stepTime,.1)stepTime=0
 local root=rootOf(player)if not root then return end local actors={}
 for _,p in ipairs(Players:GetPlayers())do local r,h=rootOf(p)if r and(r.Position-root.Position).Magnitude<30 then
  local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)actors[#actors+1]=Vector3.new(r.Position.X,feet+.1,r.Position.Z)
 end end grass:Step(step,actors,root.Position)
end)
script.Destroying:Connect(function()destroyed=true heartbeat:Disconnect()rendered:Disconnect()stream:Disconnect()grass:Destroy()visible:Destroy()storage:Destroy()table.clear(active)table.clear(empty)end)
