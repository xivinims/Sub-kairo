local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local serde = require('@lune/serde')

local meta = serde.decode('json', fs.readFile('/tmp/fps-recovery-meta.json'))
local result = {}
local function pathList(root, limit)
	local rows = {}
	for _, item in ipairs(root:GetDescendants()) do
		if #rows >= limit then break end
		table.insert(rows, {path = item:GetFullName(), class = item.ClassName, descendants = #item:GetDescendants()})
	end
	table.sort(rows, function(a, b) return a.path < b.path end)
	return rows
end
local function inspectPlace(kind)
	local game = roblox.deserializePlace(fs.readFile('/tmp/fps-recovery-' .. kind))
	assert(game and game:IsA('DataModel'), 'Could not deserialize place ' .. kind)
	local out = {kind = kind, descendants = #game:GetDescendants(), roots = {}, tools = {}, matchedScripts = {}, keyRoots = {}}
	for _, root in ipairs(game:GetService('Workspace'):GetChildren()) do table.insert(out.roots, root.Name .. ':' .. root.ClassName .. ':' .. #root:GetDescendants()) end
	table.sort(out.roots)
	for _, item in ipairs(game:GetDescendants()) do
		if item:IsA('Tool') then
			local handle = item:FindFirstChild('Handle')
			table.insert(out.tools, {path = item:GetFullName(), requiresHandle = item.RequiresHandle, hasHandle = handle ~= nil, descendantCount = #item:GetDescendants()})
		elseif item:IsA('LuaSourceContainer') then
			local source = item.Source
			local lower = string.lower(item.Name .. '\n' .. source)
			local matches = lower:find('crouch', 1, true) or lower:find('cameraoffset', 1, true) or lower:find('currentcamera', 1, true) or lower:find('camera type', 1, true)
			local weaponMatch = lower:find('weapon', 1, true) or lower:find('blaster', 1, true) or lower:find('viewmodel', 1, true)
			if matches or (kind == 'overhauled-fps-reference' and weaponMatch and #out.matchedScripts < 100) then
				table.insert(out.matchedScripts, {path = item:GetFullName(), class = item.ClassName, bytes = #source, source = #source <= 9000 and source or source:sub(1, 9000)})
			end
		end
	end
	table.sort(out.tools, function(a, b) return a.path < b.path end)
	table.sort(out.matchedScripts, function(a, b) return a.path < b.path end)
	local rs = game:GetService('ReplicatedStorage')
	for _, path in ipairs({'Game', 'Library', 'Blaster'}) do
		local root = rs:FindFirstChild(path)
		if root then out.keyRoots['ReplicatedStorage.' .. path] = pathList(root, 1000) end
	end
	local gui = game:GetService('StarterGui')
	out.keyRoots.StarterGui = pathList(gui, 1000)
	local ss = game:GetService('ServerScriptService')
	out.keyRoots.ServerScriptService = pathList(ss, 1000)
	return out
end
local function inspectModel(kind)
	local roots = roblox.deserializeModel(fs.readFile('/tmp/fps-recovery-' .. kind))
	assert(roots and #roots > 0, 'Could not deserialize model ' .. kind)
	local out = {kind = kind, roots = {}, classes = {}, scripts = {}, parts = 0, spawnLocations = {}, bounds = {min = {x = math.huge, y = math.huge, z = math.huge}, max = {x = -math.huge, y = -math.huge, z = -math.huge}}}
	for _, root in ipairs(roots) do
		table.insert(out.roots, {name = root.Name, class = root.ClassName, descendants = #root:GetDescendants()})
		local function visit(item)
			out.classes[item.ClassName] = (out.classes[item.ClassName] or 0) + 1
			if item:IsA('BasePart') then
				out.parts += 1
				pcall(function()
					local p, s = item.CFrame.Position, item.Size
					out.bounds.min.x = math.min(out.bounds.min.x, p.X - s.X / 2); out.bounds.max.x = math.max(out.bounds.max.x, p.X + s.X / 2)
					out.bounds.min.y = math.min(out.bounds.min.y, p.Y - s.Y / 2); out.bounds.max.y = math.max(out.bounds.max.y, p.Y + s.Y / 2)
					out.bounds.min.z = math.min(out.bounds.min.z, p.Z - s.Z / 2); out.bounds.max.z = math.max(out.bounds.max.z, p.Z + s.Z / 2)
				end)
			end
			if item:IsA('SpawnLocation') then table.insert(out.spawnLocations, {path = item:GetFullName(), position = tostring(item.CFrame.Position), size = tostring(item.Size), enabled = item.Enabled}) end
			if item:IsA('LuaSourceContainer') then table.insert(out.scripts, item:GetFullName() .. ':' .. #item.Source) end
		end
		visit(root)
		for _, item in ipairs(root:GetDescendants()) do visit(item) end
	end
	table.sort(out.scripts)
	return out
end

for _, asset in ipairs(meta) do
	if asset.kind == 'original-fps' or asset.kind == 'overhauled-fps-reference' then
		table.insert(result, inspectPlace(asset.kind))
	else
		table.insert(result, inspectModel(asset.kind))
	end
end
print(serde.encode('json', result))
