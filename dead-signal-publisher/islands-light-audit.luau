local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde')
local roots=R.deserializeModel(fs.readFile('/tmp/asset-17835285085.rbxl'));local items={}
for _,root in ipairs(roots) do local list=root:GetDescendants();table.insert(list,1,root)
 for _,d in ipairs(list) do
  local row={name=d.Name,class=d.ClassName}
  if d:IsA('LuaSourceContainer') then row.source=d.Source:sub(1,16000) end
  if d:IsA('BloomEffect') then row.intensity=d.Intensity;row.threshold=d.Threshold end
  table.insert(items,row)
 end
end
print(serde.encode('json',{asset='17835285085',items=items}))
