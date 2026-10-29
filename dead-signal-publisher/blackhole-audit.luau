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
local bh=W.Skybox.BlackHole
local detail={}
for _,d in ipairs(bh:GetDescendants()) do
 if d:IsA('BasePart') then table.insert(detail,{name=d.Name,class=d.ClassName,size={d.Size.X,d.Size.Y,d.Size.Z},position={d.CFrame.X,d.CFrame.Y,d.CFrame.Z}}) end
end
local controls={}
for _,d in ipairs(dm:GetDescendants()) do if d:IsA('LuaSourceContainer') then
 local source=d.Source
 local pos=source:find('DebrisField',1,true) or source:find('AccretionDisc',1,true) or source:find('BlackHole',1,true)
 if pos and #controls<8 then table.insert(controls,{path=d:GetFullName(),source=source:sub(math.max(1,pos-800),pos+8000)}) end
end end
print('BLACK HOLE DETAILS '..serde.encode('json',{parts=detail,controls=controls}))
