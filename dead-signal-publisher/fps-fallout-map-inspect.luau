local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local serde = require('@lune/serde')

local bytes = fs.readFile('/tmp/fps-fallout-map-asset')
local roots = roblox.deserializeModel(bytes)
assert(roots and #roots > 0, 'Fallout map model is empty')
local result = {container = 'Model', roots = {}, classes = {}, scripts = {}, total = 0}
for _, root in ipairs(roots) do result.total += 1 + #root:GetDescendants() end

for _, root in ipairs(roots) do table.insert(result.roots, root.Name .. ' [' .. root.ClassName .. ']') end
table.sort(result.roots)
local function visit(item)
	result.classes[item.ClassName] = (result.classes[item.ClassName] or 0) + 1
	if item:IsA('LuaSourceContainer') then table.insert(result.scripts, item:GetFullName() .. ':' .. #item.Source) end
end
for _, root in ipairs(roots) do visit(root); for _, item in ipairs(root:GetDescendants()) do visit(item) end end
table.sort(result.scripts)
print(serde.encode('json', result))
