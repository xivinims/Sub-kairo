local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-original.rbxl'))
local RS=dm:GetService('ReplicatedStorage');local SP=dm:GetService('StarterPlayer')
assert(math.abs(SP.CharacterJumpHeight-7.2)<.001 and SP.CharacterUseJumpPower==false,'Jump defaults not installed')
local source=RS.Library.Client.MovementHandler.Source
-- Execute the shipped movement methods against a deterministic avatar/service harness.
source=source:gsub('local library = require%(game.ReplicatedStorage:WaitForChild%("Library"%)%)','')
source=source:gsub('require%(script.Config%)','library.TestConfig'):gsub('require%(script.Multiplier%)','library.TestMultiplier')
local factory=luau.load('return function(library, workspace, Enum, CFrame, Vector3, TweenInfo)\n'..source..'\nend')()
local signal={new=function() return {Fire=function() end,Connect=function() end} end}
local weapon=nil;local applications=0
local library={Utility={Signal=signal,Lerp=function(a,b,t) return a+(b-a)*t end},Players={LocalPlayer={CharacterRemoving={Connect=function() end}}},StarterPlayer={CharacterWalkSpeed=12,CharacterJumpHeight=7.2},WeaponsHandler={GetEquippedWeapon=function() return weapon end},TestConfig={SprintWalkSpeedMultiplier=1.5,SprintAcceleration=1,SprintDeceleration=1,CrouchWalkSpeedMultiplier=.6},FOVHandler={TweenTargetOffset=function() end}}
library.TestMultiplier={new=function(callback)
 local values={};local function update() local total=1;for _,v in pairs(values) do total*=v end;callback(total) end
 return {Set=function(_,k,v) values[k]=v;update() end,Add=function(_,k,v) values[k]=v;update() end,Remove=function(_,k) values[k]=nil;update() end}
end}
library.TweenService={Create=function(_,object,_,props) return {Cancel=function() end,Play=function() for k,v in pairs(props) do object[k]=v end end} end}
local world={CurrentCamera={CameraType=R.Enum.CameraType.Custom}}
local m=factory(library,world,R.Enum,R.CFrame,R.Vector3,{new=function() return {} end})
m.humanoid={HipHeight=2.4,RigType=R.Enum.HumanoidRigType.R15,MoveDirection=R.Vector3.new(0,0,-1),FloorMaterial=R.Enum.Material.Concrete,WalkSpeed=12}
m.__standingHipHeight=2.4
local root={CFrame=R.CFrame.new()};m.character={HumanoidRootPart=root,FindFirstChild=function() return root end}
m.__cameraOffsetsHandler={SetSpringTarget=function() end,ImpulseSpring=function() end,UpdateOffsets=function() end,ApplyOffsets=function() applications+=1 end}
m:ToggleCrouch(true);assert(not m:IsCrouching() and m.humanoid.HipHeight==2.4,'Unarmed crouch was allowed')
weapon={WeaponInfo={WeaponType={'Melee'}}}
for _=1,20 do
 m:ToggleCrouch(true);assert(math.abs(m.humanoid.HipHeight-1.75)<.001,'R15 crouch height incorrect')
 m:ToggleCrouch(false);assert(m.humanoid.HipHeight==2.4,'Standing height drift')
end
assert(not m:CanSlide(),'R6-only physics slide was enabled on R15')
for _,dt in ipairs({1/240,1/60,1/30,.1,.5}) do
 m:ToggleSprint(true);m:OnRenderStepped(dt);assert(m.humanoid.WalkSpeed>=12 and m.humanoid.WalkSpeed<=18,'Sprint interpolation overshot at '..dt)
 m:ToggleSprint(false);m:OnRenderStepped(dt);assert(m.humanoid.WalkSpeed>=12 and m.humanoid.WalkSpeed<=18,'Deceleration overshot at '..dt)
end
local previous=applications;world.CurrentCamera.CameraType=R.Enum.CameraType.Scriptable;m:OnRenderStepped(.1);assert(applications==previous,'Movement modified cinematic camera')
assert(SP.StarterCharacterScripts.Movement.Disabled and SP.StarterCharacterScripts.BodyVisible.Disabled)
assert(SP.CameraMode==R.Enum.CameraMode.Classic and SP.CameraMinZoomDistance>=8 and SP.CameraMaxZoomDistance>SP.CameraMinZoomDistance,'First person camera still enabled')
assert(RS.OriginalStarterGui.Scripts.Game.MouseTilt.Disabled)
assert(RS.OriginalStarterGui.Scripts.Game.ClientHandler.Disabled,'Shooter first-person camera script still enabled')
assert(not dm:GetService('ServerStorage').OriginalWorld.Content.Exterior.Props.Vechicles:FindFirstChild('SUV_Damaged'))
print('GAMEPLAY REGRESSION PASS: R15 crouch/stand x20; unarmed gating; third-person camera; 2-240 FPS speed bounds; cinematic camera ownership; wreck removed')
