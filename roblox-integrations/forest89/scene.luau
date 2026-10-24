local Seasons=require(script.Parent:WaitForChild("Seasons"))
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
	return Seasons.at(x,z)~="Inverno" and shore < 0.96 and y > water + 0.5 and (material == Enum.Material.Grass or material == Enum.Material.LeafyGrass)
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
