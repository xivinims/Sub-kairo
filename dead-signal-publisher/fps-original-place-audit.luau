local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local serde = require('@lune/serde')
local game = roblox.deserializePlace(fs.readFile('/tmp/fps-system-demo-source'))
assert(game and game:IsA('DataModel'), 'Source FPS place is not readable')
local workspace = game:GetService('Workspace')
local function vector(v) return {x = v.X, y = v.Y, z = v.Z} end
local result = {workspaceRoots = {}, map3 = nil, spawns = {}, outsideParts = {}, floors = {}, starterPack = {}, weaponScripts = {}, coreScripts = {}}
for _, child in ipairs(workspace:GetChildren()) do
	table.insert(result.workspaceRoots, child.Name .. ' [' .. child.ClassName .. ']')
	if child.Name == 'Map3' then
		local min = {x = math.huge, y = math.huge, z = math.huge}
		local max = {x = -math.huge, y = -math.huge, z = -math.huge}
		for _, part in ipairs(child:GetDescendants()) do
			if part:IsA('BasePart') then
				pcall(function()
					local p, s = part.CFrame.Position, part.Size
					min.x = math.min(min.x, p.X - s.X / 2); max.x = math.max(max.x, p.X + s.X / 2)
					min.y = math.min(min.y, p.Y - s.Y / 2); max.y = math.max(max.y, p.Y + s.Y / 2)
					min.z = math.min(min.z, p.Z - s.Z / 2); max.z = math.max(max.z, p.Z + s.Z / 2)
				end)
			end
		end
		result.map3 = {class = child.ClassName, min = min, max = max, descendants = #child:GetDescendants()}
	end
end
table.sort(result.workspaceRoots)
for _, item in ipairs(workspace:GetDescendants()) do
	pcall(function()
		if item:IsA('SpawnLocation') then
			table.insert(result.spawns, {path = item:GetFullName(), position = vector(item.CFrame.Position), size = vector(item.Size), enabled = item.Enabled, neutral = item.Neutral, teamColor = tostring(item.TeamColor)})
		elseif item:IsA('BasePart') and (item.Name:lower():find('spawn') or item.Name:lower():find('floor') or item.Name:lower():find('baseplate')) then
			table.insert(result.floors, {path = item:GetFullName(), position = vector(item.CFrame.Position), size = vector(item.Size), anchored = item.Anchored, transparency = item.Transparency, canCollide = item.CanCollide})
		end
		if item:IsA('BasePart') and not item:IsDescendantOf(workspace:FindFirstChild('Map3')) then
			local p = item.CFrame.Position
			if #result.outsideParts < 100 then
				table.insert(result.outsideParts, {path = item:GetFullName(), position = vector(p), size = vector(item.Size), anchored = item.Anchored, transparency = item.Transparency, canCollide = item.CanCollide})
			end
		end
	end)
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
