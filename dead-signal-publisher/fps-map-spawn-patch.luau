local workspace = game:GetService('Workspace')
local map = workspace:FindFirstChild('Map3')
local spawn = workspace:FindFirstChild('SpawnLocation')
local baseplate = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Baseplate')
assert(map and map:IsA('Folder'), 'Expected original Workspace.Map3 folder')
assert(spawn and spawn:IsA('SpawnLocation'), 'Expected original root SpawnLocation')
assert(baseplate and baseplate:IsA('BasePart'), 'Expected original Workspace.Map.Baseplate')
assert(baseplate.Anchored and baseplate.CanCollide, 'Original baseplate is not a safe spawn floor')
local destination = Vector3.new(500, baseplate.Position.Y + baseplate.Size.Y / 2 + spawn.Size.Y / 2, 500)
assert(math.abs(destination.X) + 10 < baseplate.Size.X / 2, 'Spawn X is outside the baseplate')
assert(math.abs(destination.Z) + 10 < baseplate.Size.Z / 2, 'Spawn Z is outside the baseplate')
assert(not map:IsAncestorOf(spawn), 'Root spawn unexpectedly belongs to Map3')

local function snapshotWeapons()
	local rows = {}
	for _, root in ipairs({game:GetService('ServerScriptService'):FindFirstChild('Weapons'), game:GetService('ReplicatedStorage'):FindFirstChild('Game') and game.ReplicatedStorage.Game:FindFirstChild('Weapons'), game:GetService('StarterPack')}) do
		if root then
			table.insert(rows, root:GetFullName() .. ':' .. root.ClassName)
			for _, item in ipairs(root:GetDescendants()) do
				local detail = item:GetFullName() .. ':' .. item.ClassName
				if item:IsA('LuaSourceContainer') then detail ..= ':' .. #item.Source .. ':' .. item.Source end
				table.insert(rows, detail)
			end
		end
	end
	table.sort(rows)
	return table.concat(rows, '\n')
end

local beforeWeapons = snapshotWeapons()
local beforeSpawn = spawn.Position
local beforeMapDescendants = #map:GetDescendants()
local beforeCount = #game:GetDescendants()
spawn.Position = destination
assert((spawn.Position - destination).Magnitude < 0.01, 'Spawn did not move to the open baseplate area')
map:Destroy()
assert(not workspace:FindFirstChild('Map3'), 'Original Map3 was not removed')
assert(spawn.Parent == workspace, 'Spawn was removed with the map')
assert(snapshotWeapons() == beforeWeapons, 'Weapon scripts or tools changed during map removal')
assert(#game:GetDescendants() == beforeCount - beforeMapDescendants - 1, 'Unexpected instances changed outside the requested map removal')

local result = {
	mapRemoved = true,
	removedMapDescendants = beforeMapDescendants,
	spawnMoved = true,
	oldSpawn = {x = beforeSpawn.X, y = beforeSpawn.Y, z = beforeSpawn.Z},
	newSpawn = {x = spawn.Position.X, y = spawn.Position.Y, z = spawn.Position.Z},
	baseplateTop = baseplate.Position.Y + baseplate.Size.Y / 2,
	weaponsPreserved = true,
	remainingWorkspace = {},
}
for _, child in ipairs(workspace:GetChildren()) do table.insert(result.remainingWorkspace, child.Name .. ':' .. child.ClassName) end
table.sort(result.remainingWorkspace)
return game:GetService('HttpService'):JSONEncode(result)
