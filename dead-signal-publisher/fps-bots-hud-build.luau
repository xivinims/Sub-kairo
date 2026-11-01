local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local files={
 {'Server','Script','fallout-server.luau'},
 {'FalloutClient','LocalScript','fallout-client.luau'},
 {'FalloutCombatHUD','ModuleScript','fallout-combat-hud.luau'},
 {'CombatBots','ModuleScript','fallout-combat-bots.luau'},
}
local patch=R.Instance.new('Model')
patch.Name='FPSCombatBotsPatch'
for _,entry in ipairs(files) do
 local name,class,path=entry[1],entry[2],entry[3]
 local source=fs.readFile(path)
 assert(#source>1000,'Empty source '..path)
 local compiled=luau.load(source,{debugName=path})
 assert(compiled,'Could not parse '..path)
 local item=R.Instance.new(class);item.Name=name;item.Source=source;item.Parent=patch
end
local server=patch.Server.Source
local client=patch.FalloutClient.Source
local hud=patch.FalloutCombatHUD.Source
local bots=patch.CombatBots.Source
assert(server:find("CombatBots:Start()",1,true),'NPC match startup is not installed')
assert(server:find("CombatBots:Hit(",1,true),'Server is not checking shot hits on NPC rigs')
assert(server:find("command=='BotAdd'",1,true),'Owner cannot add bots')
assert(server:find("C.OwnerUserId",1,true),'Missing owner permission check')
assert(client:find("owner",1,true)==nil or client:find("OwnerNPCControls",1,true),'Owner controls missing')
assert(client:find("scores=state.scores",1,true),'Combat HUD score feed missing')
assert(hud:find("MatchScoreStrip",1,true) and hud:find("TeamMarker",1,true),'Match layout missing')
assert(hud:find("ScreenInsets=Enum.ScreenInsets.None",1,true),'Crosshair viewport alignment missing')
assert(bots:find("CreateHumanoidModelFromDescriptionAsync",1,true),'Must create R6 NPC rigs')
assert(bots:find("FalloutWeaponTemplates",1,true),'Bots must use the real game gun templates')
assert(bots:find("onBotDamage",1,true),'Bot hits must go through game server damage callback')
assert(bots:find("maximum=4",1,true),'Mobile bot limit must remain bounded')
fs.writeFile('/tmp/fps-bots-hud-patch.rbxm',R.serializeModel({patch}))
print('FPS_BOTS_HUD_BUILD sourceModules=4 format=rbxm parser=passed gameHud=refined bots=bounded')
