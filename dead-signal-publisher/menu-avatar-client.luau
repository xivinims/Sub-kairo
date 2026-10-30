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

-- Slow atmospheric stones, in distinct depth planes, deliberately orbiting
-- OUTSIDE the avatar's personal space. The genuine asset debris field is also
-- still rendered by SkyBlackHoleClient; these add close parallax for the camera.
local stones={}
local numStones=UIS.TouchEnabled and 4 or 6
local colors={Color3.fromRGB(46,51,55),Color3.fromRGB(64,66,69),Color3.fromRGB(38,48,53)}
for i=1,numStones do
 local rock=Instance.new('Model');rock.Name='PassingStone'..i;rock.Parent=menuRoot
 local scale=.11+(i%4)*.024
 local function piece(kind,size,localCF,color)
  local p=Instance.new(kind)
  p.Name='RockFragment';p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  p.Material=Enum.Material.Slate;p.Color=color;p.CastShadow=false;p.CFrame=localCF
  p.Parent=rock
 end
 piece('WedgePart',Vector3.new(1.4,1.0,1.8)*scale,CFrame.new(0,0,0),colors[i%3+1])
 piece('WedgePart',Vector3.new(.9,.7,1.1)*scale,CFrame.new(.33,.3,-.24)*CFrame.Angles(0,math.rad(155),math.rad(32)),colors[(i+1)%3+1])
 piece('Part',Vector3.new(.55,.35,.88)*scale,CFrame.new(-.3,-.24,.22)*CFrame.Angles(math.rad(15),0,math.rad(-30)),colors[i%3+1])
 local phase=i*2.399963229728653
 local radius=4.6+(i%4)*.65
 local inFront=i%3==0
 local z=inFront and 1.1+(i%3)*.3 or -3.4-(i%3)*.8
 local center=anchor+Vector3.new(math.cos(phase)*radius,math.sin(phase)*radius*.78,z)
 rock:PivotTo(CFrame.new(center))
 table.insert(stones,{model=rock,phase=phase,radius=radius,depth=z,speed=(i%3+2)*.005,spin=i*.14})
end

local elapsed=0
local stoneAccum=0
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
 stoneAccum+=dt
 if stoneAccum>1/24 then
  stoneAccum=0
  for _,stone in ipairs(stones) do
   local theta=stone.phase+elapsed*stone.speed
   local r=stone.radius
   -- X/Y radial clearance is at least 3.9 studs, even when a stone is in front.
   local center=anchor+Vector3.new(math.cos(theta)*r,math.sin(theta)*r*.78+math.sin(elapsed*.19+stone.spin)*.26,stone.depth)
   local tilt=CFrame.Angles(elapsed*.033+stone.spin,theta*.44,elapsed*.018)
   stone.model:PivotTo(CFrame.new(center)*tilt)
  end
 end
end)
