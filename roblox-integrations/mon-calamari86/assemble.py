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
assert(game.PlaceVersion==85,"Published map changed")
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage
 local value=require(m)m:Destroy()return value
end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)
 local s=Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
'''
body = header + 'local geometry=factory(' + quote(read('world.luau')) + ').install()\n'
body += 'local runtime=game.ReplicatedStorage.MonCalamariRuntime\n'
body += 'source(runtime,"ModuleScript","Visuals",' + quote(read('lighting.luau')) + ')\n'
body += 'source(game.ServerScriptService,"Script","MonCalamariServer",' + quote(read('server.luau')) + ')\n'
body += 'source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","MonCalamariClient",' + quote(read('client.luau')) + ')\n'
body += 'require(runtime.Visuals).apply()\n'
body += 'local tests=run(' + quote(read('tests.luau')) + ')\n'
body += 'run(game.ServerScriptService.MonCalamariServer.Source)\n'
(root / 'stage.luau').write_text(body + 'return{staged=true,baseVersion=game.PlaceVersion,geometry=geometry,tests=tests}\n')
(root / 'install.luau').write_text(body + '''local baseVersion=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,baseVersion=baseVersion,expectedVersion=baseVersion+1,geometry=geometry,tests=tests}
''')
verify = '''assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==86,"Expected published city version 86")
local runtime=assert(game.ReplicatedStorage:FindFirstChild("MonCalamariRuntime"))
assert(game.ServerScriptService.MonCalamariServer.Source:find('require(runtime:WaitForChild("Visuals")).apply()',1,true),"Server rendering bootstrap missing")
assert(game.StarterPlayer.StarterPlayerScripts.MonCalamariClient.Source:find("Visuals.apply()",1,true),"Client rendering bootstrap missing")
local rendererBeforeStartup=tostring(game.Lighting.LightingStyle)
require(runtime.Visuals).apply()
local function run(code)
 local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage
 local result=require(m)()m:Destroy()return result
end
'''
verify += 'local tests=run(' + quote(read('tests.luau')) + ')\n'
verify += 'run(game.ServerScriptService.MonCalamariServer.Source)\n'
verify += 'return{ok=true,version=game.PlaceVersion,assetId=workspace.MonCalamariWorld:GetAttribute("SourceAssetId"),rendererBeforeStartup=rendererBeforeStartup,renderingBootstrapVerified=true,tests=tests}\n'
(root / 'verify.luau').write_text(verify)
print({'stageCharacters': len(read('stage.luau')), 'installCharacters': len(read('install.luau')), 'verificationCharacters': len(read('verify.luau'))})
