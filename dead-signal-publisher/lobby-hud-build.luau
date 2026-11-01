local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local bundle=R.Instance.new('Model');bundle.Name='LobbyHUDPatch'
local function source(name,class,file)
 local code=fs.readFile(file);luau.load(code,{debugName=file})
 local item=R.Instance.new(class);item.Name=name;item.Source=code;item.Parent=bundle
end
source('FalloutClient','LocalScript','fallout-client.luau')
source('FalloutUI','ModuleScript','fallout-ui.luau')
source('FalloutHealthUI','ModuleScript','fallout-health-ui.luau')
source('FalloutCombatHUD','ModuleScript','fallout-combat-hud.luau')
for _,file in ipairs({'lobby-hud-install.luau','lobby-hud-verify.luau','lobby-hud-invariants.luau','lobby-hud-radar.luau'}) do luau.load(fs.readFile(file),{debugName=file}) end
fs.writeFile('/tmp/lobby-hud-bundle.rbxm',R.serializeModel({bundle}))
print('LOBBY_HUD_BUILD compiled=8 existingHealthTemplate=preserved existingOutfit=preserved')
