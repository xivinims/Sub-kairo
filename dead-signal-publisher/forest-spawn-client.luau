local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local function pulse(char)
 local hrp=char:WaitForChild('HumanoidRootPart',10);if not hrp then return end
 local cam=workspace.CurrentCamera
 if cam and (cam.CFrame.Position-hrp.Position).Magnitude>120 then return end
 local glow=Instance.new('Highlight');glow.Name='ArrivalGlow';glow.Adornee=char
 glow.FillColor=Color3.fromRGB(224,237,173);glow.OutlineColor=Color3.fromRGB(255,240,182)
 glow.FillTransparency=.55;glow.OutlineTransparency=.15;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=char
 Tween:Create(glow,TweenInfo.new(2.6),{FillTransparency=1,OutlineTransparency=1}):Play();Debris:AddItem(glow,2.7)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
 local hit=workspace:Raycast(hrp.Position,Vector3.new(0,-16,0),params)
 if not hit then return end
 local center=hit.Position+Vector3.new(0,.10,0)
 local fx=Instance.new('Folder');fx.Name='LocalArrivalRing';fx.Parent=workspace;Debris:AddItem(fx,2.8)
 for i=1,32 do
  local a=(i-1)*math.pi*2/32
  local p=Instance.new('Part');p.Name='ArrivalArc';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(227,238,166);p.Size=Vector3.new(.10,.06,.48)
  p.CFrame=CFrame.new(center+Vector3.new(math.cos(a)*2.6,0,math.sin(a)*2.6))*CFrame.Angles(0,-a,0)
  p.Parent=fx
  Tween:Create(p,TweenInfo.new(2.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.new(center+Vector3.new(math.cos(a+.35)*4.8,0,math.sin(a+.35)*4.8))*CFrame.Angles(0,-a-.35,0),Transparency=1}):Play()
 end
end
local function watch(p)
 p.CharacterAdded:Connect(function(c) task.spawn(pulse,c) end)
 if p.Character then task.spawn(pulse,p.Character) end
end
Players.PlayerAdded:Connect(watch)
for _,p in ipairs(Players:GetPlayers()) do watch(p) end
