from pathlib import Path
import json
root=Path(__file__).parent
def read(n): return (root/n).read_text()
def q(s): return '[============['+s+']============]'
header='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==95,"Published base changed")
game:GetService("ServerStorage")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)runtime:SetAttribute("ForestTestMode",true)
'''
body=header
for name,file in [('Foliage','foliage.luau'),('RiverReflection','reflection.luau'),('MusicUI','music-ui.luau'),('SeasonController','season-server.luau')]:
 body+='source(runtime,"ModuleScript","'+name+'",'+q(read(file))+')\n'
body+='local reports={}\n'
for name,file in [('terrain','terrain.luau'),('foliage','foliage.luau'),('bridges','bridges.luau'),('water','water.luau'),('lamps','lamps.luau'),('roots','vegetation.luau'),('tea','tea.luau'),('theme','theme.luau')]:
 body+='reports.'+name+'='+("require(runtime.Foliage).install()" if name=='foliage' else 'factory('+q(read(file))+').install()')+'\n'
body+='workspace.ForestWorld:SetAttribute("UpgradeVersion",96)\n'
for parent,cls,name,file in [('game.ServerScriptService','Script','ForestServer','server.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestGardenClient','garden-client.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestReflectionClient','reflection-client.luau')]:
 body+=f'source({parent},"{cls}","{name}",'+q(read(file))+')\n'
body+='run(game.ServerScriptService.ForestServer.Source)\nreports.tests=run('+q(read('tests.luau'))+')\n'
body+='runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)runtime:SetAttribute("ForestTestMode",nil)\n'
(root/'stage.luau').write_text(body+'return{staged=true,baseVersion=95,reports=reports}\n')
(root/'install.luau').write_text(body+'game:GetService("AssetService"):SavePlaceAsync()\nreturn{published=true,expectedVersion=96,reports=reports}\n')
verify='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==96,"Saved version mismatch")
game:GetService("ServerStorage")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage local f=require(m)local v=f()m:Destroy()return v end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)runtime:SetAttribute("ForestTestMode",true)
run(game.ServerScriptService.ForestServer.Source)
'''
verify+='local tests=run('+q(read('tests.luau'))+')\nruntime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)runtime:SetAttribute("ForestTestMode",nil)\nreturn{ok=true,version=game.PlaceVersion,tests=tests,terrainSettingsBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})))}\n'
(root/'verify.luau').write_text(verify)
elements=[{'path':'roblox-integrations/forest96/'+p.name,'mode':'100644','type':'blob','content':p.read_text()} for p in root.glob('*.luau')]
elements.extend([{'path':'roblox-publisher/patch.luau','mode':'100644','type':'blob','content':read('stage.luau')},{'path':'roblox-publisher/verify.luau','mode':'100644','type':'blob','content':read('verify.luau')}])
s=json.dumps({'tree_elements':elements},ensure_ascii=False);(root/'stage-payload.json').write_text(s);print(len(s))
