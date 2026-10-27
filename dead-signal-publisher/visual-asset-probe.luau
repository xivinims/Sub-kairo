local a=game:GetService("AssetService"):LoadAssetAsync(115602504342753)
local r={models={},animations={},joints={},bones={},parts={},scripts=0}
for _,d in ipairs(a:GetDescendants()) do if d:IsA("LuaSourceContainer") then r.scripts+=1; d:Destroy() end end
for _,d in ipairs(a:GetDescendants()) do
 if d:IsA("Humanoid") or d:IsA("AnimationController") then
  local cf,size=d.Parent:GetBoundingBox()
  table.insert(r.models,{path=d.Parent:GetFullName(),class=d.ClassName,size={size.X,size.Y,size.Z},pivot={d.Parent:GetPivot():GetComponents()},hip=d:IsA("Humanoid") and d.HipHeight or nil})
 elseif d:IsA("Animation") then table.insert(r.animations,{path=d:GetFullName(),id=d.AnimationId})
 elseif d:IsA("Motor6D") then table.insert(r.joints,{name=d.Name,path=d:GetFullName(),p0=d.Part0 and d.Part0.Name,p1=d.Part1 and d.Part1.Name})
 elseif d:IsA("Bone") then table.insert(r.bones,{name=d.Name,parent=d.Parent.Name})
 elseif d:IsA("BasePart") then table.insert(r.parts,{name=d.Name,path=d:GetFullName(),size={d.Size.X,d.Size.Y,d.Size.Z},anchored=d.Anchored,position={d.Position.X,d.Position.Y,d.Position.Z}}) end
end
a:Destroy()
return game:GetService("HttpService"):JSONEncode(r)
