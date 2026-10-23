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
local TREE_ID=4617134997
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
	if child.Name=="SweanRuntime" or child.Name=="SakuraRuntime" or child.Name=="ForestRuntime"
		or child.Name=="GrassStaticTemplate" or child.Name=="GrassWindTemplate"
		or child.Name=="XNMedia" or child.Name=="GrassTemplate" or child.Name=="SkinnedGrassRuntimeModule" then
		child:Destroy()
	end
end

local runtime=Instance.new("Folder")
runtime.Name="SweanRuntime"
runtime.Parent=ReplicatedStorage
runtime:SetAttribute("Version",115)
runtime:SetAttribute("IslandAssetId",ISLAND_ID)
runtime:SetAttribute("GrassAssetId",GRASS_ID)
runtime:SetAttribute("TreeAssetId",TREE_ID)
runtime:SetAttribute("WindAssetId",WIND_ID)

workspace.StreamingEnabled=false
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

-- Fixed world-space budget; never multiply an already enlarged island.
assert(scaleFootprint(island,260),"Island scale failed")
island:SetAttribute("TargetFootprint",260)

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
		p:SetAttribute("GrassSurfaceId",#greenSurfaces)
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

-- SKINNED GRASS: tamanho PADRÃO do asset, repetida até tapar o verde.
-- A MeshPart mede ~7.15x a grama que aparece. A versão no ar andava
-- esse tamanho inteiro, então sobrava chão verde entre os tufos.
-- Aqui o Size NÃO muda. O passo usa só a grama visível, com sobreposição,
-- e o cliente espalha os tufos. Sem isso o place não salva dezenas de
-- milhares de cópias com 100 Bones cada.
local grassAsset=loadAsset(GRASS_ID)

local sourceMesh=nil
local sourceBones=0
for _,d in ipairs(grassAsset:GetDescendants()) do
	if d:IsA("MeshPart") then
		local bones=0
		for _,b in ipairs(d:GetDescendants()) do
			if b:IsA("Bone") then bones+=1 end
		end
		if bones>0 and d.Material==Enum.Material.Neon and d.Color.G>d.Color.R then
			sourceMesh=d
			sourceBones=bones
			break
		end
	end
end
assert(sourceMesh and sourceBones==100,"Green SkinnedGrass mesh (100 Bones) not found")

local defaultSize=sourceMesh.Size
-- Measure bone roots in mesh-local space; the 100x100 MeshPart bounds
-- are much larger than the actual grass (about 14x14 studs).
local rootMin=Vector3.new(math.huge,math.huge,math.huge)
local rootMax=-rootMin
for _,bone in ipairs(sourceMesh:GetDescendants()) do
 if bone:IsA("Bone") then
  local p=sourceMesh.CFrame:PointToObjectSpace(bone.WorldPosition)
  rootMin=rootMin:Min(p) rootMax=rootMax:Max(p)
 end
end
local rootCenter=(rootMin+rootMax)*.5
local OVERLAP=1.65
local footprintX,footprintZ=rootMax.X-rootMin.X,rootMax.Z-rootMin.Z
assert(footprintX>0 and footprintZ>0,"Grass roots have no footprint")
local VISUAL_DIV=defaultSize.X/footprintX
local stepX,stepZ=footprintX/OVERLAP,footprintZ/OVERLAP
local GROUND_OFFSET=-0.08
local function gridCount(length,step,foot)
	if length<=foot then return 1 end
	return math.ceil((length-foot)/step)+1
end

local sourceModule=nil
for _,d in ipairs(grassAsset:GetDescendants()) do
	if d:IsA("ModuleScript") and d.Name=="SkinnedGrass" then
		sourceModule=d
		break
	end
end
assert(sourceModule,"SkinnedGrass module missing")

local grassModule=sourceModule:Clone()
grassModule.Name="SkinnedGrassRuntimeModule"
grassModule.Source=__GRASS_MODULE_SOURCE__
grassModule.Parent=ReplicatedStorage

local function prepareMesh(mesh)
	for _,d in ipairs(mesh:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
	mesh.Name="SkinnedGrass"
	mesh.Anchored=true
	mesh.CanCollide=false
	mesh.CanTouch=false
	mesh.CanQuery=false
	mesh.CastShadow=false
	mesh.Size=defaultSize
	return mesh
end

-- Tufo original, com Bones, sem esticar. O cliente só cria os que
-- cabem na tela. A versão anterior criava os 22 mil de uma vez e
-- pedia o mapa inteiro: o jogo fechava no celular.
local template=Instance.new("Model")
template.Name="GrassWindTemplate"
prepareMesh(sourceMesh:Clone()).Parent=template
template.Parent=ReplicatedStorage

local grassFolder=Instance.new("Folder")
grassFolder.Name="SkinnedGrassCoverage"
grassFolder:SetAttribute("AssetId",GRASS_ID)
grassFolder:SetAttribute("Rule","DefaultSizeFillGreen")
grassFolder:SetAttribute("SingleMeshOnly",true)
grassFolder:SetAttribute("SourceBones",sourceBones)
grassFolder:SetAttribute("SourceMeshId",sourceMesh.MeshId)
grassFolder:SetAttribute("TileOverlap",OVERLAP)
grassFolder:SetAttribute("VisualScaleX",1)
grassFolder:SetAttribute("VisualScaleZ",1)
grassFolder:SetAttribute("GroundOffset",GROUND_OFFSET)
grassFolder:SetAttribute("DefaultSizeX",defaultSize.X)
grassFolder:SetAttribute("DefaultSizeY",defaultSize.Y)
grassFolder:SetAttribute("DefaultSizeZ",defaultSize.Z)
grassFolder:SetAttribute("FootprintX",footprintX)
grassFolder:SetAttribute("FootprintZ",footprintZ)
grassFolder:SetAttribute("RootCenterX",rootCenter.X)
grassFolder:SetAttribute("RootCenterZ",rootCenter.Z)
grassFolder:SetAttribute("RootMinY",rootMin.Y)
grassFolder:SetAttribute("StepX",stepX)
grassFolder:SetAttribute("StepZ",stepZ)
grassFolder:SetAttribute("VisualDiv",VISUAL_DIV)
grassFolder:SetAttribute("SpawnMode","ClientSafeRadius")
grassFolder:SetAttribute("MaxTouch",96)
grassFolder:SetAttribute("MaxDesktop",240)
grassFolder.Parent=workspace

local placed=0
local coveredSurfaces=0
for _,surface in ipairs(greenSurfaces) do
	local nx=gridCount(surface.Size.X,stepX,footprintX)
	local nz=gridCount(surface.Size.Z,stepZ,footprintZ)
	placed+=nx*nz
	coveredSurfaces+=1
end
grassAsset:Destroy()

assert(coveredSurfaces==#greenSurfaces,"Not every green surface received SkinnedGrass")
assert(placed>=#greenSurfaces,"Grass grid is empty")
runtime:SetAttribute("GrassPatchCount",placed)
runtime:SetAttribute("GrassCoveredSurfaces",coveredSurfaces)
runtime:SetAttribute("GrassVisualOverlap",OVERLAP)
runtime:SetAttribute("GrassTileSpacing",stepX)
runtime:SetAttribute("GrassSingleMeshBones",sourceBones)
runtime:SetAttribute("GrassCenterOffset",GROUND_OFFSET)
runtime:SetAttribute("GrassVisualScaleX",1)
runtime:SetAttribute("GrassVisualScaleZ",1)
runtime:SetAttribute("GrassDefaultSizeX",defaultSize.X)
runtime:SetAttribute("GrassDefaultSizeY",defaultSize.Y)
runtime:SetAttribute("GrassDefaultSizeZ",defaultSize.Z)
runtime:SetAttribute("GrassFootprintX",footprintX)
runtime:SetAttribute("GrassFootprintZ",footprintZ)
runtime:SetAttribute("GrassVisualDiv",VISUAL_DIV)
runtime:SetAttribute("GrassSpawnMode","ClientSafeRadius")

-- SAFE_GRASS_CAP: tamanho original, tufos encostados, só o que o
-- celular aguenta ao mesmo tempo. Anda junto com o jogador.
local grassRunner=Instance.new("LocalScript")
grassRunner.Name="SkinnedGrassRunner"
grassRunner.Source=__GRASS_SOURCE__
grassRunner.Parent=StarterPlayer.StarterPlayerScripts

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

local targetTreeHeight=64
assert(scaleHeight(tree,targetTreeHeight),"Tree scale failed")
assert(bottomPlace(tree,treeGround.Position,0,6),"Tree grounding failed")
runtime:SetAttribute("TreeGroundX",treeGround.Position.X)
runtime:SetAttribute("TreeGroundY",treeGround.Position.Y)
runtime:SetAttribute("TreeGroundZ",treeGround.Position.Z)
runtime:SetAttribute("TargetTreeHeight",targetTreeHeight)

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

-- FallingLeavesController renders local leaf geometry from this invisible volume.

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
controller.Source=__WIND_SOURCE__

local wl=windLines:Clone() wl.Parent=controller
local ws=windShake:Clone() ws.Parent=controller
controller.Parent=StarterPlayer.StarterPlayerScripts
windAsset:Destroy()

-- Spawn seguro perto do centro, afastado da árvore.
local spawnHit=nil
for radius=35,math.max(80,math.min(islandSize.X,islandSize.Z)*.28),15 do
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
server.Source=__SERVER_SOURCE__
server.Parent=ServerScriptService

Lighting.ClockTime=16.2
Lighting.Brightness=2.4
Lighting.GlobalShadows=true
Lighting.Ambient=Color3.fromRGB(142,143,137)
Lighting.OutdoorAmbient=Color3.fromRGB(174,171,161)

-- Exact Flat Shader preset; no arbitrary imported scripts are executed.
for _,d in ipairs(Lighting:GetChildren()) do
 if d:IsA("PostEffect") or d:IsA("Sky") or d:IsA("Atmosphere") then d:Destroy() end
end
local shaderAsset=loadAsset(86563808574363)
local shaderCount=0
for _,d in ipairs(shaderAsset:GetDescendants()) do
 if d:IsA("PostEffect") or d:IsA("Sky") or d:IsA("Atmosphere") then
  local copy=d:Clone()
  for _,child in ipairs(copy:GetDescendants()) do if child:IsA("LuaSourceContainer") then child:Destroy() end end
  copy:SetAttribute("SourceAssetId",86563808574363)
  copy.Parent=Lighting
  shaderCount+=1
 end
end
shaderAsset:Destroy()
assert(shaderCount==6,"Incomplete Flat Shader preset")
runtime:SetAttribute("ShaderAssetId",86563808574363)
local quality=Instance.new("LocalScript")
quality.Name="MobileShaderQuality"
quality.Source=[[
local mobile=game:GetService("UserInputService").TouchEnabled
if mobile then
 for _,effect in ipairs(game:GetService("Lighting"):GetChildren()) do
  if effect:GetAttribute("SourceAssetId")==86563808574363 and
   (effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect")) then effect.Enabled=false end
 end
end
]]
quality.Parent=StarterPlayer.StarterPlayerScripts

-- Keep the invisible fixed SpawnLocation; remove the decorative spawn model.
runtime:SetAttribute("SpawnAssetId",0)
-- Recover before the character reaches FallenPartsDestroyHeight.
runtime:SetAttribute("VoidThreshold",islandCF.Position.Y-islandSize.Y/2-12)
workspace.FallenPartsDestroyHeight=math.min(-500,runtime:GetAttribute("VoidThreshold")-150)
local remoteOld=ReplicatedStorage:FindFirstChild("SweanVoidEvent") if remoteOld then remoteOld:Destroy() end
local remote=Instance.new("RemoteEvent") remote.Name="SweanVoidEvent" remote.Parent=ReplicatedStorage
local void=Instance.new("LocalScript") void.Name="VoidSequence" void.Source=__VOID_SOURCE__ void.Parent=StarterPlayer.StarterPlayerScripts
local falling=Instance.new("LocalScript") falling.Name="FallingLeavesController" falling.Source=__LEAVES_SOURCE__ falling.Parent=StarterPlayer.StarterPlayerScripts
-- Use the asset's billboard and typography, without duplicate default labels.
local nameAsset=loadAsset(123212555736117)
local tag=assert(nameAsset:FindFirstChild("Nametag",true),"Nametag asset missing")
assert(tag:IsA("BillboardGui") and tag:FindFirstChild("Username"))
local names=Instance.new("Script") names.Name="NametagService" names.Source=__NAMETAG_SOURCE__
local templateTag=tag:Clone() templateTag.Parent=names
names:SetAttribute("AssetId",123212555736117) names.Parent=ServerScriptService
nameAsset:Destroy()
runtime:SetAttribute("NametagAssetId",123212555736117)
runtime:SetAttribute("FullMapLoaded",true)
runtime:SetAttribute("TreeSink",6)
runtime:SetAttribute("LogoAssetId",89648072626653)
local media=Instance.new("Folder") media.Name="XNMedia" media.Parent=ReplicatedStorage
for name,id in pairs({MenuClick=12221967,VoidMusic=110526913527016,FriendJoined=87437544236708,Regenerate=73292002268424}) do
 local sound=Instance.new("Sound") sound.Name=name sound.SoundId="rbxassetid://"..id
 sound.Volume=name=="VoidMusic" and .28 or .4 sound.Looped=name=="VoidMusic" sound.Parent=media
end
local friends=Instance.new("LocalScript") friends.Name="FriendPresence" friends.Source=__FRIENDS_SOURCE__ friends.Parent=StarterPlayer.StarterPlayerScripts

do
-- Two complete asphalt loops. Use the ready-made road's surface, adapted to the island.
local roadAsset,roadAssetId
for _,id in ipairs({9709196113,70715691404724,106767575447853,18986157292,94758719029933}) do
 local ok,asset=pcall(AssetService.LoadAssetAsync,AssetService,id)
 if ok and asset then roadAsset=asset roadAssetId=id break end
end
assert(roadAsset,"No ready-made asphalt road is accessible to this experience")
local roadSource=nil
for _,d in ipairs(roadAsset:GetDescendants()) do
 if d:IsA("BasePart") and (not roadSource or d.Size.X*d.Size.Z>roadSource.Size.X*roadSource.Size.Z) then roadSource=d end
end
assert(roadSource,"Ready-made asphalt road has no surface")
local roads=Instance.new("Folder") roads.Name="IslandRoads" roads.Parent=workspace
roads:SetAttribute("SourceAssetId",roadAssetId)
print("ROAD_SOURCE",roadAssetId)
local center=treeGround.Position
local width=8
local groundRay=RaycastParams.new() groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={island}
local function ground(x,z)
 return workspace:Raycast(Vector3.new(x,islandCF.Position.Y+islandSize.Y+80,z),Vector3.new(0,-islandSize.Y-180,0),groundRay)
end
local function ringFits(radius)
 for i=0,95 do
  local a=i/96*math.pi*2
  for _,offset in ipairs({-width/2,0,width/2}) do
   local hit=ground(center.X+math.cos(a)*(radius+offset),center.Z+math.sin(a)*(radius+offset))
   if not hit or hit.Normal.Y<.55 then return false end
  end
 end
 return true
end
local outerRadius
for r=math.floor(math.min(islandSize.X,islandSize.Z)*.47)-width,45,-1 do
 if ringFits(r) then outerRadius=r break end
end
assert(outerRadius,"No grounded outer circular road fits the island")
local innerRadius=math.min(27,outerRadius*.4)
assert(ringFits(innerRadius),"Inner road has unsupported ground")
roads:SetAttribute("Center",center) roads:SetAttribute("InnerRadius",innerRadius) roads:SetAttribute("OuterRadius",outerRadius) roads:SetAttribute("Width",width)
for _,ring in ipairs({{name="TreeLoop",radius=innerRadius,count=72},{name="EdgeLoop",radius=outerRadius,count=144}}) do
 local model=Instance.new("Model") model.Name=ring.name model.Parent=roads model:SetAttribute("Radius",ring.radius)
 local previous=nil local firstPoint=nil
 for i=0,ring.count do
  local a=i/ring.count*math.pi*2
  local x,z=center.X+math.cos(a)*ring.radius,center.Z+math.sin(a)*ring.radius
  local hit=assert(ground(x,z),"Road surface lost")
  local point=hit.Position+Vector3.new(0,.12,0)
  if previous then
   local segment=roadSource:Clone() segment.Name="Asphalt"
   for _,d in ipairs(segment:GetDescendants()) do
    if not d:IsA("Texture") and not d:IsA("Decal") and not d:IsA("SurfaceAppearance") then d:Destroy() end
   end
   local length=(point-previous).Magnitude
   segment.Size=Vector3.new(width,.24,length+.15)
   segment.CFrame=CFrame.lookAt((previous+point)/2,point)
   segment.Anchored=true segment.CanCollide=true segment.CanTouch=false segment.CastShadow=false
   segment.Material=Enum.Material.Asphalt segment.Color=Color3.fromRGB(63,65,66)
   segment:SetAttribute("Start",previous) segment:SetAttribute("End",point)
   segment.Parent=model
  end
  previous=point firstPoint=firstPoint or point
 end
end
roadAsset:Destroy()
-- Full island bind-pose coverage. Only the nearby replacements carry animated bones.
local static=Instance.new("Folder") static.Name="FullIslandGrass" static.Parent=workspace
local offset=Vector3.new(rootCenter.X,rootMin.Y,rootCenter.Z)
local margin=math.sqrt(footprintX^2+footprintZ^2)/2+2
local function clearOfRoad(pos)
 local distance=Vector2.new(pos.X-center.X,pos.Z-center.Z).Magnitude
 return math.abs(distance-innerRadius)>width/2+margin and math.abs(distance-outerRadius)>width/2+margin
end
local count=0
for _,surface in ipairs(greenSurfaces) do
 local nx,nz=gridCount(surface.Size.X,stepX,footprintX),gridCount(surface.Size.Z,stepZ,footprintZ)
 for x=1,nx do for z=1,nz do
  local p=surface.CFrame:PointToWorldSpace(Vector3.new((x-(nx+1)/2)*stepX,surface.Size.Y/2,(z-(nz+1)/2)*stepZ))
  local hit=ground(p.X,p.Z)
  if hit and hit.Instance==surface and hit.Normal.Y>.6 and clearOfRoad(hit.Position) then
   local mesh=ReplicatedStorage.GrassWindTemplate.SkinnedGrass:Clone()
   for _,d in ipairs(mesh:GetDescendants()) do if d:IsA("Bone") then d:Destroy() end end
   count+=1 mesh.Name="Grass_"..count mesh.Anchored=true mesh.CanCollide=false mesh.CanTouch=false mesh.CanQuery=false mesh.CastShadow=false
   mesh.CFrame=(CFrame.new(hit.Position)*surface.CFrame.Rotation)*CFrame.new(-offset+Vector3.new(0,-.08,0))
   mesh:SetAttribute("GroundPosition",hit.Position) mesh:SetAttribute("GrassScale",1) mesh.Parent=static
  end
 end end
end
local smallScale=.5
local smallMargin=margin*smallScale
for _,surface in ipairs(greenSurfaces) do
 local sx,sz=stepX*smallScale,stepZ*smallScale
 local nx,nz=gridCount(surface.Size.X,sx,footprintX*smallScale),gridCount(surface.Size.Z,sz,footprintZ*smallScale)
 for x=1,nx do for z=1,nz do
  local p=surface.CFrame:PointToWorldSpace(Vector3.new((x-(nx+1)/2)*sx,surface.Size.Y/2,(z-(nz+1)/2)*sz))
  local distance=Vector2.new(p.X-center.X,p.Z-center.Z).Magnitude
  local gap=math.min(math.abs(distance-innerRadius),math.abs(distance-outerRadius))-width/2
  if gap>smallMargin and gap<margin+stepX*.5 then
   local hit=ground(p.X,p.Z)
   if hit and hit.Instance==surface and hit.Normal.Y>.6 then
    local mesh=ReplicatedStorage.GrassWindTemplate.SkinnedGrass:Clone()
    for _,d in ipairs(mesh:GetDescendants()) do if d:IsA("Bone") then d:Destroy() end end
    count+=1 mesh.Name="Grass_"..count mesh.Size*=smallScale
    mesh.Anchored=true mesh.CanCollide=false mesh.CanTouch=false mesh.CanQuery=false mesh.CastShadow=false
    mesh.CFrame=(CFrame.new(hit.Position)*surface.CFrame.Rotation)*CFrame.new(-offset*smallScale+Vector3.new(0,-.08,0))
    mesh:SetAttribute("GroundPosition",hit.Position) mesh:SetAttribute("GrassScale",smallScale) mesh.Parent=static
   end
  end
 end end
end
assert(count>100,"Full island grass coverage unexpectedly small")
static:SetAttribute("PatchCount",count) static:SetAttribute("AssetId",87377915371959)
static:SetAttribute("RoadClearance",margin)
runtime:SetAttribute("FullGrassPatchCount",count)
runtime:SetAttribute("GrassSpawnMode","FullIslandWithNearbyAnimation")
grassFolder:SetAttribute("SpawnMode","FullIslandWithNearbyAnimation")

end

return{
	version=115,
	islandParts=countParts(island),
	greenSurfaces=#greenSurfaces,
	grassPatches=placed,
	treeFoliage=#foliageParts
}

