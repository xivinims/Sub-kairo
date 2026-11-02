local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local serde = require('@lune/serde')
local luau = require('@lune/luau')

local game = roblox.deserializePlace(fs.readFile('/tmp/fps-system-demo-source'))
assert(game and game:IsA('DataModel'), 'Patched FPS place is unreadable')
local workspace = game:GetService('Workspace')
local server = game:GetService('ServerScriptService')
local starter = game:GetService('StarterPlayer'):FindFirstChild('StarterPlayerScripts')
assert(workspace:FindFirstChild('Map3'), 'Original FPS template map missing')
assert(server:FindFirstChild('Weapons'), 'Original FPS weapon system missing')
local menu = assert(starter and starter:FindFirstChild('DeadSignalMenu'), 'Screenshot menu missing')
assert(menu:IsA('LocalScript') and menu:GetAttribute('ManagedBy') == 'FPS template screenshot menu', 'Menu ownership mismatch')
assert(menu.Source:find("local REVISION = 'fps-template-menu-v2'", 1, true), 'Menu revision marker missing')
assert(menu.Source:find('EXPERIENCE', 1, true) and menu.Source:find('Camera Banking', 1, true), 'Reference menu pages missing')
assert(menu.Source:find('gasterblaster787388', 1, true), 'Credits page is missing reference credit text')
assert(menu.Source:find('TweenService:Create(nextPage', 1, true), 'Horizontal page transition missing')

local counts, scripts, suspicious = {}, {}, {}
for _, object in ipairs(game:GetDescendants()) do
	counts[object.ClassName] = (counts[object.ClassName] or 0) + 1
	if object:IsA('LuaSourceContainer') then
		local source = object.Source
		local ok, err = pcall(function() return luau.load(source, {debugName = object:GetFullName()}) end)
		assert(ok, 'Luau syntax error in ' .. object:GetFullName() .. ': ' .. tostring(err))
		for _, pattern in ipairs({'loadstring%s*%(', 'HttpService:GetAsync', 'HttpService:PostAsync', 'require%s*%(%s*%d+', 'getfenv%s*%(', 'setfenv%s*%(', 'InsertService:LoadAsset'}) do
			if source:find(pattern) then table.insert(suspicious, {path = object:GetFullName(), pattern = pattern}) end
		end
		table.insert(scripts, object:GetFullName() .. ':' .. #source)
	end
end
table.sort(scripts)
assert(#game:GetDescendants() == 198477, 'FPS template should contain the exact original plus the menu')
assert(#scripts == 237, 'FPS template scripts changed beyond the menu addition')
assert(#suspicious == 0, 'Unexpected dynamic execution/network/asset loading appeared')
print(serde.encode('json', {
	containerType = 'Place',
	descendantCount = #game:GetDescendants(),
	classCounts = counts,
	scriptCount = #scripts,
	scripts = scripts,
	suspiciousPatterns = suspicious,
	map = 'Map3',
	weapons = 'ServerScriptService.Weapons',
	menuRevision = 'fps-template-menu-v2',
}))
