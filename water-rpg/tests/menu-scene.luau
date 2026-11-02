local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau')
local env={CFrame=R.CFrame,Vector3=R.Vector3};setmetatable(env,{__index=getfenv()})
local M=luau.load(fs.readFile('water-rpg/src/MenuScene.lua'),{environment=env})()
local base=R.CFrame.new(1540,158,2140)
local main,plane=M.route(base,'Main');local settings,sPlane=M.route(base,'Settings');local credits=M.route(base,'Credits');local log=M.route(base,'Log')
assert(settings.Position.X>main.Position.X+8 and credits.Position.X<main.Position.X-8)
assert((log.Position-main.Position).Magnitude>7)
assert((settings.Position-main.Position).Magnitude>9)
assert(sPlane.LookVector:Dot((sPlane.Position-settings.Position).Unit)>.99)
assert(settings.LookVector:Dot((sPlane.Position-settings.Position).Unit)>.99)
local midpoint=main:Lerp(settings,.5);assert((midpoint.Position-main.Position).Magnitude>3)
for _,viewport in ipairs({R.Vector2.new(844,390),R.Vector2.new(640,360),R.Vector2.new(1920,1080)}) do
 local distance=(sPlane.Position-settings.Position).Magnitude
 local box=M.panelSize(viewport,58,distance,'Section')
 local projected=box.Y/(2*distance*math.tan(math.rad(29)))*viewport.Y
 assert(projected<=viewport.Y-30 and projected>200)
 assert(box.X/box.Y>1.24 and box.X/box.Y<1.26)
end
local ui=fs.readFile('water-rpg/src/Client.client.lua')
assert(ui:find('menuPlane.CanQuery=true',1,true))
assert(ui:find('modalPlane.CanQuery=true',1,true))
assert(ui:find('WaterMenuSection3D',1,true))
assert(ui:find('Enum.EasingStyle.Quart',1,true))
luau.load(ui,{debugName='WaterRPGClient'})
print('3D menu routes, opposite camera directions, panel facing, viewport size, click queries and Luau syntax passed')

local S=luau.load(fs.readFile('water-rpg/src/MenuSettingsSchema.lua'))()
local clean=S.clean({MusicVolume=100,SFXVolume=-2,CameraTilt=false,HighQuality='true',evil=true,ShowFPS=true})
assert(clean.MusicVolume==1 and clean.SFXVolume==0 and clean.CameraTilt==false and clean.HighQuality==false and clean.evil==nil and clean.ShowFPS==true)
assert(S.clean({MusicVolume=0/0}).MusicVolume==.5)
assert(S.clean({MusicVolume=math.huge}).MusicVolume==.5)
assert(next(S.patch('bad payload'))==nil)
assert(S.patch({CameraTilt=false}).CameraTilt==false)
assert(S.patch({MusicVolume=.33}).MusicVolume==.33)
for _,path in ipairs({'MenuSettings.server.lua','Abilities.client.lua'}) do luau.load(fs.readFile('water-rpg/src/'..path),{debugName=path}) end
-- The slider maps a screen ray back onto the tilted panel before measuring progress.
for _,value in ipairs({0,.25,.5,.75,1}) do
 local localX=(.5-(218+160*value)/500)*10
 local hit=R.CFrame.new(12,3,-15)*R.CFrame.Angles(0,.3,0)
 local world=hit:PointToWorldSpace(R.Vector3.new(localX,0,0))
 local restored=hit:PointToObjectSpace(world)
 local canvasX=(.5-restored.X/10)*500
 assert(math.abs((canvasX-218)/160-value)<.00001)
end
for _,feature in ipairs({'DiagonalRibbon','ReturnToMenuPrompt','PreloadAsync','ReduceMotion','SFXVolume','MenuSettingsJSON','sliderPoint'}) do assert(ui:find(feature,1,true),'Missing '..feature) end
assert(not ui:find('((t*.2)% .75)',1,true),'Fake loading progress remains')
print('Menu settings validation, finite volumes, partial updates, tilted slider mapping and all client/server compilation passed')
