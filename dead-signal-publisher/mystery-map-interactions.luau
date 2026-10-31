local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local CollectionService=game:GetService('CollectionService')
local TweenService=game:GetService('TweenService')

local PoolGame=require(script.Parent.PoolGame)
local Interactions={}
local activeMap
local doors={}
local cooldown=setmetatable({},{__mode='k'})

local function aliveRoot(player)
	local character=player.Character
	local root=character and character:FindFirstChild('HumanoidRootPart')
	local humanoid=character and character:FindFirstChildOfClass('Humanoid')
	if not root or not humanoid or humanoid.Health<=0 then return nil end
	return root
end

local function hostFor(target)
	return target:FindFirstChild('Hitbox') or target.PrimaryPart
end

local function canReach(player,target,maximumDistance)
	if typeof(target)~='Instance' or not activeMap or not target:IsDescendantOf(activeMap) then return nil end
	local root=aliveRoot(player)
	local host=hostFor(target)
	if not root or not host or not host:IsA('BasePart') then return nil end
	if (root.Position-host.Position).Magnitude>(maximumDistance or 10) then return nil end
	local ray=RaycastParams.new()
	ray.FilterType=Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances={player.Character}
	ray.RespectCanCollide=true
	local hit=workspace:Raycast(root.Position,host.Position-root.Position,ray)
	if hit and not hit.Instance:IsDescendantOf(target) then return nil end
	return root,host
end

function Interactions.SetDoorOpen(door,open,instant)
	local state=doors[door]
	if not state or state.busy then return false end
	state.busy=true
	state.flag.Value=open
	door:SetAttribute('IsOpen',open)
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
		local tween=TweenService:Create(state.hinge,TweenInfo.new(.35,Enum.EasingStyle.Sine,open and Enum.EasingDirection.Out or Enum.EasingDirection.In),{CFrame=target})
		tween.Completed:Once(finish)
		tween:Play()
	end
	return true
end

local function toggleLight(target)
	local lights={}
	for _,object in ipairs(target:GetDescendants()) do
		if object:IsA('PointLight') or object:IsA('SpotLight') or object:IsA('SurfaceLight') then table.insert(lights,object) end
	end
	if #lights==0 then return false end
	local enabled=target:GetAttribute('IsLightOn')~=true
	for _,light in ipairs(lights) do light.Enabled=enabled end
	target:SetAttribute('IsLightOn',enabled)
	return true
end

function Interactions.Interact(player,target)
	if typeof(target)~='Instance' or not activeMap or not target:IsDescendantOf(activeMap) then return false end
	local kind=target:GetAttribute('InteractionKind')
	local root,host=canReach(player,target,kind=='PoolTable' and 11 or 10)
	if not root then return false end
	if os.clock()-(cooldown[player] or -1)<.25 then return false end
	cooldown[player]=os.clock()
	if kind=='Door' then
		local state=doors[target]
		if not state then return false end
		return Interactions.SetDoorOpen(target,not state.flag.Value)
	elseif kind=='PoolTable' then
		return PoolGame.Join(player)
	elseif kind=='Light' then
		return toggleLight(target)
	end
	return false
end

local function registerLight(target)
	local firstPart
	local hasLight=false
	local isOn=false
	for _,object in ipairs(target:GetDescendants()) do
		if not firstPart and object:IsA('BasePart') then firstPart=object end
		if object:IsA('PointLight') or object:IsA('SpotLight') or object:IsA('SurfaceLight') then
			hasLight=true
			isOn=isOn or object.Enabled
		end
	end
	if not hasLight or not firstPart then return false end
	target.PrimaryPart=target.PrimaryPart or firstPart
	target:SetAttribute('InteractionKind','Light')
	target:SetAttribute('IsLightOn',isOn)
	CollectionService:AddTag(target,'StillHereInteractable')
	return true
end

function Interactions.Initialize(map)
	if activeMap then assert(activeMap==map,'Interaction map already initialized');return end
	activeMap=map
	local remote=ReplicatedStorage:WaitForChild('MysteryUIAction')
	for _,door in ipairs(map:GetDescendants()) do
		if door:GetAttribute('InteractionKind')=='Door' then
			local hinge=assert(door:FindFirstChild('Hinge'))
			local hitbox=assert(door:FindFirstChild('Hitbox'))
			local flag=assert(door:FindFirstChild('Open'))
			for _,object in ipairs(door:GetDescendants()) do
				if object:IsA('ProximityPrompt') or object:IsA('ClickDetector') then object:Destroy() end
			end
			doors[door]={hinge=hinge,hitbox=hitbox,flag=flag,closed=hinge.CFrame,busy=false}
			Interactions.SetDoorOpen(door,flag.Value,true)
			CollectionService:AddTag(door,'StillHereInteractable')
		end
	end
	local poolTable=assert(map:FindFirstChild('PoolTable1',true),'Pool table not found')
	PoolGame.Initialize(map,remote)
	CollectionService:AddTag(poolTable,'StillHereInteractable')
	for _,object in ipairs(map:GetDescendants()) do
		if object:IsA('Model') and (object.Name=='Lamp' or object.Name=='Light') then registerLight(object) end
	end
	remote.OnServerEvent:Connect(function(player,action,target)
		if action=='interact' then Interactions.Interact(player,target)
		elseif action=='pool_shoot' then PoolGame.Shoot(player,target)
		elseif action=='pool_restart' then PoolGame.Restart(player)
		elseif action=='pool_exit' then PoolGame.Exit(player)
		elseif action=='lamp' then
			local root=aliveRoot(player)
			local head=root and player.Character:FindFirstChild('Head')
			if not head or os.clock()-(cooldown[player] or -1)<.15 then return end
			cooldown[player]=os.clock()
			local light=head:FindFirstChild('MysteryHeadlamp')
			if not light then
				light=Instance.new('SpotLight')
				light.Name='MysteryHeadlamp';light.Range=40;light.Angle=65;light.Brightness=2.2
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

return Interactions
