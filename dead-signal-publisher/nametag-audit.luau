local R=require('@lune/roblox')
local fs=require('@lune/fs')
local serde=require('@lune/serde')
local roots=R.deserializeModel(fs.readFile('/tmp/nametag-source.rbxm'))
local items={}
for _,root in ipairs(roots) do
 local all={root};for _,child in ipairs(root:GetDescendants()) do table.insert(all,child) end
 for _,item in ipairs(all) do
  local record={path=item:GetFullName(),class=item.ClassName}
  if item:IsA('LuaSourceContainer') then record.source=item.Source end
  if item:IsA('GuiObject') then record.size=tostring(item.Size);record.position=tostring(item.Position);record.background=tostring(item.BackgroundColor3) end
  if item:IsA('TextLabel') then record.text=item.Text;record.font=tostring(item.FontFace);record.textColor=tostring(item.TextColor3);record.textSize=item.TextSize end
  if item:IsA('BillboardGui') then record.size=tostring(item.Size);record.offset=tostring(item.StudsOffset);record.alwaysOnTop=item.AlwaysOnTop end
  table.insert(items,record)
 end
end
print('NAMETAG_STRUCTURE '..serde.encode('json',items))
