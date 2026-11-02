-- Natural R6 wall climbing based on R15 & R6 Wall Climbing System.rbxl.
-- Climb when walking FORWARD into a vertical wall. No climb button.
-- Chakra wall walking is a separate optional mode and takes priority.
-- Original stamina values and R6 climb Animation are retained.
local RunService=game:GetService("RunService")
local character=script.Parent
local humanoid=character:WaitForChild("Humanoid")
if humanoid.RigType~=Enum.HumanoidRigType.R6 then return end
local root=character:WaitForChild("HumanoidRootPart")
local animate=character:WaitForChild("Animate")
local animator=humanoid:WaitForChild("Animator",10)
if not animator then warn("[Climb] Missing R6 Animator");return end

local SPEED=10
local DRAIN=15
local RECOVERY=12
local MAX_STAMINA=100
local COOLDOWN=2
local CHECK_INTERVAL=0.09
local status={
 enabled=false, exhausted=false, untilTime=0, lastCheck=0,
 nearWall=false, stamina=MAX_STAMINA, lastSent=-1,
}
character:SetAttribute("Climbing",false)
character:SetAttribute("ClimbNaturalEnabled",true)
character:SetAttribute("Stamina",MAX_STAMINA)
if character:GetAttribute("ChakraActive")==nil then
 character:SetAttribute("ChakraActive",false)
end

-- Keep the original model's StaminaBar module (UI gradient + thresholds).
-- The display is lightweight and only shown during use/recovery.
local meter=Instance.new("BillboardGui")
meter.Name="Stamina"
meter.Adornee=root
meter.Size=UDim2.fromOffset(26,96)
meter.StudsOffsetWorldSpace=Vector3.new(2.3,0,0)
meter.AlwaysOnTop=true
meter.Enabled=false
meter.MaxDistance=44
meter.Parent=character
local bg=Instance.new("Frame")
bg.Name="Frame"
bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.fromRGB(4,13,29)
bg.BackgroundTransparency=.24
bg.BorderSizePixel=0
bg.Parent=meter
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,9)
corner.Parent=bg
local outline=Instance.new("UIStroke")
outline.Color=Color3.fromRGB(198,226,255)
outline.Transparency=.35
outline.Thickness=1
outline.Parent=bg
local bar=Instance.new("Frame")
bar.Name="Bar"
bar.Size=UDim2.fromScale(1,1)
bar.AnchorPoint=Vector2.new(0,1)
bar.Position=UDim2.fromScale(0,1)
bar.BorderSizePixel=0
bar.BackgroundColor3=Color3.fromRGB(79,199,253)
bar.Parent=bg
local grad=Instance.new("UIGradient")
grad.Color=ColorSequence.new(Color3.fromRGB(106,220,255),
 Color3.fromRGB(37,114,248))
grad.Rotation=90
grad.Parent=bar
local barCorner=Instance.new("UICorner")
barCorner.CornerRadius=UDim.new(0,8)
barCorner.Parent=bar
local staminaBar=require(script:WaitForChild("StaminaBar"))
staminaBar.Init(character)
meter.Enabled=false

local climbingTrack
local climbClip=animate:FindFirstChild("climb")
climbClip=climbClip and climbClip:FindFirstChild("ClimbAnim")
if climbClip and climbClip:IsA("Animation") then
 local ok,track=pcall(function()return animator:LoadAnimation(climbClip)end)
 if ok and track then
  track.Priority=Enum.AnimationPriority.Action
  track.Looped=true
  climbingTrack=track
 end
end
local originalAutoRotate=humanoid.AutoRotate
local alive=true
local function setClimbing(active)
 if status.enabled==active then return end
 status.enabled=active
 character:SetAttribute("Climbing",active)
 if active then
  originalAutoRotate=humanoid.AutoRotate
  humanoid.AutoRotate=false
  if climbingTrack then climbingTrack:Play(0.14,1,1) end
 else
  humanoid.AutoRotate=originalAutoRotate
  if climbingTrack then climbingTrack:Stop(0.15) end
 end
end
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={character}
params.IgnoreWater=true

local function forwardIntoWall()
 if humanoid.MoveDirection.Magnitude<0.15 then return false end
 if humanoid.MoveDirection:Dot(root.CFrame.LookVector)<0.32 then return false end
 local origin=root.Position+Vector3.new(0,-0.6,0)
 local direction=root.CFrame.LookVector
 local hit=workspace:Raycast(origin,direction*1.7,params)
 if not hit then return false end
 if hit.Instance.CanCollide==false then return false end
 if math.abs(hit.Normal.Y)>0.27 then return false end
 if hit.Instance:IsDescendantOf(character) then return false end
 return true
end
local function inBlockedState()
 local mode=humanoid:GetState()
 return mode==Enum.HumanoidStateType.Seated or humanoid.Sit
  or mode==Enum.HumanoidStateType.Swimming
  or mode==Enum.HumanoidStateType.Dead
  or humanoid.Health<=0
end
local updateClock=0
local conn
conn=RunService.Heartbeat:Connect(function(dt)
 if not alive or not character.Parent or humanoid.Health<=0 then
  setClimbing(false)
  if conn then conn:Disconnect();conn=nil end
  meter.Enabled=false
  return
 end
 local now=os.clock()
 if now-status.lastCheck>=CHECK_INTERVAL then
  status.lastCheck=now
  status.nearWall=forwardIntoWall()
 end
 local chakra=character:GetAttribute("ChakraActive")==true
 local allowed=not chakra and not inBlockedState()
  and now>=status.untilTime and status.stamina>0 and status.nearWall
 if allowed then
  setClimbing(true)
  -- Stand R6 walking-on-wall motion from uploaded model:
  -- gentle upward velocity, not a teleport and not a key-operated ability.
  root.AssemblyLinearVelocity=Vector3.new(0,SPEED,0)
   + root.CFrame.LookVector*0.9
  status.stamina=math.max(0,status.stamina-DRAIN*dt)
  if status.stamina<=0 then
   status.untilTime=now+COOLDOWN
   setClimbing(false)
  end
 else
  setClimbing(false)
  status.stamina=math.min(MAX_STAMINA,status.stamina+RECOVERY*dt)
 end
 meter.Enabled=status.enabled or status.stamina<MAX_STAMINA-0.25
 updateClock+=dt
 if updateClock>=.12 then
  updateClock=0
  local rounded=math.floor(status.stamina+0.5)
  if rounded~=status.lastSent then
   status.lastSent=rounded
   character:SetAttribute("Stamina",rounded)
  end
 end
end)
humanoid.Died:Once(function()
 alive=false
 setClimbing(false)
 meter.Enabled=false
end)
script.Destroying:Once(function()
 alive=false
 setClimbing(false)
 if conn then conn:Disconnect() end
 if climbingTrack then climbingTrack:Destroy() end
 if meter.Parent then meter:Destroy() end
end)
