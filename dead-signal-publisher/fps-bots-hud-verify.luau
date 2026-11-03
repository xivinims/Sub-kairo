local RS=game.ReplicatedStorage
local runtime=game.ServerScriptService.FalloutRuntime
local UI=require(RS.FalloutUI)
local Health=require(RS.FalloutHealthUI)
local outfit=require(runtime.FrozenAvatar)
assert(workspace:GetAttribute('FalloutCombatHUDRevision')=='reference-tactical-bots-v2')
assert(workspace:GetAttribute('FalloutHUDRevision')=='fps-left-options-v4')
assert(workspace:GetAttribute('FalloutViewportRevision')=='weapon-clones-v1')
assert(workspace:GetAttribute('FalloutBotsBuild')=='training-bots-v1')
local botSource=runtime.CombatBots.Source
assert(botSource:find('CreateHumanoidModelFromDescriptionAsync',1,true),'NPC models must use R6 rigs')
assert(botSource:find('FalloutWeaponTemplates',1,true),'NPC must equip existing Roblox weapons')
assert(botSource:find('onBotDamage',1,true),'NPC damage must stay server-side')
local clientSource=game.StarterPlayer.StarterPlayerScripts.FalloutClient.Source
assert(clientSource:find("OwnerNPCControls",1,true),'Creator bot controls missing')
assert(clientSource:find("board.screen.Enabled=state.phase~='Match'",1,true),'Match should use tactical HUD, not lobby portraits')
local serverSource=runtime.Server.Source
assert(serverSource:find("command=='BotAdd'",1,true),'Owner bot add command absent')
assert(serverSource:find("p.UserId~=C.OwnerUserId",1,true),'Owner-only permission check absent')
assert(serverSource:find("CombatBots:Hit(",1,true),'Player raycasts cannot hit NPCs')
local before=protectedSnapshot()
-- Verify count bounds and NPC team allocation without touching live combat.
local BotCore=require(runtime.CombatBots)
local mock=BotCore.new({
 teamSize=5,catalog=require(game.ReplicatedStorage.FalloutConfig).ById,
 teamIndex=function()return 0 end,getPhase=function()return 'Waiting' end,
 onChanged=function()end,onPlayerHit=function()end,
 onBotEliminated=function()end,onBotShot=function()end,onBotDamage=function()end,
})
local ok,limit=mock:SetCount(12)
assert(ok and limit==4 and mock:Count()==4,'NPC count must be limited for mobile')
mock:SetCount(2)
assert(mock:Count()==2 and #mock:Roster()==0,'Lobby bots must stay out of combat')
mock:Start()
local teams=mock:TeamCounts()
assert(teams[1]==1 and teams[2]==1,'Bots should balance both teams')
assert(#mock:Roster()==2,'NPCs missing from virtual roster')
task.wait(3)
local count=0
for _,slot in ipairs(mock.slots) do
 if slot.bot and slot.bot.model and slot.bot.hum and slot.bot.tool then
  assert(slot.bot.hum.RigType==Enum.HumanoidRigType.R6,'NPC must use R6 player-compatible animation rig')
  assert(slot.bot.tool:GetAttribute('FalloutItem'),'NPC equipped tool has no existing weapon id')
  count+=1
 end
end
mock:Stop()
mock.folder:Destroy()
assert(count==2,'Combat NPC rigs or existing weapons did not spawn')
local fixture=Instance.new('Folder')
local board=UI.scoreboard(fixture,{Color3.new(0,0,1),Color3.new(1,0,0)})
assert(board.root.Size==UDim2.fromOffset(286,28) and board.root.AnchorPoint.Y==0)
assert(board.screen.ScreenInsets==Enum.ScreenInsets.DeviceSafeInsets)
local portraits=0
for _,item in ipairs(board.root:GetDescendants()) do
 if item:IsA('ImageLabel') then portraits+=1 end
 if item:IsA('TextLabel') then assert(not item.Text:find('×',1,true)) end
end
assert(portraits==10)
local layouts={
 {viewport=Vector2.new(812,375),device=Rect.new(0,-58,694,296),topbar=Rect.new(164,-58,694,0),top=0,center=true},
 {viewport=Vector2.new(896,414),device=Rect.new(0,-58,778,335),topbar=Rect.new(164,-58,778,0),top=0,center=true},
 {viewport=Vector2.new(640,360),device=Rect.new(0,-58,600,281),topbar=Rect.new(164,-58,600,0),top=0,center=true},
 {viewport=Vector2.new(390,844),device=Rect.new(0,-58,390,766),topbar=Rect.new(180,-58,360,0),top=58},
 {viewport=Vector2.new(1024,768),device=Rect.new(0,-58,1024,710),topbar=Rect.new(164,-58,1024,0),top=0,center=true},
 {viewport=Vector2.new(812,375),device=Rect.new(0,-58,694,296),topbar=Rect.new(570,-58,694,0),top=58},
}
for _,layout in ipairs(layouts) do
 UI.fitScoreboard(board,layout.viewport,layout.topbar,layout.device)
 local x=board.root.Position.X.Offset;local half=UI.ScoreWidth*board.scale.Scale/2
 assert(board.root.Position.Y.Offset==layout.top,'HUD separated from top edge')
 assert(x-half>=0 and x+half<=layout.device.Width,'HUD outside device safe area')
 if layout.center then assert(math.abs(x-layout.device.Width/2)<.01,'HUD centered on leftover space instead of screen') end
 if not board.fallback then assert(x-half>=layout.topbar.Min.X-layout.device.Min.X+4 and x+half<=layout.topbar.Max.X-layout.device.Min.X-4,'HUD overlaps Roblox controls') end
end
local wallet=UI.wallet(fixture)
assert(wallet.root.Size.Y.Offset==26 and wallet.root:FindFirstChildOfClass('UICorner').CornerRadius.Scale==1)
assert(not wallet.root:FindFirstChild('Progress') and wallet.root:FindFirstChild('CoinIcon'))
UI.setBalance(wallet,'0');assert(wallet.root.Size.X.Offset==64)
UI.setBalance(wallet,UI.money(1234567));assert(wallet.balance.Text=='1.234.567' and wallet.root.Size.X.Offset<140)
local template=RS.LobbyHealthTemplate
assert(template.HealthGui.HealthFrame.Size==UDim2.fromOffset(170,18))
for _,item in ipairs(template:GetDescendants()) do assert(not item:IsA('LuaSourceContainer'),'Unreviewed asset script') end
local health=Health.create(fixture,template)
local human=Instance.new('Humanoid');human.MaxHealth=100;human.Health=100
Health.update(health,'Waiting',human);assert(health.screen.Enabled and health.bar.Size.X.Scale==1 and health.bar.Image:find('35238053',1,true))
Health.update(health,'Match',human);assert(not health.screen.Enabled)
human.Health=20;Health.update(health,'Intermission',human);assert(health.screen.Enabled and math.abs(health.bar.Size.X.Scale-.2)<.001 and health.bar.Image:find('35238036',1,true))
Health.update(health,'Results',human);assert(not health.screen.Enabled and not health.overlay.Visible)
Health.update(health,'Waiting',nil);assert(not health.screen.Enabled)
local respawn=Instance.new('Humanoid');respawn.MaxHealth=150;respawn.Health=150
Health.update(health,'Waiting',respawn);assert(health.bar.Size.X.Scale==1)
respawn.Health=0;Health.update(health,'Waiting',respawn);task.wait(.35);assert(health.bar.Size.X.Scale==0)
Health.update(health,'Match',respawn);assert(not health.overlay.Visible)
human:Destroy();respawn:Destroy();fixture:Destroy()
local HUD=require(RS.FalloutCombatHUD)
local radar=require(RS.FalloutRadarData)
assert(#radar.rects>0 and #radar.rects<=120 and radar.width>1 and radar.depth>1)
do
 local fixture=Instance.new('Folder')
 local equippedId
 local hud=HUD.create(fixture,UI,function(id)equippedId=id end)
 assert(hud.reticleScreen.ScreenInsets==Enum.ScreenInsets.None and hud.cross.Position==UDim2.fromScale(.5,.5),'Aim marker must match viewport ray center')
 assert(hud.scoreboard.Name=='MatchScoreStrip' and hud.scoreText and hud.timeText,'Reference match team score bars missing')
 assert(#hud.markers==2 and hud.brand.Text=='DEAD SIGNAL','HUD objective markers and branding missing')
 local character=Instance.new('Model');character.Parent=fixture
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=Vector3.new(radar.minX+radar.width/2,0,radar.minZ+radar.depth/2);root.Parent=character
 local human=Instance.new('Humanoid');human.Parent=character
 local tool=Instance.new('Tool');tool:SetAttribute('FalloutItem','compact');tool:SetAttribute('Ammo',12);tool:SetAttribute('Reserve',96);tool.Parent=character
 local backpack=Instance.new('Folder');backpack.Parent=fixture
 local knife=Instance.new('Tool');knife:SetAttribute('FalloutItem','knife');knife.Parent=backpack
 local catalog=require(RS.FalloutConfig).ById
 local context={phase='Waiting',humanoid=human,character=character,backpack=backpack,catalog=catalog,tool=tool,def=catalog.compact,touch=true}
 HUD.update(hud,context);assert(not hud.screen.Enabled and not hud.reticleScreen.Enabled)
 context.phase='Match';hud.lastSlow=-math.huge;HUD.update(hud,context)
 assert(hud.screen.Enabled and hud.reticleScreen.Enabled and hud.count.Text=='012' and hud.reserve.Text=='/ 096')
 assert(hud.preview:FindFirstChild('ModelPreview') and hud.slots[1].id=='compact' and hud.slots[2].id=='knife')
 HUD.equipSlot(hud,2);assert(equippedId=='knife');HUD.cycleEquipment(hud,1);assert(equippedId=='knife')
 assert(math.abs(hud.own.Position.X.Scale-.5)<.001 and math.abs(hud.own.Position.Y.Scale-.5)<.001)
 HUD.addKill(hud,{killer='Alpha',victim='Bravo',headshot=true});hud.lastSlow=-math.huge;HUD.update(hud,context);assert(hud.feedRows[1].Text:find('Alpha',1,true))
 tool:SetAttribute('Ammo',0);tool:SetAttribute('Reloading',true);HUD.update(hud,context);assert(hud.count.Text=='000' and hud.reserve.Text=='RECARGA')
 context.downed=true;HUD.update(hud,context);assert(not hud.reticleScreen.Enabled and hud.hpTitle.Text=='CAÍDO')
 context.downed=false;context.reticleEnabled=false;context.radarEnabled=false;context.killfeedEnabled=false;HUD.update(hud,context);assert(not hud.reticleScreen.Enabled and not hud.radar.Visible and not hud.feed.Visible)
 context.menuOpen=true;HUD.update(hud,context);assert(not hud.screen.Enabled)
 context.phase='Intermission';HUD.update(hud,context);assert(not hud.screen.Enabled)
 fixture:Destroy()
end
local npc=workspace.Shopkeeper
assert(npc:GetAttribute('FrozenOutfitRevision')=='2026-11-01-owner-avatar')
local frozenDescription=outfit.create()
local frozenProperties={Shirt=frozenDescription.Shirt,Pants=frozenDescription.Pants,GraphicTShirt=frozenDescription.GraphicTShirt}
assert(frozenProperties.Shirt==123193711263166 and frozenProperties.Pants==12900240938)
assert(npc:GetAttribute('OwnerAvatarUserId')==8344738123 and npc.Humanoid.RigType==Enum.HumanoidRigType.R6)
local applied=npc.Humanoid:GetAppliedDescription()
for _,key in ipairs({'Shirt','Pants','GraphicTShirt'}) do assert(applied[key]==frozenProperties[key],'Frozen outfit mismatch: '..key) end
local expected={};for _,entry in ipairs(frozenDescription:GetAccessories(true)) do expected[entry.AssetId]=true end
local accessoryCount=0
for _,entry in ipairs(applied:GetAccessories(true)) do assert(expected[entry.AssetId],'Unexpected NPC accessory');expected[entry.AssetId]=nil;accessoryCount+=1 end
assert(next(expected)==nil,'An outfit accessory was dropped')
applied:Destroy();frozenDescription:Destroy()
local copy=outfit.create();copy.Shirt=0;copy:Destroy();copy=outfit.create();assert(copy.Shirt==frozenProperties.Shirt);copy:Destroy()
assert(not runtime.ShopkeeperLayout.Source:find('GetHumanoidDescriptionFromUserId',1,true),'NPC still follows live account appearance')
assert(npc.PrimaryPart.Anchored and npc.Head:FindFirstChild('gui') and npc:FindFirstChild('ProximityPrompt'))
local window=workspace.Lobby.Shop:FindFirstChild('WindowFrame',true)
assert(math.abs((npc.Head.Position-window.Position):Dot(window.CFrame.RightVector))<.2)
local feet=math.min(npc['Left Leg'].Position.Y-npc['Left Leg'].Size.Y/2,npc['Right Leg'].Position.Y-npc['Right Leg'].Size.Y/2)
assert(math.abs(feet-npc:GetAttribute('FloorHeight'))<.06)
assert(protectedSnapshot()==before,'Verification changed unrelated content')
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,revision='reference-tactical-bots-v2',preserved=before,scoreSize={286,28},phoneScoreSize={263.12,25.76},portraits=portraits,layouts=#layouts,walletZeroSize={64,26},healthAsset='84860453909277',healthPhases='Waiting/Intermission only',healthRespawn=true,frozenShirt=frozenProperties.Shirt,frozenPants=frozenProperties.Pants,frozenAccessories=accessoryCount,frozenAt='2026-11-01T14:36:42Z',combatHUD='fine-reticle/vitals/ammo/equipment/killfeed',radarFootprints=#radar.rects})
