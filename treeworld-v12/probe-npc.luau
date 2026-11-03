local out={version=game.PlaceVersion,models={},products={}}
for _,id in ipairs({125374377423034,139607718})do
 local row={id=id}
 local ok,m=pcall(function()return game:GetService("InsertService"):LoadAsset(id)end)
 row.ok=ok;row.nodes={}
 if ok then
  for _,d in ipairs(m:GetDescendants())do
   local v={name=d:GetFullName(),class=d.ClassName}
   if d:IsA("LuaSourceContainer")then v.source=d.Source end
   if d:IsA("Animation")then v.animation=d.AnimationId end
   if d:IsA("StringValue")then v.value=d.Value end
   if #row.nodes<100 then table.insert(row.nodes,v)end
  end;m:Destroy()
 else row.error=tostring(m)end
 table.insert(out.models,row)
 local ok,p=pcall(function()return game:GetService("MarketplaceService"):GetProductInfoAsync(id,Enum.InfoType.Asset)end)
 if ok then table.insert(out.products,{id=id,name=p.Name,type=p.AssetTypeId,creator=p.Creator.Name})end
end
local desc=Instance.new("HumanoidDescription");desc.RightLeg=139607718
local ok,npc=pcall(function()return game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)end)
out.r15={ok=ok}
if ok then out.r15.rig=tostring(npc.Humanoid.RigType);out.r15.nodes={};for _,p in ipairs(npc:GetDescendants())do if p:IsA("BasePart")or p:IsA("Motor6D")then table.insert(out.r15.nodes,{name=p.Name,class=p.ClassName})end end;npc:Destroy()else out.r15.error=tostring(npc)end
return out