local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 for _,p in ipairs(C:GetTagged("RuinMoodPrompt"))do p:Destroy()end
 local old=world.Amenities.ForestRuins:FindFirstChild("EntrancePath")if old then old:Destroy()end
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),ray)).Position end
 local positions={}
 local report={moved=0,steps=0,removedDeco=0}
 local landmarks=world.Amenities.ForestLandmarks
 local function place(m,target)
  local best,score
  for r=0,48,8 do for i=0,11 do local a=i*math.pi/6 local x,z=target.X+math.cos(a)*r,target.Y+math.sin(a)*r
   local lo,hi=math.huge,-math.huge
   for _,xx in ipairs({-18,0,18})do for _,zz in ipairs({-18,0,18})do local p=ground(x+xx,z+zz)lo=math.min(lo,p.Y)hi=math.max(hi,p.Y)end end
   local merit=hi-lo+r*.03 if lo>9 and hi-lo<5 and(not score or merit<score)then best=Vector3.new(x,hi+.18,z)score=merit end
  end end
  assert(best,"No walkable separated ruin site")local original=m:GetAttribute("Origin")m:PivotTo(m:GetPivot()+best-original)m:SetAttribute("Origin",best)
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
   if p.Name=="LandmarkStep"then p:Destroy()
   elseif p.Name=="LandmarkFoundation"then local gp=ground(p.Position.X,p.Position.Z)local top=best.Y-.6 local height=math.max(.4,top-gp.Y+.2)p.Size=Vector3.new(p.Size.X,height,p.Size.Z)p.CFrame=CFrame.new(p.Position.X,top-height*.5,p.Position.Z)p:SetAttribute("GroundPoint",gp)
   end
  end end
  for _,f in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,model in ipairs(f:GetChildren())do local v=model:GetPivot().Position
   if(math.abs(v.X-best.X)<35 and math.abs(v.Z-best.Z)<24)then model:Destroy()report.removedDeco+=1 end
  end end
  positions[#positions+1]=best report.moved+=1 return best
 end
 local mist=place(landmarks.MossySanctuary,Vector2.new(-290,-220))
 place(landmarks.StoneToriiGlade,Vector2.new(220,-205))place(landmarks.BrokenWatchtower,Vector2.new(-250,245))
 -- A separate weathered stair climbs the hill to the sanctuary, rather than dropping from the main courtyard.
 local stairs=Instance.new("Model")stairs.Name="WeatheredHillStair"stairs.Parent=world.Amenities stairs.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local lowest,startAngle
 for i=0,31 do local a=i*math.pi/16 local p=ground(mist.X+math.cos(a)*38,mist.Z+math.sin(a)*38)if not lowest or p.Y<lowest.Y then lowest=p startAngle=a end end
 local finish=Vector3.new(mist.X+math.cos(startAngle)*13,mist.Y,mist.Z+math.sin(startAngle)*13)
 if finish.Y-lowest.Y>1 then
  local n=math.max(12,math.ceil((finish.Y-lowest.Y)/.38))local nodes={}
  for i=1,n do local t=i/n local p=lowest:Lerp(finish,t)local hit=ground(p.X,p.Z)local top=math.max(p.Y,hit.Y+.1)local height=math.max(.28,top-hit.Y+.2)
   local step=Instance.new("Part")step.Name="UphillStoneStep"step.Size=Vector3.new(7,height,(finish-lowest).Magnitude/n+.18)step.CFrame=CFrame.lookAt(Vector3.new(p.X,top-height*.5,p.Z),Vector3.new(finish.X,top-height*.5,finish.Z))step.Color=Color3.fromRGB(143,158,135)step.Material=Enum.Material.Cobblestone step.Anchored=true step.CanCollide=true step.CanQuery=true step.CanTouch=false step:SetAttribute("GroundPoint",hit)step.Parent=stairs nodes[#nodes+1]={p.X,top,p.Z}report.steps+=1
  end
  stairs:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 end
 local main=world.Amenities.ForestRuins
 -- Flatten the ugly descent into a naturally sloped grassy approach. Only dry ground beside the courtyard is raised.
 local origin=main:GetAttribute("Origin")
 local region=Region3.new(Vector3.new(-152,0,32),Vector3.new(-96,36,64)):ExpandToGrid(4)
 local channels=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidMaterial","SolidOccupancy"})
 for x=1,channels.Size.X do for z=1,channels.Size.Z do
  local wx=region.CFrame.Position.X-region.Size.X*.5+(x-.5)*4 local wz=region.CFrame.Position.Z-region.Size.Z*.5+(z-.5)*4
  local hit=ground(wx,wz)local weight=math.clamp((-wx-96)/46,0,1)*math.clamp(1-math.abs(wz-48)/15,0,1)
  local height=math.max(hit.Y,hit.Y+(origin.Y-hit.Y)*weight)
  for y=1,channels.Size.Y do local low=region.CFrame.Position.Y-region.Size.Y*.5+(y-1)*4 local fill=math.clamp((height-low)/4,0,1)
   if fill>channels.SolidOccupancy[x][y][z]then channels.SolidOccupancy[x][y][z]=fill channels.SolidMaterial[x][y][z]=height-low<5 and Enum.Material.Grass or Enum.Material.Ground end
  end
 end end workspace.Terrain:WriteVoxelChannels(region,4,{SolidMaterial=channels.SolidMaterial,SolidOccupancy=channels.SolidOccupancy})
 runtime:SetAttribute("RuinOrigins",game:GetService("HttpService"):JSONEncode({{origin.X,origin.Y,origin.Z},{positions[1].X,positions[1].Y,positions[1].Z},{positions[2].X,positions[2].Y,positions[2].Z},{positions[3].X,positions[3].Y,positions[3].Z}}))
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 return report
end
return B
