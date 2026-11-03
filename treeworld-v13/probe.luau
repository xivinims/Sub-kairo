local world=workspace:FindFirstChild('OveryardPhotoWorld')
assert(world,'world missing')
local out={placeVersion=game.PlaceVersion,children={},special={}}
for _,c in ipairs(world:GetChildren())do
 local item={name=c.Name,class=c.ClassName}
 if c:IsA('Model')then
  local ok,cf,size=pcall(function()local a,b=c:GetBoundingBox();return a,b end)
  if ok then item.center={cf.Position.X,cf.Position.Y,cf.Position.Z};item.size={size.X,size.Y,size.Z}end
 end
 table.insert(out.children,item)
end
for _,d in ipairs(world:GetDescendants())do
 local n=string.lower(d.Name)
 if d:IsA('Model')and(string.find(n,'torii',1,true)or string.find(n,'bridge',1,true)or string.find(n,'ruin',1,true)or string.find(n,'house',1,true)or string.find(n,'shrine',1,true))then
  local cf,size=d:GetBoundingBox()
  table.insert(out.special,{name=d:GetFullName(),center={cf.Position.X,cf.Position.Y,cf.Position.Z},size={size.X,size.Y,size.Z}})
 end
end
return out