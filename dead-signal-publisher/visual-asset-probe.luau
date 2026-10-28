local m=game:GetService("AssetService"):LoadAssetAsync(98751037263074)
local r={parts={},bones={},joints={}}
for _,d in ipairs(m:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then d:Destroy()
 elseif d:IsA("BasePart") then table.insert(r.parts,{name=d.Name,path=d:GetFullName(),size={d.Size.X,d.Size.Y,d.Size.Z},cf={d.CFrame:GetComponents()},mesh=d:IsA("MeshPart") and d.MeshId or nil,texture=d:IsA("MeshPart") and d.TextureID or nil})
 elseif d:IsA("Bone") then table.insert(r.bones,{name=d.Name,parent=d.Parent.Name,cf={d.CFrame:GetComponents()}})
 elseif d:IsA("Motor6D") then table.insert(r.joints,{name=d.Name,p0=d.Part0 and d.Part0.Name,p1=d.Part1 and d.Part1.Name}) end
end
m:Destroy();return game:GetService("HttpService"):JSONEncode(r)
