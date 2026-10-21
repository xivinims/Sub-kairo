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

pcall(function() A.AllowInsertFreeAssets=true end)

for _,v in ipairs(W:GetChildren()) do
	if v~=T and not v:IsA("Camera") then v:Destroy() end
end
T:Clear()
for _,v in ipairs(L:GetChildren()) do
	if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") then v:Destroy() end
end

W.GlobalWind=Vector3.new(8,0,3)
T:FillBlock(CFrame.new(0,-18,0),Vector3.new(900,30,900),Enum.Material.Water)
T.WaterColor=Color3.fromRGB(69,112,118)
T.WaterTransparency=.24
T.WaterReflectance=.28
T.WaterWaveSize=.11
T.WaterWaveSpeed=6

local root=Instance.new("Folder",W) root.Name="SakuraIsland"
local trees=Instance.new("Folder",root) trees.Name="CherryTrees"
local grasses=Instance.new("Folder",root) grasses.Name="SkinnedGrass"
local stones=Instance.new("Folder",root) stones.Name="StonePath"
local flowers=Instance.new("Folder",root) flowers.Name="Flowers"
local effects=Instance.new("Folder",root) effects.Name="Effects"

local function H(x,z)
	local r=math.sqrt((x/292)^2+(z/232)^2)
	return -3+math.clamp(1-r,0,1)*15+math.sin(x/78)*1.4+math.sin(z/96)*1.1+math.sin((x+z)/145)*.7
end

for x=-280,280,16 do
	for z=-224,224,16 do
		if math.sqrt((x/292)^2+(z/232)^2)<1 then
			T:FillBall(Vector3.new(x,H(x,z)-14,z),22,Enum.Material.Grass)
		end
	end
end
pcall(function() T.Decoration=true T.GrassLength=.45 end)

local function load(id)
	local ok,res=pcall(A.LoadAssetAsync,A,id)
	if not ok or not res then error("asset "..id.." failed: "..tostring(res)) end
	return res
end

local function clean(inst)
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored=true end
	end
end

local function asModel(inst)
	if inst:IsA("Model") then return inst end
	local m=Instance.new("Model")
	inst.Parent=m
	return m
end

local function putOnGround(model,x,z,yaw,scale)
	model=asModel(model)
	clean(model)
	pcall(function() model:ScaleTo(scale) end)
	model:PivotTo(CFrame.new(x,0,z)*CFrame.Angles(0,yaw,0))
	local cf,size=model:GetBoundingBox()
	local bottom=cf.Position.Y-size.Y/2
	model:PivotTo(model:GetPivot()+Vector3.new(0,H(x,z)-bottom+.12,0))
	return model
end

local skyAsset=load(SKY_ID)
local sky=skyAsset:FindFirstChildWhichIsA("Sky",true)
if not sky then error("Sky asset did not contain a Sky instance") end
sky=sky:Clone()
sky.Parent=L
skyAsset:Destroy()

L.ClockTime=16.15
L.Brightness=2.65
L.ExposureCompensation=.08
L.EnvironmentDiffuseScale=.55
L.EnvironmentSpecularScale=.7
L.Ambient=Color3.fromRGB(132,137,131)
L.OutdoorAmbient=Color3.fromRGB(176,171,158)
local at=Instance.new("Atmosphere",L)
at.Density=.2
at.Offset=.08
at.Color=Color3.fromRGB(224,211,194)
at.Decay=Color3.fromRGB(155,139,131)
at.Glare=.06
at.Haze=.75
local cc=Instance.new("ColorCorrectionEffect",L)
cc.Brightness=.025
cc.Contrast=.02
cc.Saturation=.06
cc.TintColor=Color3.fromRGB(255,238,218)

local treeSource=load(TREE_ID)
clean(treeSource)
local positions={}
local attempts=0
while #positions<27 and attempts<3000 do
	attempts+=1
	local x=RNG:NextNumber(-236,236)
	local z=RNG:NextNumber(-184,184)
	if math.sqrt((x/250)^2+(z/198)^2)<.91 then
		local pathX=-24+math.sin((z+175)*.072)*12+math.sin((z+175)*.026)*7
		local ok=math.abs(x-pathX)>20
		for _,q in ipairs(positions) do
			if (Vector2.new(x,z)-q).Magnitude<31 then ok=false break end
		end
		if ok then table.insert(positions,Vector2.new(x,z)) end
	end
end
assert(#positions==27,"could not place 27 trees")
for i,p in ipairs(positions) do
	local c=treeSource:Clone()
	c.Name=string.format("Sakura_%02d",i)
	c.Parent=trees
	putOnGround(c,p.X,p.Y,RNG:NextNumber(0,math.pi*2),RNG:NextNumber(1.18,1.34))
end
treeSource:Destroy()

local grassAsset=load(GRASS_ID)
clean(grassAsset)
local candidates={}
for _,c in ipairs(grassAsset:GetChildren()) do
	if c:IsA("Model") or c:IsA("BasePart") then table.insert(candidates,c) end
end
if #candidates==0 then candidates={grassAsset} end
local function luminance(inst)
	local sum,n=0,0
	if inst:IsA("BasePart") then
		sum=(inst.Color.R+inst.Color.G+inst.Color.B)/3 n=1
	end
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then sum+=(d.Color.R+d.Color.G+d.Color.B)/3 n+=1 end
	end
	return n>0 and sum/n or 1
end
table.sort(candidates,function(a,b) return luminance(a)<luminance(b) end)
local grassSource=candidates[1]
for i=1,230 do
	local x=RNG:NextNumber(-250,250)
	local z=RNG:NextNumber(-195,195)
	if math.sqrt((x/262)^2+(z/205)^2)<.93 then
		local c=grassSource:Clone()
		local m=asModel(c)
		m.Name=string.format("Grass_%03d",i)
		m.Parent=grasses
		putOnGround(m,x,z,RNG:NextNumber(0,math.pi*2),RNG:NextNumber(.85,1.15))
		m:SetAttribute("RestPivot",m:GetPivot())
	end
end
grassAsset:Destroy()

local stoneAsset=load(STONE_ID)
clean(stoneAsset)
for i=1,18 do
	local z=-176+(i-1)*20
	local x=-24+math.sin(i*.65)*13+math.sin(i*.23)*7
	local c=stoneAsset:Clone()
	c.Name=string.format("Path_%02d",i)
	c.Parent=stones
	putOnGround(c,x,z,math.rad(math.sin(i*.82)*24),RNG:NextNumber(.56,.7))
end
stoneAsset:Destroy()

for i=1,320 do
	local x=RNG:NextNumber(-248,248)
	local z=RNG:NextNumber(-194,194)
	if math.sqrt((x/260)^2+(z/204)^2)<.92 then
		local stem=Instance.new("Part")
		stem.Name="FlowerStem" stem.Size=Vector3.new(.08,.7,.08)
		stem.Color=Color3.fromRGB(72,112,58) stem.Material=Enum.Material.Grass
		stem.Anchored=true stem.CanCollide=false stem.Position=Vector3.new(x,H(x,z)+.45,z) stem.Parent=flowers
		local bloom=Instance.new("Part")
		bloom.Name="Flower" bloom.Size=Vector3.new(.42,.18,.42) bloom.Shape=Enum.PartType.Ball
		bloom.Color=(i%4==0) and Color3.fromRGB(241,236,222) or Color3.fromRGB(225,190,206)
		bloom.Material=Enum.Material.SmoothPlastic bloom.Anchored=true bloom.CanCollide=false
		bloom.Position=stem.Position+Vector3.new(0,.45,0) bloom.Parent=flowers
	end
end

local windOk,windAsset=pcall(A.LoadAssetAsync,A,WIND_ID)
if windOk and windAsset then
	clean(windAsset)
	windAsset.Name="WindEffects"
	windAsset.Parent=effects
	local wm=asModel(windAsset)
	wm:PivotTo(CFrame.new(0,H(0,0)+3,0))
end

local spawn=Instance.new("SpawnLocation",root)
spawn.Name="IslandSpawn" spawn.Size=Vector3.new(7,.5,7)
spawn.Transparency=1 spawn.CanCollide=false spawn.Anchored=true
spawn.Position=Vector3.new(-24,H(-24,-165)+4,-165)

local controller=Instance.new("Script",root)
controller.Name="GrassWindAndFootResponse"
controller.Source=[[
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local folder=workspace.SakuraIsland.SkinnedGrass
local t=0
RunService.Heartbeat:Connect(function(dt)
 t+=dt
 for _,m in ipairs(folder:GetChildren()) do
  if m:IsA("Model") then
   local rest=m:GetAttribute("RestPivot")
   if typeof(rest)=="CFrame" then
    local d=999
    for _,p in ipairs(Players:GetPlayers()) do
     local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
     if r then d=math.min(d,(Vector2.new(r.Position.X,r.Position.Z)-Vector2.new(rest.Position.X,rest.Position.Z)).Magnitude) end
    end
    local press=math.clamp((5.5-d)/5.5,0,1)
    local sway=math.sin(t*1.8+rest.Position.X*.035+rest.Position.Z*.04)*.035
    local target=rest*CFrame.Angles(sway+press*.22,0,-.035)
    m:PivotTo(m:GetPivot():Lerp(target,math.clamp(dt*(press>0 and 10 or 3.5),0,1)))
   end
  end
 end
end)
]]
root:SetAttribute("SkyAssetId",SKY_ID)
root:SetAttribute("SakuraAssetId",TREE_ID)
root:SetAttribute("GrassAssetId",GRASS_ID)
root:SetAttribute("StonePathAssetId",STONE_ID)
root:SetAttribute("WindAssetId",WIND_ID)

A:SavePlaceAsync()
return{
 ok=true,
 clock=L.ClockTime,
 skyAsset=SKY_ID,
 trees=#trees:GetChildren(),
 treeAsset=TREE_ID,
 grassPatches=#grasses:GetChildren(),
 grassAsset=GRASS_ID,
 stoneSegments=#stones:GetChildren(),
 stoneAsset=STONE_ID,
 flowers=#flowers:GetChildren(),
 windAsset=WIND_ID,
 windLoaded=windOk and windAsset~=nil,
 placeId=game.PlaceId,
 universeId=game.GameId
}
