local Run=game:GetService("RunService")local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local world=workspace:WaitForChild("ForestWorld")
local localWorld=Instance.new("Folder")localWorld.Name="TreeWorldGardenEffects"localWorld.Parent=workspace
local rng=Random.new()local leaves={}local cap=UIS.TouchEnabled and 14 or 24
for i=1,cap do local p=Instance.new("Part")p.Name="FallingLeaf"p.Shape=Enum.PartType.Ball p.Size=Vector3.new(.23,.035,.43)p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=1 p.Parent=localWorld leaves[i]={part=p,birth=-100}end
local canopies={}local Collection=game:GetService("CollectionService")
local function tree(m)if m:IsA("Model")then canopies[m]=true end end
for _,m in ipairs(Collection:GetTagged("ForestTree"))do tree(m)end
Collection:GetInstanceAddedSignal("ForestTree"):Connect(tree)Collection:GetInstanceRemovedSignal("ForestTree"):Connect(function(m)canopies[m]=nil end)
local soundFolder=runtime:WaitForChild("GardenSounds")
local function sound(name,parent,volume)local s=soundFolder[name]:Clone()s.Parent=parent s.Volume=volume or s.Volume return s end
local birds=sound("Forest",game:GetService("SoundService"),.27)birds:Play()
local wind=sound("Wind",game:GetService("SoundService"),.12)wind:Play()
local river=sound("River",game:GetService("SoundService"),0)river:Play()
local rain=sound("Rain",game:GetService("SoundService"),0)rain:Play()
local foot local footChar local footTime=0
local rainRoot=Instance.new("Part")rainRoot.Name="LocalRainCeiling"rainRoot.Size=Vector3.new(35,.1,35)rainRoot.Anchored=true rainRoot.Transparency=1 rainRoot.CanCollide=false rainRoot.CanTouch=false rainRoot.CanQuery=false rainRoot.Parent=localWorld
local emitter=Instance.new("ParticleEmitter")emitter.Name="GentleRain"emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"emitter.Rate=0 emitter.Lifetime=NumberRange.new(.45,.65)emitter.Speed=NumberRange.new(32,40)emitter.EmissionDirection=Enum.NormalId.Bottom emitter.Size=NumberSequence.new(.045)emitter.Color=ColorSequence.new(Color3.fromRGB(191,224,228))emitter.Transparency=NumberSequence.new(.65)emitter.Acceleration=Vector3.new(4,-18,1)emitter.SpreadAngle=Vector2.new(4,4)emitter.Parent=rainRoot
local WindLines=require(runtime.WindEffects:WaitForChild("WindLines"))
WindLines:Init({Direction=workspace.GlobalWind.Unit,Speed=7,Lifetime=1.5,SpawnRate=UIS.TouchEnabled and 1 or 3})
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.RespectCanCollide=true
local scan,elapsed,spawnClock,leafIndex=0,0,0,0 local nearby={}
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt spawnClock+=dt if elapsed<1/18 then return end local step=elapsed elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position local now=workspace:GetServerTimeNow()
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if scan>1.2 then
  scan=0 table.clear(nearby)
  for m in pairs(canopies)do if m.Parent then local p=m:GetAttribute("ActualRootPoint")or m:GetPivot().Position if(Vector2.new(p.X-pos.X,p.Z-pos.Z)).Magnitude<24 then nearby[#nearby+1]=p end end end
  if #nearby>8 then while #nearby>8 do table.remove(nearby)end end
  if root then
   ray.FilterDescendantsInstances={world.Amenities,workspace.Terrain,world.Decor}
   local roof=workspace:Raycast(root.Position+Vector3.yAxis*2,Vector3.yAxis*24,ray)
   local raining=runtime:GetAttribute("Raining")
   emitter.Rate=raining and not roof and(UIS.TouchEnabled and 65 or 100)or 0
   Tween:Create(rain,TweenInfo.new(1),{Volume=raining and(roof and .035 or .14)or 0}):Play()
   local riverX=require(runtime.Scene).riverX(root.Position.Z)local riverWidth=require(runtime.Scene).riverWidth(root.Position.Z)
   local proximity=math.clamp(1-(math.abs(root.Position.X-riverX)-riverWidth)/40,0,1)
   local lake=world:GetAttribute("CentralLake")
   if lake then local r=math.sqrt(((root.Position.X-lake.X)/76)^2+((root.Position.Z-lake.Z)/52)^2)proximity=math.max(proximity,math.clamp((1.35-r)*2,0,1))end
   if math.abs(root.Position.Z)>295 then proximity=0 end
   Tween:Create(river,TweenInfo.new(1),{Volume=.24*proximity}):Play()
  end
 end
 rainRoot.CFrame=CFrame.new((root and root.Position or pos)+Vector3.yAxis*18)
 if spawnClock>.45 and #nearby>0 and runtime:GetAttribute("SeasonName")~="Inverno"then
  spawnClock=0 leafIndex=leafIndex%cap+1 local e=leaves[leafIndex]local p=nearby[rng:NextInteger(1,#nearby)]
  local focus=root and root.Position or pos
  local x=math.clamp(p.X,focus.X-10,focus.X+10)+rng:NextNumber(-3,3)local z=math.clamp(p.Z,focus.Z-10,focus.Z+10)+rng:NextNumber(-3,3)
  e.start=Vector3.new(x,focus.Y+rng:NextNumber(6,9),z)e.birth=now e.phase=rng:NextNumber(0,6.28)e.life=6

  e.part.Color=runtime:GetAttribute("SeasonName")=="Outono"and Color3.fromRGB(181,134,66)or Color3.fromRGB(128,153,93)e.part.Transparency=.12
 end
 for _,e in ipairs(leaves)do local age=now-e.birth if age< (e.life or 0)then local drift=Vector3.new(age*.25+math.sin(age*1.6+e.phase)*.4,-age*1.35,math.cos(age*1.2+e.phase)*.3)
  e.part.CFrame=CFrame.new(e.start+drift)*CFrame.Angles(age*.7,e.phase+age*.9,.3*math.sin(age*2))e.part.Transparency=.12+.88*math.clamp((age-e.life+1.5)/1.5,0,1)
 else e.part.Transparency=1 end end
 if c~=footChar then if foot then foot:Destroy()end footChar=c foot=root and sound("GrassStep",root,.055)or nil if foot then foot.Looped=false end end
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
