local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
for _,id in ipairs({'7902470429','15864801103'}) do
 local dm=R.deserializePlace(fs.readFile('/tmp/asset-'..id..'.rbxl'))
 local index={id=id,scripts={},roots={}}
 for _,service in ipairs(dm:GetChildren()) do local children={};for _,c in ipairs(service:GetChildren()) do table.insert(children,c.Name..':'..c.ClassName) end;table.insert(index.roots,{name=service.Name,children=children}) end
 for _,d in ipairs(dm:GetDescendants()) do if d:IsA('LuaSourceContainer') then
 local path=d:GetFullName();table.insert(index.scripts,{path=path,class=d.ClassName,length=#d.Source})
 print('ORIGINAL_SCRIPT '..J.encode('json',{asset=id,path=path,class=d.ClassName,source=d.Source}))
 end end
 print('ORIGINAL_INDEX '..J.encode('json',index))
end
