local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-186677844.rbxl'))
local rows={};local scripts={}
for _,d in ipairs(dm:GetDescendants()) do
 local n=string.lower(d.Name)
 if d:IsA('BasePart') and (n:find('door',1,true) or n:find('entrance',1,true)) then
 table.insert(rows,{path=d:GetFullName(),class=d.ClassName,size=tostring(d.Size),position=tostring(d.Position),collide=d.CanCollide,transparency=d.Transparency})
 end
 if d:IsA('LuaSourceContainer') and (n:find('door',1,true) or d.Source:find('CanCollide',1,true)) then table.insert(scripts,{path=d:GetFullName(),source=d.Source:sub(1,5000)}) end
end
print('DOOR AUDIT '..J.encode('json',{doors=rows,scripts=scripts}))
local source=R.deserializePlace(fs.readFile('/tmp/still-here-source.rbxl'))
for _,d in ipairs(source:GetDescendants()) do if d:IsA('ModuleScript') and (d.Name=='WindShake' or d.Name=='WindLines') then print('WIND MODULE '..d.Name..' '..d.Source) end end
