local fs=require('@lune/fs')
local luau=require('@lune/luau')
local source=fs.readFile('fallout-options-client.luau')
assert(#source>18000,'Options menu source is unexpectedly short')
local compiled=luau.load(source,{debugName='fallout-options-client.luau'})
assert(compiled,'Options module must compile')
local function has(pattern) return source:find(pattern,1,true)~=nil end
assert(has("Name='OpenOptions'") and has("make('ImageButton',gui,{"),'Open button must be a real ImageButton')
assert(not has("openButton.Text=") and not has("Text='OPÇÕES  ☰'"),'Opening gear cannot contain button text')
assert(has("SettingsGearIcon") and has("GearTooth") and has("CenterHole"),'Missing complete code-drawn gear')
assert(has("BackgroundTransparency=.31"),'Camera overlay should remain transparent')
assert(has("math.clamp(viewport.X*.265,188,235)"),'Options must stay at the edge, never fill screen')
assert(has("UIS.InputChanged:Connect") and has("SliderTouchArea"),'Mobile sliders must stay interactive')
assert(has("SettingsSave") and has("SettingsGet"),'Do not remove persistent settings')
assert(has("ColorCalibration") and has("currentPage=='home'"),'Missing subpages')
for _,viewport in ipairs({
 Vector2.new(390,844),
 Vector2.new(812,375),
 Vector2.new(896,414),
 Vector2.new(1024,768)
}) do
 local width=math.floor(math.clamp(viewport.X*.265,188,235))
 local top=viewport.Y<355 and 91 or 98
 local height=math.floor(math.clamp(viewport.Y-top-10,168,352))
 assert(width<=235 and width<viewport.X*.56)
 assert(height<=352 and top+height<=viewport.Y)
end
print('OPTIONS_VISUAL_COMPILE_PASS iconOnly=true leftPanelMax=235 layouts=4 persistentControls=true')
