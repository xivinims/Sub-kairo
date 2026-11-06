-- Runs the shipped camera/movement controllers against deterministic Roblox API
-- doubles. This covers lifecycle regressions, not rendering or a client playtest.
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local R=require('@lune/roblox')
local V,C=R.Vector3,R.CFrame
local function signal()
 local callbacks={}
 return {
  Connect=function(_,fn)
   local entry={fn=fn,connected=true};table.insert(callbacks,entry)
   return {Disconnect=function()entry.connected=false end}
  end,
  Fire=function(_,...)for _,entry in ipairs(table.clone(callbacks))do if entry.connected then entry.fn(...)end end end,
 }
end
local function character()
 local h={Parent=true,Health=100,HipHeight=0,WalkSpeed=26,JumpPower=45,MoveDirection=V.zero,FloorMaterial=R.Enum.Material.Plastic,Sit=false,AutoRotate=true,CameraOffset=V.zero}
 local root={Parent=true,Position=V.new(0,4,0),CFrame=C.new(0,4,0),Anchored=false,AssemblyLinearVelocity=V.zero}
 local parts={Humanoid=h,HumanoidRootPart=root,['Left Arm']={},['Right Arm']={}}
 local char={Parent=true}
 function char:FindFirstChildOfClass(kind)return kind=='Humanoid'and h or nil end
 function char:FindFirstChild(name)return parts[name]end
 function char:WaitForChild(name)return parts[name]end
 return char,h,root
end
local function actor()
 local p={attributes={},CharacterAdded=signal(),CharacterRemoving=signal(),PlayerScripts={}}
 function p:GetAttribute(key)return self.attributes[key]end
 function p:SetAttribute(key,value)self.attributes[key]=value end
 function p.PlayerScripts:WaitForChild()return 'PlayerModule'end
 return p
end
local function loadController(name,services,world,extras)
 local globals={game={GetService=function(_,key)return assert(services[key],key)end},workspace=world,Enum=R.Enum,Vector3=V,CFrame=C}
 for key,value in pairs(extras or {})do globals[key]=value end
 setmetatable(globals,{__index=getfenv()})
 local fn=luau.load(fs.readFile('nextbot-rebuild/'..name..'.luau'),{debugName=name,environment=globals})
 fn()
end
local p=actor();local h,root
p.Character,h,root=character()
p:SetAttribute('NBInArena',true)
local gui={attributes={NBLoadComplete=false}}
function gui:GetAttribute(key)return self.attributes[key]end
function p:WaitForChild(name)assert(name=='PlayerGui');return gui end
local players={LocalPlayer=p}
function players:GetPlayers()return {p}end
function players:GetPlayerByUserId(id)return id==2 and self.target or nil end
local controls={enabled=false,Enable=function(self)self.enabled=true end,Disable=function(self)self.enabled=false end}
local render={}
local run={BindToRenderStep=function(_,name,priority,fn)render[name]={priority=priority,fn=fn}end,UnbindFromRenderStep=function(_,name)render[name]=nil end}
local mouse={MouseEnabled=true,MouseIconEnabled=true,MouseBehavior=R.Enum.MouseBehavior.Default,GetFocusedTextBox=function()return nil end,GetMouseLocation=function()return R.Vector2.new(500,300)end}
local package={attributes={},GetAttribute=function(self,key)return self.attributes[key]end}
local replicated={WaitForChild=function()return package end}
local camera={CFrame=C.lookAt(V.new(0,7,8),root.Position),Focus=C.new(root.Position),ViewportSize=R.Vector2.new(1000,600),FieldOfView=70}
local world={CurrentCamera=camera,FindFirstChild=function()return nil end}
local destroy=signal()
loadController('Camera.client',{Players=players,RunService=run,UserInputService=mouse,ReplicatedStorage=replicated},world,{script={Destroying=destroy},require=function()return {GetControls=function()return controls end}end})
local distance=.5
local function frame()
 render.ExactRunCameraBefore.fn()
 -- Model the default camera's persistent zoom state and distance constraints.
 if p.CameraMode==R.Enum.CameraMode.LockFirstPerson then distance=.5 else distance=math.clamp(distance,p.CameraMinZoomDistance,p.CameraMaxZoomDistance)end
 render.ExactRunCamera.fn(1/60)
end
frame();assert(not controls.enabled and camera.CameraType==R.Enum.CameraType.Scriptable,'loading must gate movement')
gui.attributes.NBLoadComplete=true
frame();assert(distance==8 and h.AutoRotate==false,'third person must seed a real zoom distance')
assert(mouse.MouseBehavior==R.Enum.MouseBehavior.LockCenter,'desktop play must follow the pointer')
local flat=V.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z).Unit
assert(root.CFrame.LookVector:Dot(flat)>.999,'avatar yaw must follow camera yaw')
frame();frame();assert(p.CameraMinZoomDistance==4 and p.CameraMaxZoomDistance==16)
p:SetAttribute('NBFirstPerson',true);frame();assert(distance==.5 and p.CameraMode==R.Enum.CameraMode.LockFirstPerson)
p:SetAttribute('NBPlayingEmote','pack_test')
local before=root.CFrame
camera.CFrame=C.lookAt(V.new(10,5,0),root.Position)
frame();assert(distance==8 and p.CameraMode==R.Enum.CameraMode.Classic and h.AutoRotate,'emotes must release first person')
assert(root.CFrame==before and mouse.MouseBehavior==R.Enum.MouseBehavior.Default,'emote must not rotate avatar or trap pointer')
p:SetAttribute('NBPlayingEmote','');frame();assert(distance==.5 and not h.AutoRotate,'ending emote must restore requested POV')
p:SetAttribute('NBFirstPerson',false);frame();assert(distance==8,'return from first to third person must zoom out')
frame();frame();assert(distance>=4 and p.CameraMinZoomDistance==4,'third person cannot pinch back inside head')
p:SetAttribute('NBOverlay','Inventory');frame();assert(mouse.MouseBehavior==R.Enum.MouseBehavior.Default,'inventory must release pointer')
p:SetAttribute('NBOverlay','')
local old=h
p.Character,h,root=character();frame();assert(camera.CameraSubject==h and old.AutoRotate,'respawn must replace subject and release old humanoid')
p:SetAttribute('NBFirstPerson',true);frame()
p:SetAttribute('NBInArena',false);frame();assert(p.CameraMode==R.Enum.CameraMode.Classic and not controls.enabled and h.AutoRotate,'menu cannot inherit first-person lock')
local target=actor();target.Character=character();target:SetAttribute('NBInRound',true);players.target=target
p:SetAttribute('NBSpectating',true);p:SetAttribute('NBSpectateTarget',2);frame()
assert(camera.CameraSubject==target.Character:FindFirstChildOfClass('Humanoid')and p.CameraMode==R.Enum.CameraMode.Classic,'spectate must use target in third person')
p:SetAttribute('NBSpectating',false);p:SetAttribute('NBInArena',true);frame();assert(camera.CameraSubject==h and distance==.5)
package.attributes.VotingOpen=true;frame();assert(not controls.enabled and mouse.MouseBehavior==R.Enum.MouseBehavior.Default,'voting must freeze controls and release pointer')
package.attributes.VotingOpen=false;frame();assert(controls.enabled and distance==.5,'voting completion must restore requested POV')
gui.attributes.NBLoadComplete=false;frame();assert(not controls.enabled and mouse.MouseBehavior==R.Enum.MouseBehavior.Default)
destroy:Fire();assert(not render.ExactRunCamera and not render.ExactRunCameraBefore and h.AutoRotate,'cleanup must release camera bindings')

-- Server speed/slide/controller lifecycle.
local serverPlayer=actor();local sh,sr
serverPlayer.Character,sh,sr=character()
serverPlayer:SetAttribute('NBInArena',true)
local heartbeat=signal();local remote={OnServerEvent=signal()}
local config={WalkSpeed=26,CrouchSpeed=12,SprintSpeed=33.3}
local serverPackage={Config=config,WaitForChild=function()return remote end}
local serverPlayers={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {serverPlayer}end}
local clock=10
local spawned={}
loadController('Movement.server',{Players=serverPlayers,RunService={Heartbeat=heartbeat},ReplicatedStorage={WaitForChild=function()return serverPackage end}},{GetServerTimeNow=function()return clock end,Raycast=function()return nil end},{require=function()return config end,task={spawn=function(fn,...)fn(...)end},os={clock=function()return clock end},RaycastParams={new=function()return {}end}})
heartbeat:Fire(.05);assert(sh.WalkSpeed==26,'arena spawn must start at configured walk speed')
remote.OnServerEvent:Fire(serverPlayer,'Sprint',true)
for _=1,5 do clock+=.05;heartbeat:Fire(.05)end
assert(sh.WalkSpeed>26 and sh.WalkSpeed<=33.3,'sprint acceleration must be bounded')
remote.OnServerEvent:Fire(serverPlayer,'Sprint',false)
heartbeat:Fire(.05);assert(sh.WalkSpeed==26,'sprint release must take effect')
-- An immediate off after on must be accepted, even inside the anti-spam window.
clock+=1;remote.OnServerEvent:Fire(serverPlayer,'Sprint',true);remote.OnServerEvent:Fire(serverPlayer,'Sprint',false)
heartbeat:Fire(.05);assert(serverPlayer:GetAttribute('NBMobility')=='Walk')
clock+=1;remote.OnServerEvent:Fire(serverPlayer,'Sprint',true)
sr.AssemblyLinearVelocity=V.new(0,0,-20)
remote.OnServerEvent:Fire(serverPlayer,'Crouch',true)
heartbeat:Fire(.05);assert(serverPlayer:GetAttribute('NBMobility')=='Slide','slide setup failed')
local firstRoot=sr
serverPlayer.Character,sh,sr=character();serverPlayer.CharacterAdded:Fire(serverPlayer.Character)
heartbeat:Fire(.05)
assert(serverPlayer:GetAttribute('NBMobility')=='Walk'and sh.WalkSpeed==26 and sr.AssemblyLinearVelocity==V.zero,'respawn must discard slide velocity and speed state')
clock+=2;remote.OnServerEvent:Fire(serverPlayer,'Sprint',true)
serverPlayer:SetAttribute('NBDowned',true);heartbeat:Fire(.05);assert(sh.WalkSpeed==3 and sh.JumpPower==0)
serverPlayer:SetAttribute('NBDowned',false);heartbeat:Fire(.05);assert(serverPlayer:GetAttribute('NBMobility')=='Walk','revive must not restore stale sprint')
serverPlayer:SetAttribute('NBInArena',false);heartbeat:Fire(.05);assert(sh.WalkSpeed==16)
serverPlayer:SetAttribute('NBInArena',true);heartbeat:Fire(.05);assert(sh.WalkSpeed==26)
print('PASS: camera POV/emote/menu/loading/spectate/respawn lifecycle and movement spawn/sprint/slide/revive/reset regressions (API doubles; no rendered client).')

local motionPlayer=actor();local mh,mr
motionPlayer.Character,mh,mr=character();mh.RigType=R.Enum.HumanoidRigType.R6
motionPlayer.signals={}
function motionPlayer:GetAttributeChangedSignal(key)
 self.signals[key]=self.signals[key]or signal();return self.signals[key]
end
local function desc(kind,name)
 return {Name=name,Enabled=true,IsA=function(_,class)return class==kind end}
end
local animate=desc('LocalScript','Animate')
local animator=desc('Animator','Animator');animator.AnimationPlayed=signal()
function animator:GetPlayingAnimationTracks()return {}end
function motionPlayer.Character:GetDescendants()return {animate,animator}end
motionPlayer.Character.DescendantAdded=signal()
function motionPlayer.Character:SetAttribute()end
local motor={Parent=true,Transform=C.identity}
local applied={}
local pose={Bindings=function()return {}end,Motors=function()return {Torso=motor}end,Decode=function(sequence)return sequence.data end,Apply=function(data,_,t)motor.Transform=C.Angles(.1,0,0);table.insert(applied,{name=data.name,time=t})end}
local clipFolder={clips={}}
function clipFolder:FindFirstChild(name)
 if not self.clips[name]then self.clips[name]={Loop=true,data={name=name,duration=1},GetAttribute=function()return nil end}end
 return self.clips[name]
end
local rigFolder={GetChildren=function()return {}end}
local motionPackage={PosePlayer=pose,MovementClips=clipFolder,MovementSourceRig={},MovementSourceRigs=rigFolder}
function motionPackage:WaitForChild(key)return self[key]end
local simulation=signal()
local motionPlayers={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {motionPlayer}end}
loadController('Locomotion.client',{Players=motionPlayers,RunService={PreSimulation=simulation},ReplicatedStorage={WaitForChild=function()return motionPackage end}},{},{require=function()return pose end,task={spawn=function(fn,...)fn(...)end}})
simulation:Fire(.1);assert(applied[#applied].name=='CommunityIdle'and not animate.Enabled)
mr.AssemblyLinearVelocity=V.new(0,0,-13);simulation:Fire(.1)
assert(applied[#applied].name=='CommunityWalk'and math.abs(applied[#applied].time-.05)<.0001,'walking cadence must follow measured speed')
mr.AssemblyLinearVelocity=V.new(0,0,-26);simulation:Fire(.1)
assert(math.abs(applied[#applied].time-.15)<.0001,'walk clock must continue through acceleration')
motionPlayer:SetAttribute('NBMobility','Sprint');mr.AssemblyLinearVelocity=V.new(0,0,-33.3);simulation:Fire(.1)
assert(applied[#applied].name=='CommunityRun')
local count=#applied
motionPlayer:SetAttribute('NBPlayingEmote','pack_test');simulation:Fire(.1);assert(#applied==count,'locomotion must yield every joint while emoting')
motionPlayer:SetAttribute('NBPlayingEmote','');simulation:Fire(.1)
assert(#applied==count+1 and applied[#applied].name=='CommunityRun','motion must resume after emote')
motionPlayer:GetAttributeChangedSignal('NBAppearanceRevision'):Fire();simulation:Fire(.1)
assert(applied[#applied].time<.11,'appearance rebuild must restart with fresh joint state')
print('PASS: R6 authored-pose ownership, velocity-based stride cadence, emote handoff, appearance rebuild regressions (API doubles).')
