-- Swean Island v102 — Floating Island + SkinnedGrass + Big Tree + Wind
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local AssetService=game:GetService("AssetService")
local CollectionService=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Terrain=workspace.Terrain

local ISLAND_ID=10485490600
local GRASS_ID=87377915371959
local TREE_ID=86013526879602
local WIND_ID=11946229834

local function loadAsset(id)
	local ok,res=pcall(AssetService.LoadAssetAsync,AssetService,id)
	if not ok or not res then error("Asset "..id.." failed: "..tostring(res)) end
	return res
end

local function countParts(root)
	local n=0
	if root:IsA("BasePart") then n+=1 end
	for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
	return n
end

local function sanitize(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
		end
	end
end

local function largestVisual(asset,preferredWords)
	local best,bestScore=nil,-1
	local function score(inst)
		local pc=countParts(inst)
		if pc<=0 then return -1 end
		local s=pc
		local name=inst.Name:lower()
		for _,word in ipairs(preferredWords or {}) do
			if name:find(word,1,true) then s+=100000 end
		end
		local ok,_,size=pcall(function()
			local cf,sz=inst:GetBoundingBox()
			return cf,sz
		end)
		if ok and size then s+=math.min(50000,(size.X*size.Z)/10) end
		return s
	end
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("Model") then
			local s=score(d)
			if s>bestScore then best,bestScore=d,s end
		end
	end
	if best then return best end
	local p=asset:FindFirstChildWhichIsA("BasePart",true)
	return p
end

local function asModel(inst)
	if inst:IsA("Model") then return inst end
	local m=Instance.new("Model")
	inst.Parent=m
	return m
end

local function bounds(model)
	local ok,cf,size=pcall(function() return model:GetBoundingBox() end)
	if not ok or not size or size.X<=0 or size.Y<=0 or size.Z<=0 then return nil end
	return cf,size
end

local function scaleFootprint(model,target)
	local _,size=bounds(model)
	if not size then return false end
	local current=math.max(size.X,size.Z)
	if current<=0 then return false end
	return pcall(function() model:ScaleTo(model:GetScale()*(target/current)) end)
end

local function scaleHeight(model,target)
	local _,size=bounds(model)
	if not size or size.Y<=0 then return false end
	return pcall(function() model:ScaleTo(model:GetScale()*(target/size.Y)) end)
end

local function bottomPlace(model,pos,yaw,sink)
	model:PivotTo(CFrame.new(pos.X,0,pos.Z)*CFrame.Angles(0,yaw or 0,0))
	local cf,size=bounds(model)
	if not size then return false end
	local bottom=cf.Position.Y-size.Y/2
	model:PivotTo(model:GetPivot()+Vector3.new(0,pos.Y-bottom-(sink or 0),0))
	return true
end

-- LIMPA TUDO DA BUILD ANTERIOR.
for _,child in ipairs(workspace:GetChildren()) do
	if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()
for _,container in ipairs({
	ServerScriptService,
	StarterPlayer.StarterPlayerScripts,
	game:GetService("ReplicatedFirst"),
	game:GetService("StarterGui")
}) do
	for _,child in ipairs(container:GetChildren()) do child:Destroy() end
end
for _,child in ipairs(ReplicatedStorage:GetChildren()) do
	if child.Name=="SweanRuntime" or child.Name=="SakuraRuntime" or child.Name=="ForestRuntime" then child:Destroy() end
end

local runtime=Instance.new("Folder")
runtime.Name="SweanRuntime"
runtime.Parent=ReplicatedStorage
runtime:SetAttribute("Version",102)
runtime:SetAttribute("IslandAssetId",ISLAND_ID)
runtime:SetAttribute("GrassAssetId",GRASS_ID)
runtime:SetAttribute("TreeAssetId",TREE_ID)
runtime:SetAttribute("WindAssetId",WIND_ID)

pcall(function()
	workspace.StreamingEnabled=true
	workspace.StreamingMinRadius=96
	workspace.StreamingTargetRadius=260
end)
workspace.FallenPartsDestroyHeight=-300

-- ILHA EXATA
local islandAsset=loadAsset(ISLAND_ID)
local islandSource=largestVisual(islandAsset,{"floating","island","obby"})
assert(islandSource,"Floating Island visual not found")
local island=asModel(islandSource:Clone())
island.Name="FloatingIsland"
island:SetAttribute("AssetId",ISLAND_ID)
island.Parent=workspace
sanitize(island)

local islandCF,islandSize=bounds(island)
assert(islandSize,"Floating Island has invalid bounds")
-- Centraliza sem deformar.
island:PivotTo(island:GetPivot()+Vector3.new(-islandCF.Position.X,12-islandCF.Position.Y,-islandCF.Position.Z))
islandCF,islandSize=bounds(island)
runtime:SetAttribute("IslandParts",countParts(island))
runtime:SetAttribute("IslandSizeX",islandSize.X)
runtime:SetAttribute("IslandSizeY",islandSize.Y)
runtime:SetAttribute("IslandSizeZ",islandSize.Z)
islandAsset:Destroy()

-- DETECTA SOMENTE O CHÃO VERDE/GRAMADO DA ILHA.
local greenSurfaces={}
local function greenish(c)
	return c.G>c.R*1.05 and c.G>c.B*1.05 and c.G>.22
end
for _,p in ipairs(island:GetDescendants()) do
	if p:IsA("BasePart")
		and p.Transparency<.8
		and p.CFrame.UpVector.Y>.55
		and p.Size.X>=2 and p.Size.Z>=2
		and (p.Material==Enum.Material.Grass or greenish(p.Color)) then
		table.insert(greenSurfaces,p)
		CollectionService:AddTag(p,"IslandGreenGround")
	end
end
assert(#greenSurfaces>0,"No green island surfaces detected")
runtime:SetAttribute("GreenSurfaceCount",#greenSurfaces)

local greenParams=RaycastParams.new()
greenParams.FilterType=Enum.RaycastFilterType.Include
greenParams.FilterDescendantsInstances=greenSurfaces
greenParams.IgnoreWater=true

local function rayGreen(x,z)
	return workspace:Raycast(
		Vector3.new(x,islandCF.Position.Y+islandSize.Y+80,z),
		Vector3.new(0,-(islandSize.Y+180),0),
		greenParams
	)
end

-- SKINNED GRASS POR CIMA DE TODA A ÁREA VERDE.
local grassAsset=loadAsset(GRASS_ID)
local grassSource=largestVisual(grassAsset,{"dark","grass","skinned"})
assert(grassSource,"SkinnedGrass visual not found")
local grassTemplate=asModel(grassSource:Clone())
sanitize(grassTemplate)
grassAsset:Destroy()

local grassFolder=Instance.new("Folder")
grassFolder.Name="SkinnedGrassCoverage"
grassFolder:SetAttribute("AssetId",GRASS_ID)
grassFolder:SetAttribute("Rule","IslandGreenGroundOnly")
grassFolder.Parent=workspace

local rng=Random.new(102873)

local placed=0
local samples=0
local coveredSurfaces=0

for _,surface in ipairs(greenSurfaces) do
	local surfacePlaced=0
	local target=math.clamp(math.min(surface.Size.X,surface.Size.Z)*.88,.55,3.6)
	local step=math.max(.65,target*.82)
	local nx=math.max(1,math.ceil(surface.Size.X/step))
	local nz=math.max(1,math.ceil(surface.Size.Z/step))

	for ix=0,nx-1 do
		for iz=0,nz-1 do
			local lx=-surface.Size.X*.42+(ix+.5)*(surface.Size.X*.84/nx)
			local lz=-surface.Size.Z*.42+(iz+.5)*(surface.Size.Z*.84/nz)
			local guess=surface.CFrame:PointToWorldSpace(Vector3.new(lx,0,lz))
			local hit=rayGreen(guess.X,guess.Z)
			samples+=1
			if hit and hit.Instance==surface and hit.Normal.Y>.5 then
				local patch=grassTemplate:Clone()
				patch.Name=string.format("SkinnedGrass_%03d",placed+1)
				scaleFootprint(patch,target)
				patch.Parent=grassFolder
				CollectionService:AddTag(patch,"SkinnedGrassPatch")
				bottomPlace(patch,hit.Position,rng:NextNumber(0,math.pi*2),.015)
				patch:SetAttribute("GroundPart",surface.Name)
				surfacePlaced+=1
				placed+=1
			end
		end
	end

	if surfacePlaced==0 then
		local hit=rayGreen(surface.Position.X,surface.Position.Z)
		if hit and hit.Instance==surface then
			local patch=grassTemplate:Clone()
			patch.Name=string.format("SkinnedGrass_%03d",placed+1)
			scaleFootprint(patch,target)
			patch.Parent=grassFolder
			CollectionService:AddTag(patch,"SkinnedGrassPatch")
			bottomPlace(patch,hit.Position,rng:NextNumber(0,math.pi*2),.015)
			patch:SetAttribute("GroundPart",surface.Name)
			surfacePlaced=1
			placed+=1
		end
	end

	if surfacePlaced>0 then coveredSurfaces+=1 end
end

grassTemplate:Destroy()
assert(coveredSurfaces==#greenSurfaces,"Not every green surface received SkinnedGrass: "..tostring(coveredSurfaces).."/"..tostring(#greenSurfaces))
assert(placed>=#greenSurfaces,"Too little skinned grass coverage: "..tostring(placed))
runtime:SetAttribute("GrassPatchCount",placed)
runtime:SetAttribute("GrassCoverageSamples",samples)
runtime:SetAttribute("GrassCoveredSurfaces",coveredSurfaces)

-- ÁRVORE GRANDE EXATA NO MEIO, ENCOSTADA NO CHÃO.
local treeAsset=loadAsset(TREE_ID)
local treeSource=largestVisual(treeAsset,{"tree","big","stud"})
assert(treeSource,"Big Tree visual not found")
local tree=asModel(treeSource:Clone())
tree.Name="BigCenterTree"
tree:SetAttribute("AssetId",TREE_ID)
tree.Parent=workspace
sanitize(tree)
treeAsset:Destroy()

local center=Vector3.new(islandCF.Position.X,0,islandCF.Position.Z)
local treeGround=rayGreen(center.X,center.Z)
if not treeGround then
	for radius=4,math.max(islandSize.X,islandSize.Z)*.35,4 do
		for i=1,24 do
			local a=i/24*math.pi*2
			local hit=rayGreen(center.X+math.cos(a)*radius,center.Z+math.sin(a)*radius)
			if hit then treeGround=hit break end
		end
		if treeGround then break end
	end
end
assert(treeGround,"No green center ground found for tree")

local targetTreeHeight=math.clamp(math.min(islandSize.X,islandSize.Z)*.88,12,18)
scaleHeight(tree,targetTreeHeight)
assert(bottomPlace(tree,treeGround.Position,rng:NextNumber(0,math.pi*2),.55),"Tree grounding failed")
runtime:SetAttribute("TreeGroundX",treeGround.Position.X)
runtime:SetAttribute("TreeGroundY",treeGround.Position.Y)
runtime:SetAttribute("TreeGroundZ",treeGround.Position.Z)

-- Folhagem da árvore recebe WindShake.
local foliageParts={}
for _,p in ipairs(tree:GetDescendants()) do
	if p:IsA("BasePart") then
		local n=p.Name:lower()
		if n:find("leaf",1,true) or n:find("foliage",1,true) or greenish(p.Color) then
			table.insert(foliageParts,p)
			CollectionService:AddTag(p,"WindShake")
			p:SetAttribute("WindPower",.34)
			p:SetAttribute("WindSpeed",15)
		end
	end
end
if #foliageParts==0 then
	local largest=nil
	for _,p in ipairs(tree:GetDescendants()) do
		if p:IsA("BasePart") and (not largest or p.Size.Magnitude>largest.Size.Magnitude) then largest=p end
	end
	if largest then
		table.insert(foliageParts,largest)
		CollectionService:AddTag(largest,"WindShake")
	end
end
assert(#foliageParts>0,"Tree foliage not found")
runtime:SetAttribute("TreeFoliageParts",#foliageParts)

-- FOLHAS CAINDO: volume invisível na copa.
local treeCF,treeSize=bounds(tree)
local emitterHost=Instance.new("Part")
emitterHost.Name="FallingLeavesEmitter"
emitterHost.Size=Vector3.new(
	math.max(5,treeSize.X*.65),
	math.max(2,treeSize.Y*.18),
	math.max(5,treeSize.Z*.65)
)
emitterHost.CFrame=CFrame.new(
	treeCF.Position.X,
	treeCF.Position.Y+treeSize.Y*.27,
	treeCF.Position.Z
)
emitterHost.Anchored=true
emitterHost.CanCollide=false
emitterHost.CanTouch=false
emitterHost.CanQuery=false
emitterHost.Transparency=1
emitterHost.Parent=tree

local leaves=Instance.new("ParticleEmitter")
leaves.Name="FallingLeaves"
leaves.Texture="rbxasset://textures/particles/leaf_main.dds"
leaves.Shape=Enum.ParticleEmitterShape.Box
leaves.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
leaves.EmissionDirection=Enum.NormalId.Bottom
leaves.Rate=math.clamp(treeSize.X*.25,7,16)
leaves.Lifetime=NumberRange.new(4.5,7.5)
leaves.Speed=NumberRange.new(.25,1.1)
leaves.Acceleration=Vector3.new(0,-1.8,0)
leaves.Drag=1.4
leaves.WindAffectsDrag=true
leaves.Rotation=NumberRange.new(0,360)
leaves.RotSpeed=NumberRange.new(-70,70)
leaves.SpreadAngle=Vector2.new(70,70)
leaves.Size=NumberSequence.new({
	NumberSequenceKeypoint.new(0,.32,.10),
	NumberSequenceKeypoint.new(.75,.22,.08),
	NumberSequenceKeypoint.new(1,.12,.04)
})
leaves.Transparency=NumberSequence.new({
	NumberSequenceKeypoint.new(0,1),
	NumberSequenceKeypoint.new(.08,.05),
	NumberSequenceKeypoint.new(.82,.12),
	NumberSequenceKeypoint.new(1,1)
})
leaves.Color=ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(108,151,68)),
	ColorSequenceKeypoint.new(.55,Color3.fromRGB(88,133,56)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(142,169,82))
})
leaves.LightInfluence=.8
leaves.Parent=emitterHost

-- VENTO REAL: GlobalWind + módulos WindLines/WindShake.
workspace.GlobalWind=Vector3.new(14,0,5)
local windAsset=loadAsset(WIND_ID)
local windSource=windAsset:FindFirstChild("WindController",true)
assert(windSource and windSource:IsA("LocalScript"),"WindController missing")
local windLines=windSource:FindFirstChild("WindLines")
local windShake=windSource:FindFirstChild("WindShake")
assert(windLines and windShake,"Wind modules missing")

local controller=Instance.new("LocalScript")
controller.Name="WindController"
controller:SetAttribute("AssetId",WIND_ID)
controller.Source=[==========[
local CollectionService=game:GetService("CollectionService")
local WindLines=require(script:WaitForChild("WindLines"))
local WindShake=require(script:WaitForChild("WindShake"))

local wind=workspace.GlobalWind
local dir=wind.Magnitude>0 and wind.Unit or Vector3.new(1,0,0)
local speed=math.max(1,wind.Magnitude)

WindLines:Init({
	Direction=dir;
	Speed=speed;
	Lifetime=1.8;
	SpawnRate=13;
})

pcall(function()
	WindShake:SetDefaultSettings({
		WindSpeed=speed;
		WindDirection=dir;
		WindPower=.34;
	})
end)
WindShake:Init()
]==========]

local wl=Instance.new("ModuleScript")
wl.Name="WindLines"
wl.Source=windLines.Source
wl.Parent=controller
local ws=Instance.new("ModuleScript")
ws.Name="WindShake"
ws.Source=windShake.Source
ws.Parent=controller
controller.Parent=StarterPlayer.StarterPlayerScripts
windAsset:Destroy()

-- SkinnedGrass: anima Bones próximos do jogador para responder ao vento sem mexer o patch inteiro.
local grassWind=Instance.new("LocalScript")
grassWind.Name="SkinnedGrassWind"
grassWind.Source=[==========[
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local folder=workspace:WaitForChild("SkinnedGrassCoverage")
local bones={}
local base={}

local function scan()
	table.clear(bones)
	table.clear(base)
	for _,d in ipairs(folder:GetDescendants()) do
		if d:IsA("Bone") then
			table.insert(bones,d)
			base[d]=d.Transform
		end
	end
end
scan()
folder.DescendantAdded:Connect(function(d)
	if d:IsA("Bone") then
		table.insert(bones,d)
		base[d]=d.Transform
	end
end)

local accum=0
RunService.RenderStepped:Connect(function(dt)
	accum+=dt
	if accum<1/24 then return end
	accum=0
	local char=player.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	local t=time()
	for i,b in ipairs(bones) do
		if b.Parent and base[b] then
			local near=true
			if root then
				local ok,wp=pcall(function() return b.WorldPosition end)
				if ok then near=(wp-root.Position).Magnitude<190 end
			end
			if near then
				local phase=i*.31
				local sway=math.sin(t*2.1+phase)*.095
				local side=math.cos(t*1.65+phase)*.045
				b.Transform=base[b]*CFrame.Angles(sway,0,side)
			else
				b.Transform=base[b]
			end
		end
	end
end)
]==========]
grassWind.Parent=StarterPlayer.StarterPlayerScripts

-- Spawn seguro perto do centro, afastado da árvore.
local spawnHit=nil
for radius=3,math.max(5,math.min(islandSize.X,islandSize.Z)*.32),1 do
	for i=1,24 do
		local a=i/24*math.pi*2
		local hit=rayGreen(treeGround.Position.X+math.cos(a)*radius,treeGround.Position.Z+math.sin(a)*radius)
		if hit then spawnHit=hit break end
	end
	if spawnHit then break end
end
spawnHit=spawnHit or treeGround

local spawn=Instance.new("SpawnLocation")
spawn.Name="IslandSpawn"
spawn.Size=Vector3.new(7,.4,7)
spawn.Anchored=true
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Transparency=1
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.CFrame=CFrame.new(spawnHit.Position+Vector3.new(0,.2,0))
spawn.Parent=workspace

local safety=Instance.new("Part")
safety.Name="VoidSafety"
safety.Size=Vector3.new(
	math.max(400,islandSize.X*2.2),
	2,
	math.max(400,islandSize.Z*2.2)
)
safety.CFrame=CFrame.new(islandCF.Position.X,islandCF.Position.Y-islandSize.Y*.75-60,islandCF.Position.Z)
safety.Anchored=true
safety.CanCollide=true
safety.CanTouch=false
safety.Transparency=1
safety.Parent=workspace

local server=Instance.new("Script")
server.Name="IslandServer"
server.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("IslandSpawn")
local safetyY=workspace:WaitForChild("VoidSafety").Position.Y
local function protect(char)
	task.spawn(function()
		while char.Parent do
			local root=char:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y<safetyY+3 then
				char:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
			end
			task.wait(.4)
		end
	end)
end
local function hook(p)
	p.RespawnLocation=spawn
	p.CharacterAdded:Connect(protect)
	if p.Character then protect(p.Character) end
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
]]
server.Parent=ServerScriptService

Lighting.ClockTime=16.2
Lighting.Brightness=2.4
Lighting.GlobalShadows=true
Lighting.Ambient=Color3.fromRGB(142,143,137)
Lighting.OutdoorAmbient=Color3.fromRGB(174,171,161)

return{
	version=102,
	islandParts=countParts(island),
	greenSurfaces=#greenSurfaces,
	grassPatches=placed,
	treeFoliage=#foliageParts
}
