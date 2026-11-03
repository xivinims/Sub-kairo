local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
local source=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'))
local screens={}
for _,gui in ipairs(source:GetService('StarterGui'):GetChildren()) do
 local record={name=gui.Name,class=gui.ClassName,objects={}}
 for _,d in ipairs(gui:GetDescendants()) do
  if d:IsA('GuiButton') or d:IsA('TextLabel') or d:IsA('LocalScript') then
   table.insert(record.objects,{path=d:GetFullName(),class=d.ClassName,text=(d:IsA('TextLabel') or d:IsA('TextButton')) and d.Text or nil,visible=d:IsA('GuiObject') and d.Visible or nil,source=d:IsA('LocalScript') and d.Source or nil})
  end
 end
 table.insert(screens,record)
end
print('MYSTERY_UI_SOURCE '..serde.encode('json',screens))
local roots=R.deserializeModel(fs.readFile('assets/hotel/1940sHotelLobby.rbxm'))
local count=0
for _,root in ipairs(roots) do count+=#root:GetDescendants()+1 end
print('HOTEL_SOURCE '..serde.encode('json',{roots=#roots,instances=count}))
