local a=game:GetService("AssetService"):LoadAssetAsync(18509954401)
local r={parts=0,scripts=0,models={},lights={},floors={},bounds={},animations={}}
for _,d in ipairs(a:GetDescendants()) do if d:IsA("LuaSourceContainer") then r.scripts+=1; d:Destroy() end end
local cf,size=a:GetBoundingBox(); r.bounds={cf={cf:GetComponents()},size={size.X,size.Y,size.Z}}
for _,d in ipairs(a:GetDescendants()) do
 if d:IsA("BasePart") then
  r.parts+=1
  if d.Size.Y<3 and d.Size.X>12 and d.Size.Z>12 then table.insert(r.floors,{name=d.Name,pos={d.Position.X,d.Position.Y,d.Position.Z},size={d.Size.X,d.Size.Y,d.Size.Z},collide=d.CanCollide}) end
 elseif d:IsA("Model") and d.Parent==a then table.insert(r.models,{name=d.Name,count=#d:GetDescendants()})
 elseif d:IsA("Light") then table.insert(r.lights,{name=d.Name,parent=d.Parent.Name,pos=d.Parent:IsA("BasePart") and {d.Parent.Position.X,d.Parent.Position.Y,d.Parent.Position.Z} or nil}) end
end
a:Destroy()
for _,pair in ipairs({{"Idle",139381547469301},{"Walk",135958881774590},{"Attack",72696245387791}}) do
 local ok,seq=pcall(function() return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync("rbxassetid://"..pair[2]) end)
 if ok then local frames=seq:GetKeyframes(); table.insert(r.animations,{name=pair[1],ok=true,frames=#frames}); seq:Destroy() else table.insert(r.animations,{name=pair[1],ok=false,error=tostring(seq)}) end
end
return game:GetService("HttpService"):JSONEncode(r)
