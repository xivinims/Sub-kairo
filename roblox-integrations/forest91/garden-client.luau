local Run=game:GetService("RunService")local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local world=workspace:WaitForChild("ForestWorld")
local localWorld=Instance.new("Folder")localWorld.Name="TreeWorldGardenEffects"localWorld.Parent=workspace
local rng=Random.new()local leaves={}local cap=UIS.TouchEnabled and 22 or 40
for i=1,cap do local p=Instance.new("WedgePart")p.Name="MicroLeaf"p.Size=Vector3.new(.08,.025,.18)p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=1 p.Parent=localWorld leaves[i]={part=p,birth=-100}end
local canopies={}local Collection=game:GetService("CollectionService")
local function leafPart(p)if p:IsA("BasePart")and not canopies[p]then canopies[p]=true end end
for _,p in ipairs(Collection:GetTagged("ForestWindFoliage"))do leafPart(p)end
Collection:GetInstanceAddedSignal("ForestWindFoliage"):Connect(leafPart)Collection:GetInstanceRemovedSignal("ForestWindFoliage"):Connect(function(p)canopies[p]=nil end)
local entries={}
local function route(value)
 if not value:IsA("StringValue")then return end
 local points=game:GetService("HttpService"):JSONDecode(value.Value)local nodes={}local cumulative={0}local length=0
 for _,p in ipairs(points)do nodes[#nodes+1]=Vector3.new(unpack(p))end
 for i=1,#nodes do length+=(nodes[i%#nodes+1]-nodes[i]).Magnitude cumulative[i+1]=length end
 entries[#entries+1]={source=value,nodes=nodes,cumulative=cumulative,length=length}
end
local routes=world.Amenities:WaitForChild("CuteAnimalRoutes")for _,v in ipairs(routes:GetChildren())do route(v)end routes.ChildAdded:Connect(route)
local function activate(e)
 local m=runtime.CuteAnimalTemplates[e.source:GetAttribute("Species")]:Clone()m.Parent=localWorld e.model=m e.groups={}
 for _,group in ipairs(m:GetChildren())do if group:IsA("BasePart")then local rec={root=group,base=group.CFrame,parts={}}
  for _,p in ipairs(group:GetDescendants())do if p:IsA("BasePart")then rec.parts[p]=group.CFrame:ToObjectSpace(p.CFrame)end end e.groups[#e.groups+1]=rec
 end end
end
local soundFolder=runtime:WaitForChild("GardenSounds")
local function sound(name,parent,volume)local s=soundFolder[name]:Clone()s.Parent=parent s.Volume=volume or s.Volume return s end
local birds=sound("Forest",game:GetService("SoundService"),.12)birds:Play()
local wind=sound("Wind",game:GetService("SoundService"),.08)wind:Play()
local river=sound("River",game:GetService("SoundService"),0)river:Play()
local rain=sound("Rain",game:GetService("SoundService"),0)rain:Play()
local foot local footChar local footTime=0
local rainRoot=Instance.new("Part")rainRoot.Name="LocalRainCeiling"rainRoot.Size=Vector3.new(35,.1,35)rainRoot.Anchored=true rainRoot.Transparency=1 rainRoot.CanCollide=false rainRoot.CanTouch=false rainRoot.CanQuery=false rainRoot.Parent=localWorld
local emitter=Instance.new("ParticleEmitter")emitter.Name="GentleRain"emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"emitter.Rate=0 emitter.Lifetime=NumberRange.new(.45,.65)emitter.Speed=NumberRange.new(32,40)emitter.EmissionDirection=Enum.NormalId.Bottom emitter.Size=NumberSequence.new(.045)emitter.Color=ColorSequence.new(Color3.fromRGB(191,224,228))emitter.Transparency=NumberSequence.new(.65)emitter.Acceleration=Vector3.new(4,-18,1)emitter.SpreadAngle=Vector2.new(4,4)emitter.Parent=rainRoot
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.RespectCanCollide=true
local scan,elapsed,spawnClock,leafIndex=0,0,0,0 local nearby={}
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt spawnClock+=dt if elapsed<1/24 then return end local step=elapsed elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position local now=workspace:GetServerTimeNow()
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if scan>1 then
  scan=0 table.clear(nearby)
  for p in pairs(canopies)do if p.Parent and(p.Position-pos).Magnitude<48 and p.Size.X>3 then nearby[#nearby+1]=p end end
  if #nearby>12 then while #nearby>12 do table.remove(nearby)end end
  if root then
   ray.FilterDescendantsInstances={world.Amenities,workspace.Terrain,world.Decor}
   local roof=workspace:Raycast(root.Position+Vector3.yAxis*2,Vector3.yAxis*24,ray)
   local raining=runtime:GetAttribute("Raining")
   emitter.Rate=raining and not roof and(UIS.TouchEnabled and 65 or 100)or 0
   Tween:Create(rain,TweenInfo.new(1),{Volume=raining and(roof and .035 or .14)or 0}):Play()
   local riverX=require(runtime.Scene).riverX(root.Position.Z)local riverWidth=require(runtime.Scene).riverWidth(root.Position.Z)
   local proximity=math.clamp(1-(math.abs(root.Position.X-riverX)-riverWidth)/40,0,1)
   if math.abs(root.Position.Z)>295 then proximity=0 end
   Tween:Create(river,TweenInfo.new(1),{Volume=.13*proximity}):Play()
  end
 end
 rainRoot.CFrame=CFrame.new((root and root.Position or pos)+Vector3.yAxis*18)
 if spawnClock>.55 and #nearby>0 and runtime:GetAttribute("SeasonName")~="Inverno"then
  spawnClock=0 leafIndex=leafIndex%cap+1 local e=leaves[leafIndex]local p=nearby[rng:NextInteger(1,#nearby)]
  e.start=p.Position+Vector3.new(rng:NextNumber(-p.Size.X*.25,p.Size.X*.25),-p.Size.Y*.2,rng:NextNumber(-p.Size.Z*.25,p.Size.Z*.25))e.birth=now e.phase=rng:NextNumber(0,6.28)e.life=rng:NextNumber(5,8)
  e.part.Color=runtime:GetAttribute("SeasonName")=="Outono"and Color3.fromRGB(181,134,66)or Color3.fromRGB(128,153,93)e.part.Transparency=.12
 end
 for _,e in ipairs(leaves)do local age=now-e.birth if age< (e.life or 0)then local drift=Vector3.new(age*.25+math.sin(age*1.6+e.phase)*.4,-age*1.35,math.cos(age*1.2+e.phase)*.3)
  e.part.CFrame=CFrame.new(e.start+drift)*CFrame.Angles(age*.7,e.phase+age*.9,.3*math.sin(age*2))e.part.Transparency=.12+.88*math.clamp((age-e.life+1.5)/1.5,0,1)
 else e.part.Transparency=1 end end
 for _,e in ipairs(entries)do
  local distance=(e.nodes[1]-pos).Magnitude
  if distance<85 then if not e.model then activate(e)end
   local speed=e.source:GetAttribute("Speed")local phase=e.source:GetAttribute("Phase")local travel=(now*speed+phase)%e.length local index=1
   while index<#e.nodes and e.cumulative[index+1]<travel do index+=1 end
   local a,b=e.nodes[index],e.nodes[index%#e.nodes+1]local t=(travel-e.cumulative[index])/(e.cumulative[index+1]-e.cumulative[index])local point=a:Lerp(b,t)
   local rabbit=e.source:GetAttribute("Species")=="Conejo"local gait=math.sin(now*(rabbit and 7 or 5)+phase)local cf=CFrame.lookAt(point,point+Vector3.new(b.X-a.X,0,b.Z-a.Z))
   if rabbit then cf+=Vector3.yAxis*math.max(0,gait)*.18 end
   for _,g in ipairs(e.groups)do local leg=g.root.Name:find("Pata",1,true)local swing=CFrame.identity
    -- Native body groups and their children share one gait transform.
    if leg then local n=tonumber(g.root.Name:match("%d+"))or 1 swing=CFrame.Angles(gait*.2*(n%2==0 and 1 or -1),0,0)end
    g.root.CFrame=cf*g.base*swing for p,offset in pairs(g.parts)do p.CFrame=g.root.CFrame*offset end
   end
  elseif e.model then e.model:Destroy()e.model=nil end
 end
 if c~=footChar then if foot then foot:Destroy()end footChar=c foot=root and sound("GrassStep",root,.23)or nil if foot then foot.Looped=false end end
 if h and root and foot then
  local default=root:FindFirstChild("Running")if default then default.Volume=0 end
  local moving=h.MoveDirection.Magnitude>.1 and h.FloorMaterial~=Enum.Material.Air and h.Health>0 and not h.Sit and h:GetState()~=Enum.HumanoidStateType.Swimming
  local material=h.FloorMaterial local name=(material==Enum.Material.Wood or material==Enum.Material.WoodPlanks)and"WoodStep"or(material==Enum.Material.Grass or material==Enum.Material.LeafyGrass or material==Enum.Material.Ground or material==Enum.Material.Mud)and"GrassStep"or"StoneStep"
  local id=soundFolder[name].SoundId if foot.SoundId~=id then foot:Stop()foot.SoundId=id end foot.Looped=name~="GrassStep"
  foot.PlaybackSpeed=math.clamp(root.AssemblyLinearVelocity.Magnitude/14,.7,1.25)
  footTime+=step
  if moving then if foot.Looped then if not foot.IsPlaying then foot:Play()end elseif footTime>.42/foot.PlaybackSpeed then footTime=0 foot:Play()end elseif foot.IsPlaying then foot:Stop()end
 end
end)
