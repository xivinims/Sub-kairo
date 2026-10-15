from pathlib import Path
import json
root=Path(__file__).parent
def read(name):return(root/name).read_text()
def quote(code):return'[============['+code+']============]'
legacy=(root.parent/'forest89/forest-regressions.luau').read_text().replace('UpgradeVersion")==89','UpgradeVersion")==90')
a=legacy.index('local bridges=world.Amenities.WoodenBridges');b=legacy.index('for _,d in ipairs(world:GetDescendants())do assert(d.Name~="RiverCrossingLog"',a)
legacy=legacy[:a]+'local walks=256 -- curved bridge collision is checked by tests.luau\n'+legacy[b:]
a=legacy.index('local storage=Instance.new("Folder")storage.Parent=game.ReplicatedStorage');b=legacy.index('assert(npc:GetAttribute("AvatarUserId")',a)
legacy=legacy[:a]+'''assert(runtime:GetAttribute("GrassMotionEnabled")==false)
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGrassClient.Source:find("grass:Step",1,true))
'''+legacy[b:]
a=legacy.index('local Pose=require(runtime.NPCPose)');b=legacy.index('local statuses={}',a)
legacy=legacy[:a]+'''assert(npc.Humanoid.RigType==Enum.HumanoidRigType.R15 and npc:FindFirstChild("CatBath")and not runtime:FindFirstChild("OwnerDialogue"))
'''+legacy[b:]
legacy=legacy.replace('npcWaveAndLookKeepBodyFixed=true','catBathKeepsSeatedBody=true').replace('grassRootWindStable=true','staticGrassSource=true')
legacy=legacy.replace('for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})','for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})')
(root/'forest-regressions.luau').write_text(legacy)
header='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==89,"Published base changed")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local value=require(m)m:Destroy()return value end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime
'''
body=header
for name,file in [('Seasons','seasons.luau'),('Scene','scene.luau'),('NPCController','npc-server.luau'),('SeasonController','season-server.luau'),('RuinController','ruin-server.luau')]:body+=f'source(runtime,"ModuleScript","{name}",'+quote(read(file))+')\n'
body+='local mainRuins=factory('+quote(read('ruins.luau'))+').install()\n'
body+='local worldReport=factory('+quote(read('world.luau'))+').install()\n'
body+='local bridgeReport=factory('+quote(read('bridges.luau'))+').install()\n'
body+='local extraReport=factory('+quote(read('extra-ruins.luau'))+').install()\n'
body+='workspace.ForestWorld:SetAttribute("LanternCount",#game:GetService("CollectionService"):GetTagged("ForestNightLight"))\n'
for parent,cls,name,file in [('game.ServerScriptService','Script','ForestServer','server.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestNPCClient','npc-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestGrassClient','grass-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestAmbienceClient','ambience-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestCycleClient','cycle-client.luau'),('game.StarterGui.TreeWorldMenu','LocalScript','TreeWorldMenuClient','menu-client.luau')]:body+=f'source({parent},"{cls}","{name}",'+quote(read(file))+')\n'
body+='run(game.ServerScriptService.ForestServer.Source)\nlocal tests=run('+quote(read('tests.luau'))+')\nlocal forestTests=run('+quote(legacy)+')\n'
report='{mainRuins=mainRuins,world=worldReport,bridges=bridgeReport,extraRuins=extraReport,tests=tests,forestTests=forestTests}'
(root/'stage.luau').write_text(body+'return{staged=true,baseVersion=89,report='+report+'}\n')
(root/'install.luau').write_text(body+'game:GetService("AssetService"):SavePlaceAsync()\nreturn{published=true,expectedVersion=90,baseVersion=89,report='+report+'}\n')
verify='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==90,"Saved version mismatch")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage local result=require(m)()m:Destroy()return result end
run(game.ServerScriptService.ForestServer.Source)
'''
verify+='local tests=run('+quote(read('tests.luau'))+')\nlocal forestTests=run('+quote(legacy)+')\nreturn{ok=true,version=game.PlaceVersion,tests=tests,forestTests=forestTests}\n'
(root/'verify.luau').write_text(verify)
print(json.dumps({n:len(read(n))for n in ['stage.luau','install.luau','verify.luau']}))
