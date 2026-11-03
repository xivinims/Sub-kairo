while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService');local Input=game:GetService('UserInputService')
local p=Players.LocalPlayer;local event=RS:WaitForChild('MansionEvent')
p.CameraMinZoomDistance=.5;p.CameraMaxZoomDistance=.5;p.CameraMode=Enum.CameraMode.LockFirstPerson
local gui=Instance.new('ScreenGui');gui.Name='MansionAtmosphere';gui.ResetOnSpawn=false;gui.DisplayOrder=45;gui.Parent=p:WaitForChild('PlayerGui')
local text=Instance.new('TextLabel');text.AnchorPoint=Vector2.new(.5,1);text.Position=UDim2.fromScale(.5,.9);text.Size=UDim2.new(.85,0,0,85);text.BackgroundTransparency=1;text.Font=Enum.Font.Code;text.TextSize=18;text.TextColor3=Color3.fromRGB(231,225,212);text.TextStrokeTransparency=.45;text.TextWrapped=true;text.Text='';text.Parent=gui
task.delay(8,function() text.Text='' end)
-- An authored story cue; the changing visitor is impersonating a deceased owner.
local function memoir()
 text.Text='Registro da casa: Amélia Duarte — falecida.\nNinguém deveria estar pedindo para entrar em nome dela.'
 task.delay(10,function() text.Text='' end)
end
local shakeUntil=0;local ticket=0
event.OnClientEvent:Connect(function(kind,object,line)
 if kind=='record' then memoir();return end
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if not root then return end
 if kind=='knock' and typeof(object)=='Vector3' and (root.Position-object).Magnitude<100 then
  shakeUntil=os.clock()+.18
  local template=RS:FindFirstChild('MansionKnock');if template then local sound=template:Clone();sound.Volume=.35;sound.Parent=workspace.CurrentCamera;sound:Play();game:GetService('Debris'):AddItem(sound,5) end
 elseif kind=='visitor' and object and object:FindFirstChild('HumanoidRootPart') and (root.Position-object.HumanoidRootPart.Position).Magnitude<120 then
  ticket+=1;local current=ticket;text.Text='Uma voz do lado de fora:\n“'..line..'”'
  task.delay(9,function() if ticket==current then text.Text='' end end)
 end
end)
local smooth=Vector3.zero
Run:BindToRenderStep('MansionWeightedCamera',Enum.RenderPriority.Camera.Value+1,function(dt)
 local camera=workspace.CurrentCamera;local char=p.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
 if not camera or not root or camera.CameraType~=Enum.CameraType.Custom then return end
 local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
 local t=os.clock();local target=Vector3.new(math.sin(t*5)*math.min(speed/1000,.012),math.sin(t*10)*math.min(speed/500,.025),0)
 smooth=smooth:Lerp(target,math.min(1,dt*5));camera.CFrame*=CFrame.new(smooth)*CFrame.Angles(0,0,math.sin(t*2)*.001)
 if t<shakeUntil then camera.CFrame*=CFrame.Angles(math.sin(t*80)*.005,0,0) end
 local visitor=workspace:FindFirstChild('TheFormerOwner')
 if visitor then
  local head=visitor:FindFirstChild('Head');local neck=visitor:FindFirstChild('Neck',true)
  if neck and neck:IsA('Motor6D') then neck.Transform=CFrame.Angles(math.sin(t*.7)*.08,math.sin(t*.4)*.2,.1) end
  local walking=visitor:GetAttribute('Walking');local stride=walking and math.sin(t*9)*.4 or 0
  local left=visitor:FindFirstChild('LeftHip',true);local right=visitor:FindFirstChild('RightHip',true)
  if left and left:IsA('Motor6D') then left.Transform=CFrame.Angles(stride,0,0) end
  if right and right:IsA('Motor6D') then right.Transform=CFrame.Angles(-stride,0,0) end
 end
end)

Run.PreSimulation:Connect(function()
 local rig=workspace:FindFirstChild('ForestStalker');if not rig then return end
 local root=rig:FindFirstChild('HumanoidRootPart');if not root then return end
 local t=os.clock();local moving=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>1
 local stride=moving and math.sin(t*8)*.45 or 0
 for _,spec in ipairs({{'LeftHip',stride},{'RightHip',-stride},{'LeftShoulder',-stride*.7},{'RightShoulder',stride*.7}}) do
  local joint=rig:FindFirstChild(spec[1],true);if joint and joint:IsA('Motor6D') then joint.Transform=CFrame.Angles(spec[2],0,0) end
 end
 local neck=rig:FindFirstChild('Neck',true);if neck and neck:IsA('Motor6D') then neck.Transform=CFrame.Angles(math.sin(t*.5)*.04,math.sin(t*.35)*.12,.04) end
end)
