local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local luau = require('@lune/luau')

local placeBytes = fs.readFile('/tmp/fps-system-demo-source')
local game = roblox.deserializePlace(placeBytes)
assert(game and game:IsA('DataModel'), 'FPS template source is not a complete place')
local workspace = game:GetService('Workspace')
local scripts = game:GetService('ServerScriptService')
local starterPlayer = game:GetService('StarterPlayer')
local playerScripts = starterPlayer:FindFirstChild('StarterPlayerScripts')
assert(workspace:FindFirstChild('Map3'), 'Original FPS demo map Map3 is missing')
assert(scripts:FindFirstChild('Weapons'), 'Original FPS weapon server is missing')
assert(playerScripts, 'Original FPS client script folder is missing')
assert(not playerScripts:FindFirstChild('DeadSignalMenu'), 'Template unexpectedly already contains the menu')

local originalWorkspaceCount = #workspace:GetDescendants()
local originalWeapons = scripts.Weapons
local originalWeaponsCount = #originalWeapons:GetDescendants()
local originalScripts = {}
for _, item in ipairs(game:GetDescendants()) do
	if item:IsA('LuaSourceContainer') then originalScripts[item] = true end
end

local source = fs.readFile('fps-template-menu-client.luau')
assert(source and #source > 10000, 'Screenshot-based sliding menu source is missing')
assert(luau.load(source, {debugName = 'FPS template sliding menu'}), 'Menu source did not compile')
for _, text in ipairs({'EXPERIENCE', 'SETTINGS', 'CREDITS', 'UPDATE LOG', 'Camera Banking', 'Music Volume', 'gasterblaster787388'}) do
	assert(source:find(text, 1, true), 'Screenshot menu feature is missing: ' .. text)
end
assert(source:find('TweenService:Create(old', 1, true) and source:find('TweenService:Create(nextPage', 1, true), 'Page transition does not slide both screens')

local menu = roblox.Instance.new('LocalScript')
menu.Name = 'DeadSignalMenu'
menu.Source = source
menu:SetAttribute('ManagedBy', 'FPS template screenshot menu')
menu.Parent = playerScripts

assert(#workspace:GetDescendants() == originalWorkspaceCount, 'Map changed while installing the menu')
assert(scripts.Weapons == originalWeapons and #originalWeapons:GetDescendants() == originalWeaponsCount, 'Weapon system changed while installing the menu')
for _, item in ipairs(game:GetDescendants()) do
	if item:IsA('LuaSourceContainer') and item ~= menu then
		assert(originalScripts[item] == true, 'Original FPS script was replaced: ' .. item:GetFullName())
	end
end
local preservedScripts = 0
for _ in pairs(originalScripts) do preservedScripts += 1 end
assert(preservedScripts == 236, 'Original template script set changed before the menu patch')
assert(#game:GetDescendants() == 198477, 'Expected exactly one added menu script in the original FPS template')

fs.writeFile('/tmp/fps-system-demo-source', roblox.serializePlace(game))
print('FPS_TEMPLATE_MENU_PATCH originalMap=unchanged originalWeapons=unchanged originalScripts=unchanged menuAdded=true')
