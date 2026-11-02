local fs = require('@lune/fs')
local Roblox = require('@lune/roblox')
local Luau = require('@lune/luau')

local source = fs.readFile('fps-dynamic-menu-client.luau')
assert(source and #source > 10000, 'Sliding FPS menu source is missing or unexpectedly short')
assert(Luau.load(source, {debugName = 'fps-dynamic-menu-client.luau'}), 'Sliding FPS menu does not compile')
assert(source:find("local REVISION = 'fps-menu-sliding-v1'", 1, true), 'Menu revision marker is missing')
assert(source:find("TweenService:Create(old", 1, true), 'Tab transition must slide the old screen out')
assert(source:find("TweenService:Create(nextPage", 1, true), 'Tab transition must slide the next screen in')
assert(source:find("CFrame.lookAt(origin + Vector3.new(offset", 1, true), 'Tab transitions must pan the menu camera')
assert(source:find("'JOGAR'", 1, true) and source:find("'CONFIGURAÇÕES'", 1, true), 'Main menu navigation is incomplete')

local bundle = Roblox.Instance.new('Model')
bundle.Name = 'FPSDynamicMenuPatch'
local script = Roblox.Instance.new('LocalScript')
script.Name = 'DeadSignalMenu'
script.Source = source
script:SetAttribute('ManagedBy', 'Aurivane FPS sliding menu')
script.Parent = bundle
fs.writeFile('/tmp/fps-dynamic-menu-patch.rbxm', Roblox.serializeModel({bundle}))
print('FPS_DYNAMIC_MENU_BUILD compiled=true pageSlide=true cameraPan=true')
