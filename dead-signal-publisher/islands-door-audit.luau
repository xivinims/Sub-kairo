local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-186677844.rbxl'));local W=dm:GetService('Workspace');local rows={}
for _,d in ipairs(W:GetDescendants()) do
 if d:IsA('BasePart') and (d.Name:lower():find('water') or d.Name:lower():find('ocean')) then table.insert(rows,{path=d:GetFullName(),cf={d.CFrame:GetComponents()},size={d.Size.X,d.Size.Y,d.Size.Z}}) end
end
print('WATER AUDIT '..J.encode('json',rows))
