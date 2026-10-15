local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("ForestRuntime")local player=Players.LocalPlayer local world=workspace:WaitForChild("ForestWorld")
local Field=require(runtime:WaitForChild("Scene"))
local Priority=require(runtime:WaitForChild("GrassPriority"))
local sampler=require(runtime:WaitForChild("GrassSampler")).new(world)
local template=runtime.SkinnedGrassTemplates.GrassCard local templateMesh=template:FindFirstChildOfClass("MeshPart")
local sourceBones,offsets={},{}
for _,b in ipairs(templateMesh:GetChildren())do if b:IsA("Bone")then sourceBones[#sourceBones+1]=b end end
table.sort(sourceBones,function(a,b)return a.Name<b.Name end)
for i,b in ipairs(sourceBones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local visible=Instance.new("Folder")visible.Name="ForestInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="ForestGrassLocalStorage"storage.Parent=RS
local touch=UIS.TouchEnabled local radius=touch and 42 or 70 local maxActive=touch and 432 or 1152
local active,empty={},{}local count=0 local queue={}local cursor=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if h and h.Health>0 and r then return r,h end end
local function add(cell)
 local heights,anchor,valid,color=sampler:sample(cell,offsets)
 if not anchor then empty[cell.key]=os.clock()+3 return end
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center.X,anchor,cell.center.Z))
 local mesh=model:FindFirstChildOfClass("MeshPart")local appearance=mesh:FindFirstChildOfClass("SurfaceAppearance")
 mesh.Color=color if appearance then appearance.Color=color end
 local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=heights[i]
  local point=height and Vector3.new(original.X,height+template:GetAttribute("BladeBaseOffset"),original.Z)or original-Vector3.new(0,240,0)
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 model.Parent=visible active[cell.key]={model=model,cell=cell,roots=valid}count+=1
end
local function remove(key)local entry=active[key]if not entry then return end entry.model:Destroy()active[key]=nil count-=1 end
local stream=world.DescendantAdded:Connect(function(p)if p:IsA("BasePart")then refresh=1 table.clear(empty)end end)
player:SetAttribute("SerenaWholeMapGrassReady",true)player:SetAttribute("ForestGrassSpacing",Field.Spacing)
local reported=-1
local heartbeat=Run.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end refresh+=dt
 if refresh>=.4 then
  refresh=0 local now=os.clock()
  local removals,newQueue=Priority.plan(active,Field.around(root.Position,radius),maxActive,empty,now)
  for _,key in ipairs(removals)do remove(key)end queue=newQueue cursor=1
  for key,time in pairs(empty)do if now>time+6 then empty[key]=nil end end
 end
 local started=os.clock()
 for _=1,touch and 3 or 6 do
  local cell=queue[cursor]if not cell or count>=maxActive then break end cursor+=1
  if not active[cell.key]then add(cell)end
  if os.clock()-started>(touch and .003 or .0045)then break end
 end
 if reported~=count then reported=count player:SetAttribute("SerenaGrassLoadedPatches",count)end
 player:SetAttribute("SerenaGrassNearbyReady",cursor>#queue)
end)
local revision=runtime:GetAttribute("SeasonRevision")or 0
local changed=runtime:GetAttributeChangedSignal("SeasonRevision"):Connect(function()
 revision=runtime:GetAttribute("SeasonRevision")
 for key in pairs(active)do remove(key)end table.clear(empty)refresh=1
end)
local seasonChanged=runtime:GetAttributeChangedSignal("SeasonName"):Connect(function()
 for key in pairs(active)do remove(key)end table.clear(empty)refresh=1
end)
script.Destroying:Connect(function()destroyed=true heartbeat:Disconnect()changed:Disconnect()seasonChanged:Disconnect()stream:Disconnect()visible:Destroy()storage:Destroy()table.clear(active)table.clear(empty)end)
