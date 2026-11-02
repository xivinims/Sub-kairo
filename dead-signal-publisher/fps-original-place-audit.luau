local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local serde = require('@lune/serde')
local game = roblox.deserializePlace(fs.readFile('/tmp/fps-system-demo-source'))
assert(game and game:IsA('DataModel'), 'Source FPS place is not readable')
local workspace = game:GetService('Workspace')
local function vector(v) return {x = v.X, y = v.Y, z = v.Z} end
local result = {workspaceRoots = {}, map3 = nil, spawns = {}, floors = {}, starterPack = {}, weaponScripts = {}, coreScripts = {}}
for _, child in ipairs(workspace:GetChildren()) do
	table.insert(result.workspaceRoots, child.Name .. ' [' .. child.ClassName .. ']')
	if child.Name == 'Map3' then
		local cf, size = child:GetBoundingBox()
		result.map3 = {class = child.ClassName, center = vector(cf.Position), size = vector(size), descendants = #child:GetDescendants()}
	end
end
table.sort(result.workspaceRoots)
for _, item in ipairs(workspace:GetDescendants()) do
	if item:IsA('SpawnLocation') then
		table.insert(result.spawns, {path = item:GetFullName(), position = vector(item.Position), size = vector(item.Size), enabled = item.Enabled, neutral = item.Neutral, teamColor = tostring(item.TeamColor)})
	elseif item:IsA('BasePart') and (item.Name:lower():find('spawn') or item.Name:lower():find('floor') or item.Name:lower():find('baseplate')) then
		table.insert(result.floors, {path = item:GetFullName(), position = vector(item.Position), size = vector(item.Size), anchored = item.Anchored, transparency = item.Transparency, canCollide = item.CanCollide})
	end
end
for _, item in ipairs(game:GetService('StarterPack'):GetChildren()) do
	table.insert(result.starterPack, {name = item.Name, class = item.ClassName, tool = item:IsA('Tool')})
end
local weapons = game:GetService('ServerScriptService'):FindFirstChild('Weapons')
if weapons then
	for _, item in ipairs(weapons:GetDescendants()) do
		if item:IsA('LuaSourceContainer') then
			local disabled = false
			pcall(function() disabled = item.Disabled end)
			table.insert(result.weaponScripts, {path = item:GetFullName(), class = item.ClassName, disabled = disabled, sourceBytes = #item.Source})
		end
	end
end
for _, serviceName in ipairs({'ReplicatedStorage', 'ServerStorage', 'StarterGui', 'StarterPlayer'}) do
	for _, item in ipairs(game:GetService(serviceName):GetDescendants()) do
		if item:IsA('LuaSourceContainer') and (item.Name:lower():find('weapon') or item.Name:lower():find('intro') or item.Name:lower():find('spawn')) then
			local disabled = false
			pcall(function() disabled = item.Disabled end)
			table.insert(result.coreScripts, {path = item:GetFullName(), class = item.ClassName, disabled = disabled, sourceBytes = #item.Source})
		end
	end
end
print(serde.encode('json', result))
