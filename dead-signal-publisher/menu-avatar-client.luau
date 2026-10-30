-- Still Here: local-only avatar cinematic in front of the original black hole.
-- Plays the publicly listed Low Gravity emote if Roblox permits it.
-- Otherwise uses our own procedural low-gravity motion: NO animation asset needed.
-- Not a copy of a third-party animation's hidden keyframes.
local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end

local Players=game:GetService('Players')
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local camera=W.CurrentCamera
local anchor=Vector3.new(-1.3,5000,-7.2)

local previous=W:FindFirstChild('LocalMenuCinematic')
if previous then previous:Destroy() end
local scene=Instance.new('Folder')
scene.Name='LocalMenuCinematic'
scene.Parent=W

local zoom=Instance.new('NumberValue')
zoom.Name='CameraZoom'
zoom.Value=0
zoom.Parent=scene
local zoomTween
local function onCameraModeChanged()
 local state=player:GetAttribute('MenuCameraMode')
 local target=(state=='close' or state=='starting') and 1 or 0
 if zoomTween then zoomTween:Cancel() end
 zoomTween=TweenService:Create(
  zoom,
  TweenInfo.new(state=='starting' and 1.05 or .86,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
  {Value=target}
 )
 zoomTween:Play()
end
local cameraSignal=player:GetAttributeChangedSignal('MenuCameraMode'):Connect(onCameraModeChanged)
onCameraModeChanged()

local avatar
local emoteTrack
local fallback=true
local rigMotors={}
local fallbackTransforms={}
local function captureMotors(model)
 table.clear(rigMotors)
 table.clear(fallbackTransforms)
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA('Motor6D') then
   rigMotors[d.Name]=d
   fallbackTransforms[d.Name]=d.Transform
  end
 end
end
local function setMotor(name,cf)
 local motor=rigMotors[name]
 if motor then motor.Transform=cf end
end
local function originalFloatPose(t)
 -- Authored fallback, independent from Roblox item 103686359406944.
 -- Soft arms-out levitation, lightly bent legs, subtle shifts at waist.
 local sway=math.sin(t*.58)
 local wave=math.sin(t*.91)
 setMotor('Waist',CFrame.Angles(math.rad(5)+wave*.025,0,sway*.035))
 setMotor('Neck',CFrame.Angles(-wave*.014,0,-sway*.015))
 setMotor('RightShoulder',CFrame.Angles(math.rad(-16)+wave*.07,0,math.rad(34)+sway*.06))
 setMotor('LeftShoulder',CFrame.Angles(math.rad(-16)-wave*.07,0,math.rad(-34)+sway*.06))
 setMotor('RightElbow',CFrame.Angles(math.rad(-17)+sway*.03,0,0))
 setMotor('LeftElbow',CFrame.Angles(math.rad(-17)-sway*.03,0,0))
 setMotor('RightHip',CFrame.Angles(math.rad(14)+wave*.035,0,math.rad(5)))
 setMotor('LeftHip',CFrame.Angles(math.rad(10)-wave*.035,0,math.rad(-5)))
 setMotor('RightKnee',CFrame.Angles(math.rad(-22),0,0))
 setMotor('LeftKnee',CFrame.Angles(math.rad(-15),0,0))
 -- R6 fallback when the player's real avatar rig has legacy shoulder names.
 setMotor('Right Shoulder',CFrame.Angles(math.rad(-14),0,math.rad(26)+sway*.05))
 setMotor('Left Shoulder',CFrame.Angles(math.rad(-14),0,math.rad(-26)+sway*.05))
 setMotor('Right Hip',CFrame.Angles(math.rad(8)+wave*.03,0,0))
 setMotor('Left Hip',CFrame.Angles(math.rad(6)-wave*.03,0,0))
end

local function positionAvatar(t)
 local rise=math.sin(t*.72)*.19
 local roll=math.sin(t*.39)*math.rad(3)
 -- Mostly upright, but demonstrably floating, without an artificial water plane.
 return CFrame.new(anchor+Vector3.new(0,rise,0))
  * CFrame.Angles(math.rad(-9)+math.sin(t*.44)*math.rad(2),0,roll)
  * CFrame.Angles(0,math.pi,0)
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
 local humanoid=model:FindFirstChildOfClass('Humanoid')
 local root=model:FindFirstChild('HumanoidRootPart')
 if not humanoid or not root then
  warn('[MenuCinematic] Invalid player avatar rig')
  model:Destroy()
  return
 end
 model.Name='LowGravityAvatar'
 model.Parent=scene
 model:PivotTo(positionAvatar(0))
 avatar=model
 captureMotors(model)
 player:SetAttribute('MenuAvatarReady',true)
 player:SetAttribute('MenuEmoteMode','procedural')

 -- Try the requested public Low Gravity emote first, never require it.
 task.spawn(function()
  local animator=humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator')
  animator.Parent=humanoid
  local animation=Instance.new('Animation')
  animation.Name='RequestedLowGravity'
  animation.AnimationId='rbxassetid://103686359406944'
  animation.Parent=model
  local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
  if not ok or not track then
   warn('[MenuCinematic] Low Gravity unavailable; independent procedural float active')
   return
  end
  track.Looped=true
  track.Priority=Enum.AnimationPriority.Action4
  local played,err=pcall(function() track:Play(.25,1,1) end)
  if not played then
   warn('[MenuCinematic] Low Gravity refused: '..tostring(err))
   return
  end
  local started=os.clock()
  while scene.Parent and avatar==model and track.Length<=0 and os.clock()-started<3 do
   task.wait(.15)
  end
  if scene.Parent and avatar==model and track.Length>0 then
   emoteTrack=track
   fallback=false
   player:SetAttribute('MenuEmoteMode','asset')
  else
   pcall(function() track:Stop(0) end)
   warn('[MenuCinematic] Low Gravity not loaded; independent coded fallback active')
  end
 end)
end

task.spawn(function()
 local ok,model=pcall(function()
  return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
 end)
 if ok and model and model:IsA('Model') then
  installAvatar(model)
 else
  warn('[MenuCinematic] Avatar model unavailable')
 end
end)

local elapsed=0
local render
render=RunService.RenderStepped:Connect(function(dt)
 if not scene.Parent or W:GetAttribute('GameMode')~='Menu' then
  render:Disconnect()
  cameraSignal:Disconnect()
  if emoteTrack then pcall(function() emoteTrack:Stop(0) end) end
  scene:Destroy()
  return
 end
 elapsed+=math.min(dt,.08)
 local headPosition=anchor+Vector3.new(0,1.5,0)
 if avatar then
  avatar:PivotTo(positionAvatar(elapsed))
  if fallback then originalFloatPose(elapsed) end
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
 camera.CFrame=CFrame.lookAt(
  wideEye:Lerp(closeEye,t),
  wideTarget:Lerp(closeTarget,t)
 )
end)
