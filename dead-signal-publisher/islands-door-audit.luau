local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
for _,id in ipairs({'7902470429','13037825880'}) do
 local dm=R.deserializePlace(fs.readFile('/tmp/asset-'..id..'.rbxl'));local result={id=id,scripts={},gui={},monsters={}}
 for _,d in ipairs(dm:GetDescendants()) do
  local path=d:GetFullName();local lower=path:lower()
  if d:IsA('ScreenGui') then local names={};for _,c in ipairs(d:GetDescendants()) do if c:IsA('GuiObject') then table.insert(names,{name=c.Name,class=c.ClassName}) end end;table.insert(result.gui,{path=path,children=names}) end
  if d:IsA('LuaSourceContainer') and (id=='7902470429' and (path:find('StarterGui',1,true) or lower:find('peek') or lower:find('door') or lower:find('mission') or lower:find('camera')) or id=='13037825880' and (lower:find('emmadream') or lower:find('sepul'))) then table.insert(result.scripts,{path=path,source=d.Source:sub(1,26000)}) end
  if id=='13037825880' and d:IsA('Model') and (d.Name:lower():find('sepul') or d.Name:lower():find('monster')) then local names={};for _,c in ipairs(d:GetChildren()) do table.insert(names,c.Name..':'..c.ClassName) end;table.insert(result.monsters,{path=path,count=#d:GetDescendants(),children=names}) end
 end
 print('MANSION RESTORE AUDIT '..J.encode('json',result))
end
