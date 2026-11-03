local m=game:GetService("AssetService"):LoadAssetAsync(11946229834)
local sources={}
for _,d in ipairs(m:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then table.insert(sources,{name=d.Name,class=d.ClassName,path=d:GetFullName(),source=d.Source}) end
end
m:Destroy()
return game:GetService("HttpService"):JSONEncode({asset=11946229834,parented=false,sources=sources})
