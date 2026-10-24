local W=game:GetService("Workspace")
local T=W.Terrain
local L=game:GetService("Lighting")
local A=game:GetService("AssetService")
local RNG=Random.new(9419478735)

local SKY_ID=137401994501544
local TREE_ID=9626366517
local GRASS_ID=87377915371959
local STONE_ID=136068114177879
local WIND_ID=11946229834

for _,v in ipairs(W:GetChildren()) do
	if v~=T and not v:IsA("Camera") then v:Destroy() end
end
T:Clear()

for _,v in ipairs(L:GetChildren()) do
	if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") then
		v:Destroy()
	end
end

W.GlobalWind=Vector3.new(8,0,3)
T:FillBlock(CFrame.new(0,-18,0),Vector3.new(900,30,900),Enum.Material.Water)
T.WaterColor=Color3.fromRGB(70,112,118)
T.WaterTransparency=.25
T.WaterReflectance=.26
T.WaterWaveSize=.1
T.WaterWaveSpeed=6

local root=Instance.new("Folder")
root.Name="SakuraIsland"
root.Parent=W

local trees=Instance.new("Folder")
trees.Name="CherryTrees"
trees.Parent=root

local grasses=Instance.new("Folder")
grasses.Name="SkinnedGrass"
grasses.Parent=root

local stones=Instance.new("Folder")
stones.Name="StonePath"
stones.Parent=root

local flowers=Instance.new("Folder")
flowers.Name="Flowers"
flowers.Parent=root

local effects=Instance.new("Folder")
effects.Name="Effects"
effects.Parent=root

local function H(x,z)
	local r=math.sqrt((x/292)^2+(z/232)^2)
	return -3+math.clamp(1-r,0,1)*14.5
		+math.sin(x/82)*1.15
		+math.sin(z/101)*.9
		+math.sin((x+z)/155)*.55
end

-- Ground intentionally replaces Grass material so Roblox terrain grass cannot appear.
for x=-280,280,16 do
	for z=-224,224,16 do
		if math.sqrt((x/292)^2+(z/232)^2)<1 then
			T:FillBall(Vector3.new(x,H(x,z)-14,z),22,Enum.Material.Ground)
		end
	end
end
pcall(function() T.Decoration=false end)

local function loadAsset(id)
	local ok,res=pcall(A.LoadAssetAsync,A,id)
	if not ok or not res then
		error("Failed to load exact asset "..id..": "..tostring(res))
	end
	return res
end

local function sanitize(inst)
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
			d.CanQuery=true
		end
	end
end

local function wrapModel(inst)
	if inst:IsA("Model") then return inst end
	local m=Instance.new("Model")
	inst.Parent=m
	return m
end

local function visualParts(inst)
	local n=0
	if inst:IsA("BasePart") then n+=1 end
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then n+=1 end
	end
	return n
end

local function preferredModel(asset,words)
	local best,bestScore=nil,-1
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("Model") and visualParts(d)>0 then
			local name=string.lower(d.Name)
			local score=visualParts(d)
			for _,word in ipairs(words) do
				if string.find(name,word,1,true) then score+=10000 end
			end
			if score>bestScore then best,bestScore=d,score end
		end
	end
	if best then return best end
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	error("Asset has no visual geometry")
end

local function bounds(model)
	model=wrapModel(model)
	local _,size=model:GetBoundingBox()
	return size
end

local function scaleToHeight(model,targetHeight)
	model=wrapModel(model)
	local size=bounds(model)
	if size.Y<=0 then return model end
	local factor=targetHeight/size.Y
	model:ScaleTo(model:GetScale()*factor)
	return model
end

local function scaleToFootprint(model,targetFootprint)
	model=wrapModel(model)
	local size=bounds(model)
	local current=math.max(size.X,size.Z)
	if current<=0 then return model end
	local factor=targetFootprint/current
	model:ScaleTo(model:GetScale()*factor)
	return model
end

local function groundModel(model,x,z,yaw)
	model=wrapModel(model)
	model:PivotTo(CFrame.new(x,0,z)*CFrame.Angles(0,yaw,0))
	local cf,size=model:GetBoundingBox()
	local bottom=cf.Position.Y-size.Y/2
	model:PivotTo(model:GetPivot()+Vector3.new(0,H(x,z)-bottom+.08,0))
	return model
end

-- Exact sky asset, afternoon/daylight.
local skyAsset=loadAsset(SKY_ID)
local sky=skyAsset:FindFirstChildWhichIsA("Sky",true)
assert(sky,"Sky asset contains no Sky instance")
sky=sky:Clone()
sky.Parent=L
skyAsset:Destroy()

L.ClockTime=15.8
L.Brightness=2.8
L.ExposureCompensation=.1
L.EnvironmentDiffuseScale=.62
L.EnvironmentSpecularScale=.72
L.Ambient=Color3.fromRGB(142,145,137)
L.OutdoorAmbient=Color3.fromRGB(184,178,164)

local at=Instance.new("Atmosphere")
at.Density=.18
at.Offset=.06
at.Color=Color3.fromRGB(226,216,199)
at.Decay=Color3.fromRGB(160,146,137)
at.Glare=.04
at.Haze=.6
at.Parent=L

local cc=Instance.new("ColorCorrectionEffect")
cc.Brightness=.03
cc.Contrast=.01
cc.Saturation=.05
cc.TintColor=Color3.fromRGB(255,242,222)
cc.Parent=L

-- Exact Sakura asset. Every tree is normalized to a controlled height.
local treeAsset=loadAsset(TREE_ID)
sanitize(treeAsset)
local treeSource=preferredModel(treeAsset,{"sakura","tree","cherry"})
local positions={}
local attempts=0
while #positions<27 and attempts<4000 do
	attempts+=1
	local x=RNG:NextNumber(-236,236)
	local z=RNG:NextNumber(-184,184)
	if math.sqrt((x/250)^2+(z/198)^2)<.91 then
		local pathX=-24+math.sin((z+175)*.072)*12+math.sin((z+175)*.026)*7
		local ok=math.abs(x-pathX)>18
		for _,q in ipairs(positions) do
			if (Vector2.new(x,z)-q).Magnitude<30 then ok=false break end
		end
		if ok then table.insert(positions,Vector2.new(x,z)) end
	end
end
assert(#positions==27,"Could not place exactly 27 Sakura trees")

for i,p in ipairs(positions) do
	local c=treeSource:Clone()
	c=wrapModel(c)
	c.Name=string.format("Sakura_%02d",i)
	c.Parent=trees
	local targetHeight=RNG:NextNumber(24,29)
	scaleToHeight(c,targetHeight)
	groundModel(c,p.X,p.Y,RNG:NextNumber(0,math.pi*2))
end
treeAsset:Destroy()

-- Exact SkinnedGrass asset. Select the darkest visual variant.
local grassAsset=loadAsset(GRASS_ID)
sanitize(grassAsset)
local candidates={}
for _,d in ipairs(grassAsset:GetChildren()) do
	if (d:IsA("Model") or d:IsA("BasePart")) and visualParts(d)>0 then
		table.insert(candidates,d)
	end
end
if #candidates==0 then
	table.insert(candidates,preferredModel(grassAsset,{"grass","dark"}))
end

local function luminance(inst)
	local total,n=0,0
	if inst:IsA("BasePart") then
		total+=(inst.Color.R+inst.Color.G+inst.Color.B)/3
		n+=1
	end
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			total+=(d.Color.R+d.Color.G+d.Color.B)/3
			n+=1
		end
	end
	return n>0 and total/n or 1
end

table.sort(candidates,function(a,b) return luminance(a)<luminance(b) end)
local grassSource=candidates[1]
local grassCount=0
local spacing=17

for x=-248,248,spacing do
	for z=-192,192,spacing do
		local jx=x+RNG:NextNumber(-3.5,3.5)
		local jz=z+RNG:NextNumber(-3.5,3.5)
		if math.sqrt((jx/260)^2+(jz/204)^2)<.93 then
			local c=grassSource:Clone()
			c=wrapModel(c)
			grassCount+=1
			c.Name=string.format("SkinnedGrass_%03d",grassCount)
			c.Parent=grasses
			scaleToFootprint(c,20)
			groundModel(c,jx,jz,RNG:NextNumber(0,math.pi*2))
			c:SetAttribute("RestPivot",c:GetPivot())
		end
	end
end
grassAsset:Destroy()
assert(grassCount>400,"Not enough exact SkinnedGrass coverage")

-- Exact stone pathway asset, normalized into a thin crooked trail.
local stoneAsset=loadAsset(STONE_ID)
sanitize(stoneAsset)
local stoneSource=preferredModel(stoneAsset,{"stone","path","road","walkway","trail"})
for i=1,20 do
	local z=-178+(i-1)*18.3
	local x=-24+math.sin(i*.63)*12+math.sin(i*.21)*7
	local nextZ=z+2
	local nextX=-24+math.sin((i+.11)*.63)*12+math.sin((i+.11)*.21)*7
	local yaw=math.atan2(nextX-x,nextZ-z)
	local c=stoneSource:Clone()
	c=wrapModel(c)
	c.Name=string.format("StonePath_%02d",i)
	c.Parent=stones
	scaleToFootprint(c,19)
	groundModel(c,x,z,yaw)
end
stoneAsset:Destroy()

-- Small flowers between grass patches.
for i=1,300 do
	local x=RNG:NextNumber(-248,248)
	local z=RNG:NextNumber(-194,194)
	if math.sqrt((x/260)^2+(z/204)^2)<.92 then
		local stem=Instance.new("Part")
		stem.Name="FlowerStem"
		stem.Size=Vector3.new(.07,.62,.07)
		stem.Color=Color3.fromRGB(70,108,56)
		stem.Material=Enum.Material.Grass
		stem.Anchored=true
		stem.CanCollide=false
		stem.Position=Vector3.new(x,H(x,z)+.38,z)
		stem.Parent=flowers

		local bloom=Instance.new("Part")
		bloom.Name="Flower"
		bloom.Size=Vector3.new(.38,.16,.38)
		bloom.Shape=Enum.PartType.Ball
		bloom.Color=(i%4==0) and Color3.fromRGB(242,237,223) or Color3.fromRGB(226,193,208)
		bloom.Material=Enum.Material.SmoothPlastic
		bloom.Anchored=true
		bloom.CanCollide=false
		bloom.Position=stem.Position+Vector3.new(0,.38,0)
		bloom.Parent=flowers
	end
end

local windAsset=loadAsset(WIND_ID)
sanitize(windAsset)
windAsset.Name="WindEffects"
windAsset.Parent=effects

local spawn=Instance.new("SpawnLocation")
spawn.Name="IslandSpawn"
spawn.Size=Vector3.new(7,.5,7)
spawn.Transparency=1
spawn.CanCollide=false
spawn.Anchored=true
spawn.Position=Vector3.new(-24,H(-24,-165)+4,-165)
spawn.Parent=root

-- Nearby patches bend under players and return smoothly.
local controller=Instance.new("Script")
controller.Name="GrassFootResponse"
controller.Source=[[
local Players=game:GetService("Players")
local folder=workspace.SakuraIsland.SkinnedGrass
while task.wait(.08) do
	for _,m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") then
			local rest=m:GetAttribute("RestPivot")
			if typeof(rest)=="CFrame" then
				local nearest=999
				for _,p in ipairs(Players:GetPlayers()) do
					local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if r then
						local d=(Vector2.new(r.Position.X,r.Position.Z)-Vector2.new(rest.Position.X,rest.Position.Z)).Magnitude
						if d<nearest then nearest=d end
					end
				end
				local press=math.clamp((5-nearest)/5,0,1)
				local target=rest*CFrame.Angles(press*.18,0,-press*.08)
				m:PivotTo(m:GetPivot():Lerp(target,press>0 and .45 or .18))
			end
		end
	end
end
]]
controller.Parent=root

root:SetAttribute("SkyAssetId",SKY_ID)
root:SetAttribute("SakuraAssetId",TREE_ID)
root:SetAttribute("GrassAssetId",GRASS_ID)
root:SetAttribute("StonePathAssetId",STONE_ID)
root:SetAttribute("WindAssetId",WIND_ID)
root:SetAttribute("TerrainNativeGrassDisabled",true)
root:SetAttribute("TreeTargetHeightMin",24)
root:SetAttribute("TreeTargetHeightMax",29)

A:SavePlaceAsync()

return{
	ok=true,
	clock=L.ClockTime,
	skyAsset=SKY_ID,
	trees=#trees:GetChildren(),
	treeAsset=TREE_ID,
	treeHeightMin=24,
	treeHeightMax=29,
	terrainMaterial="Ground",
	nativeTerrainGrass=false,
	grassPatches=#grasses:GetChildren(),
	grassAsset=GRASS_ID,
	stoneSegments=#stones:GetChildren(),
	stoneAsset=STONE_ID,
	flowers=#flowers:GetChildren(),
	windAsset=WIND_ID,
	placeId=game.PlaceId,
	universeId=game.GameId
}
