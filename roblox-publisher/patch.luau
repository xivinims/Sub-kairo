assert(game.PlaceId==118064584465155 and game.PlaceVersion==89)
local Asset=game:GetService("AssetService")local report={readOnly=true,version=game.PlaceVersion,assets={}}
for _,id in ipairs({17216750157,117077041338395,2141575508,96982217504466})do
 local ok,raw=pcall(function()return Asset:LoadAssetAsync(id)end)
 local info={ok=ok,id=id,items={},sources={}}report.assets[tostring(id)]=info
 if ok then
  for _,d in ipairs(raw:GetDescendants())do
   if d:IsA("LuaSourceContainer")then info.sources[#info.sources+1]={path=d:GetFullName(),source=d.Source}
   elseif d:IsA("Model")or d:IsA("Folder")or d:IsA("ScreenGui")or d:IsA("GuiObject")then
    local row={name=d.Name,class=d.ClassName,path=d:GetFullName()}
    if d:IsA("Model")then local cf,size=d:GetBoundingBox()row.size={size.X,size.Y,size.Z}row.pivot={d:GetPivot():GetComponents()}end
    if d:IsA("TextLabel")or d:IsA("TextButton")then row.text=d.Text end
    info.items[#info.items+1]=row
   elseif d:IsA("BasePart")then info.items[#info.items+1]={class=d.ClassName,name=d.Name,path=d:GetFullName(),cf={d.CFrame:GetComponents()},size={d.Size.X,d.Size.Y,d.Size.Z},mesh=d:IsA("MeshPart")and d.MeshId or nil}end
  end
  raw:Destroy()
 else info.error=tostring(raw)end
end
local description=game.Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
report.owner={shirt=description.Shirt,pants=description.Pants,head=description.Head,torso=description.Torso,emotes=description:GetEmotes(),accessories=description:GetAccessories(true)}description:Destroy()
return report
