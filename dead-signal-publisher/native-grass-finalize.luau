assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local W=workspace
assert(W:GetAttribute("DeadSignalBuildId")=="still-here-native-grass-v7","Wrong native grass file")
for cx=0,7 do for cz=0,7 do
 local a=Vector3.new(-1024+cx*256,-16,-1024+cz*256)
 local region=Region3.new(a,a+Vector3.new(256,96,256)):ExpandToGrid(4)
 W.Terrain:ReplaceMaterial(region,4,Enum.Material.LeafyGrass,Enum.Material.Grass)
 W.Terrain:ReplaceMaterial(region,4,Enum.Material.Rock,Enum.Material.Grass)
 task.wait()
end end
W.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(128,143,69))
W:SetAttribute("ForestSurfaceMaterial","Grass")
local prior=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return game:GetService("HttpService"):JSONEncode({ok=true,sourceVersion=prior})
