assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==95,"Unexpected base")
local out={readOnly=true,version=game.PlaceVersion,assets={},effects={},teaTool={}}
for _,id in ipairs({10080695893,580221169})do
 local ok,raw=pcall(function()return game:GetService("AssetService"):LoadAssetAsync(id)end)
 if ok then local a={items={},classes={}}
  for _,d in ipairs(raw:GetDescendants())do local r={name=d.Name,path=d:GetFullName(),class=d.ClassName}a.classes[d.ClassName]=(a.classes[d.ClassName]or 0)+1
   if d:IsA("BasePart")then r.size={d.Size.X,d.Size.Y,d.Size.Z}r.cf={d.CFrame:GetComponents()}r.transparency=d.Transparency r.material=d.Material.Name
    if d:IsA("MeshPart")then r.meshId=d.MeshId r.textureId=d.TextureID end
   elseif d:IsA("LuaSourceContainer")then r.source=d.Source
   end a.items[#a.items+1]=r
  end out.assets[tostring(id)]=a raw:Destroy()
 else out.assets[tostring(id)]={error=tostring(raw)}end
end
for _,d in ipairs(workspace.ForestWorld:GetDescendants())do if d:IsA("ParticleEmitter")or d:IsA("Beam")or d:IsA("Trail")then out.effects[#out.effects+1]={name=d.Name,class=d.ClassName,path=d:GetFullName(),enabled=d.Enabled}end end
for _,d in ipairs(game.ReplicatedStorage.ForestRuntime.TeaCupTool:GetDescendants())do local r={name=d.Name,class=d.ClassName}if d:IsA("BasePart")then r.size={d.Size.X,d.Size.Y,d.Size.Z}r.cf={d.CFrame:GetComponents()}end out.teaTool[#out.teaTool+1]=r end
out.menu={}for _,d in ipairs(game.StarterGui.TreeWorldMenu:GetDescendants())do if d:IsA("LuaSourceContainer")then out.menu[#out.menu+1]={name=d.Name,source=d.Source}end end
return out
