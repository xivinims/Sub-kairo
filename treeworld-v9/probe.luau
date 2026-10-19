assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local report={version=game.PlaceVersion,assets={},lighting={}}
for _,id in ipairs({6432306802,112552460612661,5036801877}) do
 local ok,root=pcall(function()return game:GetService("InsertService"):LoadAsset(id)end)
 local a={id=id,ok=ok,models={}}
 if ok then
  for _,m in ipairs(root:GetDescendants()) do
   if m:IsA("Model") and m:FindFirstChildWhichIsA("BasePart",true) then
    local cf,sz=m:GetBoundingBox()
    local n,meshes,scripts=0,0,0
    for _,p in ipairs(m:GetDescendants()) do
     if p:IsA("BasePart")then n+=1 end
     if p:IsA("MeshPart")then meshes+=1 end
     if p:IsA("LuaSourceContainer")then scripts+=1 end
    end
    table.insert(a.models,{name=m.Name,path=m:GetFullName(),parts=n,meshes=meshes,scripts=scripts,size={sz.X,sz.Y,sz.Z}})
   end
  end
  root:Destroy()
 else a.error=tostring(root)end
 table.insert(report.assets,a)
end
local L=game:GetService("Lighting")
for _,k in ipairs({"ClockTime","Brightness","ExposureCompensation","FogStart","FogEnd"})do report.lighting[k]=L[k]end
report.effects={}
for _,p in ipairs(L:GetChildren())do
 local a={name=p.Name,class=p.ClassName}
 if p:IsA("Atmosphere")then a.density=p.Density;a.haze=p.Haze;a.offset=p.Offset end
 table.insert(report.effects,a)
end
return report
