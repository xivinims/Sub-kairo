while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Input=game:GetService('UserInputService');local Tween=game:GetService('TweenService');local Run=game:GetService('RunService')
local p=Players.LocalPlayer;local event=RS:WaitForChild('AdventureEvent')
local gui=Instance.new('ScreenGui');gui.Name='AdventureObjectives';gui.ResetOnSpawn=false;gui.DisplayOrder=40;gui.Parent=p:WaitForChild('PlayerGui')
local label=Instance.new('TextLabel');label.Position=UDim2.new(.14,0,0,16);label.Size=UDim2.new(.72,0,0,66);label.BackgroundTransparency=1;label.Font=Enum.Font.Code;label.TextColor3=Color3.fromRGB(226,236,241);label.TextStrokeTransparency=.5;label.TextSize=16;label.TextWrapped=true;label.Text='';label.Parent=gui
local notice=label:Clone();notice.Position=UDim2.new(.14,0,.72,0);notice.TextColor3=Color3.fromRGB(247,204,153);notice.Parent=gui
local sneak=Instance.new('TextButton');sneak.AnchorPoint=Vector2.new(.5,1);sneak.Position=UDim2.new(.5,0,1,-24);sneak.Size=UDim2.fromOffset(100,48);sneak.Text='FURTIVO';sneak.Font=Enum.Font.Code;sneak.TextSize=14;sneak.TextColor3=Color3.new(1,1,1);sneak.BackgroundColor3=Color3.fromRGB(26,38,41);sneak.BackgroundTransparency=.25;sneak.Parent=gui
local enabled=false;local function toggle() enabled=not enabled;sneak.Text=enabled and 'FURTIVO ✓' or 'FURTIVO';event:FireServer('sneak',enabled) end
sneak.Activated:Connect(toggle);Input.InputBegan:Connect(function(i,processed) if not processed and i.KeyCode==Enum.KeyCode.LeftControl then toggle() end end)
local direction=label:Clone();direction.Position=UDim2.new(.14,0,0,80);direction.TextSize=12;direction.Text='';direction.Parent=gui
local objectiveTarget
local ticket=0
event.OnClientEvent:Connect(function(kind,index,text,target)
 if kind=='mission' then
  objectiveTarget=index<=6 and target or nil
  ticket+=1;local id=ticket;label.TextTransparency=1;label.Text='Nova missão: '..text;Tween:Create(label,TweenInfo.new(.45),{TextTransparency=0}):Play()
  task.delay(5,function() if id==ticket then label.Text='Missão: '..text end end)
 elseif kind=='detected' then notice.Text=index;task.delay(5,function() notice.Text='' end) end
end)
event:FireServer('state')
local poses=setmetatable({},{__mode='k'})
Run.RenderStepped:Connect(function(dt)
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local camera=workspace.CurrentCamera
 if objectiveTarget and root and camera then local delta=objectiveTarget-root.Position;local localDelta=camera.CFrame:VectorToObjectSpace(delta);direction.Text=math.floor(Vector3.new(delta.X,0,delta.Z).Magnitude)..' studs · '..(math.abs(localDelta.X)>math.abs(localDelta.Z) and (localDelta.X>0 and 'à direita' or 'à esquerda') or (localDelta.Z<0 and 'à frente' or 'atrás')) else direction.Text='' end
 local actors=workspace:FindFirstChild('AdventureThreats');if not actors then return end
 for _,model in ipairs(actors:GetChildren()) do if model.PrimaryPart then
  local target=model:GetAttribute('MotionTarget')
  if target then
   local state=poses[model];if not state then state={cf=model:GetPivot(),parts={}};for _,part in ipairs(model:GetChildren()) do if part:IsA('BasePart') then state.parts[part]=model:GetPivot():ToObjectSpace(part.CFrame) end end;poses[model]=state end
   state.cf=state.cf:Lerp(target,math.min(1,dt*10));local t=os.clock()
   for part,offset in pairs(state.parts) do if part.Parent then
    local animate=CFrame.identity
    if part.Name=='Head' then animate=CFrame.Angles(0,math.sin(t*.7)*.18,0)
    elseif part.Name=='Arm' or part.Name=='Leg' then animate=CFrame.Angles(math.sin(t*7+offset.X*2)*.19,0,0) end
    part.CFrame=state.cf*offset*animate
   end end
  end
 end end
end)
