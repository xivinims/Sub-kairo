assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==86,"Wrong target/version")
local Asset=game:GetService("AssetService")
local function vec(v)return{v.X,v.Y,v.Z}end
local function info(d)
 local r={name=d.Name,class=d.ClassName,children={}}
 if d:IsA("Model")then local cf,s=d:GetBoundingBox()r.position=vec(cf.Position)r.size=vec(s)end
 if d:IsA("BasePart")then r.position=vec(d.Position)r.size=vec(d.Size)r.material=d.Material.Name r.color=vec(Vector3.new(d.Color.R,d.Color.G,d.Color.B))r.cf={d.CFrame:GetComponents()}r.collide=d.CanCollide end
 if d:IsA("MeshPart")then r.meshId=d.MeshId r.textureId=d.TextureID r.doubleSided=d.DoubleSided end
 for _,c in ipairs(d:GetChildren())do r.children[#r.children+1]={name=c.Name,class=c.ClassName}end
 return r
end
local output={readOnly=true,version=game.PlaceVersion,assets={}}
for _,id in ipairs({6432306802,87377915371959})do
 local raw=Asset:LoadAssetAsync(id)
 local classes,items,sources={},{},{}
 for _,d in ipairs(raw:GetDescendants())do
  classes[d.ClassName]=(classes[d.ClassName]or 0)+1
  if d:IsA("LuaSourceContainer")then sources[#sources+1]={path=d:GetFullName(),name=d.Name,class=d.ClassName,source=d.Source}
  elseif d:IsA("Model")or d:IsA("Folder")or d:IsA("MeshPart")or d:IsA("SurfaceAppearance")then
   local r=info(d)r.path=d:GetFullName()
   if d:IsA("SurfaceAppearance")then
    r.pbr=true
    for _,key in ipairs({"ColorMap","NormalMap","RoughnessMap","AlphaMode"})do local ok,value=pcall(function()return tostring(d[key])end)if ok then r[key]=value end end
   end
   items[#items+1]=r
  end
 end
 output.assets[tostring(id)]={root=info(raw),classes=classes,items=items,sources=sources}
 raw:Destroy()
end
local runtime=game.ReplicatedStorage.MonCalamariRuntime
output.liveWind=runtime.WindEffects:GetAttribute("SourceAssetId")
output.lightingSource=runtime.Visuals.Source
return output
