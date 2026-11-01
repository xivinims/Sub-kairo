local R=require('@lune/roblox')
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local bundle=R.Instance.new('Model');bundle.Name='HUDFixPatch'
local files={
 Profiles={'ModuleScript','fallout-profiles.luau'},Server={'Script','fallout-server.luau'},
 FalloutClient={'LocalScript','fallout-client.luau'},FalloutUI={'ModuleScript','fallout-ui.luau'},
 ShopkeeperLayout={'ModuleScript','fallout-shopkeeper.luau'},
 FrozenAvatar={'ModuleScript','fallout-frozen-avatar.luau'},
 OptionsStore={'ModuleScript','fallout-options-store.luau'},
 FalloutOptionsClient={'ModuleScript','fallout-options-client.luau'},
}
for name,entry in pairs(files) do
 local source=fs.readFile(entry[2]);luau.load(source,{debugName=entry[2]})
 local item=R.Instance.new(entry[1]);item.Name=name;item.Source=source;item.Parent=bundle
end
-- Use the exact uploaded 2014 Roblox HealthUi GUI, not a hand-drawn imitation.
local roots=R.deserializeModel(fs.readFile('/tmp/lobby-health-source.rbxm'))
local original
for _,root in ipairs(roots) do
 if root:IsA('ScreenGui') and root.Name=='HealthUi' then original=root end
 for _,descendant in ipairs(root:GetDescendants()) do
  if descendant:IsA('ScreenGui') and descendant.Name=='HealthUi' then original=descendant;break end
 end
end
assert(original,'Original 2014 HealthUi not found in downloaded model')
local legacy=original:Clone()
legacy.Name='LobbyHealthTemplate'
legacy.ResetOnSpawn=false
for _,instance in ipairs(legacy:GetDescendants()) do
 if instance:IsA('LuaSourceContainer') then instance:Destroy() end
end
assert(legacy.HealthGui.HealthFrame.HealthBar:IsA('ImageLabel'),'Original 2014 health image missing')
legacy.Parent=bundle
for _,name in ipairs({'hudfix-invariants.luau','hudfix-install.luau','hudfix-verify.luau'}) do luau.load(fs.readFile(name),{debugName=name}) end
require('./hudfix-tests')
fs.writeFile('/tmp/hudfix-bundle.rbxm',R.serializeModel({bundle}))
print('HUDFIX_BUILD scripts=8 options=on retroLobbyBar=original-sanitized compiled=true')
