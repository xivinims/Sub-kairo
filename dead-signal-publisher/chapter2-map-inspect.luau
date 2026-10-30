local fs=require('@lune/fs')
local R=require('@lune/roblox')
local J=require('@lune/serde')
local place=R.deserializePlace(fs.readFile('/tmp/chapter2-map.rbxl'))
local workspace=place:GetService('Workspace')
local summary={roots={},totalParts=0,totalModels=0,totalScripts=0,totalPrompts=0,totalLights=0}
for _,item in ipairs(workspace:GetDescendants()) do
 if item:IsA('BasePart') then summary.totalParts+=1 end
 if item:IsA('Model') then summary.totalModels+=1 end
 if item:IsA('LuaSourceContainer') then summary.totalScripts+=1 end
 if item:IsA('ProximityPrompt') then summary.totalPrompts+=1 end
 if item:IsA('Light') then summary.totalLights+=1 end
end
for _,root in ipairs(workspace:GetChildren()) do
 local row={name=root.Name,class=root.ClassName,parts=0,models=0,scripts=0,prompts=0,lights=0,children={}}
 for _,item in ipairs(root:GetDescendants()) do
  if item:IsA('BasePart') then row.parts+=1 end
  if item:IsA('Model') then row.models+=1 end
  if item:IsA('LuaSourceContainer') then row.scripts+=1 end
  if item:IsA('ProximityPrompt') then row.prompts+=1 end
  if item:IsA('Light') then row.lights+=1 end
 end
 for i,child in ipairs(root:GetChildren()) do
  if i<=35 then table.insert(row.children,child.Name..' ['..child.ClassName..']') end
 end
 table.insert(summary.roots,row)
end
print('CHAPTER2_MAP_STRUCTURE '..J.encode('json',summary))
