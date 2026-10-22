assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")
local rt=game.ReplicatedStorage:FindFirstChild("XNRuntime")
assert(rt and rt:GetAttribute("Version")==110,"v110 missing")
assert(rt:GetAttribute("GameName")=="XN [VOICE]","name wrong")
assert(rt:GetAttribute("WorldWidth")==270000 and rt:GetAttribute("WorldDepth")==270000,"world scale wrong")
assert(rt:GetAttribute("PBRAssetId")==13536410655,"PBR wrong")
assert(rt:GetAttribute("HDAssetId")==18242663106,"HD wrong")
assert(rt:GetAttribute("ROCKSAssetId")==8248445118,"rocks wrong")
assert(rt:GetAttribute("BIGTREEAssetId")==86013526879602,"big tree wrong")
assert(not workspace:FindFirstChild("BrookhavenMap") and not workspace:FindFirstChild("XN_City"),"old city remains")
local t=game.ServerStorage:FindFirstChild("NatureTemplates"); assert(t,"templates missing")
for _,n in ipairs({"PBR","HD","Rocks","BigTree","Butterfly","LeafFX"}) do assert(t:FindFirstChild(n) and #t[n]:GetChildren()>0,"missing pack "..n) end
local gen=game.ServerScriptService:FindFirstChild("NatureWorldGenerator"); assert(gen and gen:IsA("Script"),"generator missing")
for _,token in ipairs({"WORLD_HALF=135000","depth=lake(x,z) and 9 or 7","Enum.Material.Water","NaturePackRock","GiantTree","Wildflower","Butterfly","RealTreeLeafFall","local islands="}) do assert(gen.Source:find(token,1,true),"generator feature missing "..token) end
local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController"); assert(wind and wind:GetAttribute("AssetId")==11946229834,"wind missing")
assert(workspace.GlobalWind.Magnitude>10,"global wind missing")
assert(workspace:FindFirstChild("NatureSpawn"),"spawn missing")
assert(game.ReplicatedFirst:FindFirstChild("XNLoading"),"loading missing")
return {ok=true,version=110,worldWidth=270000,worldDepth=270000,chunkSize=512,globalWind={workspace.GlobalWind.X,workspace.GlobalWind.Y,workspace.GlobalWind.Z},mapParts=0,lots=0,grass=0,pumpkins=0,pumpkinClusters=0}
