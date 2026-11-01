local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local bundle=R.Instance.new('Model')
bundle.Name='OriginalFPSRestore'
local specs={
 {'FalloutClient','LocalScript','fallout-client.luau'},
 {'FalloutUI','ModuleScript','fallout-ui.luau'},
 {'Server','Script','fallout-server.luau'},
}
for _,entry in ipairs(specs) do
 local name,class,path=entry[1],entry[2],entry[3]
 local source=fs.readFile(path)
 assert(#source>6000,'Missing original FPS file: '..path)
 assert(luau.load(source,{debugName=path}),'Failed to compile original FPS: '..path)
 local script=R.Instance.new(class)
 script.Name=name
 script.Source=source
 script.Parent=bundle
end
local client=bundle.FalloutClient.Source
local gui=bundle.FalloutUI.Source
local server=bundle.Server.Source
assert(client:find("local ammo=label(gui",1,true),'Original ammo counter missing')
assert(client:find("local health=label(gui,'100 PV'",1,true),'Original health GUI missing')
assert(client:find("local cross=label(gui,'+'",1,true),'Original crosshair missing')
assert(client:find("viewModel=original:Clone()",1,true),'Original first-person gun models missing')
assert(client:find("net.Action:FireServer('Fire'",1,true),'Weapon shooting unavailable')
assert(client:find("net.Action:FireServer('Reload'",1,true),'Gun reload action unavailable')
assert(client:find("FalloutItemVisuals",1,true),'Gun models no longer shown to the player')
assert(client:find("UI.catalogPreview",1,true),'Original gun shop preview absent')
assert(not client:find("CombatHUD",1,true),'Experimental combat HUD still loaded')
assert(not client:find("FalloutOptionsClient",1,true),'Experimental settings HUD still loaded')
assert(not client:find("OwnerMatchBotControls",1,true),'Bot control still on original GUI')
assert(gui:find("function UI.scoreboard(",1,true),'Original team score GUI missing')
assert(gui:find("function UI.wallet(",1,true),'Original wallet missing')
assert(gui:find("function UI.preview(",1,true),'Original gun viewport missing')
assert(not server:find("CombatBots",1,true),'Experimental NPC server remained enabled')
assert(server:find("if action=='Fire' then attack(",1,true),'Server weapon damage logic missing')
assert(server:find("if action=='Reload' then reload(",1,true),'Server gun reload logic missing')
assert(server:find("OptionsStore",1,true),'Existing player data persistence was not preserved')
fs.writeFile('/tmp/fps-original-restore.rbxm',R.serializeModel({bundle}))
print('FPS_ORIGINAL_BUILD compiled=3 gui=original_first_person ammo=true guns=true bots=false')
