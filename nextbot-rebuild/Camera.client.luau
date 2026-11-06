local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local controls
pcall(function()controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls()end)
local controlsEnabled

local mode,viewState='',''
local viewCharacter,viewCamera,previousHumanoid
local offset=Vector3.zero
local time,zoomFrames=0,0
local defaultMouseIcon=UIS.MouseIconEnabled

local function releaseHumanoid(h)
 if h and h.Parent then h.AutoRotate=true;h.CameraOffset=Vector3.zero end
end

local function setView(state)
 -- Apply zoom before the Roblox camera update. Leaving LockFirstPerson alone
 -- retains its .5-stud distance, so seed third person for two camera updates.
 player.CameraMode=Enum.CameraMode.Classic
 player.CameraMaxZoomDistance=16
 player.CameraMinZoomDistance=state=='First'and .5 or 8
 if state=='First'then
  player.CameraMode=Enum.CameraMode.LockFirstPerson
  zoomFrames=0
 else
  player.CameraMaxZoomDistance=8
  zoomFrames=2
 end
end

local function applyInputState(canMove,lockPointer)
 if controls and canMove~=controlsEnabled then
  controlsEnabled=canMove
  if canMove then controls:Enable()else controls:Disable()end
 end
 UIS.MouseBehavior=lockPointer and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
 UIS.MouseIconEnabled=lockPointer and false or defaultMouseIcon
end

Run:BindToRenderStep('ExactRunCameraBefore',Enum.RenderPriority.Camera.Value-1,function()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if previousHumanoid~=humanoid then
  releaseHumanoid(previousHumanoid)
  previousHumanoid=humanoid;offset=Vector3.zero;time=0;controlsEnabled=nil
 end
 local loaded=playerGui:GetAttribute('NBLoadComplete')==true and package:GetAttribute('VotingOpen')~=true
 local spectating=player:GetAttribute('NBSpectating')==true
 local nextMode=not loaded and 'Loading'or spectating and 'Spectate'or player:GetAttribute('NBInArena')and 'Play'or 'Menu'
 local emoting=(player:GetAttribute('NBPlayingEmote')or '')~=''
 local nextView=nextMode=='Play'and (emoting and 'Emote'or player:GetAttribute('NBFirstPerson')and 'First'or 'Third')or 'Third'
 local changed=nextMode~=mode or viewCharacter~=character or viewCamera~=camera
 if changed or viewState~=nextView then
  setView(nextView)
  viewState=nextView;viewCharacter=character;viewCamera=camera
 end
 mode=nextMode
 if viewState~='First'and zoomFrames==0 then
  -- Keep third person outside the head even after scrolling or touch pinching.
  player.CameraMaxZoomDistance=16;player.CameraMinZoomDistance=4
 end
 local down=player:GetAttribute('NBDowned')==true
 if humanoid then
  humanoid.AutoRotate=mode~='Play'or emoting or down or humanoid.Sit
  if mode~='Play'then humanoid.CameraOffset=Vector3.zero;offset=Vector3.zero end
 end
 local overlay=(player:GetAttribute('NBOverlay')or '')~=''
 local pointer=mode=='Play'and not emoting and not overlay and UIS.MouseEnabled and not UIS:GetFocusedTextBox()
 applyInputState(mode=='Play'and humanoid~=nil and humanoid.Health>0,pointer)
 if mode=='Menu'or mode=='Loading'then
  camera.CameraType=Enum.CameraType.Scriptable
 elseif mode=='Spectate'then
  camera.CameraType=Enum.CameraType.Custom
  local target=Players:GetPlayerByUserId(player:GetAttribute('NBSpectateTarget')or 0)
  if not target or not target:GetAttribute('NBInRound')then
   target=nil
   for _,candidate in ipairs(Players:GetPlayers())do if candidate~=player and candidate:GetAttribute('NBInRound')then target=candidate;break end end
  end
  local targetHumanoid=target and target.Character and target.Character:FindFirstChildOfClass('Humanoid')
  if targetHumanoid or humanoid then camera.CameraSubject=targetHumanoid or humanoid end
 elseif humanoid then
  camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=humanoid
 end
end)

Run:BindToRenderStep('ExactRunCamera',Enum.RenderPriority.Camera.Value+1,function(dt)
 local camera=workspace.CurrentCamera;if not camera then return end
 if zoomFrames>0 then zoomFrames-=1 end
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if mode=='Menu'or mode=='Loading'then
  UIS.MouseBehavior=Enum.MouseBehavior.Default
  local anchors=workspace:FindFirstChild('MenuCameras')
  local page=player:GetAttribute('NBMenuPage')or 'Home'
  local anchor=anchors and (anchors:FindFirstChild(page)or anchors:FindFirstChild('Home'))
  if anchor then
   local mouse=UIS:GetMouseLocation();local viewport=camera.ViewportSize
   local x=UIS.MouseEnabled and math.clamp(mouse.X/math.max(viewport.X,1)-.5,-.5,.5)or 0
   local y=UIS.MouseEnabled and math.clamp(mouse.Y/math.max(viewport.Y,1)-.5,-.5,.5)or 0
   camera.CFrame=camera.CFrame:Lerp(anchor.CFrame*CFrame.Angles(-y*.025,-x*.04,0),1-math.exp(-dt*5))
  end
 elseif mode=='Play'and humanoid and root then
  local emoting=(player:GetAttribute('NBPlayingEmote')or '')~=''
  local down=player:GetAttribute('NBDowned')==true
  if not emoting and not down and humanoid.Health>0 and not humanoid.Sit and not root.Anchored then
   local facing=camera.CFrame.LookVector
   local flat=Vector3.new(facing.X,0,facing.Z)
   if flat.Magnitude>.001 then root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit)end
  end
  local mobility=player:GetAttribute('NBMobility')
  local crouch=mobility=='Crouch'or mobility=='Slide'or down
  time+=dt*math.clamp(humanoid.WalkSpeed*.45,5,16)
  local moving=humanoid.MoveDirection.Magnitude>.1 and humanoid.FloorMaterial~=Enum.Material.Air
  local legacy=player:GetAttribute('NBSetting_LegacyCamera')==true
  local bob=moving and not emoting and not legacy and player:GetAttribute('NBSetting_Viewbob')~=false and .07 or 0
  local target=Vector3.new(math.cos(time)*bob,(crouch and -.65 or 0)+math.abs(math.sin(time))*bob,0)
  offset=offset:Lerp(target,1-math.exp(-dt*12));humanoid.CameraOffset=offset
  local first=viewState=='First'
  for _,name in ipairs({'Left Arm','Right Arm'})do
   local arm=character:FindFirstChild(name)
   if arm then arm.LocalTransparencyModifier=first and player:GetAttribute('NBSetting_RunningViewmodel')~=false and moving and 0 or first and 1 or 0 end
  end
  local fov=player:GetAttribute('NBSetting_FOV')or 70
  local desiredFov=fov+(not legacy and mobility=='Sprint'and not emoting and 5 or 0)
  camera.FieldOfView+=(desiredFov-camera.FieldOfView)*math.min(dt*8,1)
  local overlay=(player:GetAttribute('NBOverlay')or '')~=''
  local pointer=not emoting and not overlay and UIS.MouseEnabled and not UIS:GetFocusedTextBox()
  UIS.MouseBehavior=pointer and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
  UIS.MouseIconEnabled=pointer and false or defaultMouseIcon
 else
  -- The default first-person camera may lock the cursor after the pre-step.
  UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=defaultMouseIcon
 end
end)

script.Destroying:Connect(function()
 Run:UnbindFromRenderStep('ExactRunCameraBefore');Run:UnbindFromRenderStep('ExactRunCamera')
 releaseHumanoid(previousHumanoid)
 player.CameraMode=Enum.CameraMode.Classic;player.CameraMaxZoomDistance=16;player.CameraMinZoomDistance=.5
 UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=defaultMouseIcon
 if controls then controls:Enable()end
end)
