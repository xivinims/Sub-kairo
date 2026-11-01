local RS=game.ReplicatedStorage
local SS=game.ServerStorage
local runtime=game.ServerScriptService.FalloutRuntime
local playerScripts=game.StarterPlayer.StarterPlayerScripts
local C=require(RS.FalloutConfig)
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Wrong FPS project')
assert(workspace:GetAttribute('FalloutCombatHUDRevision')=='original-fps-v1','Original HUD revision not applied')
assert(workspace:GetAttribute('FalloutBotsBuild')=='disabled-original-fps','NPC bots still enabled')
assert(not runtime:FindFirstChild('CombatBots'),'Combat bot runtime module still installed')
assert(not RS:FindFirstChild('FalloutCombatHUD'),'Experimental combat GUI module still installed')
local client=playerScripts.FalloutClient.Source
local ui=RS.FalloutUI.Source
local server=runtime.Server.Source
assert(not client:find('CombatHUD',1,true) and not client:find('OwnerMatchBotControls',1,true),'Modern HUD or AI controls present')
assert(client:find("local ammo=label(gui",1,true),'Original ammo display missing')
assert(client:find("local health=label(gui,'100 PV'",1,true),'Original health label missing')
assert(client:find("local cross=label(gui,'+'",1,true),'Original crosshair missing')
assert(client:find('viewModel=original:Clone()',1,true),'First-person gun preview missing')
assert(client:find("net.Action:FireServer('Fire'",1,true),'Weapon firing input missing')
assert(client:find("net.Action:FireServer('Reload'",1,true),'Gun reloading input missing')
assert(client:find("UI.catalogPreview(",1,true),'Gun shop previews missing')
assert(ui:find("function UI.scoreboard(",1,true) and ui:find("function UI.wallet(",1,true),'Original scoreboard or wallet missing')
assert(not server:find('CombatBots',1,true),'Experimental NPC server still active')
assert(server:find("if action=='Fire' then attack(",1,true),'Server gunshot logic missing')
assert(server:find("if action=='Reload' then reload(",1,true),'Server weapon reload logic missing')
local templates=assert(SS:FindFirstChild('FalloutWeaponTemplates'),'Original weapon templates missing')
local visuals=assert(RS:FindFirstChild('FalloutItemVisuals'),'Original gun models missing')
local guns=0
for _,item in ipairs(C.Catalog) do
 if item.kind=='Gun' then
  local template=assert(templates:FindFirstChild(item.id),'Missing gun template: '..item.id)
  assert(template:IsA('Tool') and template:GetAttribute('FalloutItem')==item.id,'Wrong weapon tool: '..item.id)
  assert(template.RequiresHandle and template:FindFirstChild('Handle'),'Missing equipped gun mesh: '..item.id)
  assert(template.Handle:FindFirstChild('Muzzle'),'Missing gun visual attachment: '..item.id)
  local original=assert(visuals:FindFirstChild(item.id),'Missing first-person mesh: '..item.id)
  assert(original:IsA('BasePart'),'Weapon camera model is not a part: '..item.id)
  local clone=original:Clone();assert(clone,'Cannot clone gun');clone:Destroy()
  guns+=1
 end
end
assert(guns==8,'Expected eight original FPS guns')
local fixture=Instance.new('Folder')
local UI=require(RS.FalloutUI)
local board=UI.scoreboard(fixture,{Color3.fromRGB(88,175,240),Color3.fromRGB(237,100,98)})
local wallet=UI.wallet(fixture)
assert(board.root and board.root.Size==UDim2.fromOffset(430,42),'Original FPS scoreboard dimensions differ')
assert(board.slots[1][1] and board.slots[2][5],'Original FPS scoreboard missing team slots')
assert(wallet.root and wallet.root.Size==UDim2.fromOffset(158,42),'Original FPS wallet dimensions differ')
fixture:Destroy()
local preserved=protectedSnapshot()
if beforeSnapshot then assert(preserved==beforeSnapshot,'Map or existing item changed while restoring original FPS') end
return game:GetService('HttpService'):JSONEncode({
 ok=true,version=game.PlaceVersion,preserved=preserved,
 originalGui=true,gunCount=guns,
 firstPersonWeaponMeshes=true,gunReload=true,gunShooting=true,
 legacyHealth=true,legacyCrosshair=true,legacyScoreboard=true,
 extraBotsRemoved=true,experimentalHUDRemoved=true,
 mapAndItemsPreserved=true,
 revision='original-fps-v1'
})
