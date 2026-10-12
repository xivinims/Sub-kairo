
local AS=game:GetService("AssetService")
local out={placeVersion=game.PlaceVersion,sequences={},animations={},scripts={}}
local ok,asset=pcall(function()return AS:LoadAssetAsync(12472190351)end)
out.loaded=ok
if ok and asset then
 for _,d in ipairs(asset:GetDescendants()) do
  if d:IsA("KeyframeSequence") then
   table.insert(out.sequences,{name=d.Name,path=d:GetFullName(),frames=#d:GetKeyframes(),loop=d.Loop})
  elseif d:IsA("Animation") then
   table.insert(out.animations,{name=d.Name,path=d:GetFullName(),id=d.AnimationId})
  elseif d:IsA("LuaSourceContainer") then
   local low=string.lower(d.Source)
   if string.find(low,"emote",1,true) or string.find(low,"animation",1,true) then
    table.insert(out.scripts,{name=d.Name,path=d:GetFullName(),source=string.sub(d.Source,1,8000)})
   end
  end
 end
 asset:Destroy()
end
return out
