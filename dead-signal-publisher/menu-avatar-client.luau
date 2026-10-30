-- STILL HERE / menu avatar cinematic.
-- Preferred: real Roblox Low Gravity emote 103686359406944.
-- Safe independent fallback: original procedural low-gravity pose animated by
-- Motor6D.C0 (never Motor6D.Transform, which the Animator can overwrite).
-- All changes are local to the menu, never applied to the actual player's character.
local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end

local Players=game:GetService('Players')
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local ContentProvider=game:GetService('ContentProvider')
local player=Players.LocalPlayer
local camera=W.CurrentCamera
local anchor=Vector3.new(-1.3,5000,-7.2)

local previous=W:FindFirstChild('LocalMenuCinematic')
if previous then previous:Destroy() end
local scene=Instance.new('Folder')
scene.Name='LocalMenuCinematic'
scene.Parent=W

local zoom=Instance.new('NumberValue')
zoom.Name='CameraZoom';zoom.Value=0;zoom.Parent=scene
local zoomTween
local cameraSignal=player:GetAttributeChangedSignal('MenuCameraMode'):Connect(function()
 local state=player:GetAttribute('MenuCameraMode')
 if zoomTween then zoomTween:Cancel() end
 zoomTween=TweenService:Create(zoom,
  TweenInfo.new(state=='starting' and 1.05 or .86,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
  {Value=(state=='close' or state=='starting') and 1 or 0})
 zoomTween:Play()
end)

local avatar
local humanoid
local emoteTrack
local mode='procedural'
local bones={}
local baseC0={}
local loops=0

local function status(value)
 mode=value
 player:SetAttribute('MenuEmoteMode',value)
end
status('procedural')

local function capture(model)
 table.clear(bones);table.clear(baseC0)
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA('Motor6D') then
   bones[d.Name]=d
   baseC0[d.Name]=d.C0
  end
 end
end

local function pose(name,cf)
 local motor=bones[name]
 local rest=baseC0[name]
 if motor and rest then
  motor.C0=rest*cf
 end
end

local function resetPose()
 for name,motor in pairs(bones) do
  local rest=baseC0[name]
  if motor.Parent and rest then motor.C0=rest end
 end
end

-- Authored fallback, not a copy of copyrighted emote keyframes:
-- weightless arms open, legs gently folding, torso and head tracking the drift.
-- C0 is stable during both RenderStepped and PreSimulation even without assets.
local function proceduralLevitation(t)
 local a=math.sin(t*1.03)
 local b=math.sin(t*.61+.85)
 local c=math.sin(t*.43+2.1)
 pose('Waist',CFrame.Angles(math.rad(-7)+a*.08,b*.035,c*.09))
 pose('Neck',CFrame.Angles(math.rad(7)-a*.04,-b*.03,-c*.06))
 pose('RightShoulder',CFrame.Angles(math.rad(-19)+b*.16,math.rad(13),math.rad(49)+a*.17))
 pose('LeftShoulder',CFrame.Angles(math.rad(-17)-b*.16,math.rad(-13),math.rad(-49)-a*.17))
 pose('RightElbow',CFrame.Angles(math.rad(-23)+c*.12,0,0))
 pose('LeftElbow',CFrame.Angles(math.rad(-18)-c*.10,0,0))
 pose('RightWrist',CFrame.Angles(0,0,a*.15))
 pose('LeftWrist',CFrame.Angles(0,0,-a*.15))
 pose('RightHip',CFrame.Angles(math.rad(18)+a*.11,0,math.rad(7)))
 pose('LeftHip',CFrame.Angles(math.rad(12)-a*.12,0,math.rad(-7)))
 pose('RightKnee',CFrame.Angles(math.rad(-25)-b*.10,0,0))
 pose('LeftKnee',CFrame.Angles(math.rad(-18)+b*.11,0,0))
 pose('RightAnkle',CFrame.Angles(b*.08,0,0))
 pose('LeftAnkle',CFrame.Angles(-b*.08,0,0))
 -- Same original float for classic avatar joints.
 pose('RootJoint',CFrame.Angles(math.rad(-7)+a*.05,0,c*.06))
 pose('Right Shoulder',CFrame.Angles(math.rad(-23)+b*.14,0,math.rad(43)+a*.14))
 pose('Left Shoulder',CFrame.Angles(math.rad(-23)-b*.14,0,math.rad(-43)-a*.14))
 pose('Right Hip',CFrame.Angles(math.rad(15)+a*.1,0,0))
 pose('Left Hip',CFrame.Angles(math.rad(12)-a*.1,0,0))
end

local function positionAvatar(t)
 local rise=.46*math.sin(t*.78)
 local drift=.15*math.sin(t*.37)
 -- Face the viewer while genuinely floating, not leaning sideways.
 return CFrame.new(anchor+Vector3.new(drift,rise,0))
  * CFrame.Angles(math.rad(-7)+math.sin(t*.43)*math.rad(3),math.pi,math.sin(t*.32)*math.rad(2))
end

local function playRequestedEmote(model)
 local animator=humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator')
 animator.Parent=humanoid
 local animation=Instance.new('Animation')
 animation.Name='RobloxLowGravityEmote'
 animation.AnimationId='rbxassetid://103686359406944'
 animation.Parent=model

 -- Request the asset, but do not block the procedural motion or the menu.
 task.spawn(function()
  pcall(function() ContentProvider:PreloadAsync({animation}) end)
 end)
 local ok,trackOrError=pcall(function() return animator:LoadAnimation(animation) end)
 if not ok or not trackOrError then
  warn('[StillHereEmote] Low Gravity asset is inaccessible: '..tostring(trackOrError))
  status('procedural-unavailable')
  return
 end
 local track=trackOrError
 track.Priority=Enum.AnimationPriority.Action4
 track.Looped=true
 local played,err=pcall(function() track:Play(.15,1,1) end)
 if not played then
  status('procedural-unavailable')
  warn('[StillHereEmote] Low Gravity did not start: '..tostring(err))
  return
 end

 -- Length alone is not proof of playback. Verify BOTH valid timing and
 -- that the requested track is still playing, otherwise keep our own motion.
 local start=os.clock()
 while scene.Parent and avatar==model and os.clock()-start<6 do
  if track.Length>.05 and track.IsPlaying then
   emoteTrack=track
   resetPose()
   status('asset')
   track.Stopped:Connect(function()
    if avatar==model and scene.Parent and mode=='asset' then
     emoteTrack=nil
     status('procedural-stopped')
    end
   end)
   return
  end
  task.wait(.12)
 end
 pcall(function() track:Stop(0) end)
 if scene.Parent and avatar==model then
  status('procedural-unavailable')
  warn('[StillHereEmote] Low Gravity sequence unavailable or not playing, using procedural levitation')
 end
end

local function installAvatar(model)
 if not scene.Parent then model:Destroy();return end
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA('BaseScript') then d:Destroy()
  elseif d:IsA('Sound') then d:Destroy()
  elseif d:IsA('BasePart') then
   d.CanCollide=false;d.CanTouch=false;d.CanQuery=false
   d.CastShadow=false;d.Massless=true
   if d.Name=='HumanoidRootPart' then
    d.Anchored=true;d.Transparency=1
   end
  end
 end
 humanoid=model:FindFirstChildOfClass('Humanoid')
 local root=model:FindFirstChild('HumanoidRootPart')
 if not humanoid or not root then
  warn('[StillHereEmote] No valid avatar rig')
  model:Destroy();return
 end
 humanoid.AutoRotate=false
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 model.Name='LowGravityAvatar'
 model.Parent=scene
 model:PivotTo(positionAvatar(0))
 avatar=model
 capture(model)
 -- Start with a REAL visible pose even before Roblox downloads the emote.
 proceduralLevitation(0)
 player:SetAttribute('MenuAvatarReady',true)
 task.spawn(playRequestedEmote,model)
end

task.spawn(function()
 local ok,model=pcall(function()
  return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
 end)
 if ok and model and model:IsA('Model') then installAvatar(model)
 else warn('[StillHereEmote] Failed to load user avatar') end
end)

local elapsed=0
local uniqueRender='StillHereLowGravityMenu_'..tostring(player.UserId)
RunService:BindToRenderStep(uniqueRender,Enum.RenderPriority.Camera.Value+1,function(dt)
 if not scene.Parent or W:GetAttribute('GameMode')~='Menu' then
  RunService:UnbindFromRenderStep(uniqueRender)
  cameraSignal:Disconnect()
  if emoteTrack then pcall(function() emoteTrack:Stop(0) end) end
  player:SetAttribute('MenuAvatarReady',false)
  scene:Destroy()
  return
 end
 elapsed+=math.min(dt,.08)
 local headPosition=anchor+Vector3.new(0,1.55,0)
 if avatar then
  avatar:PivotTo(positionAvatar(elapsed))
  if mode~='asset' or not emoteTrack or not emoteTrack.IsPlaying then
   if mode=='asset' then status('procedural-stopped') end
   proceduralLevitation(elapsed)
  end
  local head=avatar:FindFirstChild('Head')
  if head and head:IsA('BasePart') then headPosition=head.Position end
 end
 local wideEye=Vector3.new(0,5001.05,1.3)
 local wideTarget=Vector3.new(-.65,5001.05,-12)
 local closeEye=headPosition+Vector3.new(1.20,.13,2.72)
 local closeTarget=headPosition+Vector3.new(1.05,-.03,-.2)
 local t=math.clamp(zoom.Value,0,1)
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=60-t*8
 camera.CFrame=CFrame.lookAt(wideEye:Lerp(closeEye,t),wideTarget:Lerp(closeTarget,t))
end)
