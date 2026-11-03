assert(workspace:GetAttribute('WaterRPGBuild')=='water-rpg-v1-assets','Wrong RPG build')
assert(not workspace:FindFirstChild('BreuLobby') and not game.ServerStorage:FindFirstChild('BreuMaps'),'BREU content remains')
local map=assert(workspace:FindFirstChild('WaterCastleMap'))
local parts=0
for _,x in ipairs(map:GetDescendants()) do if x:IsA('BasePart') then parts+=1 end end
assert(parts>=100000,'Water castle map is incomplete: '..parts)
assert(workspace:GetAttribute('RPGTerrainRestored'),'Terrain not restored')
local clothes=0;local residents=0
for _,npc in ipairs(workspace.Residents:GetChildren()) do
 residents+=1
 assert(npc:FindFirstChild('HumanoidRootPart') and npc:FindFirstChildOfClass('Humanoid'),'Invalid resident')
 local shirt=npc:FindFirstChildOfClass('Shirt');local pants=npc:FindFirstChildOfClass('Pants')
 assert(shirt and pants,'Resident outfit missing')
 local function id(value) return tostring(value):match('%d+') end
 assert(id(shirt.ShirtTemplate)==id(npc:GetAttribute('ExpectedShirt')),'Shirt changed for '..npc.Name)
 assert(id(pants.PantsTemplate)==id(npc:GetAttribute('ExpectedPants')),'Pants changed for '..npc.Name)
 clothes+=1
end
assert(residents==18 and clothes==18,'Resident count mismatch')
local arrival=workspace.RPGMarkers.Arrival.Position
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={workspace.Terrain,workspace.WaterCastleMap};ray.IgnoreWater=false
local ground=workspace:Raycast(arrival+Vector3.new(0,3,0),Vector3.new(0,-10,0),ray)
assert(ground and ground.Material~=Enum.Material.Water,'Arrival has no solid floor')
local shared=game.ReplicatedStorage.WaterRPG
assert(shared.PlayerAssets.ClassicLantern and shared.PlayerAssets.Bow and shared.PlayerAssets.DialogueSkin and shared.PlayerAssets.ChakraFeet,'Player models missing')
assert(game.ServerScriptService.PlayerAbilities and game.StarterPlayer.StarterPlayerScripts.PlayerAbilities,'Ability controllers missing')
local ui=game.StarterPlayer.StarterPlayerScripts.WaterRPGClient.Source
assert(ui:find('WaterMenu3D',1,true) and ui:find('YOU DIED',1,true) and ui:find('UPDATE LOG',1,true),'Reference menus missing')
assert(ui:find('Enum.NormalId.Back',1,true),'3D UI facing away from camera')
local Rules=require(shared.Rules)
assert(Rules.quest(0,'Guide')==1 and Rules.quest(1,'Apothecary')==2)
assert(#workspace.TrainingTargets:GetChildren()==3,'Training targets missing')
local camera=require(shared.Config).MenuCamera
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=workspace:GetAttribute('WaterRPGBuild'),parts=parts,residents=residents,outfitsVerified=clothes,terrain=true,grounded=workspace:GetAttribute('RPGGroundedResidents'),spawn={arrival.X,arrival.Y,arrival.Z},camera={camera.X,camera.Y,camera.Z},playerModels=true,menu3D=true,streaming=workspace.StreamingEnabled})
