local results={}
for _,id in ipairs({76722373571113,186677844,5326950832,88883160098456}) do
 local ok,res=pcall(function()
  local m=game:GetService('AssetService'):LoadAssetAsync(id)
  local counts,children,sources={},{},{}
  for _,d in ipairs(m:GetDescendants()) do
   counts[d.ClassName]=(counts[d.ClassName] or 0)+1
   if d:IsA('LuaSourceContainer') then table.insert(sources,{path=d:GetFullName(),bytes=#d.Source}) end
  end
  for _,d in ipairs(m:GetChildren()) do
   local item={name=d.Name,class=d.ClassName,children={}}
   if d:IsA('Model') then local cf,s=d:GetBoundingBox();item.size={s.X,s.Y,s.Z} end
   for _,c in ipairs(d:GetChildren()) do table.insert(item.children,{name=c.Name,class=c.ClassName,count=#c:GetDescendants()}) end
   table.insert(children,item)
  end
  m:Destroy()
  return {id=tostring(id),counts=counts,children=children,scripts=sources}
 end)
 table.insert(results,ok and res or {id=tostring(id),error=tostring(res)})
end
return game:GetService('HttpService'):JSONEncode(results)
