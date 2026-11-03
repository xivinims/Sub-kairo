assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==94,"Unexpected base")
local output={readOnly=true,assets={},audio={},version=game.PlaceVersion}
local ok,raw=pcall(function()return game:GetService("AssetService"):LoadAssetAsync(15855506991)end)
if ok then local a={items={},classes={}}
 for _,d in ipairs(raw:GetDescendants())do a.classes[d.ClassName]=(a.classes[d.ClassName]or 0)+1 local r={name=d.Name,class=d.ClassName}
  if d:IsA("BasePart")then r.size={d.Size.X,d.Size.Y,d.Size.Z}r.cf={d.CFrame:GetComponents()}r.transparency=d.Transparency if d:IsA("MeshPart")then r.meshId=d.MeshId r.textureId=d.TextureID end
  elseif d:IsA("LuaSourceContainer")then r.source=d.Source
  elseif d:IsA("Sound")then r.soundId=d.SoundId r.volume=d.Volume
  end a.items[#a.items+1]=r
 end output.assets["15855506991"]=a raw:Destroy()
else output.assets["15855506991"]={error=tostring(raw)}end
for _,id in ipairs({113146693867357,9120533892,9114178280,9114178044,9120532414,9112902017,9114177820,80031799500164,72688058173547,109647250911986,105504604402949})do
 local info local ok,product=pcall(function()return game:GetService("MarketplaceService"):GetProductInfoAsync(id,Enum.InfoType.Asset)end)
 if ok then info={id=id,name=product.Name,description=product.Description,creator=product.Creator.Name,type=product.AssetTypeId}
  local s=Instance.new("Sound")s.SoundId="rbxassetid://"..id s.Parent=game:GetService("SoundService")local loaded=pcall(function()game:GetService("ContentProvider"):PreloadAsync({s})end)
  info.loaded=loaded and s.IsLoaded info.length=s.TimeLength s:Destroy()
 else info={id=id,error=tostring(product)}end output.audio[#output.audio+1]=info
end
output.terrain={}
local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
for z=-260,280,30 do local x=require(game.ReplicatedStorage.ForestRuntime.Scene).pathX(z)local h=workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,rp)output.terrain[#output.terrain+1]={x=x,z=z,y=h and h.Position.Y,normal=h and h.Normal.Y}end
local rawForest=game:GetService("AssetService"):LoadAssetAsync(6432306802)output.forestModels={}for _,m in ipairs(rawForest["Forest Pack"]:GetChildren())do if m:IsA("Model")then output.forestModels[#output.forestModels+1]=m.Name end end rawForest:Destroy()
output.cottage={}
for _,p in ipairs(workspace.ForestWorld.Amenities.RiversideGarden.WaterCottage:GetDescendants())do if p:IsA("BasePart")then output.cottage[#output.cottage+1]={name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},collide=p.CanCollide,transparency=p.Transparency}end end
return output
