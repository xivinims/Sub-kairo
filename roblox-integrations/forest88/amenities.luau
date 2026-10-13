local Amenities={}
local Asset=game:GetService("AssetService")
local Collection=game:GetService("CollectionService")
local function strip(model)
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("LuaSourceContainer")or p:IsA("RemoteEvent")or p:IsA("RemoteFunction")or p:IsA("Camera")then p:Destroy()end
 end
end
local function bounds(model)
 local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(point)hi=hi:Max(point)
  end end end
 end end
 return lo,hi
end
local function normalize(model,rotation)
 model:PivotTo(rotation or CFrame.identity)
 local lo,hi=bounds(model)local base=Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)
 model:PivotTo(model:GetPivot()-base)model.PrimaryPart=nil model.WorldPivot=CFrame.identity
 return hi-lo
end
local function setParts(model,collide)
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  p.Anchored=true p.CanCollide=collide p.CanQuery=collide p.CanTouch=false
  p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 end end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
end
local function part(parent,name,size,cf,material,color,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Material=material p.Color=color
 p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
function Amenities.install(Scene)
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 local folder=Instance.new("Folder")folder.Name="Amenities"folder.Parent=world
 local bridges=Instance.new("Folder")bridges.Name="WoodenBridges"bridges.Parent=folder
 local stumps=Instance.new("Folder")stumps.Name="CutTrunks"stumps.Parent=folder
 local benches=Instance.new("Folder")benches.Name="LogBenches"benches.Parent=folder
 local lanterns=Instance.new("Folder")lanterns.Name="Lanterns"lanterns.Parent=folder
 local rawBridge=Asset:LoadAssetAsync(1352279393)strip(rawBridge)
 local bridgeTemplate=assert(rawBridge:FindFirstChildOfClass("Model"))
 local bridgeSize=normalize(bridgeTemplate)
 local rawStump=Asset:LoadAssetAsync(3070634312)strip(rawStump)
 local stumpTemplate=assert(rawStump:FindFirstChildOfClass("Model"))
 local stumpSize=normalize(stumpTemplate,CFrame.Angles(0,0,math.pi/2))
 local rawLantern=Asset:LoadAssetAsync(13557849262)strip(rawLantern)
 local lanternTemplate=assert(rawLantern:FindFirstChildOfClass("Model"))
 normalize(lanternTemplate,lanternTemplate:GetPivot().Rotation)
 lanternTemplate:ScaleTo(.47)
 for _,d in ipairs(lanternTemplate:GetDescendants())do if d:IsA("Light")then d:Destroy()end end
 local rawForest=Asset:LoadAssetAsync(6432306802)strip(rawForest)
 local logTemplate=assert(rawForest["Forest Pack"]:FindFirstChild("FallenTree"))
 local logSize=normalize(logTemplate)
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),params)end
 local function clearCircle(x,z,r)
  for _,f in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do
   for _,m in ipairs(f:GetChildren())do if m:IsA("Model")and(Vector2.new(m:GetPivot().X-x,m:GetPivot().Z-z)).Magnitude<r then m:Destroy()end end
  end
 end
 local lanternCount=0
 local function lantern(position,yaw,onPost)
  lanternCount+=1 local model=lanternTemplate:Clone()model.Name="ForestLantern"..lanternCount
  setParts(model,false)model:PivotTo(CFrame.new(position)*CFrame.Angles(0,yaw or 0,0))
  model:SetAttribute("SourceAssetId",13557849262)model.Parent=lanterns
  local glow=assert(model:FindFirstChild("Light",true))
  local light=Instance.new("PointLight")light.Name="WarmLanternLight"light.Color=Color3.fromRGB(255,199,128)light.Range=20 light.Brightness=0 light.Shadows=false light.Parent=glow
  Collection:AddTag(light,"ForestNightLight")
  if onPost then
   local h=assert(ground(position.X,position.Z))
   local postHeight=position.Y-h.Position.Y+.45
   local post=part(model,"TimberPost",Vector3.new(.48,postHeight,.48),CFrame.new(position.X,h.Position.Y+postHeight*.5-.1,position.Z+.85),Enum.Material.Wood,Color3.fromRGB(91,68,51),true)
   part(model,"LanternBracket",Vector3.new(.26,.24,1.35),CFrame.new(position.X,position.Y+1.42,position.Z+.45),Enum.Material.Metal,Color3.fromRGB(65,62,54),false)
   part(model,"HangingChain",Vector3.new(.06,.35,.06),CFrame.new(position.X,position.Y+1.48,position.Z),Enum.Material.Metal,Color3.fromRGB(65,62,54),false)
   model:SetAttribute("GroundPoint",h.Position)
  end
  return model
 end
 local function stretch(model,scale)
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   local cf=p.CFrame local rot=cf.Rotation
   local function axis(a)return Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)):Dot(scale)end
   p.Size*=Vector3.new(axis(cf.RightVector),axis(cf.UpVector),axis(cf.LookVector))
   p.CFrame=CFrame.new(cf.Position*scale)*rot
  end end
 end
 local bridgeReport={}
 for _,z in ipairs({-108,176})do
  local centre=Scene.riverX(z)
  local banks={}
  for _,side in ipairs({-1,1})do
   for distance=Scene.riverWidth(z)+2,120,2 do
    local x=centre+side*distance local h=ground(x,z)
    if h and h.Material~=Enum.Material.Water and h.Position.Y>Scene.RiverY+1.2 and h.Normal.Y>.72 then banks[#banks+1]=h.Position break end
   end
  end
  assert(#banks==2,"Both bridge banks must be dry")
  local left,right=banks[1],banks[2]
  local start=Vector3.new(left.X-4,left.Y+.55,z)local finish=Vector3.new(right.X+4,right.Y+.55,z)
  local direction=(finish-start).Unit local width=8.2 local length=(finish-start).Magnitude
  local up=(Vector3.yAxis-direction*direction:Dot(Vector3.yAxis)).Unit
  local cf=CFrame.fromMatrix((start+finish)*.5,direction,up,direction:Cross(up))
  local bridge=bridgeTemplate:Clone()bridge.Name="WoodenBridge"..(#bridgeReport+1)
  stretch(bridge,Vector3.new(length/bridgeSize.X,1,width/bridgeSize.Z))
  bridge:PivotTo(cf*CFrame.new(0,-1.05,0))setParts(bridge,false)bridge.Parent=bridges
  bridge:SetAttribute("SourceAssetId",1352279393)bridge:SetAttribute("DeckStart",start)bridge:SetAttribute("DeckEnd",finish)bridge:SetAttribute("DeckWidth",width)
  -- Add separate boards and a single floor so union collision cannot seal off the walkway.
  for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then p.Color=Color3.fromRGB(113,79,53)end end
  local boardCount=math.ceil(length/1.6)
  for i=1,boardCount do
   local t=(i-.5)/boardCount
   part(bridge,"DeckBoard",Vector3.new(length/boardCount-.055,.28,width-.9),cf*CFrame.new((t-.5)*length,-.14,0),Enum.Material.WoodPlanks,Color3.fromRGB(131+(i%3)*3,98+(i%3)*2,69+(i%3)*2),false)
  end
  local floor=part(bridge,"WalkwayCollision",Vector3.new(length+.50,.35,width-1.0),cf*CFrame.new(0,-.185,0),Enum.Material.WoodPlanks,Color3.fromRGB(115,83,57),true)floor.Transparency=1
  for _,side in ipairs({-1,1})do
   local rail=part(bridge,"RailingCollision",Vector3.new(length,2.7,.22),cf*CFrame.new(0,1.20,side*(width*.5-.35)),Enum.Material.Wood,Color3.fromRGB(105,74,51),true)rail.Transparency=1
  end
  for _,point in ipairs({start,finish})do
   clearCircle(point.X,point.Z,6)
   lantern(point+Vector3.new(0,4.2,width*.5+1),0,true)
   local h=assert(ground(point.X,point.Z))
   assert(h.Material~=Enum.Material.Water,"Bridge entrance submerged")
  end
  for _,f in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do
   for _,m in ipairs(f:GetChildren())do if m:IsA("Model")then local q=cf:PointToObjectSpace(m:GetPivot().Position)
    if math.abs(q.X)<length*.5+4 and math.abs(q.Z)<width*.5+3 then m:Destroy()end
   end end
  end
  -- Short piers descend into the bed, not floating at water level.
  for _,t in ipairs({.24,.5,.76})do for _,side in ipairs({-1,1})do
   local point=cf:PointToWorldSpace(Vector3.new((t-.5)*length,-.5,side*(width*.5-.6)))
   local height=point.Y-Scene.RiverY+7
   part(bridge,"WoodenPier",Vector3.new(.65,height,.65),CFrame.new(point.X,point.Y-height*.5,point.Z),Enum.Material.Wood,Color3.fromRGB(91,66,49),false)
  end end
  bridgeReport[#bridgeReport+1]={length=length,width=width,boards=boardCount,start={start.X,start.Y,start.Z},finish={finish.X,finish.Y,finish.Z}}
 end
 local rng=Random.new(881307)
 local function stump(x,z,height,name)
  local h=ground(x,z)if not h or h.Material==Enum.Material.Water or h.Normal.Y<.88 then return nil end
  local model=stumpTemplate:Clone()model.Name=name or "CutTrunk"model:ScaleTo(height/stumpSize.Y)
  local yaw=rng:NextNumber(0,math.pi*2)
  local low=h.Position.Y
  for _,off in ipairs({Vector2.new(-1,0),Vector2.new(1,0),Vector2.new(0,-1),Vector2.new(0,1)})do local a=ground(x+off.X,z+off.Y)if a then low=math.min(low,a.Position.Y)end end
  model:PivotTo(CFrame.new(x,low-.15,z)*CFrame.Angles(0,yaw,0))setParts(model,true)model.Parent=stumps
  model:SetAttribute("SourceAssetId",3070634312)model:SetAttribute("GroundPoint",h.Position)
  local lo,hi=bounds(model)model:SetAttribute("SeatTop",Vector3.new(x,hi.Y,z))return model
 end
 local stumpCount=0
 for i=1,90 do if stumpCount>=24 then break end
  local z=rng:NextNumber(-285,295)local x=Scene.pathX(z)+rng:NextNumber(12,45)*(i%2==0 and 1 or -1)
  local h=ground(x,z)
  if h and h.Material~=Enum.Material.Water and h.Normal.Y>.88 then clearCircle(x,z,3.3)if stump(x,z,rng:NextNumber(1.4,2.4))then stumpCount+=1 end end
 end
 local benchCount=0
 for _,z in ipairs({-275,-225,-165,-60,15,80,235,290})do
  local x=Scene.pathX(z)+11
  local hit=ground(x,z)
  if not hit or hit.Material==Enum.Material.Water or hit.Normal.Y<.87 then continue end
  clearCircle(x,z,8)
  local bench=logTemplate:Clone()bench.Name="LogBench"..(benchCount+1)bench:ScaleTo(10/logSize.X)
  local angle=math.pi*.5 local y=hit.Position.Y-.18
  for _,off in ipairs({Vector2.new(0,-5),Vector2.new(0,5)})do local h=ground(x+off.X,z+off.Y)if h then y=math.min(y,h.Position.Y-.18)end end
  bench:PivotTo(CFrame.new(x,y,z)*CFrame.Angles(0,angle,0))setParts(bench,true)bench.Parent=benches
  bench:SetAttribute("SourceAssetId",6432306802)bench:SetAttribute("SourceModel","FallenTree")bench:SetAttribute("GroundPoint",hit.Position)
  local meshRay=RaycastParams.new()meshRay.FilterType=Enum.RaycastFilterType.Include meshRay.FilterDescendantsInstances={bench}
  for _,side in ipairs({-1,1})do
   local point=bench:GetPivot():PointToWorldSpace(Vector3.new(side*2.3,0,0))
   local contact=workspace:Raycast(Vector3.new(point.X,y+8,point.Z),Vector3.new(0,-12,0),meshRay)
   local seat=Instance.new("Seat")seat.Name="LogSeat"seat.Size=Vector3.new(2,.2,1.6)
   seat.CFrame=CFrame.new(point.X,(contact and contact.Position.Y or y+1.9)+.025,point.Z)*CFrame.Angles(0,angle,0)
   seat.Anchored=true seat.Transparency=1 seat.CanCollide=false seat.CanQuery=false seat.CanTouch=false seat.Parent=bench
   local prompt=Instance.new("ProximityPrompt")prompt.Name="SitPrompt"prompt.ActionText="Sentar"prompt.ObjectText="Banco de tronco"prompt.HoldDuration=.2 prompt.MaxActivationDistance=7 prompt.RequiresLineOfSight=false prompt.Parent=seat
  end
  benchCount+=1 lantern(Vector3.new(x+2,hit.Position.Y+4.2,z+4),0,true)
 end
 for _,z in ipairs({-300,-245,-190,-125,-45,40,115,220,285})do
  local x=Scene.pathX(z)-7 local h=ground(x,z)
  if h and h.Material~=Enum.Material.Water and h.Normal.Y>.75 then clearCircle(x,z,2.2)lantern(h.Position+Vector3.new(0,4.2,0),0,true)end
 end
 -- The owner sits beside the entrance, facing the path, with real account clothes and accessories.
 local npcZ=-232 local npcX=Scene.pathX(npcZ)+10 local npcFloor=assert(ground(npcX,npcZ))
 for off=0,18,2 do local h=ground(npcX+off,npcZ)if h and h.Material~=Enum.Material.Water and h.Normal.Y>.9 then npcX+=off npcFloor=h break end end
 clearCircle(npcX,npcZ,8)
 local ownerStump=assert(stump(npcX,npcZ,2.05,"OwnerCutTrunk"),"NPC trunk requires dry level ground")
 local top=ownerStump:GetAttribute("SeatTop")
 local description=game.Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
 local npc=game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
 npc.Name="OwnerNPC"npc:SetAttribute("AvatarUserId",8344738123)npc:SetAttribute("AvatarUsername","ch_ckz2n")npc:SetAttribute("Seated",true)
 npc:SetAttribute("ShirtAssetId",description.Shirt)npc:SetAttribute("PantsAssetId",description.Pants)
 strip(npc)description:Destroy()
 local root=assert(npc:FindFirstChild("HumanoidRootPart"))npc.PrimaryPart=root
 local aim=Vector3.new(Scene.pathX(npcZ)-3,top.Y+1.2,npcZ-5)
 local npcCF=CFrame.lookAt(top+Vector3.new(0,1.12,0),aim)
 npc:PivotTo(npcCF)npc.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,p in ipairs(npc:GetDescendants())do if p:IsA("BasePart")then p.Anchored=p==root p.CanCollide=false p.CanQuery=true p.CanTouch=false p.Massless=true end end
 local hum=assert(npc:FindFirstChildOfClass("Humanoid"))hum.DisplayName="ch_ckz2n"hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.WalkSpeed=0 hum.JumpPower=0 hum.AutoRotate=false hum.BreakJointsOnDeath=false hum.MaxHealth=math.huge hum.Health=hum.MaxHealth
 for _,m in ipairs(npc:GetDescendants())do if m:IsA("Motor6D")then m:SetAttribute("OriginalC0",m.C0)end end
 npc:SetAttribute("SeatCFrame",npcCF)npc.Parent=world Collection:AddTag(npc,"ForestOwnerNPC")
 local prompt=Instance.new("ProximityPrompt")prompt.Name="TalkPrompt"prompt.ActionText="Conversar"prompt.ObjectText="ch_ckz2n"prompt.MaxActivationDistance=11 prompt.HoldDuration=0 prompt.RequiresLineOfSight=false prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=npc.Head
 local sound=Instance.new("Sound")sound.Name="HiVoice"sound.SoundId="rbxassetid://9059051593"sound.Volume=.28 sound.RollOffMinDistance=4 sound.RollOffMaxDistance=20 sound.RollOffMode=Enum.RollOffMode.InverseTapered sound.Parent=npc.Head
 local remote=Instance.new("RemoteEvent")remote.Name="OwnerDialogue"remote.Parent=runtime
 lantern(npcFloor.Position+Vector3.new(2.8,4.2,2.8),0,true)
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 world:SetAttribute("WoodenBridgeCount",#bridgeReport)world:SetAttribute("CutTrunkCount",stumpCount+1)world:SetAttribute("LogBenchCount",benchCount)world:SetAttribute("LanternCount",lanternCount)
 for _,raw in ipairs({rawBridge,rawStump,rawLantern,rawForest})do raw:Destroy()end
 return{bridges=bridgeReport,cutTrunks=stumpCount+1,logBenches=benchCount,lanterns=lanternCount,ownerAvatarUserId=8344738123,greetingAudio=9059051593}
end
return Amenities
