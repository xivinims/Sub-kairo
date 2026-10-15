local AssetService=game:GetService("AssetService")
local Workspace=game:GetService("Workspace")
local Terrain=Workspace.Terrain

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-15-reference-rebuild-v3","V3 rebuild missing")

local world=Workspace:FindFirstChild("ForestWorld")
assert(world,"ForestWorld missing")
local rocks=world:FindFirstChild("Rocks")
assert(rocks,"Rocks folder missing")

local templates={}
for _,m in ipairs(rocks:GetChildren()) do
	if m:IsA("Model") and m:FindFirstChildWhichIsA("BasePart",true) then
		table.insert(templates,m)
	end
end
assert(#templates>0,"No existing stylized rock template to clone")

local function groundAt(x,z)
	local result=Workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-360,0))
	if result and result.Instance==Terrain and result.Material~=Enum.Material.Water then
		return result.Position
	end
end

local function clearGrass(center)
	local region=Region3.new(center-Vector3.new(3.5,5,3.5),center+Vector3.new(3.5,5,3.5)):ExpandToGrid(4)
	pcall(function()
		Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground)
	end)
end

local function placeClone(source,pos,scale,yaw,index)
	local clone=source:Clone()
	clone.Name="ReferenceRockHotfix_"..index
	clone.Parent=rocks
	pcall(function() clone:ScaleTo(scale) end)
	for _,p in ipairs(clone:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored=true
			p.CanTouch=false
		end
	end
	local cf,size=clone:GetBoundingBox()
	local pivot=clone:GetPivot()
	local bottom=cf.Position.Y-size.Y/2
	local offset=pivot.Position.Y-bottom
	clone:PivotTo(CFrame.new(pos+Vector3.new(0,offset,0))*CFrame.Angles(0,yaw,0))
	clearGrass(pos)
	return true
end

local rng=Random.new(1510202604)
local existing=0
for _,m in ipairs(rocks:GetChildren()) do
	if m:IsA("Model") and m:FindFirstChildWhichIsA("BasePart",true) then existing+=1 end
end

local target=150
local added=0
local attempts=0
local zones={
	{Vector2.new(-495,455),170,235},
	{Vector2.new(470,610),105,155},
	{Vector2.new(-870,-680),95,165},
	{Vector2.new(-120,40),58,105},
	{Vector2.new(610,100),55,120},
}

while existing+added<target and attempts<1200 do
	attempts+=1
	local zone=zones[((attempts-1)%#zones)+1]
	local a=rng:NextNumber(0,math.pi*2)
	local radius=rng:NextNumber(zone[2],zone[3])
	local x=zone[1].X+math.cos(a)*radius
	local z=zone[1].Y+math.sin(a)*radius
	local hit=groundAt(x,z)
	if hit then
		local src=templates[rng:NextInteger(1,#templates)]
		if placeClone(src,hit,rng:NextNumber(.55,1.45),rng:NextNumber(0,math.pi*2),existing+added+1) then
			added+=1
		end
	end
end

local final=existing+added
assert(final>=110,"Could not add enough stylized rocks")
Workspace:SetAttribute("RockPlacementCount",final)
Workspace:SetAttribute("RockHotfixApplied",true)

local sourceVersion=game.PlaceVersion
AssetService:SavePlaceAsync()
return {
	ok=true,
	sourceVersion=sourceVersion,
	before=existing,
	added=added,
	final=final,
}
