local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-7208091524.rbxl'));local root=dm:GetService('Workspace').Skybox.DebrisField
local counts,children={},{}
for _,d in ipairs(root:GetDescendants()) do counts[d.ClassName]=(counts[d.ClassName] or 0)+1 end
for _,d in ipairs(root:GetChildren()) do if #children<12 then
 local entry={name=d.Name,class=d.ClassName,children={}}
 for _,c in ipairs(d:GetChildren()) do
  local item={name=c.Name,class=c.ClassName}
  if c:IsA('ValueBase') then local ok,v=pcall(function() return tostring(c.Value) end);if ok then item.value=v end end
  table.insert(entry.children,item)
 end
 table.insert(children,entry)
end end
local scripts={}
for _,d in ipairs(dm:GetDescendants()) do if d:IsA('LuaSourceContainer') and (d.Name:lower():find('vfx') or d.Name:lower():find('skybox')) then
 if #scripts<8 then table.insert(scripts,{path=d:GetFullName(),source=d.Source:sub(1,13000)}) end
end end
print('DEBRIS DATA '..serde.encode('json',{counts=counts,children=children,scripts=scripts}))
