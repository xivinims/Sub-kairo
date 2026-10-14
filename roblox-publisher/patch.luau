assert(game.PlaceVersion==91)
local S=game:GetService("SerializationService")local E=game:GetService("EncodingService")local original=workspace.Terrain
local region=Region3.new(Vector3.new(-32,-16,-32),Vector3.new(32,24,32))
local before=original:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
local xml='<roblox version="4"><Item class="Terrain" referent="T"><Properties><bool name="Decoration">true</bool><float name="GrassLength">0.45</float></Properties></Item></roblox>'
local ok,list=pcall(function()return S:DeserializeInstancesAsync(buffer.fromstring(xml))end)
local after=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})local same=true
for x=1,before.Size.X do for y=1,before.Size.Y do for z=1,before.Size.Z do if before.SolidOccupancy[x][y][z]~=after.SolidOccupancy[x][y][z]or before.LiquidOccupancy[x][y][z]~=after.LiquidOccupancy[x][y][z]then same=false end end end end
return{readOnly=true,deserialize=ok,sameTerrain=ok and list[1]==original,sameData=same,serializedTerrain=buffer.tostring(E:Base64Encode(S:SerializeInstancesAsync({workspace.Terrain})))}
