local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService')
local motors=setmetatable({},{__mode='k'});local clock=0
Run.Heartbeat:Connect(function(dt)
 clock+=dt;if clock<1/20 then return end;clock=0
 local world=workspace:FindFirstChild('IslandResidents');local camera=workspace.CurrentCamera;if not world or not camera then return end
 local t=os.clock()
 for index,rig in ipairs(world:GetChildren()) do
  local root=rig:FindFirstChild('HumanoidRootPart')
  if root and (root.Position-camera.CFrame.Position).Magnitude<100 then
   if not motors[rig] then local list={} for _,v in ipairs(rig:GetDescendants()) do if v:IsA('Motor6D') then list[v.Name]=v end end;motors[rig]=list end
   local m=motors[rig];local phase=t+index*1.9
   if m.Waist then m.Waist.Transform=CFrame.Angles(math.sin(phase*.8)*.018,math.sin(phase*.23)*.04,0) end
   if m.Neck then m.Neck.Transform=CFrame.Angles(math.sin(phase*.44)*.045,math.sin(phase*.31)*.16,0) end
   if m.LeftShoulder then m.LeftShoulder.Transform=CFrame.Angles(math.sin(phase*.65)*.035,0,-.035) end
   if m.RightShoulder then m.RightShoulder.Transform=CFrame.Angles(math.sin(phase*.65+1)*.04,0,.035) end
  end
 end
end)
RS:WaitForChild('ResidentDialogue').OnClientEvent:Connect(function(rig,line)
 local head=rig and rig:FindFirstChild('Head');if not head or typeof(line)~='string' then return end
 local old=head:FindFirstChild('LocalResidentSpeech');if old then old:Destroy() end
 local gui=Instance.new('BillboardGui');gui.Name='LocalResidentSpeech';gui.Size=UDim2.fromOffset(300,110);gui.StudsOffset=Vector3.new(0,2.8,0);gui.MaxDistance=40;gui.AlwaysOnTop=false;gui.Parent=head
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(10,15,23);label.BackgroundTransparency=.15;label.TextColor3=Color3.fromRGB(235,239,247);label.TextWrapped=true;label.Font=Enum.Font.Gotham;label.TextSize=14;label.Text=(rig:GetAttribute('ResidentName') or rig.Name)..'\n'..line;label.Parent=gui
 local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12);pad.Parent=label
 task.delay(9,function() gui:Destroy() end)
end)
