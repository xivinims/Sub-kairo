local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-7208091524.rbxl'));local W=dm:GetService('Workspace')
local matches={};local classes={}
for _,d in ipairs(W:GetDescendants()) do
 classes[d.ClassName]=(classes[d.ClassName] or 0)+1
 local n=string.lower(d.Name)
 if n:find('black',1,true) or n:find('hole',1,true) or n:find('accretion',1,true) or n:find('debris',1,true) then
  if #matches<120 then table.insert(matches,{name=d.Name,path=d:GetFullName(),class=d.ClassName,descendants=#d:GetDescendants()}) end
 end
end
local top={};for _,d in ipairs(W:GetChildren()) do if #top<80 then table.insert(top,{name=d.Name,class=d.ClassName,descendants=#d:GetDescendants()}) end end
print('BLACK HOLE AUDIT '..serde.encode('json',{counts=classes,matches=matches,top=top}))
