assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==95,"Published base changed")
local r={version=game.PlaceVersion}
local asset=game:GetService("AssetService"):LoadAssetAsync(97893326625257)
asset.Parent=workspace
r.lamp={}
for _,d in ipairs(asset:GetDescendants())do
 local info={name=d.Name,class=d.ClassName}
 if d:IsA("BasePart")then info.size={d.Size.X,d.Size.Y,d.Size.Z}info.pos={d.Position.X,d.Position.Y,d.Position.Z}info.color={d.Color.R,d.Color.G,d.Color.B}
  if d:IsA("MeshPart")then info.mesh=d.MeshId info.texture=d.TextureID end
 elseif d:IsA("SurfaceAppearance")then info.colorMap=d.ColorMap info.normalMap=d.NormalMap end
 table.insert(r.lamp,info)
end
local cf,size=asset:GetBoundingBox()r.lampBounds={center={cf.X,cf.Y,cf.Z},size={size.X,size.Y,size.Z}}
asset:Destroy()
local R=game.ReplicatedStorage.ForestRuntime
r.menu={}
for _,d in ipairs(game.StarterGui.TreeWorldMenu:GetDescendants())do if d:IsA("LuaSourceContainer")then table.insert(r.menu,{name=d:GetFullName(),source=d.Source})end end
r.treeTemplates={}
for _,id in ipairs({580221169,6432306802})do local model=game:GetService("AssetService"):LoadAssetAsync(id)
 for _,d in ipairs(model:GetDescendants())do if d:IsA("MeshPart")then table.insert(r.treeTemplates,{asset=id,name=d:GetFullName(),mesh=d.MeshId,texture=d.TextureID,size={d.Size.X,d.Size.Y,d.Size.Z}})end end model:Destroy()end
return r
