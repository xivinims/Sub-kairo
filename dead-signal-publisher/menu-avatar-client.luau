-- The actual player avatar stands still in dark water before the original Beyond the Dark black hole.
-- The menu camera zooms toward the face for panels and game launch.
-- Local-only objects never affect match maps, player physics, or server-owned gameplay.
local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end

local Players=game:GetService('Players')
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local camera=W.CurrentCamera
local anchor=Vector3.new(-1.3,5000,-8.4) -- upright stationary menu figure
local menuRoot=Instance.new('Folder')
menuRoot.Name='LocalMenuCinematic'
menuRoot.Parent=W
local zoom=Instance.new('NumberValue');zoom.Name='CameraZoom';zoom.Value=0;zoom.Parent=menuRoot
local zoomTween
local function modeChanged()
 local state=player:GetAttribute('MenuCameraMode')
 local to=(state=='close' or state=='starting') and 1 or 0
 if zoomTween then zoomTween:Cancel() end
 zoomTween=TweenService:Create(zoom,TweenInfo.new(state=='starting' and 1.05 or .86,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Value=to})
 zoomTween:Play()
end
player:GetAttributeChangedSignal('MenuCameraMode'):Connect(modeChanged)
modeChanged()

-- Actual Roblox R15 swimming animation, not handmade limb motion.
local avatar
local function installAvatar(model)
 if not menuRoot.Parent then model:Destroy();return end
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA('BaseScript') then d:Destroy()
  elseif d:IsA('Sound') then d:Destroy()
  elseif d:IsA('BasePart') then
   d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.CastShadow=false
   d.Massless=true
   if d.Name=='HumanoidRootPart' then d.Anchored=true;d.Transparency=1 end
  end
 end
 local humanoid=model:FindFirstChildOfClass('Humanoid')
 local root=model:FindFirstChild('HumanoidRootPart')
 if not humanoid or not root then model:Destroy();warn('[MenuCinematic] Avatar rig incomplete');return end
 model.Name='PlayerStandingInWater'
 model.Parent=menuRoot
 model:PivotTo(CFrame.lookAt(anchor,Vector3.new(0,5001.05,1.3)))
 avatar=model
 player:SetAttribute('MenuAvatarReady',true)
end
task.spawn(function()
 local ok,model=pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(player.UserId) end)
 if ok and model and model:IsA('Model') then installAvatar(model)
 else warn('[MenuCinematic] Could not load real player avatar') end
end)

-- This is only visual menu water. The avatar stays fully upright and still.
local water=Instance.new('Part')
water.Name='LocalDarkWaterSurface'
water.Anchored=true
water.CanCollide=false;water.CanTouch=false;water.CanQuery=false
water.CastShadow=false
water.Size=Vector3.new(170,.16,130)
water.CFrame=CFrame.new(anchor+Vector3.new(0,-1.1,-18))
water.Color=Color3.fromRGB(3,12,19)
water.Material=Enum.Material.SmoothPlastic
water.Transparency=.16
water.Parent=menuRoot
-- All debris now comes exclusively from the original 7208091524 DebrisField.
-- No locally generated wedge/part rocks or individual fake stone orbits.

local elapsed=0
local connection
connection=RunService.RenderStepped:Connect(function(dt)
 if not menuRoot.Parent or W:GetAttribute('GameMode')~='Menu' then
  if connection then connection:Disconnect() end
  menuRoot:Destroy()
  return
 end
 elapsed+=math.min(dt,.08)
 local headPosition=anchor+Vector3.new(0,1.65,0)
 -- Avatar is motionless, fully upright at the waterline.
 if avatar then
  avatar:PivotTo(CFrame.lookAt(anchor,Vector3.new(0,5001.05,1.3)))
  local head=avatar:FindFirstChild('Head')
  if head and head:IsA('BasePart') then headPosition=head.Position end
 end
 local wideEye=Vector3.new(0,5001.05,1.3)
 local wideTarget=Vector3.new(-.65,5001.05,-12)
 local closeEye=headPosition+Vector3.new(1.25,.15,2.8)
 -- Aim just right of the face, so the face stays at the LEFT of the panel.
 local closeTarget=headPosition+Vector3.new(1.10,0,-.15)
 local t=math.clamp(zoom.Value,0,1)
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=60-t*8
 camera.CFrame=CFrame.lookAt(wideEye:Lerp(closeEye,t),wideTarget:Lerp(closeTarget,t))
end)
