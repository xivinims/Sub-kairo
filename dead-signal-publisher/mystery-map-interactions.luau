-- The UI addresses tagged interactions and never depends on a particular map path.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Collection=game:GetService('CollectionService')
local Tween=game:GetService('TweenService')
local M={}
local activeMap
local doors={}
local cooldown=setmetatable({},{__mode='k'})
local function alive(player)
 local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 return root and humanoid and humanoid.Health>0 and root or nil
end
function M.SetDoorOpen(door,open,instant)
 local state=doors[door]
 if not state or state.busy then return false end
 state.busy=true
 state.flag.Value=open
 door:SetAttribute('IsOpen',open)
 state.prompt.ActionText=open and 'Fechar' or 'Abrir'
 local target=open and state.closed*CFrame.Angles(0,math.rad(90),0) or state.closed
 state.hitbox.CanCollide=false
 local sound=state.hitbox:FindFirstChild(open and 'open' or 'close')
 if sound and sound:IsA('Sound') and not instant then sound:Play() end
 local function finish()
  state.hitbox.CanCollide=not open
  state.busy=false
 end
 if instant then state.hinge.CFrame=target;finish()
 else
  local tween=Tween:Create(state.hinge,TweenInfo.new(.35,Enum.EasingStyle.Sine,open and Enum.EasingDirection.Out or Enum.EasingDirection.In),{CFrame=target})
  tween.Completed:Once(finish);tween:Play()
 end
 return true
end
function M.Interact(player,target)
 if typeof(target)~='Instance' or not activeMap or not target:IsDescendantOf(activeMap) then return false end
 local state=doors[target]
 local root=alive(player)
 if not root or not state or (root.Position-state.hitbox.Position).Magnitude>10 then return false end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={player.Character};ray.RespectCanCollide=true
 local hit=workspace:Raycast(root.Position,state.hitbox.Position-root.Position,ray)
 if hit and not hit.Instance:IsDescendantOf(target) then return false end
 if os.clock()-(cooldown[player] or -1)<.2 then return false end
 cooldown[player]=os.clock()
 return M.SetDoorOpen(target,not state.flag.Value)
end
function M.Initialize(map)
 if activeMap then assert(activeMap==map,'Interaction map already initialized');return end
 activeMap=map
 local remote=RS:WaitForChild('MysteryUIAction')
 for _,door in ipairs(map:GetDescendants()) do
  if door:GetAttribute('InteractionKind')=='Door' then
   local hinge=assert(door:FindFirstChild('Hinge'))
   local hitbox=assert(door:FindFirstChild('Hitbox'))
   local flag=assert(door:FindFirstChild('Open'))
   local prompt=Instance.new('ProximityPrompt')
   prompt.Name='StillHereInteract';prompt.ActionText='Abrir';prompt.ObjectText='Porta'
   prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
   prompt.MaxActivationDistance=8;prompt.HoldDuration=0;prompt.RequiresLineOfSight=true
   prompt.Parent=hitbox
   doors[door]={hinge=hinge,hitbox=hitbox,flag=flag,closed=hinge.CFrame,prompt=prompt,busy=false}
   M.SetDoorOpen(door,flag.Value,true)
   Collection:AddTag(door,'StillHereInteractable')
   prompt.Triggered:Connect(function(player) M.Interact(player,door) end)
   local click=hitbox:FindFirstChildOfClass('ClickDetector')
   if click then click.MaxActivationDistance=8;click.MouseClick:Connect(function(player) M.Interact(player,door) end) end
  end
 end
 remote.OnServerEvent:Connect(function(player,action,target)
  if action=='interact' then M.Interact(player,target)
  elseif action=='lamp' then
   local root=alive(player)
   local head=root and player.Character:FindFirstChild('Head')
   if not head or os.clock()-(cooldown[player] or -1)<.15 then return end
   cooldown[player]=os.clock()
   local light=head:FindFirstChild('MysteryHeadlamp')
   if not light then
    light=Instance.new('SpotLight');light.Name='MysteryHeadlamp'
    light.Range=40;light.Angle=65;light.Brightness=2.2
    light.Color=Color3.fromRGB(236,228,205);light.Shadows=false
    light.Face=Enum.NormalId.Front;light.Enabled=false;light.Parent=head
   end
   light.Enabled=not light.Enabled
   player:SetAttribute('HeadlampOn',light.Enabled)
  end
 end)
 local function playerAdded(player)
  player:SetAttribute('HeadlampOn',false)
  player.CharacterAdded:Connect(function() player:SetAttribute('HeadlampOn',false) end)
 end
 Players.PlayerAdded:Connect(playerAdded)
 for _,player in ipairs(Players:GetPlayers()) do playerAdded(player) end
end
return M
