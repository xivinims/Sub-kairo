local R=require('@lune/roblox')
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local bundle=R.Instance.new('Model');bundle.Name='HUDFixPatch'
local files={
 Profiles={'ModuleScript','fallout-profiles.luau'},Server={'Script','fallout-server.luau'},
 FalloutClient={'LocalScript','fallout-client.luau'},FalloutUI={'ModuleScript','fallout-ui.luau'},
 ShopkeeperLayout={'ModuleScript','fallout-shopkeeper.luau'},
}
for name,entry in pairs(files) do
 local source=fs.readFile(entry[2]);luau.load(source,{debugName=entry[2]})
 local item=R.Instance.new(entry[1]);item.Name=name;item.Source=source;item.Parent=bundle
end
for _,name in ipairs({'hudfix-invariants.luau','hudfix-install.luau','hudfix-verify.luau'}) do luau.load(fs.readFile(name),{debugName=name}) end
require('./hudfix-tests')
fs.writeFile('/tmp/hudfix-bundle.rbxm',R.serializeModel({bundle}))
print('HUDFIX_BUILD scripts=5 compiled=true')
