local fs=require('@lune/fs');local roblox=require('@lune/roblox');local process=require('@lune/process');local serde=require('@lune/serde')
local id=process.args[1]
local dm=roblox.deserializePlace(fs.readFile('/tmp/place-'..id..'.rbxl'))
local w=dm:GetService('Workspace');local children={};local counts={}
for _,v in ipairs(w:GetDescendants()) do counts[v.ClassName]=(counts[v.ClassName] or 0)+1 end
for _,v in ipairs(w:GetChildren()) do
 local row={name=v.Name,class=v.ClassName,count=#v:GetDescendants(),children={}}
 if v:IsA('Model') then local cf,s=v:GetBoundingBox();row.position={cf.X,cf.Y,cf.Z};row.size={s.X,s.Y,s.Z} end
 for _,c in ipairs(v:GetChildren()) do
  if #row.children<70 then table.insert(row.children,{name=c.Name,class=c.ClassName,count=#c:GetDescendants()}) end
 end
 table.insert(children,row)
end
print(serde.encode('json',{id=id,counts=counts,children=children}))
