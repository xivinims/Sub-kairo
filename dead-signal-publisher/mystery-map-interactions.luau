local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Collection=game:GetService('CollectionService')
local Tween=game:GetService('TweenService')
local PoolGame=require(script.Parent.PoolGame)
local PianoGame=require(script.Parent.PianoGame)
local Interactions={}
local activeMap
local doors={}
local actors=setmetatable({},{__mode='k'})
local cooldown=setmetatable({},{__mode='k'})
local function aliveRoot(player)
 local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if not root or not humanoid or humanoid.Health<=0 then return nil end
 return root
end
local function isAllowed(target)
 return activeMap and target:IsDescendantOf(activeMap) or actors[target]==true
end
local function hostFor(target)
 return target:FindFirstChild('Hitbox') or target.PrimaryPart or target:FindFirstChild('HumanoidRootPart')
end
local function canReach(player,target,maxDistance)
 if typeof(target)~='Instance' or not isAllowed(target) then return nil end
 local root=aliveRoot(player);local host=hostFor(target)
 if not root or not host or not host:IsA('BasePart') then return nil end
 if (root.Position-host.Position).Magnitude>(maxDistance or 10) then return nil end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character};params.RespectCanCollide=true
 local hit=workspace:Raycast(root.Position,host.Position-root.Position,params)
 if hit and not hit.Instance:IsDescendantOf(target) then return nil end
 return root,host
end
function Interactions.RegisterActor(target,kind)
 assert(activeMap,'Initialize map interactions before registering actors')
 assert(typeof(target)=='Instance' and target:IsA('Model'),'Actor must be a model')
 assert(kind=='Receptionist','Unsupported map actor')
 target:SetAttribute('InteractionKind',kind);actors[target]=true
 Collection:AddTag(target,'StillHereInteractable')
end
function Interactions.SetDoorOpen(door,open,instant)
 local state=doors[door];if not state or state.busy then return false end
 state.busy=true;state.flag.Value=open;door:SetAttribute('IsOpen',open)
 local target=open and state.closed*CFrame.Angles(0,math.rad(90),0) or state.closed
 state.hitbox.CanCollide=false
 local sound=state.hitbox:FindFirstChild(open and 'open' or 'close');if sound and sound:IsA('Sound') and not instant then sound:Play() end
 local function finish() state.hitbox.CanCollide=not open;state.busy=false end
 if instant then state.hinge.CFrame=target;finish() else
  local tween=Tween:Create(state.hinge,TweenInfo.new(.35,Enum.EasingStyle.Sine,open and Enum.EasingDirection.Out or Enum.EasingDirection.In),{CFrame=target})
  tween.Completed:Once(finish);tween:Play()
 end
 return true
end
local function toggleLight(target)
 local lights={}
 for _,object in ipairs(target:GetDescendants()) do if object:IsA('PointLight') or object:IsA('SpotLight') or object:IsA('SurfaceLight') then table.insert(lights,object) end end
 if #lights==0 then return false end
 local on=target:GetAttribute('IsLightOn')~=true
 for _,light in ipairs(lights) do light.Enabled=on end
 target:SetAttribute('IsLightOn',on);return true
end
function Interactions.Interact(player,target)
 if typeof(target)~='Instance' or not isAllowed(target) then return false end
 local kind=target:GetAttribute('InteractionKind')
 local maximum=kind=='PoolTable' and 11 or kind=='Piano' and 11 or kind=='Receptionist' and 9 or 10
 local root=canReach(player,target,maximum)
 if not root or os.clock()-(cooldown[player] or -1)<.25 then return false end
 cooldown[player]=os.clock()
 if kind=='Door' then local state=doors[target];return state and Interactions.SetDoorOpen(target,not state.flag.Value) or false
 elseif kind=='PoolTable' then return PoolGame.Join(player)
 elseif kind=='Piano' then return PianoGame.Join(player)
 elseif kind=='Light' then return toggleLight(target)
 elseif kind=='Receptionist' then
  RS.MysteryUIAction:FireClient(player,'receptionist_dialogue',{text='Hola. Seja bem-vindo ao hotel. A mesa de sinuca está logo ali.'})
  return true
 end
 return false
end
local function registerLight(target)
 local first;local enabled=false
 for _,object in ipairs(target:GetDescendants()) do
  if not first and object:IsA('BasePart') then first=object end
  if object:IsA('PointLight') or object:IsA('SpotLight') or object:IsA('SurfaceLight') then enabled=enabled or object.Enabled end
 end
 if not first then return false end
 local has=false;for _,object in ipairs(target:GetDescendants()) do if object:IsA('PointLight') or object:IsA('SpotLight') or object:IsA('SurfaceLight') then has=true;break end end
 if not has then return false end
 target.PrimaryPart=target.PrimaryPart or first;target:SetAttribute('InteractionKind','Light');target:SetAttribute('IsLightOn',enabled);Collection:AddTag(target,'StillHereInteractable');return true
end
function Interactions.Initialize(map)
 if activeMap then assert(activeMap==map,'Interaction map already initialized');return end
 activeMap=map
 local remote=RS:WaitForChild('MysteryUIAction')
 for _,door in ipairs(map:GetDescendants()) do
  if door:GetAttribute('InteractionKind')=='Door' then
   local hinge=assert(door:FindFirstChild('Hinge'));local hitbox=assert(door:FindFirstChild('Hitbox'));local flag=assert(door:FindFirstChild('Open'))
   for _,object in ipairs(door:GetDescendants()) do if object:IsA('ProximityPrompt') or object:IsA('ClickDetector') then object:Destroy() end end
   doors[door]={hinge=hinge,hitbox=hitbox,flag=flag,closed=hinge.CFrame,busy=false};Interactions.SetDoorOpen(door,flag.Value,true);Collection:AddTag(door,'StillHereInteractable')
  end
 end
 local pool=assert(map:FindFirstChild('PoolTable1',true),'Pool table missing')
 PoolGame.Initialize(map,remote);Collection:AddTag(pool,'StillHereInteractable')
 local piano=assert(map:FindFirstChild('Piano',true),'Hotel piano missing');PianoGame.Initialize(map,remote);Collection:AddTag(piano,'StillHereInteractable')
 for _,object in ipairs(map:GetDescendants()) do if object:IsA('Model') and (object.Name=='Lamp' or object.Name=='Light') then registerLight(object) end end
 remote.OnServerEvent:Connect(function(player,action,value)
  if action=='interact' then Interactions.Interact(player,value)
  elseif action=='pool_shoot' then PoolGame.Shoot(player,value)
  elseif action=='pool_restart' then PoolGame.Restart(player)
  elseif action=='pool_exit' then PoolGame.Exit(player)
  elseif action=='piano_note' then PianoGame.Note(player,value)
  elseif action=='piano_song' then PianoGame.Song(player,value)
  elseif action=='piano_exit' then PianoGame.Exit(player)
  elseif action=='lamp' then
   local root=aliveRoot(player);local head=root and player.Character:FindFirstChild('Head')
   if not head or os.clock()-(cooldown[player] or -1)<.15 then return end;cooldown[player]=os.clock()
   local light=head:FindFirstChild('MysteryHeadlamp')
   if not light then light=Instance.new('SpotLight');light.Name='MysteryHeadlamp';light.Range=40;light.Angle=65;light.Brightness=2.2;light.Color=Color3.fromRGB(236,228,205);light.Shadows=false;light.Face=Enum.NormalId.Front;light.Enabled=false;light.Parent=head end
   light.Enabled=not light.Enabled;player:SetAttribute('HeadlampOn',light.Enabled)
  end
 end)
 local function playerAdded(player)
  player:SetAttribute('HeadlampOn',false)
  player.CharacterAdded:Connect(function() player:SetAttribute('HeadlampOn',false) end)
 end
 Players.PlayerAdded:Connect(playerAdded)
 for _,player in ipairs(Players:GetPlayers()) do playerAdded(player) end
end
return Interactions
