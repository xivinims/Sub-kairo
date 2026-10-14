assert(game.PlaceVersion==89)
local Asset=game:GetService("AssetService")local report={readOnly=true,emoteAsset=127049078545834,assets={}}
for _,id in ipairs({127049078545834,882493119})do
 local ok,raw=pcall(function()return Asset:LoadAssetAsync(id)end)local row={id=id,ok=ok,items={}}report.assets[tostring(id)]=row
 if ok then
  for _,d in ipairs(raw:GetDescendants())do
   if d:IsA("Animation")then row.items[#row.items+1]={class=d.ClassName,name=d.Name,animationId=d.AnimationId}
   elseif d:IsA("Model")then local cf,size=d:GetBoundingBox()row.items[#row.items+1]={class=d.ClassName,name=d.Name,size={size.X,size.Y,size.Z}}
   elseif d:IsA("BasePart")then row.items[#row.items+1]={class=d.ClassName,name=d.Name,cf={d.CFrame:GetComponents()},size={d.Size.X,d.Size.Y,d.Size.Z}}
   elseif d:IsA("LuaSourceContainer")then row.items[#row.items+1]={class=d.ClassName,name=d.Name,source=d.Source}end
  end
  raw:Destroy()
 else row.error=tostring(raw)end
end
return report
