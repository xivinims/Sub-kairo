local fs=require('@lune/fs')
local roblox=require('@lune/roblox')
local luau=require('@lune/luau')
local place=roblox.deserializePlace(fs.readFile('breu-publisher/unpacked/BREU-Playtest-01.rbxlx'))
local bundle=roblox.Instance.new('Model')
bundle.Name='BREUPayload'
local scripts=0
for _,serviceName in ipairs({'Workspace','ServerScriptService','ServerStorage','ReplicatedStorage','StarterGui','Lighting','SoundService','MaterialService','StarterPlayer'}) do
 local folder=roblox.Instance.new('Folder');folder.Name=serviceName;folder.Parent=bundle
 local source=place:GetService(serviceName)
 for _,child in ipairs(source:GetChildren()) do
  if child:IsA('StarterPlayerScripts') or child:IsA('StarterCharacterScripts') then
   local f=roblox.Instance.new('Folder');f.Name=child.Name;f.Parent=folder
   for _,desc in ipairs(child:GetChildren()) do desc.Parent=f end
  elseif not child:IsA('Terrain') and not child:IsA('Camera') then child.Parent=folder end
 end
end
for _,desc in ipairs(bundle:GetDescendants()) do
 if desc:IsA('LuaSourceContainer') then
  luau.load(desc.Source,{debugName=desc:GetFullName()});scripts+=1
 end
end
assert(scripts==6,'Unexpected script count')
fs.writeFile('breu-publisher/payload.rbxm',roblox.serializeModel({bundle}))
print('BREU binary payload assembled; six scripts compiled with Luau')
