assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==93,"Unexpected base")
local function v(p)return{p.X,p.Y,p.Z}end
local out={readOnly=true,version=game.PlaceVersion,assets={},treeSamples={},amenities={}}
for _,id in ipairs({11324928349,6833503207,580221169,70515116941793})do
 local ok,raw=pcall(function()return game:GetService("AssetService"):LoadAssetAsync(id)end)
 if ok then local record={items={},classes={}}
  for _,p in ipairs(raw:GetDescendants())do record.classes[p.ClassName]=(record.classes[p.ClassName]or 0)+1
   if p:IsA("BasePart")and #record.items<100 then local item={name=p.Name,class=p.ClassName,size=v(p.Size),position=v(p.Position),cf={p.CFrame:GetComponents()},transparency=p.Transparency,material=p.Material.Name,color=v(Vector3.new(p.Color.R,p.Color.G,p.Color.B)),collide=p.CanCollide}
    if p:IsA("MeshPart")then item.meshId=p.MeshId item.textureId=p.TextureID end
    record.items[#record.items+1]=item
   end
   if p:IsA("LuaSourceContainer")then record.items[#record.items+1]={name=p.Name,class=p.ClassName,source=p.Source}end
   if p:IsA("Texture")or p:IsA("Decal")then record.items[#record.items+1]={name=p.Name,class=p.ClassName,texture=p.Texture,face=p.Face.Name}end
   if p:IsA("Light")then record.items[#record.items+1]={name=p.Name,class=p.ClassName,brightness=p.Brightness,range=p.Range}end
  end
  out.assets[tostring(id)]=record raw:Destroy()
 else out.assets[tostring(id)]={error=tostring(raw)}end
end
local world=workspace.ForestWorld local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
for i,m in ipairs(world.Decor.Trees:GetChildren())do if i%40==1 then
 local item={name=m.Name,pivot=v(m:GetPivot().Position),root=m:GetAttribute("ActualRootPoint")and v(m:GetAttribute("ActualRootPoint")),trunks={}}
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Name:lower():find("trunk",1,true)then local h=ground(p.Position.X,p.Position.Z)item.trunks[#item.trunks+1]={name=p.Name,size=v(p.Size),cf={p.CFrame:GetComponents()},ground=h and v(h.Position),class=p.ClassName}end end
 out.treeSamples[#out.treeSamples+1]=item
end end
for _,f in ipairs(world.Amenities:GetChildren())do local cf,size if f:IsA("Model")then cf,size=f:GetBoundingBox()end out.amenities[#out.amenities+1]={name=f.Name,count=#f:GetDescendants(),position=cf and v(cf.Position),size=size and v(size)}end
out.sites={}for x=-64,128,32 do for z=-80,64,32 do local h=ground(x,z)out.sites[#out.sites+1]={x=x,z=z,y=h and h.Position.Y,normal=h and h.Normal.Y}end end
return out
