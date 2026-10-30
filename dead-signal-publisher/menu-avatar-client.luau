-- Local-only menu portrait: the player's own Roblox avatar, afloat in front of the real sky.
-- Viewport background is transparent, so the 7208091524 black hole remains visible.
local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui')
gui.Name='StillHereFloatingAvatar';gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false;gui.DisplayOrder=1010;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild('PlayerGui')
local viewport=Instance.new('ViewportFrame')
viewport.Name='FloatingTorso';viewport.BackgroundTransparency=1;viewport.BorderSizePixel=0
viewport.Size=UDim2.fromScale(.48,.87);viewport.Position=UDim2.fromScale(.01,.13)
viewport.Active=false;viewport.Selectable=false;viewport.Ambient=Color3.fromRGB(115,150,163)
viewport.LightColor=Color3.fromRGB(208,221,227)
viewport.LightDirection=Vector3.new(-.4,-1,-.5)
viewport.Parent=gui
local world=Instance.new('WorldModel');world.Parent=viewport
local cam=Instance.new('Camera');cam.FieldOfView=34;cam.CFrame=CFrame.lookAt(Vector3.new(0,.9,10),Vector3.new(0,1.0,0))
cam.Parent=viewport;viewport.CurrentCamera=cam

local function fallback()
 local m=Instance.new('Model');m.Name='AvatarLoading'
 local function part(name,position,size,color,shape)
  local p=Instance.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false
  p.Size=size;p.Color=color;p.Material=Enum.Material.SmoothPlastic
  if shape then p.Shape=shape end
  p.CFrame=CFrame.new(position);p.Parent=m;return p
 end
 part('Torso',Vector3.new(0,.25,0),Vector3.new(2.2,2.4,1.1),Color3.fromRGB(60,72,84))
 part('Head',Vector3.new(0,2,0),Vector3.new(1.2,1.25,1.15),Color3.fromRGB(177,155,139),Enum.PartType.Ball)
 part('LeftArm',Vector3.new(-1.75,.15,0),Vector3.new(.8,2.4,.95),Color3.fromRGB(65,77,87))
 part('RightArm',Vector3.new(1.75,.15,0),Vector3.new(.8,2.4,.95),Color3.fromRGB(65,77,87))
 part('LowerBody',Vector3.new(0,-1.45,0),Vector3.new(2.1,1.5,1),Color3.fromRGB(34,41,50))
 m.PrimaryPart=m.Torso;m.Parent=world;return m
end
local avatar=fallback()
local shoulders={}
local function install(model)
 if not gui.Parent then model:Destroy();return end
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA('BaseScript') then d:Destroy()
  elseif d:IsA('BasePart') then
   d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.CastShadow=false
   if d.Name=='HumanoidRootPart' then d.Anchored=true;d.Transparency=1 end
  elseif d:IsA('Sound') then d:Destroy() end
 end
 model.Name='PlayerFloatingPortrait'
 model:PivotTo(CFrame.new())
 model.Parent=world
 avatar:Destroy();avatar=model
 shoulders={}
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA('Motor6D') and (d.Name=='LeftShoulder' or d.Name=='RightShoulder' or d.Name=='Left Shoulder' or d.Name=='Right Shoulder') then
   table.insert(shoulders,{motor=d,left=d.Name:find('Left',1,true)~=nil})
  end
 end
end
task.spawn(function()
 local ok,model=pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(player.UserId) end)
 if ok and model and model:IsA('Model') then install(model)
 else warn('[StillHereMenu] Avatar portrait unavailable; using a temporary mannequin') end
end)
local t=0
local connection
connection=Run.RenderStepped:Connect(function(dt)
 if not gui.Parent or not avatar.Parent then if connection then connection:Disconnect() end;return end
 t+=math.min(dt,.1)
 -- Float gently in the lower-left foreground; legs stay outside the camera crop.
 local bob=math.sin(t*1.12)*.14
 avatar:PivotTo(CFrame.new(0,-.36+bob,0)*CFrame.Angles(math.rad(5)+math.sin(t*.72)*.04,math.pi+math.sin(t*.43)*.14,math.rad(-10)+math.sin(t*.81)*.05))
 for _,joint in ipairs(shoulders) do
  local direction=joint.left and 1 or -1
  joint.motor.Transform=CFrame.Angles(math.sin(t*1.2+direction)*.20,0,direction*(.10+math.sin(t*.85)*.10))
 end
end)
