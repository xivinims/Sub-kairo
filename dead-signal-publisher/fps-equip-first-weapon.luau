local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local luau = require('@lune/luau')
local serde = require('@lune/serde')

local originalBytes = fs.readFile('/tmp/fps-system-demo-source')
local game = roblox.deserializePlace(originalBytes)
assert(game and game:IsA('DataModel'), 'Original FPS place could not be read')
local weapons = game:GetService('ServerScriptService'):FindFirstChild('Weapons')
local starterWeapons = weapons and weapons:FindFirstChild('StarterWeapons')
assert(starterWeapons and starterWeapons:IsA('Script'), 'Original StarterWeapons server script is missing')
local oldLine = '--player.Character.Humanoid:EquipTool(weaponsHandler.GetPlayerWeapons(player)[1].WeaponTool)'
local newLine = 'player.Character.Humanoid:EquipTool(weaponsHandler.GetPlayerWeapons(player)[1].WeaponTool)'
local source = starterWeapons.Source
local _, matches = source:gsub(oldLine:gsub('([%(%)%.%-%+%*%?%[%]%^%$%%])', '%%%1'), '')
assert(matches == 1, 'Expected exactly one commented original EquipTool call')

local originalCount = #game:GetDescendants()
local originalScripts = {}
for _, item in ipairs(game:GetDescendants()) do
	if item:IsA('LuaSourceContainer') then originalScripts[item] = item.Source end
end

starterWeapons.Source = source:gsub(oldLine:gsub('([%(%)%.%-%+%*%?%[%]%^%$%%])', '%%%1'), newLine)
assert(starterWeapons.Source:find(newLine, 1, true), 'EquipTool call was not reactivated')
assert(luau.load(starterWeapons.Source, {debugName = 'StarterWeapons'}), 'Reactivated StarterWeapons script did not compile')
assert(#game:GetDescendants() == originalCount, 'The edit changed the original instance count')

local changedScripts = {}
for _, item in ipairs(game:GetDescendants()) do
	if item:IsA('LuaSourceContainer') then
		assert(originalScripts[item] ~= nil, 'An original script instance changed')
		if originalScripts[item] ~= item.Source then table.insert(changedScripts, item:GetFullName()) end
	end
end
assert(#changedScripts == 1 and changedScripts[1] == starterWeapons:GetFullName(), 'More than the single requested weapon line changed')

fs.writeFile('/tmp/fps-equip-first-weapon-place', roblox.serializePlace(game))
print(serde.encode('json', {
	ok = true,
	changedScript = starterWeapons:GetFullName(),
	changedScripts = changedScripts,
	instanceCount = originalCount,
	equipCall = newLine,
}))
