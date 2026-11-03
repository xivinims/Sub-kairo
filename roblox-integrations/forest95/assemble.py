from pathlib import Path
import json
root=Path(__file__).parent
def read(n): return (root/n).read_text()
def q(s): return '[============['+s+']============]'
header='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==94,"Published base changed")
game:GetService("ServerStorage")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\\n"..code.."\\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
'''
body=header
for name,file in [('Visuals','visuals.luau'),('SeasonController','season-server.luau'),('MusicConfig','music-config.luau'),('MusicPlayer','music-player.luau'),('MusicController','music-server.luau'),('MusicUI','music-ui.luau')]:
 body+='source(runtime,"ModuleScript","'+name+'",'+q(read(file))+')\n'
body+='local reports={}\n'
for name,file in [('terrain','terrain.luau'),('cottage','cottage.luau'),('bridges','bridges.luau'),('water','water-stones.luau'),('lamps','lamps.luau'),('roots','vegetation.luau'),('radio','radio.luau')]:
 body+='reports.'+name+'=factory('+q(read(file))+').install()\n'
body+='workspace.ForestWorld:SetAttribute("UpgradeVersion",95)\n'
for parent,cls,name,file in [('game.ServerScriptService','Script','ForestServer','server.luau'),('game.StarterPlayer.StarterPlayerScripts','LocalScript','ForestMusicClient','music-client.luau')]:
 body+=f'source({parent},"{cls}","{name}",'+q(read(file))+')\n'
body+='run(game.ServerScriptService.ForestServer.Source)\nreports.tests=run('+q(read('tests.luau'))+')\n'
body+='runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)\n'
(root/'stage.luau').write_text(body+'return{staged=true,baseVersion=94,reports=reports}\n')
(root/'install.luau').write_text(body+'game:GetService("AssetService"):SavePlaceAsync()\nreturn{published=true,expectedVersion=95,reports=reports}\n')
verify='''assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==95,"Saved version mismatch")
game:GetService("ServerStorage")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\\n"..code.."\\nend"m.Parent=game.ServerStorage local f=require(m)local v=f()m:Destroy()return v end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
run(game.ServerScriptService.ForestServer.Source)
'''
verify+='local tests=run('+q(read('tests.luau'))+')\nruntime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)\nreturn{ok=true,version=game.PlaceVersion,tests=tests,terrainSettingsBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})))}\n'
(root/'verify.luau').write_text(verify)
elements=[{'path':'roblox-integrations/forest95/'+p.name,'mode':'100644','type':'blob','content':p.read_text()} for p in root.glob('*.luau')]
elements.extend([{'path':'roblox-publisher/patch.luau','mode':'100644','type':'blob','content':read('stage.luau')},{'path':'roblox-publisher/verify.luau','mode':'100644','type':'blob','content':read('verify.luau')}])
s=json.dumps({'tree_elements':elements},ensure_ascii=False);(root/'stage-payload.json').write_text(s);print(len(s))
