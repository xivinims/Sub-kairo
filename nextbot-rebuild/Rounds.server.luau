local Players=game:GetService('Players')
local Storage=game:GetService('ServerStorage')
local Replicated=game:GetService('ReplicatedStorage')
local Pathfinding=game:GetService('PathfindingService')
local Collection=game:GetService('CollectionService')
local package=Replicated:WaitForChild('NextbotReference')
local config=require(package.Config)
local State=require(package.RoundState)
local remote=package:WaitForChild('MatchAction')
local state=State.new(workspace:GetServerTimeNow(),config.Intermission,config.RoundDuration)
local admitted,cooldowns,bots={},{},{}
local function markers(name)
	local folder=workspace:FindFirstChild(name)
	local result={}
	if folder then for _,v in ipairs(folder:GetChildren()) do if v:IsA('BasePart') then table.insert(result,v) end end end
	return result
end
local function teleport(player,name)
	local points=markers(name);local character=player.Character
	if #points==0 or not character then return false end
	character:PivotTo(points[math.random(#points)].CFrame+Vector3.new(0,3,0))
	local root=character:FindFirstChild('HumanoidRootPart')
	if root then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	return true
end
local function publish()
	package:SetAttribute('Phase',state.phase)
	package:SetAttribute('Deadline',state.deadline)
	package:SetAttribute('Round',state.round)
end
local function setActive(p,active)
	p:SetAttribute('NBInRound',active)
	local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
	if h then h.WalkSpeed=config.WalkSpeed end
end
local function clearBots()
	for _,bot in ipairs(bots) do bot:Destroy() end
	table.clear(bots)
end
local function targetFrom(position)
	local closest,distance=nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		local char=p.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local h=char and char:FindFirstChildOfClass('Humanoid')
		if p:GetAttribute('NBInRound') and root and h and h.Health>0 then
			local d=(root.Position-position).Magnitude
			if d<distance then closest=root;distance=d end
		end
	end
	local folder=workspace:FindFirstChild('NBDecoys')
	if folder then for _,decoy in ipairs(folder:GetChildren()) do
		local root=decoy:FindFirstChild('HumanoidRootPart');local h=decoy:FindFirstChildOfClass('Humanoid')
		if root and h and h.Health>0 then local d=(root.Position-position).Magnitude;if d<distance then closest=root;distance=d end end
	end end
	return closest,distance
end
local function startBots()
	local templates=Storage:FindFirstChild('NextbotTemplates');local points=markers('NextbotSpawns')
	if not templates or #points==0 then return end
	for i,template in ipairs(templates:GetChildren()) do
		if i>4 then break end
		local bot=template:Clone()
		-- Only our controller runs. Imported asset scripts are never trusted implicitly.
		for _,v in ipairs(bot:GetDescendants()) do if v:IsA('LuaSourceContainer') then v:Destroy() end end
		local h=bot:FindFirstChildOfClass('Humanoid');local root=bot:FindFirstChild('HumanoidRootPart')
		if not bot:IsA('Model') or not h or not root then bot:Destroy();continue end
		bot:PivotTo(points[(i-1)%#points+1].CFrame+Vector3.new(0,3,0));bot.Parent=workspace;Collection:AddTag(bot,'NBNextbot')
		for _,part in ipairs(bot:GetDescendants()) do
			if part:IsA('BasePart') and not part.Anchored then pcall(function()part:SetNetworkOwner(nil)end) end
		end
		h.WalkSpeed=30;table.insert(bots,bot)
		task.spawn(function()
			while bot.Parent and state.phase=='Round' do
				local target,distance=targetFrom(root.Position)
				if target then
					if distance<4 then
						local ray=RaycastParams.new();ray.FilterDescendantsInstances={bot};ray.FilterType=Enum.RaycastFilterType.Exclude
						local hit=workspace:Raycast(root.Position,target.Position-root.Position,ray)
						if not hit or hit.Instance:IsDescendantOf(target.Parent) then
							local victim=target.Parent:FindFirstChildOfClass('Humanoid');if victim then victim.Health=0 end
						end
					else
						local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
						local ok=pcall(function()path:ComputeAsync(root.Position,target.Position)end)
						if not bot.Parent or state.phase~='Round' then break end
						local waypoints=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints() or {}
						local nextPoint=waypoints[2]
						if nextPoint then h.Jump=nextPoint.Action==Enum.PathWaypointAction.Jump;h:MoveTo(nextPoint.Position) end
					end
				end
				task.wait(.35)
			end
		end)
	end
end
local function setup(p)
	setActive(p,false)
	p.CharacterAdded:Connect(function(char)
		local h=char:WaitForChild('Humanoid',10)
		char:WaitForChild('HumanoidRootPart',10)
		if not p.Parent then return end
		setActive(p,false);teleport(p,'LobbySpawns')
		if h then h.Died:Connect(function()setActive(p,false)end) end
	end)
end
Players.PlayerAdded:Connect(setup)
for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerRemoving:Connect(function(p)admitted[p]=nil;cooldowns[p]=nil end)
remote.OnServerEvent:Connect(function(p,action)
	if action~='Join' and action~='Lobby' then return end
	local now=os.clock();if now-(cooldowns[p] or -10)<1 then return end;cooldowns[p]=now
	if action=='Lobby' then admitted[p]=nil;setActive(p,false);teleport(p,'LobbySpawns')
	else
		admitted[p]=true
		local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
		if state.phase=='Round' and h and h.Health>0 and teleport(p,'RoundSpawns') then setActive(p,true) end
	end
	p:SetAttribute('NBQueued',admitted[p]==true)
end)
publish()
while true do
	local ready=next(admitted)~=nil and #markers('RoundSpawns')>0 and #markers('LobbySpawns')>0
	package:SetAttribute('MapReady',#markers('RoundSpawns')>0 and #markers('LobbySpawns')>0)
	if State.tick(state,workspace:GetServerTimeNow(),ready) then
		clearBots()
		publish() -- Replicate the new round ID before equipment consumption.
		for _,p in ipairs(Players:GetPlayers()) do
			local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
			if state.phase=='Round' and admitted[p] and h and h.Health>0 and teleport(p,'RoundSpawns') then setActive(p,true)
			else setActive(p,false);teleport(p,'LobbySpawns') end
		end
		if state.phase=='Round' then startBots() end
		publish()
	end
	task.wait(.2)
end
