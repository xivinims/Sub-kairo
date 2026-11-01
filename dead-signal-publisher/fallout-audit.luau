local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
for _,name in ipairs({'current','fallout','lobby','animations','fps'}) do
 if not fs.isFile('/tmp/fallout-'..name) then continue end
 local bytes=fs.readFile('/tmp/fallout-'..name)
 local ok,root=pcall(R.deserializePlace,bytes)
 local kind='Place'
 if not ok then
  kind='Model';root=R.Instance.new('DataModel')
  for _,m in ipairs(R.deserializeModel(bytes)) do m.Parent=root:GetService('Workspace') end
 end
 local counts,scripts,top,special,animations={},{},{},{},{}
 for _,child in ipairs(root:GetChildren()) do
  for _,item in ipairs(child:GetChildren()) do table.insert(top,item:GetFullName()..' ['..item.ClassName..']') end
 end
 for _,item in ipairs(root:GetDescendants()) do
  counts[item.ClassName]=(counts[item.ClassName] or 0)+1
  if item:IsA('LuaSourceContainer') then
   table.insert(scripts,{path=item:GetFullName(),class=item.ClassName,source=item.Source})
  end
  if item:IsA('Animation') then table.insert(animations,{path=item:GetFullName(),id=item.AnimationId}) end
  if item:IsA('SpawnLocation') or (item:IsA('BasePart') and item.Name:lower():match('spawn')) or item.Name:lower():match('shop') or item.Name:lower():match('store') then
   local r={path=item:GetFullName(),class=item.ClassName};if item:IsA('BasePart') then r.position=tostring(item.CFrame.Position);r.size=tostring(item.Size) end;table.insert(special,r)
  end
 end
 local summaries={}
 for _,s in ipairs(scripts) do
  local entry={path=s.path,class=s.class,bytes=#s.source}
  if name=='animations' or (name=='current' and (s.path:lower():match('weapon') or s.path:lower():match('combat'))) or (name=='fps' and s.path:find('ServerScriptService.Weapons',1,true)) then entry.source=s.source end
  table.insert(summaries,entry)
 end
 print('ASSET_STRUCTURE '..serde.encode('json',{name=name,kind=kind,instances=#root:GetDescendants(),counts=counts,top=top,special=special,scripts=summaries,animations=animations}))
end
