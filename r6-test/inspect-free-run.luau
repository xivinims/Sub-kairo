local fs=require("@lune/fs")
local R=require("@lune/roblox")
local data=fs.readFile("r6-test/free-r6-run-model.rbxm")
local ok,model=pcall(function()return R.deserializeModel(data) end)
assert(ok,"Downloaded model is not a readable Roblox model: "..tostring(model))
local counts={}
local animations={}
local keyframes={}
local scripts={}
for _,top in ipairs(model) do
 for _,x in ipairs({top,table.unpack(top:GetDescendants())}) do
  counts[x.ClassName]=(counts[x.ClassName] or 0)+1
  if x:IsA("Animation") then table.insert(animations,{name=x.Name,id=x.AnimationId}) end
  if x:IsA("KeyframeSequence") then table.insert(keyframes,{name=x.Name,length=#x:GetKeyframes()}) end
  if x:IsA("LuaSourceContainer") then
   table.insert(scripts,{name=x.Name,className=x.ClassName,sourceSize=#x.Source})
  end
 end
end
print("PUBLIC_R6_RUN_ASSET_CONTENTS",require("@lune/serde").encode("json",{
 classes=counts,animations=animations,keyframeSequences=keyframes,scripts=scripts
}))
