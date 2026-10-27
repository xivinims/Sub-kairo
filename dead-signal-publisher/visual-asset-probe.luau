local a=game:GetService("AssetService"):LoadAssetAsync(10468403169)
local r={parts={},groups={},sounds={},scripts=0}
for _,d in ipairs(a:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then r.scripts+=1; d:Destroy() end
end
for _,d in ipairs(a:GetDescendants()) do
    if d:IsA("BasePart") then
        local p=d.Position
        table.insert(r.parts,{name=d.Name,parent=d.Parent.Name,path=d:GetFullName(),class=d.ClassName,
            cframe={d.CFrame:GetComponents()},mesh=d:IsA("MeshPart") and d.MeshId or nil,texture=d:IsA("MeshPart") and d.TextureID or nil,position={p.X,p.Y,p.Z},size={d.Size.X,d.Size.Y,d.Size.Z},color={d.Color.R,d.Color.G,d.Color.B}})
    elseif d:IsA("Model") or d:IsA("Tool") then
        table.insert(r.groups,{name=d.Name,path=d:GetFullName(),class=d.ClassName})
    elseif d:IsA("Sound") then table.insert(r.sounds,{name=d.Name,id=d.SoundId}) end
end
a:Destroy()
return game:GetService("HttpService"):JSONEncode(r)
