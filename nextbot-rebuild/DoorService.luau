local Tween=game:GetService('TweenService')
local Collection=game:GetService('CollectionService')
local Players=game:GetService('Players')
local Service={};local doors={}
function Service.Load(geometry)
 table.clear(doors)
 for _,model in ipairs(geometry:GetDescendants())do
  if not model:IsA('Model')or not model.Name:lower():find('door')then continue end
  local hinge=model:FindFirstChild('RootPart')or model:FindFirstChild('Hinge')
  if not hinge or not hinge:IsA('BasePart')then continue end
  local entry={model=model,hinge=hinge,closed=model:GetPivot(),open=false,busy=false,last=0};table.insert(doors,entry)
  entry.opened=hinge.CFrame*CFrame.Angles(0,math.rad(100),0)*hinge.CFrame:Inverse()*entry.closed
  for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')then
   local nav=Instance.new('PathfindingModifier');nav.Name='DoorPassage';nav.PassThrough=true;nav.Parent=part
  end end
  local prompt=Instance.new('ProximityPrompt');prompt.Name='NBDoor';prompt.ActionText='Abrir';prompt.ObjectText='Porta';prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.MaxActivationDistance=10;prompt.HoldDuration=0;prompt.Parent=hinge;entry.prompt=prompt
  prompt.Triggered:Connect(function(p)
   local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and root and (root.Position-hinge.Position).Magnitude<12 then Service.Toggle(entry,not entry.open)end
  end)
 end
end
function Service.Toggle(entry,open)
 if entry.busy or not entry.model.Parent or entry.open==open then return end
 entry.busy=true;entry.open=open;entry.last=os.clock();entry.prompt.ActionText=open and 'Fechar'or 'Abrir'
 local value=Instance.new('CFrameValue');value.Value=entry.model:GetPivot()
 local connection=value.Changed:Connect(function(cf)if entry.model.Parent then entry.model:PivotTo(cf)end end)
 local tween=Tween:Create(value,TweenInfo.new(.3,Enum.EasingStyle.Quad),{Value=open and entry.opened or entry.closed})
 tween.Completed:Once(function()connection:Disconnect();value:Destroy();entry.busy=false end);tween:Play()
end
function Service.Step()
 for _,entry in ipairs(doors)do
  if not entry.model.Parent then continue end
  for _,bot in ipairs(Collection:GetTagged('NBNextbot'))do
   local root=bot:FindFirstChild('HumanoidRootPart')
   if root and (root.Position-entry.hinge.Position).Magnitude<14 then Service.Toggle(entry,true);break end
  end
 end
end
return Service
