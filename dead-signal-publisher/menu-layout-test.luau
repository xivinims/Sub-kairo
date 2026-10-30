local fs=require('@lune/fs')
local luau=require('@lune/luau')
local files={'session-interface.luau','session-menu-client.luau','menu-avatar-client.luau','door-lock-extension.luau'}
for _,file in ipairs(files) do
 local source=fs.readFile(file)
 assert(source and #source>300,'Missing menu source: '..file)
 luau.load(source,{debugName=file})
end
local panel=fs.readFile('session-interface.luau')
assert(panel:find('local width=compact and .76 or .55',1,true),'Settings panel covers entire screen')
assert(panel:find("Name='OptionsHalf'",1,true),'Narrow dark settings column missing')
for _,category in ipairs({'CALIBRAÇÃO','QUALIDADE','CONTROLES','JOGABILIDADE','ÁUDIO'}) do
 assert(panel:find(category,1,true),'Missing reference category: '..category)
end
local figure=fs.readFile('menu-avatar-client.luau')
assert(figure:find('BackgroundTransparency=1',1,true),'Portrait must not hide the sky')
assert(figure:find('CreateHumanoidModelFromUserIdAsync',1,true),'Portrait is not based on the user avatar')
assert(figure:find('math.sin',1,true),'Portrait does not have an animated float')
local blackhole=fs.readFile('blackhole-client.luau')
assert(blackhole:find("=='Menu'",1,true),'Black-hole sky is not active on the menu')
local door=fs.readFile('door-lock-extension.luau')
assert(door:find('detector.Parent=target',1,true),'Lock is not clicked on a physical door part')
assert(door:find('prompt.ClickablePrompt=true',1,true),'Touch-accessible prompt missing')
assert(door:find('now-first>.45',1,true),'Double-tap threshold missing')
print('MENU TEST PASS: responsive side panel, reference category layout, real floating portrait, original sky and touch double-tap lock')
