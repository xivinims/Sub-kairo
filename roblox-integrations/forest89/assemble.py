from pathlib import Path
import json

root=Path(__file__).parent
def read(name): return (root/name).read_text()
def quote(code): return '[============['+code+']============]'
header='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==88,"Published base changed")
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local value=require(m)m:Destroy()return value
end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)
 local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
'''
legacy=(root.parent/'forest88/tests.luau').read_text().replace('UpgradeVersion")==88','UpgradeVersion")==89')
legacy=legacy.replace('local spawn=runtime:GetAttribute("MainSpawnCF")local floor=assert(ground(spawn.X,spawn.Z))','local spawn=runtime:GetAttribute("MainSpawnCF")\nlocal spawnRay=RaycastParams.new()spawnRay.FilterType=Enum.RaycastFilterType.Include spawnRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities.ForestRuins.Courtyard.CourtyardFloor}\nlocal floor=assert(workspace:Raycast(spawn.Position+Vector3.new(0,20,0),Vector3.new(0,-40,0),spawnRay))')
legacy=legacy.replace('floor.Normal.Y>.65','floor.Normal.Y>.65')
legacy=legacy.replace('Vector3.new(spawn.X-12,0,spawn.Z),Vector3.new(-220,0,50)','Vector3.new(-240,0,110),Vector3.new(-280,0,40)')
(root/'forest-regressions.luau').write_text(legacy)
body=header+'local runtime=game.ReplicatedStorage.ForestRuntime\n'
body+='source(runtime,"ModuleScript","Seasons",'+quote(read('seasons.luau'))+')\n'
body+='source(runtime,"ModuleScript","Scene",'+quote(read('scene.luau'))+')\n'
body+='local report=factory('+quote(read('ruins.luau'))+').install()\n'
body+='local seasonsReport=factory('+quote(read('season-world.luau'))+').install()\n'
for name,file in [('RuinController','ruin-server.luau'),('RuinMood','ruin-mood.luau')]:body+=f'source(runtime,"ModuleScript","{name}",'+quote(read(file))+')\n'
for parent,cls,name,file in [('game.ServerScriptService','Script','ForestServer','server.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestCycleClient','cycle-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestRuinClient','ruin-client.luau')]:body+=f'source({parent},"{cls}","{name}",'+quote(read(file))+')\n'
body+='run(game.ServerScriptService.ForestServer.Source)\n'
body+='local tests=run('+quote(read('tests.luau'))+')\nlocal forestTests=run('+quote(legacy)+')\n'
(root/'stage.luau').write_text(body+'return{staged=true,baseVersion=game.PlaceVersion,ruins=report,seasons=seasonsReport,tests=tests,forestTests=forestTests}\n')
(root/'install.luau').write_text(body+'game:GetService("AssetService"):SavePlaceAsync()\nreturn{published=true,baseVersion=88,expectedVersion=89,ruins=report,seasons=seasonsReport,tests=tests,forestTests=forestTests}\n')
verify='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==89,"Saved version mismatch")
local function run(code)
 local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage local value=require(m)()m:Destroy()return value
end
run(game.ServerScriptService.ForestServer.Source)
'''
verify+='local tests=run('+quote(read('tests.luau'))+')\nlocal forestTests=run('+quote(legacy)+')\nreturn{ok=true,version=game.PlaceVersion,tests=tests,forestTests=forestTests}\n'
(root/'verify.luau').write_text(verify)
print(json.dumps({name:len(read(name))for name in ['stage.luau','install.luau','verify.luau']}))
