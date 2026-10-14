assert(game.PlaceVersion==90)
local A=game:GetService("AssetService")
local out={readOnly=true,version=game.PlaceVersion,assets={}}
for _,id in ipairs({77173958514594})do
 local ok,raw=pcall(function()return A:LoadAssetAsync(id)end)
 local row={id=id,ok=ok,items={}}
 if ok then for _,d in ipairs(raw:GetDescendants())do
 if d:IsA("Model")or d:IsA("BasePart")or d:IsA("Animation")or d:IsA("Bone")or d:IsA("Motor6D")then
 local v={name=d.Name,path=d:GetFullName(),class=d.ClassName}
 if d:IsA("BasePart")then v.size={d.Size.X,d.Size.Y,d.Size.Z} end
 if d:IsA("Animation")then v.animation=d.AnimationId end
 row.items[#row.items+1]=v end end raw:Destroy()else row.error=tostring(raw)end out.assets[#out.assets+1]=row
end
out.waterSamples={}
local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
for z=-200,240,40 do for x=50,220,20 do local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-250,0),rp)if hit then out.waterSamples[#out.waterSamples+1]={x=x,z=z,y=hit.Position.Y,material=hit.Material.Name}end end end
return out