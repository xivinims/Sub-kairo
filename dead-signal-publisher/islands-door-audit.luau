local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
local o=R.deserializePlace(fs.readFile('/tmp/asset-13037825880.rbxl'));local emma=o:GetService('ReplicatedStorage').Dreams.EmmaDream.Map
local rows={};for _,d in ipairs(emma:GetChildren()) do
 local names={};for _,c in ipairs(d:GetChildren()) do table.insert(names,c.Name..':'..c.ClassName) end
 table.insert(rows,{name=d.Name,class=d.ClassName,children=names,count=#d:GetDescendants()})
end
print('ORDERLY FOREST ROOT '..J.encode('json',rows))
local d=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'));local w=d:GetService('Workspace');local rows={};local spawns={}
for _,p in ipairs(w:GetDescendants()) do
 if p:IsA('BasePart') and (p.Name:lower():find('door') or p:IsA('SpawnLocation')) then
  table.insert(rows,{path=p:GetFullName(),class=p.ClassName,size=tostring(p.Size),cf={p.CFrame:GetComponents()},count=#p:GetDescendants()})
 end
end
print('DUVALL DOORS '..J.encode('json',rows))
