from pathlib import Path
import json
root=Path(__file__).parent
def read(n):return(root/n).read_text()
def q(s):return'[============['+s+']============]'
header='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==91,"Published base changed")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
'''
body=header
for name,file in [('RuinMood','mood.luau'),('RuinController','ruin-server.luau'),('Visuals','visuals.luau'),('SeasonController','season-server.luau')]:body+=f'source(runtime,"ModuleScript","{name}",'+q(read(file))+')\n'
body+='local reports={}\n'
for name,file in [('ruins','ruins.luau'),('bridges','bridges.luau'),('tea','tea.luau'),('vegetation','vegetation.luau'),('camps','camp.luau'),('animals','animals.luau')]:body+=f'reports.{name}=factory('+q(read(file))+').install()\n'
body+='local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestAmbienceClient")if old then old:Destroy()end\nworkspace.ForestWorld:SetAttribute("UpgradeVersion",92)\n'
for parent,cls,name,file in [('game.ServerScriptService','Script','ForestServer','server.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestGardenClient','garden-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestRuinClient','ruin-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestCycleClient','cycle-client.luau')]:body+=f'source({parent},"{cls}","{name}",'+q(read(file))+')\n'
body+='run(game.ServerScriptService.ForestServer.Source)\nreports.tests=run('+q(read('tests.luau'))+')\nruntime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)\n'
export='local result=factory('+q(read('export.luau'))+').build()result.report=reports result.baseVersion=91 result.expectedVersion=92 '
(root/'stage.luau').write_text(body+export+'result.exportOnly=true result.staged=true return result\n')
(root/'install.luau').write_text(body+export+'result.exportOnly=false return result\n')
verify='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==92,"Saved version mismatch")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage local v=require(m)()m:Destroy()return v end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
run(game.ServerScriptService.ForestServer.Source)
'''
verify+='local tests=run('+q(read('tests.luau'))+')\nruntime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)\nreturn{ok=true,version=game.PlaceVersion,tests=tests,terrainSettingsBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})))}\n'
(root/'verify.luau').write_text(verify)
e=[]
for f in root.glob('*.luau'):e.append({'path':'roblox-integrations/forest92/'+f.name,'mode':'100644','type':'blob','content':f.read_text()})
for n in ['publish.mjs','place-settings.mjs']:e.append({'path':'roblox-publisher/'+n,'mode':'100644','type':'blob','content':read(n)})
e.append({'path':'roblox-publisher/patch.luau','mode':'100644','type':'blob','content':read('stage.luau')})
e.append({'path':'roblox-publisher/verify.luau','mode':'100644','type':'blob','content':read('verify.luau')})
s=json.dumps({'tree_elements':e});(root/'stage-payload.json').write_text(s);print(len(s))
