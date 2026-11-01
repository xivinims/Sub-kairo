local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
local roots=R.deserializeModel(fs.readFile('/tmp/lobby-health-source.rbxm'))
local rows={}
local function inspect(item)
 local row={path=item:GetFullName(),class=item.ClassName}
 if item:IsA('LuaSourceContainer') then row.source=item.Source end
 if item:IsA('GuiObject') then
  row.size=tostring(item.Size);row.position=tostring(item.Position);row.anchor=tostring(item.AnchorPoint);row.visible=item.Visible
  if item:IsA('ImageLabel') or item:IsA('ImageButton') then row.image=item.Image;row.imageRectOffset=tostring(item.ImageRectOffset);row.imageRectSize=tostring(item.ImageRectSize) end
  if item:IsA('TextLabel') then row.text=item.Text end
 end
 table.insert(rows,row)
end
for _,root in ipairs(roots) do inspect(root);for _,item in ipairs(root:GetDescendants()) do inspect(item) end end
print('LOBBY_HEALTH_ASSET '..serde.encode('json',rows))
