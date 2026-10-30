local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-7208091524.rbxl'))
local W=dm:GetService('Workspace')
local bh=W.Skybox.BlackHole
local halo=bh.Model.Singularity.Halo
local rows={}
for _,d in ipairs(bh:GetDescendants()) do
 if d:IsA('BasePart') then
  local cf=d.CFrame
  table.insert(rows,{name=d.Name,path=d:GetFullName(),class=d.ClassName,size={d.Size.X,d.Size.Y,d.Size.Z},position={cf.X,cf.Y,cf.Z},look={cf.LookVector.X,cf.LookVector.Y,cf.LookVector.Z},transparency=d.Transparency,material=tostring(d.Material)})
 end
end
local group={}
for _,child in ipairs(bh:GetChildren()) do
 table.insert(group,{name=child.Name,class=child.ClassName,count=#child:GetDescendants()})
end
local skyChildren={}
for _,c in ipairs(W.Skybox:GetChildren()) do table.insert(skyChildren,{name=c.Name,class=c.ClassName,count=#c:GetDescendants()}) end
local sky=dm:GetService('Lighting'):FindFirstChildWhichIsA('Sky')
local skyInfo=sky and {back=sky.SkyboxBk,front=sky.SkyboxFt} or nil
local spawn=W:FindFirstChildWhichIsA('SpawnLocation',true)
print('SOURCE_BLACK_HOLE_GEOMETRY '..serde.encode('json',{haloSize={halo.Size.X,halo.Size.Y,halo.Size.Z},haloPosition={halo.Position.X,halo.Position.Y,halo.Position.Z},haloLook={halo.CFrame.LookVector.X,halo.CFrame.LookVector.Y,halo.CFrame.LookVector.Z},spawnPosition=spawn and {spawn.Position.X,spawn.Position.Y,spawn.Position.Z} or nil,parts=rows,groups=group,sky=skyInfo,skyChildren=skyChildren}))
