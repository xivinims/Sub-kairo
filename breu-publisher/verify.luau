assert(workspace:GetAttribute('BreuBuild')=='0.1.0-playtest','Breu build missing')
assert(workspace.BreuLobby.Spawn:IsA('SpawnLocation'),'Lobby spawn missing')
assert(game.ServerStorage.BreuHunter:FindFirstChildOfClass('Humanoid'),'Hunter missing')
local mapCount=0
for _,map in ipairs(game.ServerStorage.BreuMaps:GetChildren()) do
 mapCount+=1
 assert(#map.Spawns:GetChildren()>=8,'Spawns missing')
 assert(#map.ObjectivePoints:GetChildren()>=3,'Objectives missing')
 assert(#map.Exits:GetChildren()==2,'Exits missing')
 assert(map:FindFirstChild('HunterSpawn'),'Hunter marker missing')
end
assert(mapCount==2,'Expected two maps')
assert(game.ServerScriptService.BreuServer.Source:find('runRound',1,true),'Server missing')
assert(game.StarterPlayer.StarterPlayerScripts.BreuClient.Source:find('BreuInterface',1,true),'Client missing')
local config=require(game.ReplicatedStorage.Breu.Config)
local rules=require(game.ReplicatedStorage.Breu.Rules)
assert(config.MaxPlayers==12 and rules.requiredGenerators(1,5)==2,'Rules failed')
local count=0
local playerScripts=game.StarterPlayer.StarterPlayerScripts
for _,child in ipairs(game:GetDescendants()) do
 if child:IsA('LuaSourceContainer') then
  local root=child
  while root.Parent and root.Parent~=playerScripts do root=root.Parent end
  local core=root.Parent==playerScripts and (root.Name=='PlayerModule' or root.Name=='PlayerScriptsLoader' or root.Name=='RbxCharacterSounds')
  if not core then count+=1 end
 end
end
assert(count==6,'Unexpected legacy gameplay scripts remain: '..count)
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=workspace:GetAttribute('BreuBuild'),maps=mapCount,scripts=count,streaming=workspace.StreamingEnabled})
