assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==91,"Published base changed")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
source(runtime,"ModuleScript","RuinMood",[============[local M={}
function M.weight(point,origin)local d=(Vector2.new(point.X-origin.X,point.Z-origin.Z)).Magnitude local t=math.clamp((72-d)/25,0,1)return t*t*(3-2*t)end
function M.apply(point,origin,mode,day)
 local L=game.Lighting local weight=M.weight(point,origin)local air=L:FindFirstChild("ForestAtmosphere")
 if not air then return end
 -- Absolute targets: repeated updates do not accumulate fog or darken the scene.
 air.Density=.24+.09*weight air.Haze=.65+.55*weight air.Offset=.16
 air.Color=Color3.fromRGB(184,201,194):Lerp(Color3.fromRGB(171,190,171),weight*.45)
 air.Glare=.12*(day or 1)
end
return M
]============])
source(runtime,"ModuleScript","RuinController",[============[local Controller={}
local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
function Controller.allowed(distance,alive,elapsed)return alive and distance<=10 and elapsed>=4 end
function Controller.start(runtime,world)
 local ruins=assert(world.Amenities:FindFirstChild("ForestRuins"))
 local last={}local sip={}
 local function actor(player)
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then return c,h,r end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  if seat:IsDescendantOf(world)then seat.SitPrompt.Triggered:Connect(function(player)
   local c,h,r=actor(player)if r and(r.Position-seat.Position).Magnitude<=9 and not seat.Occupant then seat:Sit(h)end
  end)end
 end
 local prompt=nil
 local function serve(player,sourcePrompt,seated)
  if not sourcePrompt then return false end
  local c,h,r=actor(player)if not r then return false end
  local now=os.clock()
  if not Controller.allowed((r.Position-sourcePrompt.Parent:GetPivot().Position).Magnitude,true,now-(last[player]or -math.huge))then return false end
  last[player]=now
  local backpack=player:FindFirstChildOfClass("Backpack")if not backpack then return false end
  for _,container in ipairs({c,backpack})do for _,item in ipairs(container:GetChildren())do
   if item:IsA("Tool")and item:GetAttribute("RuinTeaCup")then h:EquipTool(item)return true end
  end end
  local tool=runtime.TeaCupTool:Clone()tool.Name="Chá"tool:SetAttribute("RuinTeaCup",true)tool:SetAttribute("ServedToUserId",player.UserId)
  tool.Parent=backpack
  local bases={}local tweens={}local generation=0 local originalGrip=tool.Grip
  local function restore()
   generation+=1 if tool.Parent then tool.Grip=originalGrip end
   for _,t in ipairs(tweens)do t:Cancel()end table.clear(tweens)
   for joint,base in pairs(bases)do if joint.Parent then joint.C0=base end end table.clear(bases)
  end
  tool.Unequipped:Connect(restore)tool.Destroying:Connect(restore)
  tool.Activated:Connect(function()
   local model,hum,root=actor(player)
   if not model or tool.Parent~=model or tool:GetAttribute("ServedToUserId")~=player.UserId then return end
   local time=os.clock()if time-(sip[player]or -math.huge)<3 then return end sip[player]=time
   local original=originalGrip
   restore()local token=generation
   for _,joint in ipairs(model:GetDescendants())do if joint:IsA("Motor6D")then
    local shoulder=joint.Name=="RightShoulder"or joint.Name=="Right Shoulder"
    local elbow=joint.Name=="RightElbow"
    if shoulder or elbow then
     local base=joint.C0 bases[joint]=base
     local angle=shoulder and(hum.RigType==Enum.HumanoidRigType.R6 and 105 or 65)or 90
     local rotation=CFrame.Angles(math.rad(angle),0,math.rad(shoulder and -12 or 0))
     local goal=CFrame.new(base.Position)*rotation*base.Rotation
     local t=Tween:Create(joint,TweenInfo.new(.38,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=goal})tweens[#tweens+1]=t t:Play()
    end
   end end
   task.delay(1.1,function()
    if token~=generation or tool.Parent~=model then return end
    for joint,base in pairs(bases)do if joint.Parent then local t=Tween:Create(joint,TweenInfo.new(.45,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=base})tweens[#tweens+1]=t t:Play()end end
    task.delay(.5,function()if token==generation then restore()end end)
   end)
   local lift=Tween:Create(tool,TweenInfo.new(.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original*CFrame.new(.08,-.15,-.22)*CFrame.Angles(math.rad(-24),0,0)})tweens[#tweens+1]=lift lift:Play()
   
   task.delay(.9,function()if token==generation and tool.Parent==model then local back=Tween:Create(tool,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original})tweens[#tweens+1]=back back:Play()end end)
  end)
  task.delay(240,function()if tool.Parent then tool:Destroy()end end)
  h:EquipTool(tool)return true
 end
 for _,click in ipairs(Collection:GetTagged("TreeWorldCupClick"))do
  if click:IsDescendantOf(world)then click.MouseClick:Connect(function(player)serve(player,click,false)end)end
 end
 Players.PlayerRemoving:Connect(function(player)last[player]=nil sip[player]=nil end)
 return{serve=serve}
end
return Controller
]============])
source(runtime,"ModuleScript","Visuals",[============[local Lighting = game:GetService("Lighting")
local Visuals = {}
local Cycle=require(script.Parent:WaitForChild("Cycle"))
function Visuals.apply()
	-- Some Roblox runtime versions restrict renderer selection to Studio. The rest of the world must still initialise.
	pcall(function()Lighting.LightingStyle=Enum.LightingStyle.Realistic end)
	pcall(function()Lighting.PrioritizeLightingQuality=true end)
	Lighting.GlobalShadows = true Lighting.ShadowSoftness = 0.4
	Lighting.EnvironmentDiffuseScale = 1 Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.7 Lighting.ClockTime = Cycle.StartClock Lighting.GeographicLatitude = 28
	Lighting.ExposureCompensation = -0.10
	Lighting.Ambient = Color3.fromRGB(47, 56, 57) Lighting.OutdoorAmbient = Color3.fromRGB(99, 119, 121)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 9, 3) Lighting.ColorShift_Bottom = Color3.new()
	Lighting.FogColor = Color3.fromRGB(178, 199, 203) Lighting.FogStart = 200 Lighting.FogEnd = 1800
	local color = Lighting:FindFirstChild("ForestColor")
	if color then color.Enabled = true color.Brightness = 0.01 color.Contrast = 0.18 color.Saturation = 0.12 color.TintColor = Color3.fromRGB(255, 247, 230) end
	local rays = Lighting:FindFirstChild("ForestSunRays")
	if rays then rays.Enabled = true rays.Intensity = 0.075 rays.Spread = 0.727 end
	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then bloom.Enabled = false bloom.Intensity = 0.08 bloom.Size = 10 bloom.Threshold = 1.35 end
	local air = Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Density = 0.24 air.Offset = 0.16 air.Color = Color3.fromRGB(196, 215, 221) air.Decay = Color3.fromRGB(105, 137, 134) air.Haze = .65 air.Glare = 0.20 end
end
function Visuals.clock(clock)
	local day=Cycle.daylight(clock)local night=1-day
	local warm=math.max(0,1-math.min(math.abs(clock-6.8),math.abs(clock-17.4))/2.4)*day
	Lighting.ClockTime=clock Lighting.Brightness=1.4+1.3*day
	Lighting.ExposureCompensation=-.08-.08*night
	Lighting.Ambient=Color3.fromRGB(24,32,48):Lerp(Color3.fromRGB(49,57,58),day)
	Lighting.OutdoorAmbient=Color3.fromRGB(48,63,88):Lerp(Color3.fromRGB(100,120,123),day)
	local color=Lighting:FindFirstChild("ForestColor")
	if color then color.Contrast=.09+.03*day color.Saturation=.04+.08*day color.TintColor=Color3.fromRGB(201,219,255):Lerp(Color3.fromRGB(255,247,230),day):Lerp(Color3.fromRGB(255,222,181),warm*.38)end
	local rays=Lighting:FindFirstChild("ForestSunRays")if rays then rays.Intensity=(.055+.035*warm)*day end
	local air=Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Color=Color3.fromRGB(100,133,174):Lerp(Color3.fromRGB(196,215,221),day):Lerp(Color3.fromRGB(224,185,149),warm*.4)air.Glare=.20*day end
end
return Visuals
]============])
source(runtime,"ModuleScript","SeasonController",[============[local Controller={}
function Controller.start(runtime,world)
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local previousIndex=1 local busy=false local parts={}local lights={}
 local function record(model,kind)
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   local n=p.Name:lower()local vegetation=n:find("leaf",1,true)or n:find("leaves",1,true)or n:find("fern",1,true)or n:find("flower",1,true)or n:find("clover",1,true)
   if vegetation or kind=="plants"then
    local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
    parts[#parts+1]={part=p,appearance=appearance,base=p:GetAttribute("SeasonBaseColor")or p.Color,transparency=p:GetAttribute("SeasonBaseTransparency")or p.Transparency,kind=kind,flower=model.Name:lower():find("flower",1,true)~=nil,accent=model:GetAttribute("SpringBlossom")==true}
   end
  end end
 end
 for _,m in ipairs(world.Decor.Trees:GetChildren())do record(m,"trees")end
 for _,m in ipairs(world.Decor.Plants:GetChildren())do record(m,"plants")end
 local function surface(index)
  Terrain:SetMaterialColor(Enum.Material.Grass,index==3 and Color3.fromRGB(153,134,78)or index==2 and Color3.fromRGB(92,133,63)or Color3.fromRGB(98,139,66))
  if index~=4 and previousIndex~=4 then return end
  for bx=-512,384,128 do for bz=-512,384,128 do
   local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))
   local channels=Terrain:ReadVoxelChannels(region,4,{"SolidMaterial"})local grid=channels.SolidMaterial
   for ix=1,32 do for iz=1,32 do
    for iy=1,54 do local old=grid[ix][iy][iz]
     if old==Enum.Material.Grass or old==Enum.Material.LeafyGrass or old==Enum.Material.Snow then grid[ix][iy][iz]=index==4 and Enum.Material.Snow or Enum.Material.Grass end
    end
   end end
   Terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})task.wait()
  end end
 end
 local function apply(index,instant)
  if busy then return false end busy=true local name=Seasons.Names[index]
  runtime:SetAttribute("SeasonName",name)runtime:SetAttribute("SeasonIndex",index)runtime:SetAttribute("SeasonChanging",true)
  local changes={}
  for _,entry in ipairs(parts)do
   local p=entry.part
   if p.Parent then
    local base=entry.base local color=base
    if index==1 and entry.accent then color=Color3.fromRGB(215,170,186)
    elseif index==2 then color=base:Lerp(Color3.fromRGB(64,122,53),.12)
    elseif index==3 then color=base:Lerp(Color3.fromRGB(191,134,63),entry.flower and .22 or .72)
    elseif index==4 then color=base:Lerp(Color3.fromRGB(144,165,153),.50)end
    local hidden=index==4 and entry.kind=="plants"or index==3 and entry.flower
    changes[#changes+1]={entry=entry,from=p.Color,to=color,fromTransparency=p.Transparency,toTransparency=hidden and 1 or entry.transparency}
   end
  end
  -- Eighteen bounded updates avoid thousands of per-frame replicated server tweens on mobile.
  local frames=instant and 1 or 18
  for frame=1,frames do
   local t=instant and 1 or(frame-1)/(frames-1)local alpha=t*t*(3-2*t)
   for i,c in ipairs(changes)do local e=c.entry
    if e.part.Parent then local color=c.from:Lerp(c.to,alpha)e.part.Color=color e.part.Transparency=c.fromTransparency+(c.toTransparency-c.fromTransparency)*alpha
     if e.appearance and e.appearance.Parent then e.appearance.Color=color end
    end
    if i%250==0 then task.wait()end
   end
   if frame<frames then task.wait(Seasons.Transition/(frames-1))end
  end
  surface(index)
  runtime:SetAttribute("SeasonChanging",false)runtime:SetAttribute("SeasonRevision",(runtime:GetAttribute("SeasonRevision")or 0)+1)previousIndex=index busy=false return true
 end
 runtime:SetAttribute("SeasonEpoch",workspace:GetServerTimeNow())runtime:SetAttribute("SeasonSeconds",Seasons.Duration)
 -- Saved terrain is already spring; boot does not need to rewrite its geometry.
 runtime:SetAttribute("SeasonName","Primavera")runtime:SetAttribute("SeasonIndex",1)runtime:SetAttribute("SeasonRevision",0)runtime:SetAttribute("SeasonChanging",false)
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  if runtime:GetAttribute("SeasonTestMode")then return end
  elapsed+=dt if elapsed<2 then return end elapsed=0
  local index=Seasons.index(workspace:GetServerTimeNow(),runtime:GetAttribute("SeasonEpoch"))
  if not busy and index~=runtime:GetAttribute("SeasonIndex")then task.spawn(apply,index,false)end
 end)
 return{apply=apply,surface=surface,parts=#parts}
end
return Controller
]============])
local reports={}
reports.ruins=factory([============[local B={}
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
  for r=0,96,8 do for i=0,11 do local a=i*math.pi/6 local x,z=target.X+math.cos(a)*r,target.Y+math.sin(a)*r
   local lo,hi=math.huge,-math.huge
   for _,xx in ipairs({-18,0,18})do for _,zz in ipairs({-18,0,18})do local p=ground(x+xx,z+zz)lo=math.min(lo,p.Y)hi=math.max(hi,p.Y)end end
   local merit=hi-lo+r*.03 if lo>7 and hi-lo<8 and(not score or merit<score)then best=Vector3.new(x,hi+.18,z)score=merit end
  end end
  assert(best,"No walkable separated ruin site: "..m.Name)local original=m:GetAttribute("Origin")m:PivotTo(m:GetPivot()+best-original)m:SetAttribute("Origin",best)
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
]============]).install()
reports.bridges=factory([============[local B={}
local WOOD=Color3.fromRGB(141,111,78)local DARK=Color3.fromRGB(85,72,54)
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)
 local folder=world.Amenities.WoodenBridges folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),ray)).Position end
 local report={bridges=0,planks=0}
 local function p(parent,name,size,cf,color,collide)
  local v=Instance.new("Part")v.Name=name v.Size=size v.CFrame=cf v.Anchored=true v.Color=color or WOOD v.Material=Enum.Material.Wood v.CanCollide=collide~=false v.CanQuery=true v.CanTouch=false v.Parent=parent return v
 end
 for index,zc in ipairs({-108,176})do
  local cx=Scene.riverX(zc)local xa,xb=cx-10,cx+10
  while ground(xa,zc).Y<8.8 do xa-=2 end while ground(xb,zc).Y<8.8 do xb+=2 end
  xa-=2 xb+=2 local a,b=ground(xa,zc),ground(xb,zc)
  local m=Instance.new("Model")m.Name="WoodlandBridge"..index m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=folder
  m:SetAttribute("ReferenceStyle","Arched timber bridge, solid planks, carved posts and braces")
  local N=math.ceil((b-a).Magnitude/1.3)local W=8 local nodes={}
  local function point(t)return a:Lerp(b,t)+Vector3.yAxis*(.08+3*math.sin(math.pi*t))end
  for i=0,N do local v=point(i/N)nodes[#nodes+1]={v.X,v.Y,v.Z}end
  for i=1,N do local aa,bb=point((i-1)/N),point(i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local length=(bb-aa).Magnitude+.045
   p(m,"SolidDeckPlank",Vector3.new(W,.32,length),cf*CFrame.new(0,-.16,0),WOOD:Lerp(Color3.fromRGB(183,146,101),(i%4)*.055),true)report.planks+=1
   for _,s in ipairs({-1,1})do
    p(m,"TimberHandrail",Vector3.new(.32,.32,length),cf*CFrame.new(s*(W/2-.22),2.7,0),WOOD,true)
    p(m,"LowerRail",Vector3.new(.18,.18,length),cf*CFrame.new(s*(W/2-.22),1.15,0),DARK,true)
    if i%4==1 or i==N then
     local pos=cf:PointToWorldSpace(Vector3.new(s*(W/2-.22),0,0))local h=ground(pos.X,pos.Z)local height=pos.Y+2.9-h.Y+.3
     local post=p(m,"GroundedCarvedPost",Vector3.new(.7,height,.7),CFrame.new(pos.X,(pos.Y+2.9+h.Y-.3)*.5,pos.Z),DARK,true)post:SetAttribute("GroundPoint",h)
     p(m,"PostCap",Vector3.new(.92,.24,.92),CFrame.new(pos+Vector3.yAxis*3),WOOD,true)
     p(m,"CarvedBand",Vector3.new(.84,.16,.84),CFrame.new(pos+Vector3.yAxis*2.55),WOOD,true)
     if i>4 and i<N-3 then local lower=pos-Vector3.yAxis*1.2 local other=pos+cf.LookVector*2.7-Vector3.yAxis*.12
      p(m,"SupportBrace",Vector3.new(.42,.42,(other-lower).Magnitude),CFrame.lookAt((lower+other)*.5,other),DARK,true)
     end
    end
   end
  end
  for _,endpoint in ipairs({a,b})do p(m,"BankApron",Vector3.new(2.6,.25,W),CFrame.new(endpoint+Vector3.yAxis*-.06),WOOD,true)end
  m:SetAttribute("DeckStart",point(0))m:SetAttribute("DeckEnd",point(1))m:SetAttribute("DeckWidth",W)m:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))report.bridges+=1
 end
 local dock=world.Amenities.RiversideGarden.LakesideBoardwalk
 for _,v in ipairs(dock:GetDescendants())do if v:IsA("BasePart")then v.CanCollide=true v.CanQuery=true v.Transparency=0 end end
 return report
end
return B
]============]).install()
reports.tea=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 local reference=world.Amenities.ForestRuins.TeaCorner
 local chairTemplate=assert(reference:FindFirstChild("AntiqueTeaChair")):Clone()
 local cupTemplate=assert(reference:FindFirstChild("TeaCup")):Clone()
 local potTemplate=assert(reference:FindFirstChild("Teapot")):Clone()
 local targets={}
 for _,p in ipairs(C:GetTagged("TreeWorldTeaPrompt"))do if p:IsDescendantOf(world)then local corner=p.Parent.Parent.Parent if corner:FindFirstChild("AntiqueTeaTable")then targets[#targets+1]=corner end end end
 local report={tables=0,seats=0,cups=0}
 local function P(parent,name,size,cf,col,mat)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat or Enum.Material.SmoothPlastic p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Parent=parent return p
 end
 local function bottom(model)local low=math.huge for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then local h=(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5 low=math.min(low,p.Position.Y-h)end end return low end
 local function tabletop(table)local p=assert(table:FindFirstChild("table",true))return p.Position.Y+(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5 end
 for _,old in ipairs(targets)do
  local native=old.AntiqueTeaTable:Clone()local base=old.AntiqueTeaTable:GetPivot().Position local parent=old.Parent local name=old.Name
  local _,size=native:GetBoundingBox()native:ScaleTo(native:GetScale()*5.6/math.max(size.X,size.Z))native:PivotTo(CFrame.new(base))native:PivotTo(native:GetPivot()+Vector3.yAxis*(base.Y-bottom(native)))
  local corner=Instance.new("Model")corner.Name=name corner.Parent=parent native.Name="AntiqueTeaTable"native.Parent=corner native:SetAttribute("CompactTable",true)
  local top=tabletop(native)
  -- Imported cloth and ornaments are kept in proportion to a normal seated avatar.
  for _,p in ipairs(native:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=p.Name=="table"p.CanQuery=p.CanCollide p.CanTouch=false end end
  for i=0,3 do local angle=i*math.pi*.5 local position=base+Vector3.new(math.cos(angle)*3.8,0,math.sin(angle)*3.8)
   local chair=chairTemplate:Clone()chair:PivotTo(CFrame.lookAt(position,Vector3.new(base.X,position.Y,base.Z)))chair:PivotTo(chair:GetPivot()+Vector3.yAxis*(base.Y-bottom(chair)))chair.Parent=corner
   local seat=assert(chair:FindFirstChild("TeaSeat",true))
   local link=seat:FindFirstChild("TeaPrompt")if link then link:Destroy()end
   seat.CanTouch=false seat.CanCollide=false seat.Transparency=1 C:AddTag(seat,"RuinSeat")
   local prompt=seat:FindFirstChild("SitPrompt")prompt.ActionText="Sentar"prompt.ObjectText="Cadeira"report.seats+=1
   local cup=cupTemplate:Clone()cup.Name="TeaCup"cup:PivotTo(CFrame.new(base.X+math.cos(angle)*1.7,top+.025,base.Z+math.sin(angle)*1.7)*CFrame.Angles(0,-angle,0))cup:PivotTo(cup:GetPivot()+Vector3.yAxis*(top+.035-bottom(cup)))cup.Parent=corner
   for _,p in ipairs(cup:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=true p.CanCollide=false p.CanTouch=false end end
   local click=Instance.new("ClickDetector")click.Name="TakeCup"click.MaxActivationDistance=9 click.Parent=cup C:AddTag(click,"TreeWorldCupClick")report.cups+=1
  end
  local pot=potTemplate:Clone()local oldPrompt=pot:FindFirstChild("ServeTea",true)if oldPrompt then oldPrompt:Destroy()end
  pot:PivotTo(CFrame.new(base.X,top,base.Z))pot:PivotTo(pot:GetPivot()+Vector3.yAxis*(top+.03-bottom(pot)))pot.Parent=corner
  for _,p in ipairs(pot:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=false end end
  -- Two slim utensils and a small dessert plate; no enlarged props floating above the table.
  local plate=P(corner,"DessertPlate",Vector3.new(.07,.85,.85),CFrame.new(base.X,top+.06,base.Z-1.3)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(233,220,194))plate.Shape=Enum.PartType.Cylinder
  for j=0,2 do local cookie=P(corner,"Cookie",Vector3.new(.06,.28,.28),CFrame.new(base.X+(j-1)*.2,top+.12,base.Z-1.3)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(188,139,93))cookie.Shape=Enum.PartType.Cylinder end
  for _,s in ipairs({-1,1})do P(corner,"SilverSpoon",Vector3.new(.055,.025,.55),CFrame.new(base.X+s*1.6,top+.04,base.Z-.55),Color3.fromRGB(179,186,182),Enum.Material.Metal)end
  corner:SetAttribute("TeaTable",true)corner:SetAttribute("FloorY",base.Y)corner:SetAttribute("TableTopY",top)report.tables+=1 old:Destroy()
 end
 chairTemplate:Destroy()cupTemplate:Destroy()potTemplate:Destroy()
 local remote=runtime:FindFirstChild("RuinInteraction")if remote then remote:Destroy()end
 return report
end
return B
]============]).install()
reports.vegetation=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 for _,name in ipairs({"ForestGrassClient"})do local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild(name)if old then old:Destroy()end end
 for _,name in ipairs({"SkinnedGrassTemplates","GrassSampler","GrassPriority"})do local old=runtime:FindFirstChild(name)if old then old:Destroy()end end
 local terrainRay=RaycastParams.new()terrainRay.FilterType=Enum.RaycastFilterType.Include terrainRay.FilterDescendantsInstances={workspace.Terrain}terrainRay.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),terrainRay)end
 local report={trees=0,plants=0,rootProbes=0,removedPlants=0,removedDecor=0}
 local probeFolder=Instance.new("Folder")probeFolder.Name="ActualRootContacts"probeFolder.Parent=runtime
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,p in ipairs(folder:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=true end end end
 task.wait(.15)
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,m in ipairs(folder:GetChildren())do
  local tree=folder==world.Decor.Trees local parts={}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Name~="TrunkCollision"and(tree and p.Name:lower():find("trunk",1,true)or not tree)then
   parts[#parts+1]=p p.CanQuery=true
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(point)hi=hi:Max(point)end end end
  end end
  local own=RaycastParams.new()own.FilterType=Enum.RaycastFilterType.Include own.FilterDescendantsInstances=parts
  local samples={}local minimum=math.huge
  -- Sample the actual placed mesh from below. Source scale attributes are not trusted.
  local n=tree and 13 or 5
  for ix=0,n-1 do for iz=0,n-1 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/n local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/n
   local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)
   if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
  end end
  if tree and minimum>lo.Y+1 then
   for ix=0,30 do for iz=0,30 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/31 local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/31
    local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
   end end
  end
  local contacts={}
  for _,v in ipairs(samples)do if v.Y<minimum+(tree and .75 or .3)then contacts[#contacts+1]=v end end
  if #contacts==0 and not tree then
   -- Flat alpha cards can have no underside for an upward ray; use the actual placed mesh bounds for these plants.
   contacts={Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)}m:SetAttribute("GroundingMethod","PlacedMeshBounds")
  else m:SetAttribute("GroundingMethod","PlacedMeshRaycast")end
  assert(#contacts>0,"No real base geometry: "..m.Name)
  local shift=math.huge local center=Vector3.zero local depth=tree and .9 or .18
  for _,point in ipairs(contacts)do local h=assert(ground(point.X,point.Z),"No ground beneath visible root")shift=math.min(shift,h.Position.Y-point.Y-depth)center+=point end
  center/= #contacts m:PivotTo(m:GetPivot()+Vector3.yAxis*shift)
  local finalCenter=center+Vector3.yAxis*shift m:SetAttribute("ActualRootPoint",finalCenter)m:SetAttribute("RootEmbedDepth",depth)
  local entry=Instance.new("ObjectValue")entry.Name="RootContact"entry.Value=m entry.Parent=probeFolder
  local cf=m:GetPivot()
  for i,point in ipairs(contacts)do local v=Instance.new("Vector3Value")v.Name=tostring(i)v.Value=cf:PointToObjectSpace(point+Vector3.yAxis*shift)v.Parent=entry report.rootProbes+=1 end
  if tree then
   C:AddTag(m,"ForestTree")report.trees+=1
   local trunk=m:FindFirstChild("TrunkCollision")if trunk then local h=assert(ground(finalCenter.X,finalCenter.Z))trunk.CFrame=CFrame.new(finalCenter.X,h.Position.Y+trunk.Size.X*.5-.15,finalCenter.Z)*CFrame.Angles(0,0,math.pi*.5)end
  else report.plants+=1 end
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")then p.RenderFidelity=Enum.RenderFidelity.Performance p.CastShadow=tree
   if not p.CanCollide then p.CanQuery=false end
   if p:GetAttribute("ForestRestCF")then p:SetAttribute("ForestRestCF",p.CFrame)end
  end end
 end end
 -- Dense leaf carpets and oversized broad weeds are removed; native grass supplies continuous cover.
 for _,m in ipairs(world.Decor.Plants:GetChildren())do
  if m.Name=="DenseLeafPatch"or m.Name=="CloverPatch"then m:Destroy()report.removedPlants+=1 end
 end
 for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()local h=ground(cf.X,cf.Z)if h then m:PivotTo(m:GetPivot()+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end end
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local pivot=m:GetPivot()local h=ground(pivot.X,pivot.Z)
  if h and h.Position.Y>6 then local cf,size=m:GetBoundingBox()m:PivotTo(pivot+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end
 end
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())runtime:SetAttribute("GrassRenderer","NativeTerrain")runtime:SetAttribute("GrassMotionEnabled",false)
 return report
end
return B
]============]).install()
reports.camps=factory([============[local B={}
function B.install()
 local C=game:GetService("CollectionService")local camps=workspace.ForestWorld.Amenities.SeasonalDetails.Camps
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function floor(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)).Position end
 local function part(parent,name,size,cf,col,mat,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat p.Anchored=true p.CanCollide=collide p.CanTouch=false p.CanQuery=collide p.Parent=parent return p
 end
 local report={camps=0,stones=0}
 for _,camp in ipairs(camps:GetChildren())do local core=camp:FindFirstChild("FireCore",true)
  if core then local center=floor(core.Position.X,core.Position.Z)core.CFrame=CFrame.new(center+Vector3.yAxis*.25)
   for _,p in ipairs(camp:GetDescendants())do if p.Name=="FireRingStone"or p.Name=="Firewood"then p:Destroy()end end
   local char=part(camp,"CharredGround",Vector3.new(.03,4.5,4.5),CFrame.new(center+Vector3.yAxis*.025)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(55,48,37),Enum.Material.Slate,false)char.Shape=Enum.PartType.Cylinder
   for i=0,11 do local a=i*math.pi/6 local gp=floor(center.X+math.cos(a)*2,center.Z+math.sin(a)*2)
    local p=part(camp,"GroundedFireStone",Vector3.new(.9,.6,.8),CFrame.new(gp+Vector3.yAxis*.18)*CFrame.Angles(.12,a,.1),Color3.fromRGB(116+(i%3)*6,114+(i%3)*6,104),Enum.Material.Slate,true)p:SetAttribute("GroundPoint",gp)report.stones+=1
   end
   for i=0,3 do local p=part(camp,"SplitFireLog",Vector3.new(2.8,.38,.42),CFrame.new(center+Vector3.yAxis*(.25+i*.075))*CFrame.Angles(0,i*math.pi/4,.08),Color3.fromRGB(91,68,46),Enum.Material.Wood,false)p.Shape=Enum.PartType.Cylinder end
   local fire=core:FindFirstChildOfClass("Fire")if fire then fire.Size=2.8 fire.Heat=4 C:AddTag(fire,"RuinVFX")end
   for i=0,7 do local a=i*math.pi/4 local gp=floor(center.X+math.cos(a)*2.8,center.Z+math.sin(a)*2.8)
    local ash=part(camp,"ScatteredAsh",Vector3.new(.25,.03,.2),CFrame.new(gp+Vector3.yAxis*.025),Color3.fromRGB(100,93,75),Enum.Material.Slate,false)
   end
   report.camps+=1
  end
 end
 return report
end
return B
]============]).install()
reports.animals=factory([============[local B={}
function B.install()
 local runtime=game.ReplicatedStorage.ForestRuntime
 if runtime:FindFirstChild("CuteAnimalTemplates")then runtime.CuteAnimalTemplates:Destroy()end
 if workspace.ForestWorld.Amenities:FindFirstChild("CuteAnimalRoutes")then workspace.ForestWorld.Amenities.CuteAnimalRoutes:Destroy()end
 local raw=game:GetService("AssetService"):LoadAssetAsync(77173958514594)
 local templates=Instance.new("Folder")templates.Name="CuteAnimalTemplates"templates.Parent=game.ReplicatedStorage.ForestRuntime
 local routes=Instance.new("Folder")routes.Name="CuteAnimalRoutes"routes.Parent=workspace.ForestWorld.Amenities
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function floor(x,z)local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),rp)return h and h.Position.Y>8 and h.Normal.Y>.78 and h.Position or nil end
 for _,name in ipairs({"Conejo","Zorro"})do
  local m=assert(raw:FindFirstChild(name)):Clone()
  for _,d in ipairs(m:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("JointInstance")or d:IsA("Constraint")or d:IsA("Humanoid")or d:IsA("RemoteEvent")then d:Destroy()end end
  m:PivotTo(CFrame.identity)
  local delta=m.Head.Position-m.Torso.Position local forward=Vector3.new(delta.X,0,delta.Z)
  if forward.Magnitude>.1 then local rot=CFrame.lookAt(Vector3.zero,forward).Rotation:Inverse()for _,part in ipairs(m:GetDescendants())do if part:IsA("BasePart")then part.CFrame=rot*part.CFrame end end end
  local bottom=math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false bottom=math.min(bottom,p.Position.Y-(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5)end end
  m:PivotTo(m:GetPivot()-Vector3.yAxis*bottom)m.PrimaryPart=nil m.WorldPivot=CFrame.identity m:SetAttribute("SourceAssetId",77173958514594)m.Parent=templates
 end
 raw:Destroy()
 local count=0 local centers={{-145,-120},{-115,170},{105,-80},{110,0},{-230,90},{-120,-210}}
 local collision=RaycastParams.new()collision.FilterType=Enum.RaycastFilterType.Include collision.FilterDescendantsInstances={workspace.Terrain,workspace.ForestWorld.Decor,workspace.ForestWorld.Amenities}collision.RespectCanCollide=true collision.IgnoreWater=true
 for i,center in ipairs(centers)do
  local points={}
  for attempt=0,24 do
   points={}local shift=attempt*2.4 local cx=center[1]+math.cos(attempt*2.4)*shift local cz=center[2]+math.sin(attempt*2.4)*shift
   for j=0,31 do local a=j*math.pi*2/32 local p=floor(cx+math.cos(a)*9,cz+math.sin(a)*7)
    if not p then points={}break end points[#points+1]={p.X,p.Y+.03,p.Z}
   end
   if #points==32 then
    for j=1,32 do local a=Vector3.new(unpack(points[j]))local b=Vector3.new(unpack(points[j%32+1]))
     for _,height in ipairs({.6,1.2})do if workspace:Raycast(a+Vector3.yAxis*height,b-a,collision)then points={}break end end
     if #points==0 then break end
    end
   end
   if #points==32 then break end
  end
  if #points==32 then local r=Instance.new("StringValue")r.Name="AnimalRoute"r.Value=game:GetService("HttpService"):JSONEncode(points)r:SetAttribute("Species",i%2==0 and "Zorro"or"Conejo")r:SetAttribute("Speed",i%2==0 and 1.8 or 1.1)r:SetAttribute("Phase",i*7)r.Parent=routes count+=1 end
 end
 assert(count>=4,"Insufficient dry animal routes")return{animals=count,sourceAssetId=77173958514594}
end
return B
]============]).install()
local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestAmbienceClient")if old then old:Destroy()end
workspace.ForestWorld:SetAttribute("UpgradeVersion",92)
source(game.ServerScriptService,"Script","ForestServer",[============[local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Visuals=require(runtime:WaitForChild("Visuals"))Visuals.apply()
local Cycle=require(runtime:WaitForChild("Cycle"))
runtime:SetAttribute("CycleEpoch",Cycle.epoch(workspace:GetServerTimeNow()))
runtime:SetAttribute("CycleSeconds",Cycle.Duration)
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
require(runtime:WaitForChild("GardenWeather")).start(runtime,world)
require(runtime:WaitForChild("SeasonController")).start(runtime,world)
require(runtime:WaitForChild("RuinController")).start(runtime,world)
local Collection=game:GetService("CollectionService")
for _,seat in ipairs(world.Amenities.LogBenches:GetDescendants())do if seat:IsA("Seat")then
	local prompt=seat:FindFirstChild("SitPrompt")
	if prompt then prompt.Triggered:Connect(function(player)
		local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r and not seat.Occupant and(r.Position-seat.Position).Magnitude<9 then seat:Sit(h)end
	end)end
end end
local function character(player, model)
	local humanoid = model:WaitForChild("Humanoid", 10) local root = model:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= model then return end
	root.Anchored = false humanoid.PlatformStand = false humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16 humanoid.UseJumpPower = true humanoid.JumpPower = 50
	if (root.Position - spawnCF.Position).Magnitude > 28 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero end
end
local function playerAdded(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(model) character(player, model) end)
	if player.Character then task.spawn(character, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt if elapsed < 1 then return end elapsed = 0
	local time = workspace:GetServerTimeNow()
	local clock=Cycle.clock(time,runtime:GetAttribute("CycleEpoch"))Visuals.clock(clock)
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.7 end
	local strength = 2.8 + math.sin(time * 0.047) * 0.25 + math.sin(time * 0.023) * 0.15
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestGardenClient",[============[local Run=game:GetService("RunService")local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local world=workspace:WaitForChild("ForestWorld")
local localWorld=Instance.new("Folder")localWorld.Name="TreeWorldGardenEffects"localWorld.Parent=workspace
local rng=Random.new()local leaves={}local cap=UIS.TouchEnabled and 14 or 24
for i=1,cap do local p=Instance.new("Part")p.Name="FallingLeaf"p.Shape=Enum.PartType.Ball p.Size=Vector3.new(.23,.035,.43)p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=1 p.Parent=localWorld leaves[i]={part=p,birth=-100}end
local canopies={}local Collection=game:GetService("CollectionService")
local function tree(m)if m:IsA("Model")then canopies[m]=true end end
for _,m in ipairs(Collection:GetTagged("ForestTree"))do tree(m)end
Collection:GetInstanceAddedSignal("ForestTree"):Connect(tree)Collection:GetInstanceRemovedSignal("ForestTree"):Connect(function(m)canopies[m]=nil end)
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
 for _,e in ipairs(entries)do
  local distance=(e.nodes[1]-pos).Magnitude
  if distance<(UIS.TouchEnabled and 46 or 70) then if not e.model then activate(e)end
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
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestRuinClient",[============[local Players=game:GetService("Players")local C=game:GetService("CollectionService")local Run=game:GetService("RunService")
local player=Players.LocalPlayer local effects={}
local old=player:WaitForChild("PlayerGui"):FindFirstChild("RuinTeaNotice")if old then old:Destroy()end
local function bind(v)if v:IsA("Beam")or v:IsA("ParticleEmitter")or v:IsA("Fire")then effects[v]=true end end
for _,v in ipairs(C:GetTagged("RuinVFX"))do bind(v)end
C:GetInstanceAddedSignal("RuinVFX"):Connect(bind)C:GetInstanceRemovedSignal("RuinVFX"):Connect(function(v)effects[v]=nil end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)elapsed+=dt if elapsed<.6 then return end elapsed=0
 local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")if not root then return end
 for v in pairs(effects)do if v.Parent then local parent=v.Parent local point=parent:IsA("Attachment")and parent.WorldPosition or parent:IsA("BasePart")and parent.Position
  if point then v.Enabled=(point-root.Position).Magnitude<55 end else effects[v]=nil end end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestCycleClient",[============[local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Cycle=require(runtime:WaitForChild("Cycle"))local Visuals=require(runtime:WaitForChild("Visuals"))
local Seasons=require(runtime:WaitForChild("Seasons"))
local Mood=require(runtime:WaitForChild("RuinMood"))local player=game.Players.LocalPlayer
Visuals.apply()
local lights={}local function added(light)if light:IsA("PointLight")then lights[light]=true end end
for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do added(light)end
local addConnection=Collection:GetInstanceAddedSignal("ForestNightLight"):Connect(added)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestNightLight"):Connect(function(light)lights[light]=nil end)
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<1/10 then return end elapsed=0
 local epoch=runtime:GetAttribute("CycleEpoch")if not epoch then return end
 local clock=Cycle.clock(workspace:GetServerTimeNow(),epoch)Visuals.clock(clock)
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 if root then Seasons.visual(root.Position,Cycle.daylight(clock))end
 local origin=runtime:GetAttribute("RuinOrigin")
 if root and origin then
  local closest=origin local distance=(root.Position-origin).Magnitude
  local json=runtime:GetAttribute("RuinOrigins")
  if json then for _,v in ipairs(game:GetService("HttpService"):JSONDecode(json))do local p=Vector3.new(unpack(v))local d=(root.Position-p).Magnitude if d<distance then closest=p distance=d end end end
  Mood.apply(root.Position,closest,"Neblina",Cycle.daylight(clock))
 end
 local night=Cycle.night(clock)
 for light in pairs(lights)do if light.Parent then light.Enabled=night>.015 light.Brightness=night*1.7 else lights[light]=nil end end
end)
script.Destroying:Connect(function()connection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()table.clear(lights)end)
]============])
run(game.ServerScriptService.ForestServer.Source)
reports.tests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
assert(world:GetAttribute("UpgradeVersion")==92)
local report={trees=0,plants=0,actualRootProbes=0,walkProbes=0,teaTables=0,teaCups=0,ruins=4,audio=0}
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestGrassClient")and not runtime:FindFirstChild("SkinnedGrassTemplates"),"Skeletal spike grass remains")
assert(runtime:GetAttribute("GrassRenderer")=="NativeTerrain")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray))end
for _,entry in ipairs(runtime.ActualRootContacts:GetChildren())do local m=entry.Value if m and m:IsDescendantOf(world)then local cf=m:GetPivot()
 for _,point in ipairs(entry:GetChildren())do local p=cf:PointToWorldSpace(point.Value)local h=ground(p.X,p.Z)assert(p.Y-h.Position.Y<-.12,"Visible root remains above the soil: "..m.Name)report.actualRootProbes+=1 end
 if m.Parent==world.Decor.Trees then report.trees+=1 else report.plants+=1 end end end
assert(report.trees>300 and report.plants>700 and report.actualRootProbes>1000)
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={bridge}rp.RespectCanCollide=true
 for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide and p.CanQuery,"Bridge has an invisible or non-solid part")end end
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5,.95})do local center=a:Lerp(b,t)
   for _,offset in ipairs({-3,0,3})do local p=center+Vector3.zAxis*offset local hit=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,rp),"Bridge has a walking gap")assert(hit.Instance.Name=="SolidDeckPlank"or hit.Instance.Name=="BankApron")assert(math.abs(hit.Position.Y-center.Y)<.18,"Bridge collision disagrees with visible deck")report.walkProbes+=1 end
  end
 end
 for _,i in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[i]))assert(math.abs(ground(p.X,p.Z).Position.Y-p.Y)<.2,"Bridge shifted off the bank")end
end
assert(not world.Amenities.ForestRuins:FindFirstChild("EntrancePath"))
local positions={world.Amenities.ForestRuins:GetAttribute("Origin")}
for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do positions[#positions+1]=m:GetAttribute("Origin")end
for i=1,#positions do for j=i+1,#positions do assert((Vector2.new(positions[i].X,positions[i].Z)-Vector2.new(positions[j].X,positions[j].Z)).Magnitude>160,"Ruins still overlap")end end
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do if click:IsDescendantOf(world)then assert(click:IsA("ClickDetector")and click.MaxActivationDistance==9)report.teaCups+=1 end end
for _,m in ipairs(world:GetDescendants())do if m:IsA("Model")and m.Name=="AntiqueTeaTable"then local cf,size=m:GetBoundingBox()assert(size.X<6 and size.Z<6 and size.Y<4,"Tea table still enormous")report.teaTables+=1 end
 assert(m.Name~="MoodPrompt"and m.Name~="ServeTea","Old tea interaction or mood selection remains")
end assert(report.teaTables==4 and report.teaCups==16)
for _,seat in ipairs(C:GetTagged("RuinSeat"))do if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
 local table=seat.Parent.Parent.AntiqueTeaTable local center=table:GetPivot().Position local direction=Vector3.new(center.X-seat.Position.X,0,center.Z-seat.Position.Z).Unit
 assert(seat.CFrame.LookVector:Dot(direction)>.95,"Compact tea chair faces away from table")
end end
local desc=Instance.new("HumanoidDescription")local actor=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)desc:Destroy()actor.Name="TeaTest"actor.Parent=workspace
local click=C:GetTagged("TreeWorldCupClick")[1]local cupPoint=click.Parent:GetPivot().Position actor:PivotTo(CFrame.new(cupPoint+Vector3.yAxis*2))actor.HumanoidRootPart.Anchored=true
local bag=Instance.new("Backpack")bag.Parent=game.ServerStorage local mock={Character=actor,Backpack=bag,UserId=1092}
function mock:FindFirstChildOfClass(name)if name=="Backpack"then return bag end end
local service=require(runtime.RuinController).start(runtime,world)
assert(service.serve(mock,click,false),"Direct cup click failed to serve")assert(actor:FindFirstChildOfClass("Tool"),"Clicked cup did not reach the hand")
actor:Destroy()bag:Destroy()report.directCupServe=true
assert(not runtime:FindFirstChild("RuinInteraction")and not game.StarterPlayer.StarterPlayerScripts.ForestRuinClient.Source:find('TextLabel',1,true))
local Mood=require(runtime.RuinMood)local origin=positions[1]for _=1,60 do Mood.apply(origin,origin,"Neblina",1)end
assert(game.Lighting.ForestAtmosphere.Density<.35 and game.Lighting.ForestAtmosphere.Haze<1.3,"Fog accumulates")Mood.apply(origin+Vector3.xAxis*200,origin,"Neblina",1)assert(math.abs(game.Lighting.ForestAtmosphere.Density-.24)<.001)
for _,s in ipairs(runtime.GardenSounds:GetChildren())do game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Missing forest audio")report.audio+=1 end
assert(game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find('root,.055',1,true))
local water=RaycastParams.new()water.FilterType=Enum.RaycastFilterType.Include water.FilterDescendantsInstances={workspace.Terrain}
local Scene=require(runtime.Scene)for z=-288,288,8 do local h=assert(workspace:Raycast(Vector3.new(Scene.riverX(z),200,z),Vector3.yAxis*-300,water))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.1,"River altered by repairs")end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do for _,s in ipairs(parent:GetChildren())do if s:IsA("LuaSourceContainer")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,v=pcall(require,m)m:Destroy()assert(ok,tostring(v))compiled+=1 end end end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,v=pcall(require,s)assert(ok,tostring(v))compiled+=1 end end
report.compiled=compiled report.noTeaPopups=true report.fogStable=true report.nativeGrassRequested=true report.parts=0 report.pbr=0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then report.parts+=1 end if p:IsA("SurfaceAppearance")then report.pbr+=1 end assert(not p:IsA("LuaSourceContainer"))end
assert(report.parts<10534 and report.pbr>2500,"Forest loss or mobile geometry increase")
return report
]============])
runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)
local result=factory([============[local E={}
function E.build()
 local roots={}local manifest={}
 for _,name in ipairs({"Workspace","ReplicatedStorage","ServerScriptService","StarterPlayer","StarterGui","StarterPack","ReplicatedFirst","Lighting","SoundService","MaterialService","Teams","TextChatService"})do
  for _,obj in ipairs(game:GetService(name):GetChildren())do
   if obj.Archivable and not obj:IsA("Camera")and obj.Name~="TerrainRegion"then
    roots[#roots+1]=obj manifest[#manifest+1]={name=obj.Name,class=obj.ClassName,service=name}
   end
  end
 end
 local properties={}
 local lists={Workspace={"Gravity","GlobalWind","FallenPartsDestroyHeight"},StarterPlayer={"CameraMinZoomDistance","CameraMaxZoomDistance","CameraMode","CharacterWalkSpeed","CharacterJumpPower","CharacterUseJumpPower","AutoJumpEnabled","EnableMouseLockOption"},Lighting={"LightingStyle","PrioritizeLightingQuality","GlobalShadows","ShadowSoftness","Brightness","ClockTime","GeographicLatitude","Ambient","OutdoorAmbient","EnvironmentDiffuseScale","EnvironmentSpecularScale","ExposureCompensation"},MaterialService={"Use2022Materials"}}
 for service,names in pairs(lists)do for _,name in ipairs(names)do local ok,v=pcall(function()return game:GetService(service)[name]end)
  if ok then local kind=typeof(v)local row={service=service,name=name}
   if kind=="boolean"or kind=="number"then row.kind=kind row.value=v
   elseif kind=="EnumItem"then row.kind="enum"row.value=v.Value
   elseif kind=="Vector3"then row.kind="vector"row.value={v.X,v.Y,v.Z}
   elseif kind=="Color3"then row.kind="color"row.value={v.R,v.G,v.B}end
   if row.kind then properties[#properties+1]=row end
  end
 end end
 local payload=game:GetService("SerializationService"):SerializeInstancesAsync(roots)
 return{binaryPlaceBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(payload)),serviceRoots=manifest,serviceProperties=properties,exportSize=buffer.len(payload)}
end
return E
]============]).build()result.report=reports result.baseVersion=91 result.expectedVersion=92 result.exportOnly=true result.staged=true return result
