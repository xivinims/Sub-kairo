assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==89,"Published base changed")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local value=require(m)m:Destroy()return value end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime
source(runtime,"ModuleScript","Seasons",[============[local Seasons={Names={"Primavera","Verao","Outono","Inverno"},Duration=600,Transition=35}
function Seasons.index(now,epoch)return math.floor(math.max(0,now-epoch)/Seasons.Duration)%4+1 end
function Seasons.at()
 local runtime=game.ReplicatedStorage:FindFirstChild("ForestRuntime")return runtime and(runtime:GetAttribute("SeasonName")or "Primavera")or "Primavera"
end
function Seasons.isGreen()return Seasons.at()~="Inverno"end
function Seasons.progress(now,epoch)return math.max(0,now-epoch)%Seasons.Duration/Seasons.Duration end
function Seasons.visual(_,day)
 local name=Seasons.at()local air=game.Lighting:FindFirstChild("ForestAtmosphere")local color=game.Lighting:FindFirstChild("ForestColor")
 if not air or not color then return end
 local winter=name=="Inverno"local autumn=name=="Outono"
 air.Density=winter and .31 or .265 air.Haze=winter and 1.35 or 1.05
 color.TintColor=color.TintColor:Lerp(winter and Color3.fromRGB(225,239,249)or autumn and Color3.fromRGB(255,235,204)or Color3.fromRGB(247,251,235),.25*day)
 color.Saturation+=(winter and -.05 or autumn and .025 or .015)
end
return Seasons
]============])
source(runtime,"ModuleScript","Scene",[============[local Seasons=require(script.Parent:WaitForChild("Seasons"))
local Scene = {Minimum = -512, Maximum = 512, Spacing = 4, RiverY = 6, SeaY = 6, Seed = 20261013}
local function smooth(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end
local function gaussian(x, z, cx, cz, radius)
	return math.exp(-((x - cx)^2 + (z - cz)^2) / radius^2)
end
function Scene.riverX(z)
	return 38 * math.sin(z / 115) + 22 * math.sin(z / 57 + 0.7)
end
function Scene.riverWidth(z)
	return 13 + 3 * math.sin(z / 92)^2 + 7 * gaussian(0, z, 0, 150, 64)
end
function Scene.pathX(z)
	return -110 + 47 * math.sin((z + 140) / 140) + 16 * math.sin(z / 62)
end
function Scene.pathDistance(x, z)
	local main = math.abs(x - Scene.pathX(z))
	local east = math.abs(x - (145 + 30 * math.sin(z / 100)))
	local crossing = math.min(math.abs(z + 108), math.abs(z - 176))
	if x > -170 and x < 210 then main = math.min(main, crossing) end
	return math.min(main, east)
end
function Scene.sample(x, z)
	local r = math.sqrt((x / 442)^2 + (z / 405)^2)
	local shore = r + math.noise(x / 95, z / 95, 7) * 0.045
	local interior = 1 - smooth(0.75, 1.05, shore)
	local hill = 70 * gaussian(x, z, 220, 228, 114) + 43 * gaussian(x, z, -256, -174, 128)
		+ 31 * gaussian(x, z, -275, 177, 110) + 24 * gaussian(x, z, 274, -184, 116)
	local detail = 3.1 * math.noise(x / 75, z / 75, 3.17) + 1.5 * math.noise(x / 23, z / 23, 12.47)
	local height = -12 + interior * (29 + hill + detail)
	local rd = math.abs(x - Scene.riverX(z))
	local rw = Scene.riverWidth(z)
	local riverInfluence = (1 - smooth(rw - 2, rw + 28, rd)) * (1 - smooth(337, 401, math.abs(z)))
	local bed = Scene.RiverY - 6.5 + math.noise(x / 45, z / 65, 2) * 0.30
	height = height * (1 - riverInfluence) + bed * riverInfluence
	local lake = math.sqrt(((x - 39) / 61)^2 + ((z - 157) / 62)^2)
	local lakeInfluence = 1 - smooth(0.65, 1.25, lake)
	height = height * (1 - lakeInfluence) + (Scene.RiverY - 7) * lakeInfluence
	local path = Scene.pathDistance(x, z)
	local material = Enum.Material.Grass
	if shore > 0.94 then material = Enum.Material.Sand
	elseif height > 57 and hill > 45 then material = Enum.Material.Rock
	elseif height < Scene.RiverY + 1.5 and (rd < rw + 10 or lake < 1.25) then material = Enum.Material.Mud
	elseif path < 4.5 and shore < 0.91 then material = Enum.Material.Ground
	elseif math.noise(x / 45, z / 45, 40) > 0.1 then material = Enum.Material.LeafyGrass end
	local water = Scene.SeaY
	if riverInfluence > 0.2 or lakeInfluence > 0.1 then water = Scene.RiverY end
	return height, material, water, shore, path, rd
end
function Scene.isGreen(x, z)
	local y, material, water, shore = Scene.sample(x, z)
	return Seasons.isGreen() and shore < 0.96 and y > water + 0.5 and (material == Enum.Material.Grass or material == Enum.Material.LeafyGrass)
end
function Scene.cell(ix, iz)
	local count = (Scene.Maximum - Scene.Minimum) / Scene.Spacing + 1
	if ix < 0 or iz < 0 or ix >= count or iz >= count then return nil end
	local x, z = Scene.Minimum + ix * Scene.Spacing, Scene.Minimum + iz * Scene.Spacing
	-- Dense cells overlap the actual bone footprint, including both sides of material edges.
	local green = Scene.isGreen(x, z)
	if not green then
		for _, offset in ipairs({Vector2.new(-5, -5), Vector2.new(5, -5), Vector2.new(-5, 5), Vector2.new(5, 5),Vector2.new(0,-5),Vector2.new(0,5),Vector2.new(-5,0),Vector2.new(5,0)}) do
			if Scene.isGreen(x + offset.X, z + offset.Y) then green = true break end
		end
	end
	if not green then return nil end
	local y = Scene.sample(x, z)
	return {key = ix * count + iz + 1, center = Vector3.new(x, y, z), ix = ix, iz = iz}
end
function Scene.around(point, radius)
	local ix = math.floor((point.X - Scene.Minimum) / Scene.Spacing + 0.5)
	local iz = math.floor((point.Z - Scene.Minimum) / Scene.Spacing + 0.5)
	local steps, cells = math.ceil(radius / Scene.Spacing) + 1, {}
	for x = ix - steps, ix + steps do for z = iz - steps, iz + steps do
		local cell = Scene.cell(x, z)
		if cell and (Vector2.new(cell.center.X - point.X, cell.center.Z - point.Z)).Magnitude <= radius then cells[#cells + 1] = cell end
	end end
	table.sort(cells, function(a, b)
		return (Vector2.new(a.center.X - point.X, a.center.Z - point.Z)).Magnitude < (Vector2.new(b.center.X - point.X, b.center.Z - point.Z)).Magnitude
	end)
	return cells
end
return Scene
]============])
source(runtime,"ModuleScript","NPCController",[============[local Controller={}
local Players=game:GetService("Players")local Run=game:GetService("RunService")
function Controller.shouldGreet(distance,elapsed,dwell,entered)
 return distance<=13 and elapsed>=35 and(entered or dwell>=1.4)
end
function Controller.start(runtime,world)
 local npc=assert(world.OwnerNPC)local root=npc.HumanoidRootPart local hum=npc.Humanoid
 local animator=hum:FindFirstChildOfClass("Animator")or Instance.new("Animator",hum)
 local animation=npc:WaitForChild("CatBath")local track=animator:LoadAnimation(animation)
 track.Priority=Enum.AnimationPriority.Action track.Looped=true track:Play(.3,1,.85)
 local deadline=os.clock()+8 repeat task.wait(.1)until track.Length>0 or os.clock()>deadline
 assert(track.Length>0,"Cat Bath playback failed to load")npc:SetAttribute("CatBathTrackLength",track.Length)
 npc:SetAttribute("EmotePlaying",true)
 local previous={}local nearSince={}local spoken={}local globalLast=-math.huge local index=0 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.25 then return end elapsed=0 local now=workspace:GetServerTimeNow()
  for _,p in ipairs(Players:GetPlayers())do
   local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
   local distance=h and h.Health>0 and r and(r.Position-root.Position).Magnitude or math.huge
   if distance<13 then
    nearSince[p]=nearSince[p]or now
    local entered=not previous[p]
    if Controller.shouldGreet(distance,now-(spoken[p]or -math.huge),now-nearSince[p],entered)and now-globalLast>12 then
     spoken[p]=now globalLast=now index+=1
     local sound=index%4==0 and npc.Head.YayVoice or npc.Head.HiVoice sound.PlaybackSpeed=index%2==0 and 1.035 or .98 sound:Play()
    end
    previous[p]=true
   elseif distance>19 then previous[p]=nil nearSince[p]=nil end
  end
 end)
 Players.PlayerRemoving:Connect(function(p)previous[p]=nil nearSince[p]=nil spoken[p]=nil end)
 return{track=track}
end
return Controller
]============])
source(runtime,"ModuleScript","SeasonController",[============[local Controller={}
function Controller.start(runtime,world)
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local busy=false local parts={}local lights={}
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
  for bx=-512,384,128 do for bz=-512,384,128 do
   local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))
   local channels=Terrain:ReadVoxelChannels(region,4,{"SolidMaterial"})local grid=channels.SolidMaterial
   for ix=1,32 do for iz=1,32 do
    for iy=1,54 do local old=grid[ix][iy][iz]
     if old==Enum.Material.Grass or old==Enum.Material.LeafyGrass or old==Enum.Material.Snow then grid[ix][iy][iz]=index==4 and Enum.Material.Snow or index==3 and Enum.Material.LeafyGrass or Enum.Material.Grass end
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
  runtime:SetAttribute("SeasonChanging",false)runtime:SetAttribute("SeasonRevision",(runtime:GetAttribute("SeasonRevision")or 0)+1)busy=false return true
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
source(runtime,"ModuleScript","RuinController",[============[local Controller={}
local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
function Controller.allowed(distance,alive,elapsed)return alive and distance<=10 and elapsed>=4 end
function Controller.start(runtime,world)
 local ruins=assert(world.Amenities:FindFirstChild("ForestRuins"))local remote=runtime.RuinInteraction
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
 local prompt=ruins.TeaCorner.Teapot.PotBody.ServeTea
 local function serve(player,sourcePrompt,seated)
  sourcePrompt=sourcePrompt or prompt
  local c,h,r=actor(player)if not r then return false end
  local now=os.clock()
  if not Controller.allowed((r.Position-sourcePrompt.Parent.Position).Magnitude,true,now-(last[player]or -math.huge))then return false end
  last[player]=now
  local backpack=player:FindFirstChildOfClass("Backpack")if not backpack then return false end
  for _,container in ipairs({c,backpack})do for _,item in ipairs(container:GetChildren())do
   if item:IsA("Tool")and item:GetAttribute("RuinTeaCup")then h:EquipTool(item)remote:FireClient(player,"Já tem uma xícara! Toque para tomar um gole.")return true end
  end end
  local tool=runtime.TeaCupTool:Clone()tool.Name="Chá"tool:SetAttribute("RuinTeaCup",true)tool:SetAttribute("ServedToUserId",player.UserId)
  tool.Parent=backpack
  local bases={}local tweens={}
  local function restore()
   for _,t in ipairs(tweens)do t:Cancel()end table.clear(tweens)
   for joint,base in pairs(bases)do if joint.Parent then joint.C0=base end end table.clear(bases)
  end
  tool.Unequipped:Connect(restore)tool.Destroying:Connect(restore)
  tool.Activated:Connect(function()
   local model,hum,root=actor(player)
   if not model or tool.Parent~=model or tool:GetAttribute("ServedToUserId")~=player.UserId then return end
   local time=os.clock()if time-(sip[player]or -math.huge)<3 then return end sip[player]=time
   local original=tool.Grip
   restore()
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
    for joint,base in pairs(bases)do if joint.Parent then local t=Tween:Create(joint,TweenInfo.new(.45,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=base})tweens[#tweens+1]=t t:Play()end end
    task.delay(.5,restore)
   end)
   local lift=Tween:Create(tool,TweenInfo.new(.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original*CFrame.new(.08,-.15,-.22)*CFrame.Angles(math.rad(-24),0,0)})lift:Play()
   remote:FireClient(player,"Um chá quentinho. ☕")
   task.delay(.9,function()if tool.Parent then Tween:Create(tool,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original}):Play()end end)
  end)
  task.delay(240,function()if tool.Parent then tool:Destroy()end end)
  hum:EquipTool(tool)remote:FireClient(player,"Chá servido! Toque na xícara equipada para tomar um gole.")return true
 end
 for _,p in ipairs(Collection:GetTagged("TreeWorldTeaPrompt"))do
  if p:IsDescendantOf(world)then p.Triggered:Connect(function(player)serve(player,p,false)end)end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  local target=seat:FindFirstChild("TeaPrompt")
  if target and target.Value then seat:GetPropertyChangedSignal("Occupant"):Connect(function()
   local humanoid=seat.Occupant local player=humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
   if player then task.delay(.35,function()if seat.Occupant==humanoid then serve(player,target.Value,true)end end)end
  end)end
 end
 Players.PlayerRemoving:Connect(function(player)last[player]=nil sip[player]=nil end)
 return{serve=serve}
end
return Controller
]============])
local mainRuins=factory([============[local Builder={}
local Collection=game:GetService("CollectionService")
local CFG={Origin=Vector3.new(-180,28.2,30),Mood="Dourado",Ruin=.30,VineDensity=1,Seed=891013,SpawnInCourtyard=true}
local STONE=Color3.fromRGB(208,196,162)local PALE=Color3.fromRGB(225,212,174)
local GREEN=Color3.fromRGB(69,99,47)local PINK=Color3.fromRGB(196,135,159)
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or STONE p.Material=material or Enum.Material.Limestone
 p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function cylinder(parent,name,diameter,height,cf,color,material,collide)
 local p=part(parent,name,Vector3.new(height,diameter,diameter),cf*CFrame.Angles(0,0,math.pi/2),color,material,collide)p.Shape=Enum.PartType.Cylinder return p
end
local function ball(parent,name,size,cf,color,material)
 local p=part(parent,name,size,cf,color,material,false)p.Shape=Enum.PartType.Ball return p
end
local function line(parent,name,a,b,thickness,color,material)
 return part(parent,name,Vector3.new(thickness,thickness,(b-a).Magnitude+.025),CFrame.lookAt((a+b)*.5,b),color,material,false)
end
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 local existing=world.Amenities:FindFirstChild("ForestRuins")if existing then existing:Destroy()end
 for _,name in ipairs({"TeaCupTool","RuinInteraction"})do local old=runtime:FindFirstChild(name)if old then old:Destroy()end end
 assert(not world.Amenities:FindFirstChild("ForestRuins"),"Courtyard already exists")
 local rng=Random.new(CFG.Seed)local origin=CFrame.new(CFG.Origin)
 local function cf(x,y,z)return origin*CFrame.new(x,y,z)end
 local function pos(x,y,z)return cf(x,y,z).Position end
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-320,0),ray)end
 local removed={trees=0,plants=0,rocks=0}
 for _,info in ipairs({{world.Decor.Trees,"trees"},{world.Decor.Plants,"plants"},{world.Decor.RocksAndLogs,"rocks"}})do
  for _,m in ipairs(info[1]:GetChildren())do if m:IsA("Model")then local p=origin:PointToObjectSpace(m:GetPivot().Position)
   if math.abs(p.X)<44 and math.abs(p.Z)<34 then removed[info[2]]+=1 m:Destroy()end
  end end
 end
 local ruins=Instance.new("Model")ruins.Name="ForestRuins"ruins.Parent=world.Amenities ruins:SetAttribute("Origin",CFG.Origin)
 runtime:SetAttribute("RuinOrigin",CFG.Origin)
 ruins:SetAttribute("Mood",CFG.Mood)ruins:SetAttribute("Ruin",CFG.Ruin)ruins:SetAttribute("VineDensity",CFG.VineDensity)ruins:SetAttribute("Seed",CFG.Seed)
 local architecture=Instance.new("Model")architecture.Name="Arcade"architecture.ModelStreamingMode=Enum.ModelStreamingMode.Atomic architecture.Parent=ruins
 local courtyard=Instance.new("Model")courtyard.Name="Courtyard"courtyard.ModelStreamingMode=Enum.ModelStreamingMode.Atomic courtyard.Parent=ruins
 local garden=Instance.new("Folder")garden.Name="Garden"garden.Parent=ruins
 local floor=part(courtyard,"CourtyardFloor",Vector3.new(76,1,56),cf(0,-.5,0),STONE,Enum.Material.Limestone,true)
 -- Deep retaining blocks connect the raised level to the actual terrain; the courtyard has no floating underside.
 for x=-34,34,8 do for z=-24,24,8 do
  local h=assert(ground(CFG.Origin.X+x,CFG.Origin.Z+z))local height=math.max(.4,CFG.Origin.Y-1-h.Position.Y+.30)
  local base=part(courtyard,"Foundation",Vector3.new(8.1,height,8.1),cf(x,-1-height*.5,z),Color3.fromRGB(151,146,123),Enum.Material.Slate,true)
  base:SetAttribute("GroundPoint",h.Position)
 end end
 for x=-34,34,4 do for z=-24,24,4 do
  local tile=part(courtyard,"WornPaving",Vector3.new(3.92,.13,3.92),cf(x,.065,z),STONE:Lerp(Color3.fromRGB(152,157,132),rng:NextNumber(0,.23)),Enum.Material.Limestone,false)
  if rng:NextNumber()<.15 then
   local moss=part(courtyard,"PavingMoss",Vector3.new(rng:NextNumber(.5,2.0),.015,rng:NextNumber(.25,1.4)),cf(x+rng:NextNumber(-1,1),.139,z+rng:NextNumber(-1,1))*CFrame.Angles(0,rng:NextNumber(0,6.28),0),GREEN,Enum.Material.Grass,false)
  end
 end end
 -- Front and rear arcades: eight pillars, six real open semicircular arches.
 local archCount=0 local columns={}
 for _,z in ipairs({-16,-2})do
  for _,x in ipairs({-33,-11,11,33})do
   columns[#columns+1]=Vector3.new(x,0,z)
   part(architecture,"ColumnPlinth",Vector3.new(4.3,.7,4.3),cf(x,.35,z),STONE,Enum.Material.Limestone,true)
   part(architecture,"ColumnBase",Vector3.new(3.65,.35,3.65),cf(x,.88,z),PALE,Enum.Material.Limestone,true)
   cylinder(architecture,"ColumnShaft",2.65,9.6,cf(x,5.8,z),PALE,Enum.Material.Limestone,true)
   for _,y in ipairs({1.3,10.4})do cylinder(architecture,"ColumnMoulding",3.03,.25,cf(x,y,z),STONE,Enum.Material.Limestone,false)end
   for flute=0,11 do local angle=flute*math.pi/6
    line(architecture,"ColumnFlute",pos(x+math.cos(angle)*1.30,1.65,z+math.sin(angle)*1.30),pos(x+math.cos(angle)*1.30,10.0,z+math.sin(angle)*1.30),.055,STONE:Lerp(Color3.fromRGB(132,132,112),.17),Enum.Material.Limestone)
   end
   part(architecture,"ColumnCapital",Vector3.new(4.1,.65,3.7),cf(x,10.9,z),PALE,Enum.Material.Limestone,true)
  end
  for _,x in ipairs({-22,0,22})do
   local arch=Instance.new("Model")arch.Name="StoneArch"arch.Parent=architecture arch:SetAttribute("OpeningCentre",pos(x,7,z))
   local radius=9.3 local segments=18
   for i=0,segments-1 do
    local angle=(i+.5)*math.pi/segments
    local size=Vector3.new(2*(radius+.9)*math.sin(math.pi/segments/2)+.045,1.65,2.6)
    part(arch,"Voussoir",size,cf(x+radius*math.cos(angle),11.1+radius*math.sin(angle),z)*CFrame.Angles(0,0,angle+math.pi*.5),i==8 and PALE or STONE,Enum.Material.Limestone,true)
   end
   part(arch,"Keystone",Vector3.new(1.65,2.0,2.85),cf(x,20.2,z),PALE,Enum.Material.Limestone,false)
   archCount+=1
  end
 end
 for _,x in ipairs({-33,33})do part(architecture,"SideLintel",Vector3.new(2.9,1.5,17),cf(x,11.3,-9),STONE,Enum.Material.Limestone,true)end
 for _,z in ipairs({-16,-2})do part(architecture,"Cornice",Vector3.new(70,1.1,3.5),cf(0,21,z),PALE,Enum.Material.Limestone,true)end
 -- Roof gaps let sunlight into the walkable hall. Sparse fallen pieces remain outside the entrances.
 local holes=0
 for x=-32,32,8 do for z=-14,-4,5 do
  if rng:NextNumber()<CFG.Ruin then holes+=1 else
   part(architecture,"RoofSlab",Vector3.new(7.8,.55,4.85),cf(x,21.75,z),Color3.fromRGB(112,114,100),Enum.Material.Slate,true)
  end
 end end
 for x=-32,32,8 do part(architecture,"RoofJoist",Vector3.new(.45,.65,16.8),cf(x,21.45,-9),Color3.fromRGB(91,72,54),Enum.Material.Wood,false)end
 local vineSegments=0 local leaves=0
 for _,column in ipairs(columns)do
  local previous=nil
  for i=0,math.floor(22*CFG.VineDensity)do
   local t=i/(22*CFG.VineDensity)local angle=t*math.pi*5+column.X*.07
   local point=pos(column.X+math.cos(angle)*1.48,1.0+t*10.8,column.Z+math.sin(angle)*1.48)
   if previous then line(architecture,"SpiralVine",previous,point,.10,Color3.fromRGB(63,81,37),Enum.Material.Grass)vineSegments+=1 end previous=point
   if i%2==0 then
    for _,side in ipairs({-1,1})do ball(architecture,"VineLeaf",Vector3.new(.46,.095,.83),CFrame.new(point+Vector3.new(side*.22,.04,0))*CFrame.Angles(.2,angle+side*.5,.18*side),GREEN,Enum.Material.Grass)leaves+=1 end
   end
  end
 end
 -- Broken boundary wall, rubble and a fallen column, laid directly onto stone or native ground.
 for x=-34,34,4 do
  if math.abs(x)>7 then
   local rows=rng:NextInteger(1,3)
   for row=1,rows do part(courtyard,"BrokenWall",Vector3.new(3.9,1.3,1.4),cf(x,(row-.5)*1.3,-26),STONE,Enum.Material.Limestone,true)end
  end
 end
 for i=1,14 do
  local x,z=rng:NextNumber(-34,34),rng:NextNumber(-25,-21)
  part(courtyard,"RuinStone",Vector3.new(rng:NextNumber(.7,1.7),.55,rng:NextNumber(.7,1.5)),cf(x,.40,z)*CFrame.Angles(.06,rng:NextNumber(0,6.28),.08),STONE,Enum.Material.Limestone,true)
 end
 cylinder(courtyard,"FallenColumn",2.1,10,cf(28,1.18,-23)*CFrame.Angles(0,0,math.pi/2),PALE,Enum.Material.Limestone,true)
 local seatCount=0
 local function seat(parent,name,position,angle,cushion)
  local s=Instance.new("Seat")s.Name=name s.Size=Vector3.new(2.25,.22,2.1)s.CFrame=CFrame.new(position)*CFrame.Angles(0,angle,0)
  s.Anchored=true s.CanCollide=true s.CanTouch=false s.Color=cushion and PINK or STONE s.Material=cushion and Enum.Material.Fabric or Enum.Material.Limestone s.Parent=parent
  Collection:AddTag(s,"RuinSeat")local prompt=Instance.new("ProximityPrompt")prompt.Name="SitPrompt"prompt.ActionText="Sentar"prompt.ObjectText=cushion and "Banquinho do chá"or "Banco de pedra"prompt.MaxActivationDistance=7 prompt.HoldDuration=.15 prompt.RequiresLineOfSight=false prompt.Parent=s
  seatCount+=1 return s
 end
 for _,x in ipairs({-28,28})do
  local bench=Instance.new("Model")bench.Name="StoneBench"bench.ModelStreamingMode=Enum.ModelStreamingMode.Atomic bench.Parent=architecture
  part(bench,"BenchTop",Vector3.new(7,.45,2.5),cf(x,2.05,-9),PALE,Enum.Material.Limestone,true)
  for _,side in ipairs({-1,1})do part(bench,"BenchSupport",Vector3.new(.75,1.8,2.15),cf(x+side*2.35,.9,-9),STONE,Enum.Material.Limestone,true)seat(bench,"StoneSeat",pos(x+side*1.8,2.40,-9),0,false)end
 end
 local plantTemplate=assert(world.Decor.Plants:FindFirstChild("RhododendronVar01"))
 for _,point in ipairs({Vector2.new(-30,22),Vector2.new(30,22),Vector2.new(-34,-22),Vector2.new(34,-22)})do
  local pot=Instance.new("Model")pot.Name="PottedTopiary"pot.ModelStreamingMode=Enum.ModelStreamingMode.Atomic pot.Parent=garden
  cylinder(pot,"Planter",2.7,1.65,cf(point.X,.825,point.Y),Color3.fromRGB(174,163,135),Enum.Material.Limestone,true)
  cylinder(pot,"PlanterLip",3.05,.22,cf(point.X,1.63,point.Y),STONE,Enum.Material.Limestone,false)
  cylinder(pot,"Soil",2.65,.08,cf(point.X,1.76,point.Y),Color3.fromRGB(73,55,40),Enum.Material.Ground,false)
  local plant=plantTemplate:Clone()plant.Name="LivingTopiary"local _,size=plant:GetBoundingBox()plant:ScaleTo(plant:GetScale()*3.6/size.Y)plant:PivotTo(cf(point.X,1.76,point.Y))
  for _,d in ipairs(plant:GetDescendants())do if d:IsA("BasePart")then d.Anchored=true d.CanCollide=false d.CanQuery=false d.CanTouch=false d:SetAttribute("ForestRestCF",d.CFrame)d:SetAttribute("WindPower",.03)end end
  plant.Parent=pot
 end
 -- The tea setting is ceramic geometry: a round table, open-rim cups, curved handles, teapot, cookies and flowers.
 local tea=Instance.new("Model")tea.Name="TeaCorner"tea.ModelStreamingMode=Enum.ModelStreamingMode.Atomic tea.Parent=ruins
 local teaCentre=Vector3.new(-16,0,-9)
 local function teaCF(x,y,z)return cf(teaCentre.X+x,y,teaCentre.Z+z)end
 cylinder(tea,"TableTop",6.5,.32,teaCF(0,3.05,0),Color3.fromRGB(171,147,113),Enum.Material.Wood,true)
 cylinder(tea,"TablePedestal",.8,2.7,teaCF(0,1.4,0),Color3.fromRGB(118,94,68),Enum.Material.Wood,true)
 cylinder(tea,"TableFoot",2.9,.28,teaCF(0,.14,0),Color3.fromRGB(118,94,68),Enum.Material.Wood,true)
 local function cup(parent,base,name)
  local m=Instance.new("Model")m.Name=name m.Parent=parent
  cylinder(m,"CupBody",.72,.47,base*CFrame.new(0,.235,0),Color3.fromRGB(241,227,222),Enum.Material.SmoothPlastic,false)
  cylinder(m,"Tea",.61,.024,base*CFrame.new(0,.461,0),Color3.fromRGB(115,65,32),Enum.Material.Glass,false)
  for i=0,11 do local a=i*math.pi*2/12 local b=(i+1)*math.pi*2/12
   line(m,"CupRim",base:PointToWorldSpace(Vector3.new(.35*math.cos(a),.49,.35*math.sin(a))),base:PointToWorldSpace(Vector3.new(.35*math.cos(b),.49,.35*math.sin(b))),.052,Color3.fromRGB(224,188,160),Enum.Material.SmoothPlastic)
  end
  for i=0,7 do local a=-math.pi*.65+i*math.pi*1.3/8 local b=-math.pi*.65+(i+1)*math.pi*1.3/8
   line(m,"CupHandle",base:PointToWorldSpace(Vector3.new(.48+.2*math.cos(a),.27+.22*math.sin(a),0)),base:PointToWorldSpace(Vector3.new(.48+.2*math.cos(b),.27+.22*math.sin(b),0)),.065,Color3.fromRGB(237,222,214),Enum.Material.SmoothPlastic)
  end
  local attachment=Instance.new("Attachment")attachment.Position=Vector3.new(.30,0,0)attachment.CFrame=CFrame.new(.30,0,0)*CFrame.Angles(0,0,-math.pi*.5)attachment.Parent=m.CupBody
  local steam=Instance.new("ParticleEmitter")steam.Name="TeaSteam"steam.Texture="rbxasset://textures/particles/smoke_main.dds"steam.Color=ColorSequence.new(Color3.fromRGB(235,232,220))steam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.85),NumberSequenceKeypoint.new(.3,.93),NumberSequenceKeypoint.new(1,1)})steam.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.11),NumberSequenceKeypoint.new(1,.55)})steam.Rate=2 steam.Lifetime=NumberRange.new(1,1.8)steam.Speed=NumberRange.new(.25,.45)steam.SpreadAngle=Vector2.new(8,8)steam.Acceleration=Vector3.new(.03,.1,0)steam.Parent=attachment Collection:AddTag(steam,"RuinVFX")
  return m
 end
 for i=0,3 do local angle=i*math.pi*.5 local x,z=math.cos(angle)*4.2,math.sin(angle)*4.2
  local stool=Instance.new("Model")stool.Name="PinkStool"stool.Parent=tea
  cylinder(stool,"StoolFrame",2.3,.35,teaCF(x,1.8,z),Color3.fromRGB(127,104,76),Enum.Material.Wood,true)
  for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do part(stool,"StoolLeg",Vector3.new(.25,1.55,.25),teaCF(x+sx*.65,.8,z+sz*.65),Color3.fromRGB(127,104,76),Enum.Material.Wood,true)end end
  seat(stool,"TeaSeat",teaCF(x,2.09,z).Position,-angle-math.pi*.5,true)
  cylinder(tea,"Saucer",1.08,.06,teaCF(math.cos(angle)*2.1,3.26,math.sin(angle)*2.1),Color3.fromRGB(235,222,204),Enum.Material.SmoothPlastic,false)
  cup(tea,teaCF(math.cos(angle)*2.1,3.29,math.sin(angle)*2.1)*CFrame.Angles(0,-angle,0),"TeaCup")
 end
 local pot=Instance.new("Model")pot.Name="Teapot"pot.Parent=tea
 ball(pot,"PotBody",Vector3.new(1.55,1.17,1.55),teaCF(0,3.76,.15),Color3.fromRGB(235,215,207),Enum.Material.SmoothPlastic)
 cylinder(pot,"PotFoot",.95,.12,teaCF(0,3.24,.15),Color3.fromRGB(219,192,175),Enum.Material.SmoothPlastic,false)
 cylinder(pot,"PotLid",1.16,.14,teaCF(0,4.29,.15),Color3.fromRGB(237,219,209),Enum.Material.SmoothPlastic,false)
 ball(pot,"LidKnob",Vector3.new(.24,.22,.24),teaCF(0,4.46,.15),Color3.fromRGB(202,162,132),Enum.Material.SmoothPlastic)
 for i=0,7 do local a=-math.pi*.7+i*math.pi*1.4/8 local b=-math.pi*.7+(i+1)*math.pi*1.4/8
  line(pot,"PotHandle",teaCF(0,0,0):PointToWorldSpace(Vector3.new(-.88-.34*math.cos(a),3.78+.44*math.sin(a),.15)),teaCF(0,0,0):PointToWorldSpace(Vector3.new(-.88-.34*math.cos(b),3.78+.44*math.sin(b),.15)),.13,Color3.fromRGB(232,210,200),Enum.Material.SmoothPlastic)
 end
 local previous=teaCF(.55,3.65,.15).Position
 for _,point in ipairs({Vector3.new(.95,3.82,.15),Vector3.new(1.22,4.13,.15),Vector3.new(1.52,4.28,.15)})do local nextPoint=teaCF(point.X,point.Y,point.Z).Position line(pot,"CurvedSpout",previous,nextPoint,.24,Color3.fromRGB(235,215,207),Enum.Material.SmoothPlastic)previous=nextPoint end
 local serve=Instance.new("ProximityPrompt")serve.Name="ServeTea"serve.ActionText="Servir chá"serve.ObjectText="Cantinho do chá"serve.MaxActivationDistance=8 serve.RequiresLineOfSight=false serve.HoldDuration=.6 serve.Parent=pot.PotBody
 cylinder(tea,"CookiePlate",1.9,.07,teaCF(.15,3.26,-1.5),Color3.fromRGB(219,190,147),Enum.Material.SmoothPlastic,false)
 for i=1,6 do local x,z=.15+rng:NextNumber(-.5,.5),-1.5+rng:NextNumber(-.4,.4)
  cylinder(tea,"Cookie",.43,.075,teaCF(x,3.33+(i%2)*.06,z),Color3.fromRGB(183,129,72),Enum.Material.Sand,false)
  for chip=1,3 do ball(tea,"ChocolateChip",Vector3.new(.055,.025,.055),teaCF(x+rng:NextNumber(-.12,.12),3.38+(i%2)*.06,z+rng:NextNumber(-.12,.12)),Color3.fromRGB(70,43,24),Enum.Material.SmoothPlastic)end
 end
 cylinder(tea,"FlowerVase",.48,.67,teaCF(-.9,3.51,1.0),Color3.fromRGB(176,192,164),Enum.Material.SmoothPlastic,false)
 for i=0,4 do local a=i*math.pi*2/5 local tip=teaCF(-.9+.2*math.cos(a),4.30+(i%2)*.16,1+.2*math.sin(a)).Position
  line(tea,"FlowerStem",teaCF(-.9,3.76,1).Position,tip,.035,GREEN,Enum.Material.Grass)
  for petal=0,4 do local b=petal*math.pi*2/5 ball(tea,"PinkPetal",Vector3.new(.20,.10,.15),CFrame.new(tip+Vector3.new(math.cos(b)*.1,.02,math.sin(b)*.1)),PINK,Enum.Material.SmoothPlastic)end
 end
 local tool=Instance.new("Tool")tool.Name="Chá"tool.RequiresHandle=true tool.CanBeDropped=false tool.ToolTip="Toque para tomar um gole"tool.Grip=CFrame.new(0,-.15,0)*CFrame.Angles(0,0,math.rad(-12))
 local toolCup=cup(tool,CFrame.identity,"CupGeometry")
 local handle=Instance.new("Part")handle.Name="Handle"handle.Size=Vector3.new(.7,.55,.7)handle.Transparency=1 handle.Anchored=false handle.CanCollide=false handle.CanQuery=false handle.CanTouch=false handle.Massless=true handle.Parent=tool
 for _,p in ipairs(toolCup:GetDescendants())do if p:IsA("BasePart")then p.Anchored=false p.CanCollide=false p.CanQuery=false p.Massless=true local weld=Instance.new("WeldConstraint")weld.Part0=handle weld.Part1=p weld.Parent=p end end
 tool.Name="TeaCupTool"tool.Parent=runtime
 -- Fountain with four curved animated streams, a shallow bowl and bounded droplets.
 local fountain=Instance.new("Model")fountain.Name="GardenFountain"fountain.ModelStreamingMode=Enum.ModelStreamingMode.Atomic fountain.Parent=ruins
 local fc=cf(15,0,14)
 cylinder(fountain,"FountainBase",10,.6,fc*CFrame.new(0,.3,0),STONE,Enum.Material.Limestone,true)
 cylinder(fountain,"BasinFloor",8.9,.2,fc*CFrame.new(0,.74,0),Color3.fromRGB(133,151,142),Enum.Material.Slate,true)
 for i=0,19 do local a=i*math.pi*2/20 local b=(i+1)*math.pi*2/20
  local mid=(a+b)*.5 part(fountain,"BasinRim",Vector3.new(1.58,.95,.72),fc*CFrame.new(math.cos(mid)*4.7,1.05,math.sin(mid)*4.7)*CFrame.Angles(0,-mid-math.pi*.5,0),PALE,Enum.Material.Limestone,true)
 end
 local water=cylinder(fountain,"FountainWater",8.6,.08,fc*CFrame.new(0,1.00,0),Color3.fromRGB(111,171,175),Enum.Material.Glass,false)water.Transparency=.38 water.Reflectance=.12
 cylinder(fountain,"FountainPedestal",1.05,2.3,fc*CFrame.new(0,1.7,0),PALE,Enum.Material.Limestone,true)
 cylinder(fountain,"UpperBowl",3.2,.3,fc*CFrame.new(0,2.85,0),STONE,Enum.Material.Limestone,false)
 ball(fountain,"Finial",Vector3.new(.75,.85,.75),fc*CFrame.new(0,3.46,0),PALE,Enum.Material.Limestone)
 for i=0,3 do
  local a=i*math.pi*.5 local start=Instance.new("Attachment")start.Name="JetStart"start.CFrame=fountain.FountainBase.CFrame:ToObjectSpace(fc*CFrame.new(math.cos(a)*.5,3.05,math.sin(a)*.5)*CFrame.Angles(0,-a,math.pi*.35))start.Parent=fountain.FountainBase
  local finish=Instance.new("Attachment")finish.Name="JetEnd"finish.CFrame=fountain.FountainBase.CFrame:ToObjectSpace(fc*CFrame.new(math.cos(a)*3.5,.75,math.sin(a)*3.5)*CFrame.Angles(0,-a,-math.pi*.40))finish.Parent=fountain.FountainBase
  local jet=Instance.new("Beam")jet.Name="WaterJet"jet.Attachment0=start jet.Attachment1=finish jet.CurveSize0=3.2 jet.CurveSize1=2.0 jet.Width0=.10 jet.Width1=.18 jet.FaceCamera=true jet.Segments=16 jet.Color=ColorSequence.new(Color3.fromRGB(180,216,218))jet.Transparency=NumberSequence.new(.32)jet.LightEmission=.1 jet.Texture="rbxasset://textures/particles/smoke_main.dds"jet.TextureSpeed=2 jet.TextureLength=.65 jet.Parent=fountain Collection:AddTag(jet,"RuinVFX")
  local drops=Instance.new("ParticleEmitter")drops.Name="FountainDroplets"drops.Texture="rbxasset://textures/particles/sparkles_main.dds"drops.Rate=5 drops.Lifetime=NumberRange.new(.3,.5)drops.Speed=NumberRange.new(.7,1.5)drops.SpreadAngle=Vector2.new(25,25)drops.Size=NumberSequence.new(.06)drops.Color=ColorSequence.new(Color3.fromRGB(177,219,221))drops.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,1)})drops.Acceleration=Vector3.new(0,-8,0)drops.Parent=finish Collection:AddTag(drops,"RuinVFX")
 end
 local originalLantern=assert(world.Amenities.Lanterns:FindFirstChildOfClass("Model"))local addedLights=0
 for _,x in ipairs({-22,0,22})do
  for _,z in ipairs({-14,-4})do
   local lamp=originalLantern:Clone()lamp.Name="HangingLantern"
   for _,name in ipairs({"TimberPost","LanternBracket","HangingChain"})do local p=lamp:FindFirstChild(name,true)if p then p:Destroy()end end
   lamp:PivotTo(cf(x,15.4,z))lamp.Parent=architecture lamp.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   line(architecture,"LanternChain",pos(x,17.2,z),pos(x,21.2,z),.065,Color3.fromRGB(80,75,60),Enum.Material.Metal)
   for _,light in ipairs(lamp:GetDescendants())do if light:IsA("PointLight")then Collection:AddTag(light,"ForestNightLight")addedLights+=1 end end
  end
 end
 -- Walkable stone stairs and a winding path connect the courtyard to the existing forest trail.
 local way=Instance.new("Model")way.Name="EntrancePath"way.ModelStreamingMode=Enum.ModelStreamingMode.Atomic way.Parent=ruins
 local Scene=require(runtime.Scene)local endpoint=Vector3.new(Scene.pathX(CFG.Origin.Z+18),0,CFG.Origin.Z+18)
 local start=pos(37,0,18)local eh=assert(ground(endpoint.X,endpoint.Z))endpoint=eh.Position
 local distance=(Vector2.new(endpoint.X-start.X,endpoint.Z-start.Z)).Magnitude
 local steps=math.ceil(distance/2.8)
 local lastHeight=CFG.Origin.Y
 for i=0,steps do local t=i/steps local p=start:Lerp(endpoint,t)
  local h=assert(ground(p.X,p.Z))local desired=math.max(h.Position.Y+.12,CFG.Origin.Y+(endpoint.Y-CFG.Origin.Y)*t)
  desired=math.min(desired,lastHeight+.45)local height=math.max(.35,desired-h.Position.Y+.25)
  local stone=part(way,"ApproachStep",Vector3.new(3.0,height,8),CFrame.new(p.X,desired-height*.5,p.Z),STONE,Enum.Material.Limestone,true)stone:SetAttribute("GroundPoint",h.Position)lastHeight=desired
 end
 local mood=Instance.new("ProximityPrompt")mood.Name="MoodPrompt"mood.ActionText="Trocar luz / neblina"mood.ObjectText="Ambiente das ruínas"mood.MaxActivationDistance=9 mood.RequiresLineOfSight=false mood.Parent=architecture.ColumnPlinth
 Collection:AddTag(mood,"RuinMoodPrompt")
 local groveCount=0
 local spawn=world.ForestSpawn local spawnCF=cf(0,3.52,19)*CFrame.Angles(0,math.pi,0)
 local courtyardSpawn=Instance.new("SpawnLocation")courtyardSpawn.Name="CourtyardSpawn"courtyardSpawn.Size=Vector3.new(4,.2,4)courtyardSpawn.CFrame=cf(0,.15,19)courtyardSpawn.Transparency=1 courtyardSpawn.Anchored=true courtyardSpawn.CanCollide=false courtyardSpawn.CanQuery=false courtyardSpawn.CanTouch=false courtyardSpawn.Neutral=true courtyardSpawn.Enabled=false courtyardSpawn.Parent=courtyard
 if CFG.SpawnInCourtyard then runtime:SetAttribute("OriginalForestSpawnCF",runtime:GetAttribute("MainSpawnCF"))runtime:SetAttribute("MainSpawnCF",spawnCF)world:SetAttribute("MainSpawnCF",spawnCF)spawn.CFrame=courtyardSpawn.CFrame end
 local remote=Instance.new("RemoteEvent")remote.Name="RuinInteraction"remote.Parent=runtime
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 world:SetAttribute("LanternCount",#Collection:GetTagged("ForestNightLight"))world:SetAttribute("UpgradeVersion",90)
 ruins:SetAttribute("ArchCount",archCount)ruins:SetAttribute("SeatCount",seatCount)ruins:SetAttribute("RoofHoles",holes)ruins:SetAttribute("AutumnTrees",groveCount)
 return{origin={CFG.Origin.X,CFG.Origin.Y,CFG.Origin.Z},arches=archCount,columns=#columns,seats=seatCount,roofHoles=holes,vineSegments=vineSegments,vineLeaves=leaves,addedLanterns=addedLights,autumnTrees=groveCount,removedVegetation=removed,spawnInCourtyard=CFG.SpawnInCourtyard}
end
return Builder
]============]).install()
local worldReport=factory([============[local Builder={}
local Asset=game:GetService("AssetService")local Collection=game:GetService("CollectionService")
local function strip(root)
 for _,d in ipairs(root:GetDescendants())do
  if d:IsA("LuaSourceContainer")or d:IsA("RemoteEvent")or d:IsA("RemoteFunction")or d:IsA("Sound")then d:Destroy()end
 end
end
local function bounds(root)
 local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(v)hi=hi:Max(v)end end end
 end end return lo,hi
end
local function normalize(model)
 model:PivotTo(CFrame.identity)local lo,hi=bounds(model)local offset=Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)
 model:PivotTo(model:GetPivot()-offset)model.PrimaryPart=nil model.WorldPivot=CFrame.identity return hi-lo
end
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or Color3.fromRGB(169,173,149)p.Material=material or Enum.Material.Limestone
 p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.Parent=parent return p
end
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local rng=Random.new(901014)
 local report={teaTables=0,chairs=0,bridges=0,menuAsset=17216750157,emoteAsset=127049078545834}
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
 -- All four old regional colors are restored to one green spring across the same heightfield.
 for bx=-512,384,128 do for bz=-512,384,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))local grid=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidMaterial"}).SolidMaterial
  for ix=1,32 do for iz=1,32 do for iy=1,54 do local material=grid[ix][iy][iz]
   if material==Enum.Material.Snow or material==Enum.Material.Grass or material==Enum.Material.LeafyGrass then grid[ix][iy][iz]=Enum.Material.Grass end
  end end end workspace.Terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})task.wait()
 end end
 workspace.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(98,139,66))workspace.Terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(169,132,64))workspace.Terrain:SetMaterialColor(Enum.Material.Snow,Color3.fromRGB(236,242,247))
 pcall(function()workspace.Terrain.Decoration=false end)
 runtime:SetAttribute("SeasonName","Primavera")runtime:SetAttribute("SeasonIndex",1)runtime:SetAttribute("GrassMotionEnabled",false)
 world:SetAttribute("SeasonLayout","TemporalGlobal")world:SetAttribute("SeasonCount",4)world:SetAttribute("GameName","TreeWorld")world:SetAttribute("UpgradeVersion",90)
 local packRaw=Asset:LoadAssetAsync(6432306802)local pack=assert(packRaw["Forest Pack"])strip(pack)
 local blossoms=0
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,m in ipairs(folder:GetChildren())do
  m:SetAttribute("Season",nil)m:SetAttribute("AutumnGrove",nil)
  local accent=folder==world.Decor.Trees and m.Name=="DogwoodTree_Var01"and rng:NextNumber()<.22
  m:SetAttribute("SpringBlossom",accent)if accent then blossoms+=1 end
  local original=pack:FindFirstChild(m.Name)
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
   local sample=original and original:FindFirstChild(p.Name,true)local color=sample and sample:IsA("BasePart")and sample.Color or Color3.fromRGB(94,135,71)
   if folder==world.Decor.Plants and m.Name:lower():find("flower",1,true)then color=sample and sample.Color or Color3.fromRGB(225,218,185)end
   p:SetAttribute("SeasonBaseColor",color)p:SetAttribute("SeasonBaseTransparency",p.Transparency)
   p.Color=accent and (p.Name:lower():find("leaf",1,true)or p.Name:lower():find("leaves",1,true))and Color3.fromRGB(213,173,187)or color local a=p:FindFirstChildOfClass("SurfaceAppearance")if a then a.Color=p.Color end
  end end
 end end packRaw:Destroy()report.springBlossoms=blossoms
 -- The exact requested loading/menu UI is retained; its script is adapted for bounded loading and mobile input.
 local raw=Asset:LoadAssetAsync(17216750157)
 local menu=assert(raw:FindFirstChild("LoadingMainMenuGUI",true)):Clone()strip(menu)menu.Name="TreeWorldMenu"menu.ResetOnSpawn=false menu.IgnoreGuiInset=true menu.DisplayOrder=100 menu.Enabled=true menu:SetAttribute("SourceAssetId",17216750157)
 for _,v in ipairs(menu:GetDescendants())do if v:IsA("TextLabel")or v:IsA("TextButton")then v.Font=Enum.Font.GothamMedium v.TextScaled=false end end
 local loading=menu.Background loading.Size=UDim2.fromScale(1,1)loading.Position=UDim2.fromScale(0,0)loading.AnchorPoint=Vector2.zero loading.BackgroundColor3=Color3.fromRGB(19,32,24)loading.BackgroundTransparency=0
 local function title(label,y)
  label.Text="TreeWorld"label.AnchorPoint=Vector2.new(.5,.5)label.Position=UDim2.fromScale(.5,y)label.Size=UDim2.new(.8,0,0,75)label.TextSize=48 label.TextColor3=Color3.fromRGB(239,235,210)label.BackgroundTransparency=1 label.Font=Enum.Font.Garamond
  local constraint=Instance.new("UITextSizeConstraint")constraint.MaxTextSize=48 constraint.MinTextSize=24 constraint.Parent=label label.TextScaled=true
 end
 title(loading.GameTitle,.43)loading.Description.Text="Um lugar para explorar e descansar."loading.Description.AnchorPoint=Vector2.new(.5,.5)loading.Description.Position=UDim2.fromScale(.5,.56)loading.Description.Size=UDim2.new(.86,0,0,45)loading.Description.TextSize=15 loading.Description.TextWrapped=true loading.Description.TextColor3=Color3.fromRGB(207,220,198)loading.Description.BackgroundTransparency=1
 local bar=loading.Bar bar.AnchorPoint=Vector2.new(.5,.5)bar.Position=UDim2.fromScale(.5,.65)bar.Size=UDim2.new(.55,0,0,5)bar.BackgroundColor3=Color3.fromRGB(57,72,57)bar.BorderSizePixel=0 bar.LoadBar.Size=UDim2.fromScale(0,1)bar.LoadBar.Position=UDim2.fromScale(0,0)bar.LoadBar.AnchorPoint=Vector2.zero bar.LoadBar.BackgroundColor3=Color3.fromRGB(189,209,157)
 local main=menu.MainMenu main.Size=UDim2.fromScale(1,1)main.Position=UDim2.fromScale(0,0)main.AnchorPoint=Vector2.zero main.BackgroundTransparency=1 title(main.GameTitle,.38)
 local play=main.PlayButton play.Text="Entrar"play.AnchorPoint=Vector2.new(.5,.5)play.Position=UDim2.fromScale(.5,.58)play.Size=UDim2.new(.38,0,0,52)play.BackgroundColor3=Color3.fromRGB(42,62,43)play.TextColor3=Color3.fromRGB(240,239,218)play.TextSize=20 play.AutoButtonColor=true
 local size=Instance.new("UISizeConstraint")size.MinSize=Vector2.new(150,52)size.MaxSize=Vector2.new(270,52)size.Parent=play
 for _,obj in ipairs({play,bar,bar.LoadBar})do local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,10)corner.Parent=obj end
 local name=menu:FindFirstChild("GameName")if name then name.Value="TreeWorld"end
 menu.Parent=game.StarterGui raw:Destroy()
 local blur=game.Lighting:FindFirstChild("TreeWorldMenuBlur")or Instance.new("BlurEffect")blur.Name="TreeWorldMenuBlur"blur.Enabled=false blur.Size=0 blur.Parent=game.Lighting
 local origin=world.Amenities.ForestRuins:GetAttribute("Origin")runtime:SetAttribute("MenuCameraFocus",origin+Vector3.new(0,6,-8))runtime:SetAttribute("MenuCameraCF",CFrame.lookAt(origin+Vector3.new(54,26,65),origin+Vector3.new(0,6,-8)))
 -- Antique native chair meshes have their own authored seat and back; no procedural stools remain.
 local chairRaw=Asset:LoadAssetAsync(8474839527)strip(chairRaw)local chairTemplate=assert(chairRaw:FindFirstChildOfClass("Model"))normalize(chairTemplate)
 local seatRotation=assert(chairTemplate:FindFirstChildOfClass("Seat")).CFrame.Rotation:Inverse()
 for _,part in ipairs(chairTemplate:GetDescendants())do if part:IsA("BasePart")then part.CFrame=seatRotation*part.CFrame end end
 chairTemplate.WorldPivot=CFrame.identity normalize(chairTemplate)
 -- Remove the outside duplicate from the source container; only the authored Chair model is used.
 local tableRaw=Asset:LoadAssetAsync(18831822897)strip(tableRaw)local tableTemplate=assert(tableRaw:FindFirstChildOfClass("Model"))
 for _,d in ipairs(tableTemplate:GetDescendants())do if d.Name=="bottle"then d:Destroy()end end
 normalize(tableTemplate)
 local function tea(corner)
  local oldCF=corner:GetPivot()local top=corner:FindFirstChild("TableTop",true)or corner:FindFirstChild("TeaTableTop",true)
  local centre=top and Vector3.new(top.Position.X,origin.Y,top.Position.Z)or origin+Vector3.new(-16,0,-9)
  local table=tableTemplate:Clone()table.Name="AntiqueTeaTable"table:SetAttribute("SourceAssetId",18831822897)table:ScaleTo(1.18)table:PivotTo(CFrame.new(centre))table.Parent=corner
  for _,p in ipairs(table:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=p.Name=="table"p.CanQuery=p.CanCollide p.CanTouch=false end end
  local reference=assert(table:FindFirstChild("table",true))local tableTop=reference.Position.Y+reference.Size.Y*.5
  local cover=table:FindFirstChild("tablecover",true)if cover then tableTop=math.max(tableTop,cover.Position.Y+cover.Size.Y*.5-.03)end
  local delta=tableTop-(origin.Y+3.21)
  -- Place the existing teapot, cups, cookies and flowers on the new table surface.
  for _,d in ipairs(corner:GetChildren())do
   if d.Name=="PinkStool"or d.Name=="TableTop"or d.Name=="TablePedestal"or d.Name=="TableFoot"then d:Destroy()
   elseif d~=table and d:IsA("Model")then d:PivotTo(d:GetPivot()+Vector3.new(0,delta+.025,0))
   elseif d~=table and d:IsA("BasePart")then d.CFrame+=Vector3.new(0,delta+.025,0)end
  end
  local prompt=assert(corner:FindFirstChild("ServeTea",true))Collection:AddTag(prompt,"TreeWorldTeaPrompt")
  for i=0,3 do
   local angle=i*math.pi*.5 local point=centre+Vector3.new(math.cos(angle)*4.2,0,math.sin(angle)*4.2)
   local chair=chairTemplate:Clone()chair.Name="AntiqueTeaChair"chair:SetAttribute("SourceAssetId",8474839527)
   chair:PivotTo(CFrame.lookAt(point,Vector3.new(centre.X,point.Y,centre.Z)))chair.Parent=corner
   for _,p in ipairs(chair:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
    if p.Name:find("Cushion")then p.Color=Color3.fromRGB(169,145,155)end
   end end
   local seat=assert(chair:FindFirstChildOfClass("Seat"))seat.Name="TeaSeat"seat.Transparency=1 seat.CanCollide=false seat.CanTouch=false
   local support=part(chair,"ChairSeatCollision",Vector3.new(2,.13,1.6),seat.CFrame,Color3.new(),Enum.Material.Wood,true)support.Transparency=1
   local sit=Instance.new("ProximityPrompt")sit.Name="SitPrompt"sit.ActionText="Sentar e tomar chá"sit.ObjectText="Chá da tarde"sit.HoldDuration=.2 sit.MaxActivationDistance=7 sit.RequiresLineOfSight=false sit.Parent=seat
   local link=Instance.new("ObjectValue")link.Name="TeaPrompt"link.Value=prompt link.Parent=seat Collection:AddTag(seat,"RuinSeat")report.chairs+=1
  end
  corner:SetAttribute("TeaTable",true)report.teaTables+=1
 end
 tea(world.Amenities.ForestRuins.TeaCorner)
 -- Refresh all clothes, body parts and layered accessories from the account right now.
 local old=world.OwnerNPC local oldRoot=old.HumanoidRootPart local heading=oldRoot.CFrame.Rotation
 local stump=world.Amenities.CutTrunks.OwnerCutTrunk local seatTop=stump:GetAttribute("SeatTop")
 local desc=game.Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
 local npc=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)npc.Name="OwnerNPC"strip(npc)
 npc:SetAttribute("AvatarUserId",8344738123)npc:SetAttribute("ShirtAssetId",desc.Shirt)npc:SetAttribute("PantsAssetId",desc.Pants)npc:SetAttribute("TorsoAssetId",desc.Torso)npc:SetAttribute("HeadAssetId",desc.Head)desc:Destroy()
 npc:SetAttribute("AvatarUpdatedUTC","2026-10-14")npc:SetAttribute("EmoteAssetId",127049078545834)npc:SetAttribute("EmoteAnimationId",92824429927180)npc:SetAttribute("Seated",true)
 local root=assert(npc.HumanoidRootPart)npc.PrimaryPart=root npc.Parent=world npc.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,p in ipairs(npc:GetDescendants())do if p:IsA("BasePart")then p.Anchored=p==root p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Massless=true end end
 local hum=npc.Humanoid hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.WalkSpeed=0 hum.JumpPower=0 hum.AutoRotate=false hum.BreakJointsOnDeath=false
 local animation=Instance.new("Animation")animation.Name="CatBath"animation.AnimationId="rbxassetid://92824429927180"animation.Parent=npc
 local animator=hum:FindFirstChildOfClass("Animator")or Instance.new("Animator",hum)local track=animator:LoadAnimation(animation)track.Looped=true track:Play(0)
 local deadline=os.clock()+8 repeat task.wait(.1)until track.Length>0 or os.clock()>deadline assert(track.Length>0,"Exact Cat Bath emote is unavailable")
 npc:PivotTo(CFrame.new(0,100,0))track.TimePosition=.8 animator:StepAnimations(0)
 local done={[root]=true}local motors={}for _,m in ipairs(npc:GetDescendants())do if m:IsA("Motor6D")then motors[#motors+1]=m end end
 for _=1,18 do for _,m in ipairs(motors)do if done[m.Part0]and not done[m.Part1]then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.Transform*m.C1:Inverse()done[m.Part1]=true end end end
 local lower=npc.LowerTorso local offset=root.CFrame:PointToObjectSpace(lower.Position)
 local halfY=(math.abs(lower.CFrame.UpVector.Y)*lower.Size.Y+math.abs(lower.CFrame.RightVector.Y)*lower.Size.X+math.abs(lower.CFrame.LookVector.Y)*lower.Size.Z)*.5
 local target=seatTop+Vector3.new(0,halfY+.05,0)local placement=CFrame.new(target)*heading*CFrame.new(-offset)
 npc:PivotTo(placement)npc:SetAttribute("SeatCFrame",placement)npc:SetAttribute("SeatTop",seatTop)npc:SetAttribute("SeatedTorsoOffset",offset)npc:SetAttribute("SeatedTorsoHalfY",halfY)
 track:Stop(0)track:Destroy()animator:Destroy()
 for _,name in ipairs({"HiVoice","YayVoice"})do local sound=old.Head:FindFirstChild(name)if sound then local copy=sound:Clone()copy.Volume=name=="HiVoice"and .26 or .22 copy.RollOffMaxDistance=22 copy.Parent=npc.Head end end
 old:Destroy()Collection:AddTag(npc,"ForestOwnerNPC")
 local remote=runtime:FindFirstChild("OwnerDialogue")if remote then remote:Destroy()end local pose=runtime:FindFirstChild("NPCPose")if pose then pose:Destroy()end
 chairRaw:Destroy()tableRaw:Destroy()
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 return report
end
return Builder
]============]).install()
local bridgeReport=factory([============[local Builder={}
function Builder.install()
 local world=workspace.ForestWorld local Collection=game:GetService("CollectionService")local folder=world.Amenities.WoodenBridges
 local endpoints={}for _,m in ipairs(folder:GetChildren())do endpoints[#endpoints+1]={a=m:GetAttribute("DeckStart"),b=m:GetAttribute("DeckEnd")}end
 local raw=game:GetService("AssetService"):LoadAssetAsync(117077041338395)local template=assert(raw:FindFirstChildOfClass("Model"))
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()end end
 template:PivotTo(CFrame.identity)
 local function bounds(model)
  local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(v)hi=hi:Max(v)end end end end end return lo,hi
 end
 local lo,hi=bounds(template)local sourceLength=hi.X-lo.X
 local mid=Vector3.new((lo.X+hi.X)*.5,0,(lo.Z+hi.Z)*.5)template:PivotTo(template:GetPivot()-mid)template.PrimaryPart=nil template.WorldPivot=CFrame.identity
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={workspace.Terrain}params.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),params)end
 for _,m in ipairs(folder:GetChildren())do m:Destroy()end
 local report={bridges=0,segments=0}
 for index,item in ipairs(endpoints)do
  local a,b=item.a,item.b
  local bankA,bankB=assert(ground(a.X,a.Z)),assert(ground(b.X,b.Z))
  a=Vector3.new(a.X,bankA.Position.Y+.10,a.Z)b=Vector3.new(b.X,bankB.Position.Y+.10,b.Z)
  local span=(Vector3.new(b.X-a.X,0,b.Z-a.Z)).Magnitude
  local model=Instance.new("Model")model.Name="ArchedWoodenBridge"..index model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model:SetAttribute("SourceAssetId",117077041338395)model.Parent=folder
  local visual=template:Clone()visual.Name="NativeBridge"visual:ScaleTo((b-a).Magnitude/(sourceLength-4.0))visual.Parent=model
  for _,p in ipairs(visual:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=true p.CanTouch=false end end
  local scale=visual:GetScale()local edgeX=span*.5 local localRay=RaycastParams.new()localRay.FilterType=Enum.RaycastFilterType.Include localRay.FilterDescendantsInstances={visual}
  local sourceHit=assert(workspace:Raycast(Vector3.new(-edgeX+1,100,0),Vector3.new(0,-200,0),localRay),"Native bridge deck endpoint missing")
  local forward=(b-a).Unit local up=(Vector3.yAxis-forward*forward.Y).Unit
  local basis=CFrame.fromMatrix((a+b)*.5,forward,up)
  visual:PivotTo(basis*CFrame.new(0,-sourceHit.Position.Y+.10,0))task.wait()
  local nodes={}local count=64
  for i=0,count do
   local t=i/count local point=a:Lerp(b,t)
   local h=workspace:Raycast(point+Vector3.new(0,60,0),Vector3.new(0,-120,0),localRay)
   if not h then
    for _,offset in ipairs({-.25,.25,-.5,.5,-.9,.9})do
     h=workspace:Raycast(point+forward*offset+Vector3.new(0,60,0),Vector3.new(0,-120,0),localRay)if h then break end
    end
   end
   assert(h,"Native bridge has no plank at "..i)nodes[#nodes+1]=Vector3.new(point.X,h.Position.Y+.015,point.Z)
  end
  local width=math.clamp((hi.Z-lo.Z)*scale*.78,7,14)
  for i=1,#nodes-1 do local p,q=nodes[i],nodes[i+1]local cf=CFrame.lookAt((p+q)*.5,q)
   local collision=Instance.new("Part")collision.Name="WalkwayCollision"collision.Size=Vector3.new(width,.22,(q-p).Magnitude+.10)collision.CFrame=cf*CFrame.new(0,-.11,0)collision.Transparency=1 collision.Anchored=true collision.CanCollide=true collision.CanQuery=true collision.CanTouch=false collision.Parent=model report.segments+=1
  end
  for _,t in ipairs({.02,.28,.72,.98})do local point=nodes[math.floor(t*count)+1]
   for _,side in ipairs({-1,1})do
    local p=point+Vector3.new(0,0,side*(width*.5+.25))local bed=assert(ground(p.X,p.Z))local height=math.max(.5,p.Y-.35-bed.Position.Y+.3)
    local support=Instance.new("Part")support.Name="MasonrySupport"support.Size=Vector3.new(1.15,height,1.15)support.CFrame=CFrame.new(p.X,p.Y-.35-height*.5,p.Z)support.Material=Enum.Material.Slate support.Color=Color3.fromRGB(112,111,93)support.Anchored=true support.CanCollide=true support.CanTouch=false support:SetAttribute("GroundPoint",bed.Position)support.Parent=model
   end
  end
  model:SetAttribute("DeckStart",nodes[1])model:SetAttribute("DeckEnd",nodes[#nodes])model:SetAttribute("DeckWidth",width)
  local json={}for _,p in ipairs(nodes)do json[#json+1]={p.X,p.Y,p.Z}end model:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(json))
  report.bridges+=1
 end
 raw:Destroy()return report
end
return Builder
]============]).install()
local extraReport=factory([============[local Builder={}
local Collection=game:GetService("CollectionService")local STONE=Color3.fromRGB(156,163,141)local GREEN=Color3.fromRGB(64,100,46)
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local rng=Random.new(9014)
 local folder=Instance.new("Folder")folder.Name="ForestLandmarks"folder.Parent=world.Amenities
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
 local function p(parent,name,size,cf,color,material,collide)
  local v=Instance.new("Part")v.Name=name v.Size=size v.CFrame=cf v.Color=color or STONE v.Material=material or Enum.Material.Limestone v.Anchored=true v.CanCollide=collide~=false v.CanQuery=v.CanCollide v.CanTouch=false v.Parent=parent return v
 end
 local function line(parent,name,a,b,thickness,color,material)return p(parent,name,Vector3.new(thickness,thickness,(b-a).Magnitude+.02),CFrame.lookAt((a+b)*.5,b),color,material,false)end
 local function cylinder(parent,name,diameter,height,cf,color)
  local v=p(parent,name,Vector3.new(height,diameter,diameter),cf*CFrame.Angles(0,0,math.pi*.5),color,Enum.Material.Limestone,true)v.Shape=Enum.PartType.Cylinder return v
 end
 local function site(target,r)
  local best,score
  for radius=0,64,8 do for i=0,11 do
   local a=i*math.pi/6 local x,z=target.X+math.cos(a)*radius,target.Y+math.sin(a)*radius local centre=ground(x,z)
   if centre and centre.Material~=Enum.Material.Water and centre.Position.Y>10 then
    local lo,hi=centre.Position.Y,centre.Position.Y local valid=true
    for n=0,7 do local b=n*math.pi/4 local h=ground(x+math.cos(b)*r,z+math.sin(b)*r)if not h or h.Material==Enum.Material.Water then valid=false break end lo=math.min(lo,h.Position.Y)hi=math.max(hi,h.Position.Y)end
    local merit=hi-lo+radius*.02 if valid and hi-lo<5 and(not score or merit<score)then best=Vector3.new(x,hi+.35,z)score=merit end
   end
  end end return assert(best,"No dry supported landmark site")
 end
 local function platform(name,target,r)
  local origin=site(target,r)local model=Instance.new("Model")model.Name=name model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model:SetAttribute("Origin",origin)model.Parent=folder
  for _,group in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,m in ipairs(group:GetChildren())do local point=m:GetPivot().Position if(Vector2.new(point.X-origin.X,point.Z-origin.Z)).Magnitude<r+9 then m:Destroy()end end end
  local cf=CFrame.new(origin)
  local floor=p(model,"LandmarkFloor",Vector3.new(r*2,.6,r*2),cf*CFrame.new(0,-.3,0),STONE,Enum.Material.Limestone,true)
  for x=-r+2,r-2,4 do for z=-r+2,r-2,4 do
   local h=assert(ground(origin.X+x,origin.Z+z))local height=math.max(.45,origin.Y-.6-h.Position.Y+.3)
   local base=p(model,"LandmarkFoundation",Vector3.new(4.1,height,4.1),cf*CFrame.new(x,-.6-height*.5,z),Color3.fromRGB(126,134,118),Enum.Material.Slate,true)base:SetAttribute("GroundPoint",h.Position)
  end end
  for _=1,12 do local x,z=rng:NextNumber(-r+1,r-1),rng:NextNumber(-r+1,r-1)p(model,"GroundMoss",Vector3.new(rng:NextNumber(.6,1.6),.025,rng:NextNumber(.5,1.4)),cf*CFrame.new(x,.015,z),GREEN,Enum.Material.Grass,false)end
  -- Steps run from the local ground to the platform, including every rise on a slope.
  local entry=ground(origin.X,origin.Z+r+10)local start=assert(entry).Position local count=math.max(6,math.ceil((origin.Y-start.Y)/.4))
  for i=1,count do local t=i/count local z=origin.Z+r+10*(1-t)local top=start.Y+(origin.Y-start.Y)*t local h=assert(ground(origin.X,z))
   local height=math.max(.35,top-h.Position.Y+.3)local step=p(model,"LandmarkStep",Vector3.new(7,height,10/count+.15),CFrame.new(origin.X,top-height*.5,z),STONE,Enum.Material.Limestone,true)step:SetAttribute("GroundPoint",h.Position)
  end
  return model,cf
 end
 local function ivy(parent,cf,height,radius)
  for i=0,27 do local a=i*.62 local b=(i+1)*.62 local y=i*height/28 local yy=(i+1)*height/28
   line(parent,"IvyVine",(cf*CFrame.new(math.cos(a)*radius,y,math.sin(a)*radius)).Position,(cf*CFrame.new(math.cos(b)*radius,yy,math.sin(b)*radius)).Position,.09,GREEN,Enum.Material.Grass)
   local leaf=p(parent,"IvyLeaf",Vector3.new(.6,.07,.3),cf*CFrame.new(math.cos(a)*(radius+.15),y,math.sin(a)*(radius+.15))*CFrame.Angles(.4,a,.1),GREEN,Enum.Material.Grass,false)leaf.Shape=Enum.PartType.Ball
  end
 end
 local function column(parent,cf,height)
  p(parent,"ColumnPlinth",Vector3.new(3,.5,3),cf*CFrame.new(0,.25,0))cylinder(parent,"ColumnShaft",1.7,height,cf*CFrame.new(0,.5+height*.5,0),STONE)
  for _,y in ipairs({.7,height+.5})do cylinder(parent,"ColumnMoulding",2.15,.3,cf*CFrame.new(0,y,0),Color3.fromRGB(183,186,161))end
  p(parent,"Capital",Vector3.new(2.9,.6,2.9),cf*CFrame.new(0,height+.9,0))ivy(parent,cf,.5+height,.93)
 end
 local mist,mc=platform("MossySanctuary",Vector2.new(-245,-45),14)
 mist:SetAttribute("ReferenceStyle","Mossy stairs and circular stone sanctuary")
 -- Two wrapped gateway columns frame a stairway to a circular, broken-roof sanctuary.
 for _,side in ipairs({-1,1})do column(mist,mc*CFrame.new(side*8,0,10),14)
  for z=-8,8,4 do p(mist,"BrokenSideWall",Vector3.new(1.5,rng:NextNumber(1.8,3.6),3.7),mc*CFrame.new(side*12,1.4,z),STONE,Enum.Material.Cobblestone,true)end
 end
 for i=0,7 do local a=i*math.pi/4 column(mist,mc*CFrame.new(math.cos(a)*7,0,math.sin(a)*7-3),8)
  if i~=2 and i~=3 then local pos=Vector3.new(math.cos(a)*7,9.8,math.sin(a)*7-3)p(mist,"BrokenCircularLintel",Vector3.new(5.9,.8,2.6),mc*CFrame.new(pos)*CFrame.Angles(0,-a+math.pi*.5,0))end
 end
 p(mist,"Altar",Vector3.new(5,1.2,3),mc*CFrame.new(0,.6,-6),Color3.fromRGB(185,189,164),Enum.Material.Marble,true)
 local torii,tc=platform("StoneToriiGlade",Vector2.new(230,-95),12)torii:SetAttribute("ReferenceStyle","Weathered stone torii and scattered stepping stones")
 for gate=0,2 do local z=-8+gate*7 local h=gate==1 and 12 or 9
  for _,side in ipairs({-1,1})do cylinder(torii,"ToriiPillar",1.35,h,tc*CFrame.new(side*6,h*.5,z),Color3.fromRGB(116,127,124))p(torii,"ToriiBase",Vector3.new(2.6,.4,2.6),tc*CFrame.new(side*6,.2,z),Color3.fromRGB(133,146,136))end
  p(torii,"ToriiLintel",Vector3.new(17,.8,1.1),tc*CFrame.new(0,h,z),Color3.fromRGB(132,143,137),Enum.Material.Slate,true)
  for _,side in ipairs({-1,1})do p(torii,"RaisedLintelEnd",Vector3.new(3.4,.8,1.1),tc*CFrame.new(side*9,h+.15,z)*CFrame.Angles(0,0,side*.12),Color3.fromRGB(132,143,137),Enum.Material.Slate,true)end
  p(torii,"ToriiTie",Vector3.new(14,.5,.9),tc*CFrame.new(0,h-2,z),Color3.fromRGB(110,124,113))
 end
 local tower,wc=platform("BrokenWatchtower",Vector2.new(-260,220),12)tower:SetAttribute("ReferenceStyle","Broken forest tower with an armored skeleton guardian")
 for _,side in ipairs({-1,1})do for _,z in ipairs({-8,8})do column(tower,wc*CFrame.new(side*8,0,z),10)end
  p(tower,"WeatheredWall",Vector3.new(1.6,8,18),wc*CFrame.new(side*10,4,0),Color3.fromRGB(137,145,129),Enum.Material.Cobblestone,true)
 end
 for _,z in ipairs({-9,9})do p(tower,"BrokenRoofBeam",Vector3.new(20,1,2),wc*CFrame.new(0,11.7,z),Color3.fromRGB(179,183,163))end
 p(tower,"CrumbledRearWall",Vector3.new(14,4.5,1.5),wc*CFrame.new(0,2.25,-10),Color3.fromRGB(134,140,128),Enum.Material.Cobblestone,true)
 local raw=game:GetService("AssetService"):LoadAssetAsync(882493119)local skeleton=assert(raw:FindFirstChildOfClass("Model")):Clone()
 for _,d in ipairs(skeleton:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("ProximityPrompt")then d:Destroy()elseif d:IsA("BasePart")then d.Anchored=true d.CanCollide=false d.CanQuery=false d.CanTouch=false end end
 skeleton:PivotTo(CFrame.identity)local cf,size=skeleton:GetBoundingBox()skeleton:PivotTo(skeleton:GetPivot()-Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z))skeleton.PrimaryPart=nil skeleton.WorldPivot=CFrame.identity
 skeleton.Name="ArmoredSkeleton"skeleton:SetAttribute("SourceAssetId",882493119)skeleton:PivotTo(wc*CFrame.new(0,0,-5))skeleton.Parent=tower raw:Destroy()
 -- Two additional tea corners reuse the authored furniture and working prompts.
 local tea=world.Amenities.ForestRuins.TeaCorner
 for _,info in ipairs({{mist,mc*CFrame.new(21,0,5)},{torii,tc*CFrame.new(20,0,2)}})do
  local patio=info[2]local position=patio.Position
  p(info[1],"PatioLink",Vector3.new(4,.6,7),patio*CFrame.new(-7,-.3,0),STONE,Enum.Material.Limestone,true)
  p(info[1],"TeaPatioFloor",Vector3.new(14,.6,14),patio*CFrame.new(0,-.3,0),STONE,Enum.Material.Limestone,true)
  for x=-5,5,5 do for z=-5,5,5 do local hit=assert(ground(position.X+x,position.Z+z))
   local height=math.max(.4,position.Y-.6-hit.Position.Y+.3)local foundation=p(info[1],"LandmarkFoundation",Vector3.new(5.1,height,5.1),patio*CFrame.new(x,-.6-height*.5,z),STONE,Enum.Material.Slate,true)foundation:SetAttribute("GroundPoint",hit.Position)
  end end
  for _,group in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,m in ipairs(group:GetChildren())do local point=m:GetPivot().Position if(Vector2.new(point.X-position.X,point.Z-position.Z)).Magnitude<11 then m:Destroy()end end end
  local corner=tea:Clone()corner.Name="TeaCorner"local originalTable=corner.AntiqueTeaTable
  local origin=originalTable:GetPivot()local delta=info[2]*origin:Inverse()
  corner:PivotTo(delta*corner:GetPivot())corner.Parent=info[1]
  local prompt=assert(corner:FindFirstChild("ServeTea",true))Collection:AddTag(prompt,"TreeWorldTeaPrompt")
  for _,d in ipairs(corner:GetDescendants())do if d:IsA("Seat")then local link=d:FindFirstChild("TeaPrompt")if link then link.Value=prompt end Collection:AddTag(d,"RuinSeat")end end
 end
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())world:SetAttribute("RuinCount",4)
 return{ruins=4,additionalTeaTables=2,armoredSkeletons=1}
end
return Builder
]============]).install()
workspace.ForestWorld:SetAttribute("LanternCount",#game:GetService("CollectionService"):GetTagged("ForestNightLight"))
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
require(runtime:WaitForChild("NPCController")).start(runtime,world)
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
	local strength = 6.8 + math.sin(time * 0.047) * 0.45 + math.sin(time * 0.023) * 0.25
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestNPCClient",[============[-- The server plays the exact Cat Bath track. Proximity voice never overrides its arm or leg joints.
local Collection=game:GetService("CollectionService")
local function inspect(npc)
 for _,d in ipairs(npc:GetDescendants())do if d:IsA("ProximityPrompt")then d.Enabled=false end end
end
for _,npc in ipairs(Collection:GetTagged("ForestOwnerNPC"))do inspect(npc)end
local connection=Collection:GetInstanceAddedSignal("ForestOwnerNPC"):Connect(inspect)
script.Destroying:Connect(function()connection:Disconnect()end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestGrassClient",[============[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
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
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestAmbienceClient",[============[local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Collection = game:GetService("CollectionService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
require(runtime:WaitForChild("Visuals")).apply()
while not workspace.CurrentCamera do Run.Heartbeat:Wait() end
local WindLines = require(runtime.WindEffects:WaitForChild("WindLines"))
local WindShake = require(runtime.WindEffects:WaitForChild("WindShake"))
local function foliage(part)
	if part:IsA("BasePart") then Collection:AddTag(part, "WindShake") end
end
for _, part in ipairs(Collection:GetTagged("ForestWindFoliage")) do foliage(part) end
local added = Collection:GetInstanceAddedSignal("ForestWindFoliage"):Connect(foliage)
local removed = Collection:GetInstanceRemovedSignal("ForestWindFoliage"):Connect(function(p) Collection:RemoveTag(p, "WindShake") end)
WindLines:Init({Direction = workspace.GlobalWind.Unit, Speed = 10, Lifetime = 2, SpawnRate = UIS.TouchEnabled and 5 or 8})
WindShake:SetDefaultSettings({WindDirection = workspace.GlobalWind.Unit, WindSpeed = 10, WindPower = 0.035})
WindShake:Init()
local animals = {}
local localFolder = Instance.new("Folder") localFolder.Name = "ForestLocalWildlife" localFolder.Parent = workspace
local function addAnimal(anchor)
	if not anchor:IsA("BasePart") or animals[anchor] then return end
	animals[anchor] = {anchor = anchor, model = nil, rest = anchor.CFrame}
end
local function removeAnimal(anchor)
	local entry = animals[anchor] if not entry then return end
	if entry.track then entry.track:Stop(0) end
	if entry.model then entry.model:Destroy() end animals[anchor] = nil
end
for _, a in ipairs(Collection:GetTagged("ForestWildlifeAnchor")) do addAnimal(a) end
local animalAdded = Collection:GetInstanceAddedSignal("ForestWildlifeAnchor"):Connect(addAnimal)
local animalRemoved = Collection:GetInstanceRemovedSignal("ForestWildlifeAnchor"):Connect(removeAnimal)
local function activate(entry)
	local template = runtime.WildlifeTemplates:FindFirstChild(entry.anchor:GetAttribute("WildlifeType"))
	if not template then return end
	local model = template:Clone() model:PivotTo(entry.rest) model.Parent = localFolder entry.model = model
	local controller = model:FindFirstChildOfClass("AnimationController")
	local animator = controller and controller:FindFirstChildOfClass("Animator")
	if animator then
		task.spawn(function()
			local animation = Instance.new("Animation") animation.AnimationId = "rbxassetid://" .. template:GetAttribute("AnimationId")
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end) animation:Destroy()
			if ok and entry.model == model then track.Looped = true track:Play(0.3, 1, 1) entry.track = track end
		end)
	end
end
local elapsed, scan = 0, 0
local step = Run.Heartbeat:Connect(function(dt)
	elapsed += dt scan += dt
	if elapsed < 1 / 24 then return end elapsed = 0
	local camera = workspace.CurrentCamera if not camera then return end
	local now = workspace:GetServerTimeNow()
	if scan > 0.5 then
		scan = 0 local wind = workspace.GlobalWind
		if wind.Magnitude > 0.01 then WindLines.Direction = wind.Unit end
		WindLines.Speed = math.clamp(wind.Magnitude * 1.2, 6, 13)
		WindShake:SetDefaultSettings({WindDirection = wind.Unit, WindSpeed = WindLines.Speed, WindPower = 0.035})
	end
	local active = 0
	for _, entry in pairs(animals) do
		local distance = (entry.rest.Position - camera.CFrame.Position).Magnitude
		if distance < 65 and active < (UIS.TouchEnabled and 4 or 8) then
			active += 1 if not entry.model then activate(entry) end
			if entry.model then
				local phase = entry.rest.Z * 0.07
				entry.model:PivotTo(entry.rest + Vector3.new(math.sin(now * 0.4 + phase) * 1.8, math.sin(now * 0.65 + phase) * 0.45, math.cos(now * 0.45 + phase) * 1.3))
			end
		elseif entry.model then
			if entry.track then entry.track:Stop(0) entry.track = nil end
			entry.model:Destroy() entry.model = nil
		end
	end
end)
script.Destroying:Connect(function()
	step:Disconnect() added:Disconnect() removed:Disconnect() animalAdded:Disconnect() animalRemoved:Disconnect()
	WindLines:Cleanup() WindShake:Cleanup()
	for anchor in pairs(animals) do removeAnimal(anchor) end localFolder:Destroy()
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
 elapsed+=dt if elapsed<1/15 then return end elapsed=0
 local epoch=runtime:GetAttribute("CycleEpoch")if not epoch then return end
 local clock=Cycle.clock(workspace:GetServerTimeNow(),epoch)Visuals.clock(clock)
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 if root then Seasons.visual(root.Position,Cycle.daylight(clock))end
 local origin=runtime:GetAttribute("RuinOrigin")
 if root and origin then Mood.apply(root.Position,origin,player:GetAttribute("RuinLocalMood")or "Dourado",Cycle.daylight(clock))end
 local night=Cycle.night(clock)
 for light in pairs(lights)do if light.Parent then light.Enabled=night>.015 light.Brightness=night*1.7 else lights[light]=nil end end
end)
script.Destroying:Connect(function()connection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()table.clear(lights)end)
]============])
source(game.StarterGui.TreeWorldMenu,"LocalScript","TreeWorldMenuClient",[============[local Players=game:GetService("Players")local Run=game:GetService("RunService")local Tween=game:GetService("TweenService")local Starter=game:GetService("StarterGui")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local gui=script.Parent local loading=gui:WaitForChild("Background")local menu=gui:WaitForChild("MainMenu")local button=menu:WaitForChild("PlayButton")
local controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()controls:Disable()
local blur=game.Lighting:WaitForChild("TreeWorldMenuBlur")blur.Enabled=true blur.Size=8
player:SetAttribute("TreeWorldMenuOpen",true)
loading.Visible=true menu.Visible=false
local originalCore={}for _,kind in ipairs({Enum.CoreGuiType.Backpack,Enum.CoreGuiType.Health,Enum.CoreGuiType.PlayerList})do
 pcall(function()originalCore[kind]=Starter:GetCoreGuiEnabled(kind)Starter:SetCoreGuiEnabled(kind,false)end)
end
local hidden={}local characterConnection=player.CharacterAdded:Connect(function(character)
 if player:GetAttribute("TreeWorldMenuOpen")then for _,p in ipairs(character:GetDescendants())do if p:IsA("BasePart")then hidden[p]=p.LocalTransparencyModifier p.LocalTransparencyModifier=1 end end end
end)
if player.Character then for _,p in ipairs(player.Character:GetDescendants())do if p:IsA("BasePart")then hidden[p]=p.LocalTransparencyModifier p.LocalTransparencyModifier=1 end end end
local camera=workspace.CurrentCamera
local saved={kind=camera.CameraType,field=camera.FieldOfView}
local opened=true local origin=runtime:GetAttribute("MenuCameraCF")local focus=runtime:GetAttribute("MenuCameraFocus")
local time=0
local connection=Run.RenderStepped:Connect(function(dt)
 if not opened then return end time+=dt local c=workspace.CurrentCamera if not c then return end
 c.CameraType=Enum.CameraType.Scriptable c.FieldOfView=58
 if origin and focus then local p=origin.Position+Vector3.new(math.sin(time*.045)*2,.3*math.sin(time*.07),0)c.CFrame=CFrame.lookAt(p,focus)c.Focus=CFrame.new(focus)end
end)
Tween:Create(loading.Bar.LoadBar,TweenInfo.new(3,Enum.EasingStyle.Sine),{Size=UDim2.fromScale(1,1)}):Play()
task.delay(3,function()if not opened then return end loading.Visible=false menu.Visible=true blur.Size=5 end)
local function enter()
 if not opened then return end opened=false player:SetAttribute("TreeWorldMenuOpen",false)
 connection:Disconnect()characterConnection:Disconnect()controls:Enable()
 for p,value in pairs(hidden)do if p.Parent then p.LocalTransparencyModifier=value end end table.clear(hidden)
 local c=workspace.CurrentCamera local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 c.CameraType=Enum.CameraType.Custom if h then c.CameraSubject=h end c.FieldOfView=saved.field
 blur.Enabled=false blur.Size=0 for kind,state in pairs(originalCore)do pcall(function()Starter:SetCoreGuiEnabled(kind,state)end)end
 gui.Enabled=false
end
button.Activated:Connect(enter)
script.Destroying:Connect(function()if opened then enter()end end)
]============])
run(game.ServerScriptService.ForestServer.Source)
local tests=run([============[local world=assert(workspace.ForestWorld)local runtime=game.ReplicatedStorage.ForestRuntime
assert(world:GetAttribute("UpgradeVersion")==90 and world:GetAttribute("SeasonLayout")=="TemporalGlobal"and world:GetAttribute("GameName")=="TreeWorld")
local Seasons=require(runtime.Seasons)
assert(Seasons.index(0,0)==1 and Seasons.index(599.9,0)==1 and Seasons.index(600,0)==2 and Seasons.index(1200,0)==3 and Seasons.index(1800,0)==4 and Seasons.index(2400,0)==1)
assert(Seasons.at(-250,-200)==Seasons.at(250,200)and runtime:GetAttribute("GrassMotionEnabled")==false)
local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),groundRay)end
local report={bridges=0,bridgeWalkProbes=0,landmarkFoundations=0,teaSeats=0,teaTables=0,ruins=4,staticGrass=true,globalSeasonTests=0}
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 assert(bridge:GetAttribute("SourceAssetId")==117077041338395)
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={bridge}ray.RespectCanCollide=true
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5})do local p=a:Lerp(b,t)local hit=assert(workspace:Raycast(p+Vector3.new(0,3,0),Vector3.new(0,-6,0),ray),"Missing bridge walking collision")
   assert(hit.Instance.Name=="WalkwayCollision"and math.abs(hit.Position.Y-p.Y)<.18,"Bridge walking surface discontinuity")report.bridgeWalkProbes+=1
  end
 end
 for _,index in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[index]))local hit=assert(ground(p.X,p.Z))assert(hit.Material~=Enum.Material.Water and math.abs(hit.Position.Y-p.Y)<1.4,"Bridge does not meet the bank: "..bridge.Name.." end "..index.." deck="..p.Y.." terrain="..hit.Position.Y)end
 for _,p in ipairs(bridge:GetChildren())do if p.Name=="MasonrySupport"then local g=p:GetAttribute("GroundPoint")assert(p.Position.Y-p.Size.Y*.5<=g.Y+.01)end end
 report.bridges+=1
end
assert(report.bridges==2)
local ruins=world.Amenities.ForestRuins local geometry=RaycastParams.new()geometry.FilterType=Enum.RaycastFilterType.Include geometry.FilterDescendantsInstances={ruins}geometry.RespectCanCollide=true
local arches=0
for _,m in ipairs(ruins.Arcade:GetChildren())do if m.Name=="StoneArch"then local point=m:GetAttribute("OpeningCentre")assert(not workspace:Raycast(point-Vector3.zAxis*4,Vector3.zAxis*8,geometry))arches+=1 end end assert(arches==6)
local landmarks=world.Amenities.ForestLandmarks assert(#landmarks:GetChildren()==3 and landmarks.BrokenWatchtower:FindFirstChild("ArmoredSkeleton"))
for _,d in ipairs(landmarks:GetDescendants())do
 if d.Name=="LandmarkFoundation"then local point=d:GetAttribute("GroundPoint")local hit=assert(ground(point.X,point.Z))assert(d.Position.Y-d.Size.Y*.5<=hit.Position.Y+.05,"Floating ruin foundation")report.landmarkFoundations+=1 end
end
local Collection=game:GetService("CollectionService")
for _,prompt in ipairs(Collection:GetTagged("TreeWorldTeaPrompt"))do if prompt:IsDescendantOf(world)then report.teaTables+=1 end end
for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
 if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
  report.teaSeats+=1 local link=assert(seat:FindFirstChild("TeaPrompt"))assert(link.Value and link.Value:IsDescendantOf(world))
  local corner=seat.Parent.Parent local table=assert(corner.AntiqueTeaTable)local aim=Vector3.new(table:GetPivot().X-seat.Position.X,0,table:GetPivot().Z-seat.Position.Z).Unit
  assert(seat.CFrame.LookVector:Dot(aim)>.85,"Chair faces away from its tea table: "..seat:GetFullName().." dot="..seat.CFrame.LookVector:Dot(aim))
  local floorRay=RaycastParams.new()floorRay.FilterType=Enum.RaycastFilterType.Include floorRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities}floorRay.RespectCanCollide=true
  local pivot=seat.Parent:GetPivot().Position local h=assert(workspace:Raycast(pivot+Vector3.new(0,.05,0),Vector3.new(0,-3,0),floorRay),"Antique chair has no floor")
  assert(math.abs(pivot.Y-h.Position.Y)<.2,"Antique chair floats above the floor")
 end
end
assert(report.teaTables==3 and report.teaSeats==12)
local npc=world.OwnerNPC local root=npc.HumanoidRootPart assert(npc.Humanoid.RigType==Enum.HumanoidRigType.R15 and root.Anchored and npc:GetAttribute("EmoteAssetId")==127049078545834 and not runtime:FindFirstChild("OwnerDialogue")and not npc.Head:FindFirstChild("TalkPrompt"))
local desc=npc.Humanoid:GetAppliedDescription()assert(desc.Shirt==npc:GetAttribute("ShirtAssetId")and desc.Pants==npc:GetAttribute("PantsAssetId")and desc.Torso==npc:GetAttribute("TorsoAssetId")and desc.Head==npc:GetAttribute("HeadAssetId"))desc:Destroy()
local controller=require(runtime.NPCController)
assert(controller.shouldGreet(10,36,2,false)and controller.shouldGreet(8,36,0,true)and not controller.shouldGreet(18,36,2,true)and not controller.shouldGreet(8,2,2,true))
local animator=npc.Humanoid.Animator local track
for _,candidate in ipairs(animator:GetPlayingAnimationTracks())do if candidate.Animation and candidate.Animation.AnimationId=="rbxassetid://92824429927180"then track=candidate break end end
assert(track and track.Length>2 and track.IsPlaying and track.Looped,"Exact emote playback missing: "..tostring(track and track.Length).." / "..tostring(track and track.IsPlaying))
local original=root.CFrame
track.TimePosition=.8 animator:StepAnimations(0)
local done={[root]=true}local motors={}for _,m in ipairs(npc:GetDescendants())do if m:IsA("Motor6D")then motors[#motors+1]=m end end
for _=1,18 do for _,m in ipairs(motors)do if done[m.Part0]and not done[m.Part1]then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.Transform*m.C1:Inverse()done[m.Part1]=true end end end
local contactY=npc.LowerTorso.Position.Y-npc:GetAttribute("SeatedTorsoHalfY")assert(math.abs(contactY-npc:GetAttribute("SeatTop").Y-.05)<.18,"Cat Bath avatar is not seated on the cut trunk")
for _,sound in ipairs({npc.Head.HiVoice,npc.Head.YayVoice})do game:GetService("ContentProvider"):PreloadAsync({sound})assert(sound.IsLoaded and sound.TimeLength>0 and sound.RollOffMaxDistance<=24)sound:Play()end
assert(root.CFrame==original and track.IsPlaying,"Greeting interrupts the emote or moves the avatar")
report.catBathLength=track.Length report.currentAvatar=true report.noDialogue=true report.catBathSeatGap=contactY-npc:GetAttribute("SeatTop").Y
local menu=assert(game.StarterGui.TreeWorldMenu)assert(menu:GetAttribute("SourceAssetId")==17216750157 and menu.ResetOnSpawn==false and menu.MainMenu.PlayButton.Text=="Entrar"and menu.MainMenu.GameTitle.Text=="TreeWorld")
assert(menu.MainMenu.PlayButton.Size.Y.Offset>=48 and menu.MainMenu.PlayButton:FindFirstChildOfClass("UISizeConstraint")and menu:FindFirstChild("TreeWorldMenuClient"))
assert(runtime:GetAttribute("MenuCameraCF")and runtime:GetAttribute("MenuCameraFocus")and not game.Lighting.TreeWorldMenuBlur.Enabled)
report.importedMenu=true
-- Exercise temporal seasons on actual terrain while proving that neither water nor solid occupancy changes.
runtime:SetAttribute("SeasonTestMode",true)
local service=require(runtime.SeasonController).start(runtime,world)
local probes={Vector2.new(-280,-40),Vector2.new(-240,110),Vector2.new(160,-180),Vector2.new(240,210)}
local references={}for _,v in ipairs(probes)do local h=assert(ground(v.X,v.Y))references[#references+1]={v=v,y=h.Position.Y}end
local region=Region3.new(Vector3.new(-32,-16,-32),Vector3.new(32,24,32))
local before=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
for _,index in ipairs({3,4,2,1})do
 assert(service.apply(index,true))assert(runtime:GetAttribute("SeasonIndex")==index)
 for _,item in ipairs(references)do local h=assert(ground(item.v.X,item.v.Y))assert(math.abs(h.Position.Y-item.y)<.05,"Season transition changed terrain height")
  if index==4 then assert(h.Material==Enum.Material.Snow or h.Material==Enum.Material.Rock or h.Material==Enum.Material.Ground)end
 end
 local after=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
 for x=1,before.Size.X do for y=1,before.Size.Y do for z=1,before.Size.Z do assert(before.SolidOccupancy[x][y][z]==after.SolidOccupancy[x][y][z]and before.LiquidOccupancy[x][y][z]==after.LiquidOccupancy[x][y][z],"Season alters river geometry")end end end
 assert(Seasons.at(-280,-200)==Seasons.at(200,200))report.globalSeasonTests+=1
 if index==4 then assert(#require(runtime.Scene).around(Vector3.new(-280,0,50),42)==0,"Grass remains in winter")end
end
runtime:SetAttribute("SeasonTestMode",nil)
report.terrainChannelsPreserved=true report.grassSourceId=world:GetAttribute("GrassAssetId")
return report
]============])
local forestTests=run([============[local world=assert(workspace:FindFirstChild("ForestWorld"))
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(world:GetAttribute("ForestOnly")and world:GetAttribute("UpgradeVersion")==90)
assert(not workspace:FindFirstChild("MonCalamariWorld")and not workspace:FindFirstChild("IlhaSerena"))
local Scene=require(runtime.Scene)
local npc=assert(world:FindFirstChild("OwnerNPC"))
local parts,meshes,pbr,foreign=0,0,0,0
for _,d in ipairs(world:GetDescendants())do
 if d:IsA("BasePart")then parts+=1 if not d:IsDescendantOf(npc)then assert(d.Anchored,d:GetFullName().." unanchored")end end
 if d:IsA("MeshPart")then meshes+=1 end
 if d:IsA("SurfaceAppearance")then pbr+=1 end
 if d:IsA("LuaSourceContainer")then foreign+=1 end
end
assert(foreign==0 and meshes>2000 and pbr>1800,"PBR forest or imported-script isolation failed")
assert(world:GetAttribute("TreeCount")>350 and world:GetAttribute("PlantCount")>1000)
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
local treeCount,plantCount,supports,maxGap,maxBurial,tallest,shortest=0,0,0,0,0,0,math.huge
local buriedExamples={}
for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do
 for _,model in ipairs(folder:GetChildren())do
  local profile=assert(runtime.GroundingProfiles:FindFirstChild(model.Name),"Missing root profile")
  local pivot=model:GetPivot()local scale=model:GetAttribute("GroundingScale")
  assert(model:GetAttribute("SupportGeometryProbes")>0,model.Name.." has no lower geometry ray samples")
  local localBurial=0
  for _,point in ipairs(profile:GetChildren())do
   local p=pivot:PointToWorldSpace(point.Value*scale)
   local h=assert(ground(p.X,p.Z),"No terrain under lower geometry")
   if h.Material~=Enum.Material.Water then
    local gap=p.Y-h.Position.Y
    assert(gap<.035,model.Name.." floats at a lower contact: "..gap)
    supports+=1 maxGap=math.max(maxGap,gap)maxBurial=math.max(maxBurial,-gap)localBurial=math.max(localBurial,-gap)
   end
  end
  if localBurial>1 then buriedExamples[#buriedExamples+1]={kind=folder.Name,name=model.Name,burial=localBurial,position={pivot.X,pivot.Y,pivot.Z},scale=scale}end
  local p=pivot.Position local h=assert(ground(p.X,p.Z))
  assert(h.Material~=Enum.Material.Water,"Vegetation root is submerged")
  if folder==world.Decor.Trees then
   treeCount+=1 assert(model:FindFirstChild("TrunkCollision"))
   local _,size=model:GetBoundingBox()tallest=math.max(tallest,size.Y)shortest=math.min(shortest,size.Y)
  else plantCount+=1 end
 end
end
assert(supports>10000 and tallest>95 and tallest-shortest>45 and maxBurial<2.85,"Tree size variation or contact coverage insufficient")
local probes,green,water,trail,minY,maxY=0,0,0,0,math.huge,-math.huge
for x=-360,360,24 do for z=-336,336,24 do
 local h=ground(x,z)if h then probes+=1 minY=math.min(minY,h.Position.Y)maxY=math.max(maxY,h.Position.Y)
  if h.Material==Enum.Material.Water then water+=1
  elseif h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass then green+=1
  elseif h.Material==Enum.Material.Ground then trail+=1 end
 end
end end
assert(green>300 and water>40 and trail>10 and maxY-minY>50)
local riverProbes=0
for z=-288,288,8 do
 local h=assert(ground(Scene.riverX(z),z))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.RiverY)<.10,"River has a dry gap or uneven water plane at "..z)
 riverProbes+=1
end
assert(workspace.Terrain.WaterWaveSize>0 and workspace.Terrain.WaterReflectance<.3 and Scene.SeaY==Scene.RiverY)
for _,p in ipairs({Vector2.new(-750,0),Vector2.new(750,0),Vector2.new(0,-750),Vector2.new(0,750)})do
 local h=assert(ground(p.X,p.Y))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.SeaY)<.10,"Outer water has an abrupt edge")
end
local walks=256 -- curved bridge collision is checked by tests.luau
for _,d in ipairs(world:GetDescendants())do assert(d.Name~="RiverCrossingLog"and d.Name~="CrossingCollision","Old log crossing survived")end
local seats=0
for _,d in ipairs(world.Amenities.LogBenches:GetDescendants())do if d:IsA("Seat")then seats+=1 assert(d.Anchored and d:FindFirstChild("SitPrompt")and not d.CanCollide)end end
assert(seats>=12 and world:GetAttribute("CutTrunkCount")>=18 and world:GetAttribute("LanternCount")>=15)
local lights=game:GetService("CollectionService"):GetTagged("ForestNightLight")assert(#lights==world:GetAttribute("LanternCount"))
local spawn=runtime:GetAttribute("MainSpawnCF")
local spawnRay=RaycastParams.new()spawnRay.FilterType=Enum.RaycastFilterType.Include spawnRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities.ForestRuins.Courtyard.CourtyardFloor}
local floor=assert(workspace:Raycast(spawn.Position+Vector3.new(0,20,0),Vector3.new(0,-40,0),spawnRay))
assert(floor.Material~=Enum.Material.Water and floor.Normal.Y>.65 and math.abs(spawn.Y-floor.Position.Y-3.5)<.06)
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template.Mesh
assert(template:GetAttribute("SourceAssetId")==87377915371959 and Scene.Spacing==4 and mesh.Size.X<8 and mesh.Size.Y>1.2)
local bones,offsets={},{}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
assert(#bones==100)
for i,b in ipairs(bones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)lo=lo:Min(offsets[i])hi=hi:Max(offsets[i])end
assert(hi.X-lo.X>Scene.Spacing+1 and hi.Z-lo.Z>Scene.Spacing+1,"Grass root footprint does not overlap adjacent cells")
local sampler=require(runtime.GrassSampler).new(world)
local zones,roots,coveragePoints,misses=0,0,0,0
for _,centre in ipairs({Vector3.new(-240,0,110),Vector3.new(-280,0,40),Vector3.new(160,0,-180),Vector3.new(240,0,210)})do
 local buckets={}local zoneRoots=0
 local function key(x,z)return math.floor(x/2)..":"..math.floor(z/2)end
 for _,cell in ipairs(Scene.around(centre,25))do
  local heights,anchor,valid=sampler:sample(cell,offsets)
  if anchor then
   zoneRoots+=valid
   for i,y in pairs(heights)do
    local p=Vector3.new(cell.center.X+offsets[i].X,y,cell.center.Z+offsets[i].Z)
    local k=key(p.X,p.Z)buckets[k]=buckets[k]or{}buckets[k][#buckets[k]+1]=p
   end
  end
 end
 if zoneRoots>100 then zones+=1 roots+=zoneRoots end
 for x=centre.X-8,centre.X+8,1 do for z=centre.Z-8,centre.Z+8,1 do
  local h=ground(x,z)
  if h and(h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass)and h.Normal.Y>.35 then
   local blocked=RaycastParams.new()blocked.FilterType=Enum.RaycastFilterType.Include blocked.FilterDescendantsInstances={world.Decor,world.Amenities}blocked.RespectCanCollide=true
   if not workspace:Raycast(h.Position+Vector3.new(0,20,0),Vector3.new(0,-20,0),blocked)then
    coveragePoints+=1 local covered=false
    for dx=-1,1 do for dz=-1,1 do
     for _,p in ipairs(buckets[key(x+dx*2,z+dz*2)]or{})do if(Vector2.new(p.X-x,p.Z-z)).Magnitude<.90 then covered=true break end end
    end end
    if not covered then misses+=1 end
   end
  end
 end end
end
assert(zones>=3 and coveragePoints>400 and misses==0,"Green terrain still has gaps between grass root grids: "..misses.."/"..coveragePoints)
local Priority=require(runtime.GrassPriority)
local removals,queue=Priority.plan({[99]=true,[100]=true},{{key=1},{key=2}},2,{},0)
assert(#removals==2 and #queue==2 and queue[1].key==1,"Old distant patches prevent nearer grass")
assert(#Scene.around(spawn.Position,42)<=432 and #Scene.around(spawn.Position,70)<=1152,"Client grass budget cannot cover a complete circle")
assert(runtime:GetAttribute("GrassMotionEnabled")==false)
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGrassClient.Source:find("grass:Step",1,true))
assert(npc:GetAttribute("AvatarUserId")==8344738123 and npc.HumanoidRootPart.Anchored and npc:GetAttribute("Seated"))
local description=npc.Humanoid:GetAppliedDescription()
assert(description.Shirt==npc:GetAttribute("ShirtAssetId")and description.Pants==npc:GetAttribute("PantsAssetId")and description.Shirt>0 and description.Pants>0,"NPC does not wear owner's actual clothes")
description:Destroy()
assert(npc.Humanoid.RigType==Enum.HumanoidRigType.R15 and npc:FindFirstChild("CatBath")and not runtime:FindFirstChild("OwnerDialogue"))
local statuses={}
game:GetService("ContentProvider"):PreloadAsync({npc.Head.HiVoice,npc.Head.YayVoice},function(id,status)statuses[#statuses+1]=tostring(status)end)
assert(npc.Head.HiVoice.IsLoaded and npc.Head.HiVoice.TimeLength>0,"Requested greeting audio is unavailable in this experience")
assert(npc.Head.YayVoice.IsLoaded and npc.Head.YayVoice.TimeLength>0,"Yay voice is unavailable in this experience")
local Cycle=require(runtime.Cycle)local Visuals=require(runtime.Visuals)
assert(Cycle.clock(0,0)==6 and Cycle.clock(720,0)==18 and Cycle.clock(960,0)==6)
local epsilon=.001 local before=Cycle.clock(720-epsilon,0)local after=Cycle.clock(720+epsilon,0)
assert(math.abs(before-after)<.001,"Day/night cycle jumps")
local sunDirections={}
for _,hour in ipairs({6,12,18,0})do Visuals.clock(hour)sunDirections[#sunDirections+1]={game.Lighting:GetSunDirection().X,game.Lighting:GetSunDirection().Y,game.Lighting:GetSunDirection().Z}
 assert(game.Lighting.Brightness>=1 and game.Lighting.ForestColor.Enabled and Cycle.night(hour)>=0 and Cycle.night(hour)<=1)
end
assert(Cycle.night(0)>.9 and Cycle.night(12)<.01)
Visuals.clock(Cycle.StartClock)
assert(runtime:GetAttribute("CycleEpoch")and runtime:GetAttribute("ShaderPresetAssetId")==8490242417 and game.Lighting.ForestSky:GetAttribute("SourceAssetId")==8490242417)
assert(not game.Lighting.ForestBlur.Enabled and game.Lighting.ForestSunRays.Enabled)
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834 and workspace.GlobalWind.Magnitude>6)
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do
 for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
  local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
  local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..": "..tostring(result))compiled+=1
 end end
end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,result=pcall(require,s)assert(ok,s.Name..": "..tostring(result))compiled+=1 end end
assert(workspace.StreamingEnabled and #game.ServerScriptService:GetChildren()==1)
table.sort(buriedExamples,function(a,b)return a.burial>b.burial end)
while#buriedExamples>12 do table.remove(buriedExamples)end
return{forestOnly=true,parts=parts,realMeshParts=meshes,pbrAppearances=pbr,foreignScripts=foreign,trees=treeCount,plants=plantCount,buriedExamples=buriedExamples,
 supportPoints=supports,maximumSupportGap=maxGap,maximumSupportBurial=maxBurial,treeHeightRange={shortest,tallest},
 terrainProbes=probes,greenTerrainProbes=green,waterProbes=water,trailProbes=trail,riverContinuityProbes=riverProbes,
 woodenBridges=2,continuousWalkwayProbes=walks,logSeats=seats,cutTrunks=world:GetAttribute("CutTrunkCount"),lanterns=#lights,
 grassSampledZones=zones,validGrassRoots=roots,grassCoveragePoints=coveragePoints,grassCoverageMisses=misses,grassRootOverlap=hi.X-lo.X-Scene.Spacing,
 grassPriorityCorrect=true,staticGrassSource=true,ownerAvatarUserId=8344738123,npcSeated=true,catBathKeepsSeatedBody=true,
 greetingAudioLoaded=true,greetingAudioLength=npc.Head.HiVoice.TimeLength,yayAudioLoaded=true,yayAudioLength=npc.Head.YayVoice.TimeLength,cycleSeconds=Cycle.Duration,sunDirectionSamples=sunDirections,extendedWaterSurface=true,
 shaderPresetAssetId=8490242417,compiledScriptsAndModules=compiled,streamingEnabled=true,rendering=tostring(game.Lighting.LightingStyle)}
]============])
return{staged=true,baseVersion=89,report={mainRuins=mainRuins,world=worldReport,bridges=bridgeReport,extraRuins=extraReport,tests=tests,forestTests=forestTests}}
