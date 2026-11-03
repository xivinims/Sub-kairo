from pathlib import Path

root = Path(__file__).parent
def read(name):
    return (root / name).read_text()
def quote(code):
    eq = '============'
    while f']{eq}]' in code:
        eq += '='
    return f'[{eq}[{code}]{eq}]'
header = '''assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==86,"Published base changed")
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage
 local v=require(m)m:Destroy()return v
end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)
 if old then old.Source=code return old end
 local s=Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
'''
body = header
body += 'local Scene=factory(' + quote(read('scene.luau')) + ')\n'
body += 'local Terrain=factory(' + quote(read('terrain.luau')) + ')\n'
body += 'local geometry=factory(' + quote(read('world.luau')) + ').install(Scene,Terrain)\n'
body += 'local runtime=game.ReplicatedStorage.ForestRuntime\n'
for name, file in [('Scene', 'scene.luau'), ('Visuals', 'visuals.luau'), ('GrassSampler', 'grass-sampler.luau'), ('SkinnedGrass', 'skinned-grass.luau')]:
    body += f'source(runtime,"ModuleScript","{name}",' + quote(read(file)) + ')\n'
body += 'source(runtime.SkinnedGrass,"ModuleScript","SkinnedGrassUtils",' + quote(read('skinned-grass-utils.luau')) + ')\n'
for parent, cls, name, file in [('game.ServerScriptService', 'Script', 'ForestServer', 'server.luau'),
    ('game.StarterPlayer.StarterPlayerScripts', 'LocalScript', 'ForestAmbienceClient', 'ambience-client.luau'),
    ('game.StarterPlayer.StarterPlayerScripts', 'LocalScript', 'ForestGrassClient', 'grass-client.luau')]:
    body += f'source({parent},"{cls}","{name}",' + quote(read(file)) + ')\n'
body += 'require(runtime.Visuals).apply()\n'
body += 'local tests=run(' + quote(read('tests.luau')) + ')\n'
body += 'run(game.ServerScriptService.ForestServer.Source)\n'
(root / 'stage.luau').write_text(body + 'return{staged=true,baseVersion=game.PlaceVersion,geometry=geometry,tests=tests}\n')
(root / 'install.luau').write_text(body + '''local baseVersion=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,baseVersion=baseVersion,expectedVersion=87,geometry=geometry,tests=tests}
''')
verify = '''assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==87,"Forest version 87 was not saved")
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(game.ServerScriptService.ForestServer.Source:find('require(runtime:WaitForChild("Visuals")).apply()',1,true))
local rendererBeforeStartup=tostring(game.Lighting.LightingStyle)
require(runtime.Visuals).apply()
local function run(code)
 local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage
 local v=require(m)()m:Destroy()return v
end
'''
verify += 'local tests=run(' + quote(read('tests.luau')) + ')\n'
verify += 'run(game.ServerScriptService.ForestServer.Source)\n'
verify += 'return{ok=true,version=game.PlaceVersion,forestOnly=true,rendererBeforeStartup=rendererBeforeStartup,renderingBootstrapVerified=true,tests=tests}\n'
(root / 'verify.luau').write_text(verify)
print({name: len(read(name)) for name in ['stage.luau', 'install.luau', 'verify.luau']})
