local fs=require('@lune/fs')
local luau=require('@lune/luau')
for _,name in ipairs({'fallout-client.luau','fallout-ui.luau','fallout-install.luau','hudfix-install.luau','viewport-invariants.luau','viewport-verify.luau'}) do
 luau.load(fs.readFile(name),{debugName=name})
end
print('VIEWPORT_LUAU_COMPILE_OK')
