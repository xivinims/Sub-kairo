local RS=game.ReplicatedStorage
local runtime=game.ServerScriptService.FalloutRuntime
assert(workspace:GetAttribute('FalloutBotsBuild')=='training-bots-match-only-v2','New match bot module was not installed')
assert(workspace:GetAttribute('FalloutCombatHUDRevision')=='reference-tactical-bots-v2','HUD was overwritten')
assert(workspace:GetAttribute('FalloutOptionsVisualRevision')=='fps-gear-icon-settings-v2','Settings gear was overwritten')
local server=runtime.Server.Source
local client=game.StarterPlayer.StarterPlayerScripts.FalloutClient.Source
local code=runtime.CombatBots.Source
assert(server:find("phase~='Match' then return {ok=false,message='Bots",1,true),'Owner RPC is allowed in the lobby')
assert(server:find('CombatBots:Start()',1,true),'The match does not create combat NPCs')
assert(client:find("state.phase=='Match' and not options:isOpen()",1,true),'Controls should appear only inside combat')
assert(not client:find("OwnerNPCControls",1,true),'Legacy lobby bot controls remain')
assert(code:find('if self.config.getPhase()~=',1,true),'Bot creation must require Match phase')
assert(code:find('self:_target(bot)',1,true) and code:find('onBotDamage',1,true),'NPC AI or attack callback absent')
local before=protectedSnapshot()
local BotCore=require(runtime.CombatBots)
local mode='Waiting'
local config={
 teamSize=5,catalog=require(RS.FalloutConfig).ById,
 teamIndex=function()return 0 end,
 getPhase=function()return mode end,
 onChanged=function()end,
 onPlayerHit=function()end,onBotEliminated=function()end,
 onBotShot=function()end,onBotDamage=function()end,
}
local mock=BotCore.new(config)
assert(mock:Count()==2,'Two default enemy practice bots are required')
mock:Start()
assert(not mock.active and #mock.slots==0 and #mock.folder:GetChildren()==0,'Bots physically appeared before the match')
mode='Intermission';mock:Start()
assert(not mock.active and #mock.folder:GetChildren()==0,'NPC created during intermission')
mode='Match';mock:Start()
assert(mock.active and #mock.slots==2 and mock.folder:GetAttribute('InMatch')==true,'NPCs do not start with the combat round')
local teamCounts=mock:TeamCounts()
assert(teamCounts[1]==1 and teamCounts[2]==1,'Bot team allocation failed')
local ok,value=mock:SetCount(4)
assert(ok and value==4 and #mock.slots==4,'Creator cannot add bots during the match')
ok,value=mock:SetCount(2)
assert(ok and value==2 and #mock.slots==2,'Creator cannot remove bots during the match')
task.wait(4)
local models=0
local combatMap=workspace:FindFirstChild('CombatMap')
local lobby=workspace:FindFirstChild('Lobby')
assert(combatMap and lobby,'FPS map or lobby missing')
local mapOrigin=combatMap:GetPivot().Position
local lobbyOrigin=lobby:GetPivot().Position
for _,slot in ipairs(mock.slots) do
 local npc=slot.bot
 assert(npc and not npc.dead and npc.model and npc.model.Parent==mock.folder,'Actual animated bot did not spawn')
 assert(npc.hum and npc.hum.RigType==Enum.HumanoidRigType.R6,'Bot must use the same R6 rig as player')
 assert(npc.tool and npc.tool:GetAttribute('FalloutItem'),'Bot did not receive an actual game weapon')
 assert(npc.tool.Parent==npc.model,'Bot tool not equipped to its body')
 assert(npc.def and npc.def.kind=='Gun','Bot is not assigned a firearm from the FPS catalog')
 assert((npc.root.Position-mapOrigin).Magnitude<(npc.root.Position-lobbyOrigin).Magnitude,'Bot physically spawned in lobby instead of battle map')
 assert(npc.hum.Health>0,'Bot spawned defeated')
 models+=1
end
mock:Stop()
assert(not mock.active and #mock.slots==0,'Bot round cleanup failed')
assert(#mock.folder:GetChildren()==0,'Bots remained in the world after the match')
mock.folder:Destroy()
assert(protectedSnapshot()==before,'Native bot test altered unrelated content')
return game:GetService('HttpService'):JSONEncode({
 ok=true,version=game.PlaceVersion,preserved=before,
 revision='training-bots-match-only-v2',actualCombatRigs=models,
 noLobbyNPC=true,matchSpawnOnly=true,realFPSWeapons=true,
 matchOnlyControls=true,ownerCanAdjustActiveBots=true,
 hudPreserved=true,gearSettingsPreserved=true,soloDefaultBots=2
})
