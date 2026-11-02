local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local serde = require('@lune/serde')

local bytes = fs.readFile('/tmp/fps-fallout-map-asset')
local result = {container = '', roots = {}, classes = {}, scripts = {}, total = 0}
local okPlace, place = pcall(function() return roblox.deserializePlace(bytes) end)
local roots
if okPlace and place then
	result.container = 'Place'
	local workspace = place:GetService('Workspace')
	roots = workspace:GetChildren()
	result.total = #workspace:GetDescendants()
else
	local okModel, models = pcall(function() return roblox.deserializeModel(bytes) end)
	assert(okModel and models, 'Fallout map asset is neither a place nor a model: ' .. tostring(models))
	result.container = 'Model'
	roots = models
	for _, root in ipairs(roots) do result.total += 1 + #root:GetDescendants() end
end

for _, root in ipairs(roots) do table.insert(result.roots, root.Name .. ' [' .. root.ClassName .. ']') end
table.sort(result.roots)
local function visit(item)
	result.classes[item.ClassName] = (result.classes[item.ClassName] or 0) + 1
	if item:IsA('LuaSourceContainer') then table.insert(result.scripts, item:GetFullName() .. ':' .. #item.Source) end
end
if result.container == 'Place' then
	for _, item in ipairs(place:GetService('Workspace'):GetDescendants()) do visit(item) end
else
	for _, root in ipairs(roots) do visit(root); for _, item in ipairs(root:GetDescendants()) do visit(item) end end
end
table.sort(result.scripts)
print(serde.encode('json', result))
