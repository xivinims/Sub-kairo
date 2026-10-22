assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")
local rt=game.ReplicatedStorage:FindFirstChild("XNRuntime")
assert(rt and rt:GetAttribute("Version")==111,"v111 missing")
assert(rt:GetAttribute("GameName")=="XN [VOICE]","name wrong")
assert(rt:GetAttribute("WorldWidth")==270000 and rt:GetAttribute("WorldDepth")==270000,"world scale wrong")
assert(rt:GetAttribute("StreamingTargetStuds")==1920,"streaming target is not 5x")
assert(rt:GetAttribute("StreamingMinStuds")==384,"streaming min wrong")
assert(rt:GetAttribute("PBRAssetId")==13536410655,"PBR wrong")
assert(rt:GetAttribute("HDAssetId")==18242663106,"HD wrong")
assert(rt:GetAttribute("ROCKSAssetId")==8248445118,"rocks wrong")
assert(rt:GetAttribute("BIGTREEAssetId")==86013526879602,"big tree wrong")
assert(rt:GetAttribute("FORESTAssetId")==6432306802,"official wildlife source wrong")
assert(not workspace:FindFirstChild("BrookhavenMap") and not workspace:FindFirstChild("XN_City"),"old city remains")

local t=game.ServerStorage:FindFirstChild("NatureTemplates")
assert(t,"templates missing")
for _,n in ipairs({"PBR","HD","Rocks","BigTree","Wildlife","LeafFX"}) do
 assert(t:FindFirstChild(n) and #t[n]:GetChildren()>0,"missing pack "..n)
end
assert(t.PBR:GetAttribute("AssetId")==13536410655,"PBR provenance lost")
assert(t.HD:GetAttribute("AssetId")==18242663106,"HD provenance lost")
assert(t.Rocks:GetAttribute("AssetId")==8248445118,"rock provenance lost")
assert(t.BigTree:GetAttribute("AssetId")==86013526879602,"big tree provenance lost")
assert(t.Wildlife:GetAttribute("AssetId")==6432306802,"wildlife provenance lost")
assert(t.LeafFX:GetAttribute("AssetId")==6432306802,"leaf FX provenance lost")

local butterflies=0
for _,x in ipairs(t.Wildlife:GetChildren()) do
 if x:IsA("Model") and x.Name:find("Butterfly_FlightPath",1,true) then butterflies+=1 end
end
assert(butterflies==2,"official butterfly templates missing")
assert(t.LeafFX:FindFirstChildWhichIsA("ParticleEmitter",true),"official falling leaf emitter missing")

local gen=game.ServerScriptService:FindFirstChild("NatureWorldGenerator")
assert(gen and gen:IsA("Script"),"generator missing")
for _,token in ipairs({
 "CHUNK,WORLD_HALF,RADIUS=512,135000,4",
 "ExactBigTree",
 "NaturePackTree",
 "ExactNaturePackRock",
 "RealLeafFallVolume",
 "RealTreeLeafFall",
 "OfficialAnimatedButterfly",
 "Butterfly_FlightPath",
 "rng:NextNumber()<.08",
 "depth=lake(x,z) and 7 or 5",
 "Enum.Material.Water",
 "Wildflower",
 "local islands="
}) do
 assert(gen.Source:find(token,1,true),"generator feature missing "..token)
end

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:GetAttribute("AssetId")==11946229834,"wind missing")
assert(workspace.GlobalWind.Magnitude>10,"global wind missing")
assert(workspace:FindFirstChild("NatureSpawn"),"spawn missing")
assert(game.ReplicatedFirst:FindFirstChild("XNLoading"),"loading missing")

return {
 ok=true,
 version=111,
 worldWidth=270000,
 worldDepth=270000,
 chunkSize=512,
 streamingTarget=1920,
 streamingMin=384,
 globalWind={workspace.GlobalWind.X,workspace.GlobalWind.Y,workspace.GlobalWind.Z},
 exactPBR=13536410655,
 exactHD=18242663106,
 exactRocks=8248445118,
 exactBigTree=86013526879602,
 officialWildlife=6432306802,
 butterflyTemplates=butterflies,
 mapParts=0,lots=0,grass=0,pumpkins=0,pumpkinClusters=0
}
