local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local bundle=R.Instance.new('Model')
bundle.Name='MatchBotsPatch'
for _,spec in ipairs({
 {'Server','Script','fallout-server.luau'},
 {'CombatBots','ModuleScript','fallout-combat-bots.luau'},
 {'FalloutClient','LocalScript','fallout-client.luau'},
}) do
 local code=fs.readFile(spec[3])
 assert(#code>3000,'Missing script '..spec[3])
 assert(luau.load(code,{debugName=spec[3]}),'Compilation failed '..spec[3])
 local script=R.Instance.new(spec[2])
 script.Name=spec[1];script.Source=code;script.Parent=bundle
end
local bots=bundle.CombatBots.Source
local server=bundle.Server.Source
local client=bundle.FalloutClient.Source
assert(bots:find("getPhase()~='Match'",1,true),'Bots must never spawn outside a match')
assert(bots:find("desired=2",1,true),'Solo match must have training enemies automatically')
assert(bots:find('hum:EquipTool(tool)',1,true),'Bots must equip real game guns')
assert(bots:find('onBotShot',1,true) and bots:find('onBotDamage',1,true),'Bots must emit gameplay shots')
assert(bots:find('slot.cancelled=true',1,true),'Removing a bot must cancel pending async spawns')
assert(server:find("phase~='Match' then return {ok=false,message='Bots",1,true),'Bot control must be match-only')
assert(server:find('CombatBots:Start()',1,true),'NPC creation must start during the combat round')
assert(client:find('OwnerMatchBotControls',1,true),'Compact match-only bot controls missing')
assert(client:find("state.phase=='Match' and not options:isOpen()",1,true),'Bot controls must not appear in lobby')
assert(not client:find('OwnerNPCControls',1,true),'Old lobby bot controls still installed')
fs.writeFile('/tmp/fps-match-bots-patch.rbxm',R.serializeModel({bundle}))
print('FPS_MATCH_BOTS_COMPILE_PASS modules=3 soloEnemyNPCs=2 ownerControls=matchOnly')
