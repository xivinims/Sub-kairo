from pathlib import Path
import json
root=Path(__file__).parent
def read(n):return(root/n).read_text()
def q(s):return'[============['+s+']============]'
header='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==90,"Published base changed")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
'''
body=header
for name,file in [('GardenWeather','weather.luau'),('RuinController','ruin-server.luau')]:body+=f'source(runtime,"ModuleScript","{name}",'+q(read(file))+')\n'
for name,file in [('riverside','build.luau'),('animals','animals.luau'),('tools','tools.luau'),('audio','audio.luau'),('tea','tea-detail.luau')]:body+=f'local {name}=factory('+q(read(file))+').install()\n'
for parent,cls,name,file in [('game.ServerScriptService','Script','ForestServer','server.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestGardenClient','garden-client.luau')]:body+=f'source({parent},"{cls}","{name}",'+q(read(file))+')\n'
body+='run(game.ServerScriptService.ForestServer.Source)\n'
for name,file in [('baseTests','base-tests.luau'),('forestTests','forest-regressions.luau'),('gardenTests','tests.luau'),('interactionTests','interaction-tests.luau')]:body+=f'local {name}=run('+q(read(file))+')\n'
report='{riverside=riverside,animals=animals,tools=tools,audio=audio,tea=tea,baseTests=baseTests,forestTests=forestTests,gardenTests=gardenTests,interactionTests=interactionTests}'
(root/'stage.luau').write_text(body+'return{staged=true,baseVersion=90,report='+report+'}\n')
(root/'install.luau').write_text(body+'game:GetService("AssetService"):SavePlaceAsync()\nreturn{published=true,expectedVersion=91,baseVersion=90,report='+report+'}\n')
verify='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==91,"Saved version mismatch")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage local v=require(m)()m:Destroy()return v end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
run(game.ServerScriptService.ForestServer.Source)
'''
for name,file in [('baseTests','base-tests.luau'),('forestTests','forest-regressions.luau'),('gardenTests','tests.luau'),('interactionTests','interaction-tests.luau')]:verify+=f'local {name}=run('+q(read(file))+')\n'
(root/'verify.luau').write_text(verify+'return{ok=true,version=game.PlaceVersion,baseTests=baseTests,forestTests=forestTests,gardenTests=gardenTests,interactionTests=interactionTests}\n')
elements=[]
for f in root.glob('*.luau'):elements.append({'path':'roblox-integrations/forest91/'+f.name,'mode':'100644','type':'blob','content':f.read_text()})
elements.append({'path':'roblox-publisher/patch.luau','mode':'100644','type':'blob','content':read('stage.luau')})
(root/'stage-payload.json').write_text(json.dumps({'tree_elements':elements}))
print(len((root/'stage-payload.json').read_text()))
