local Players=game:GetService('Players')
local RunService=game:GetService('RunService')

local PoolGame={}
local state={}
local BALL_RADIUS=.205
local BALL_DIAMETER=BALL_RADIUS*2
local COLORS={
	Color3.fromRGB(240,190,45),Color3.fromRGB(45,101,202),Color3.fromRGB(207,48,47),
	Color3.fromRGB(114,65,153),Color3.fromRGB(224,111,34),Color3.fromRGB(42,132,71),
	Color3.fromRGB(114,39,46),Color3.fromRGB(22,22,23),Color3.fromRGB(240,190,45),
	Color3.fromRGB(45,101,202),Color3.fromRGB(207,48,47),Color3.fromRGB(114,65,153),
	Color3.fromRGB(224,111,34),Color3.fromRGB(42,132,71),Color3.fromRGB(114,39,46),
}

local function characterRoot(player)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass('Humanoid')
	local root=character and character:FindFirstChild('HumanoidRootPart')
	if not humanoid or humanoid.Health<=0 or not root then return nil end
	return root
end

local function playersInSession()
	local session=state.session
	if not session then return {} end
	local result={}
	if session.host and session.host.Parent==Players then table.insert(result,session.host) end
	if session.friend and session.friend.Parent==Players then table.insert(result,session.friend) end
	return result
end

local function sendUpdate(message)
	local session=state.session
	if not session then return end
	for _,player in ipairs(playersInSession()) do
		state.remote:FireClient(player,'pool_update',{
			remaining=state.remaining,
			message=message,
			waiting=session.waiting==true,
			turn=session.turn=='npc' and 'RECEPCIONISTA' or (session.turn and session.turn.DisplayName or 'AGUARDANDO'),
			canShoot=session.turn==player,
		})
	end
end

local function clearBalls()
	for _,ball in ipairs(state.ballsFolder:GetChildren()) do ball:Destroy() end
	table.clear(state.balls)
end

local function makeBall(name,color,localPosition,isCue,number)
	local ball=Instance.new('Part')
	ball.Name=name
	ball.Shape=Enum.PartType.Ball
	ball.Size=Vector3.new(BALL_DIAMETER,BALL_DIAMETER,BALL_DIAMETER)
	ball.CFrame=state.surface.CFrame*CFrame.new(localPosition)
	ball.Color=color
	ball.Material=Enum.Material.SmoothPlastic
	ball.TopSurface=Enum.SurfaceType.Smooth
	ball.BottomSurface=Enum.SurfaceType.Smooth
	ball.Anchored=false
	ball.CanCollide=true
	ball.CanTouch=true
	ball.CanQuery=true
	ball.CastShadow=true
	ball.CustomPhysicalProperties=PhysicalProperties.new(.42,.12,.78,1,1)
	ball:SetAttribute('IsCueBall',isCue)
	ball:SetAttribute('PoolNumber',number or 0)
	ball.Parent=state.ballsFolder
	pcall(function() ball:SetNetworkOwner(nil) end)
	ball.Touched:Connect(function(other)
		if not other:IsDescendantOf(state.ballsFolder) then return end
		local now=os.clock()
		if now-(state.lastImpact or 0)<.095 then return end
		local speed=ball.AssemblyLinearVelocity.Magnitude
		if speed<2.6 then return end
		state.lastImpact=now
		state.remote:FireAllClients('pool_impact',{position=ball.Position,speed=math.clamp(speed/20,.25,1)})
	end)
	table.insert(state.balls,ball)
	return ball
end

local function addTile(name,x0,x1,z0,z1)
	if x1-x0<.04 or z1-z0<.04 then return end
	local tile=Instance.new('Part')
	tile.Name=name
	tile.Size=Vector3.new(x1-x0,.10,z1-z0)
	tile.CFrame=state.surface.CFrame*CFrame.new((x0+x1)/2,state.surface.Size.Y/2-.05,(z0+z1)/2)
	tile.Transparency=1
	tile.Anchored=true
	tile.CanCollide=true
	tile.CanTouch=false
	tile.CanQuery=false
	tile.CastShadow=false
	tile.CustomPhysicalProperties=PhysicalProperties.new(.7,.18,.02,1,1)
	tile.Parent=state.collisionFolder
end

local function addCushion(name,size,localPosition)
	local part=Instance.new('Part')
	part.Name=name
	part.Size=size
	part.CFrame=state.surface.CFrame*CFrame.new(localPosition)
	part.Transparency=1
	part.Anchored=true
	part.CanCollide=true
	part.CanTouch=false
	part.CanQuery=false
	part.CastShadow=false
	part.CustomPhysicalProperties=PhysicalProperties.new(.7,.12,.72,1,1)
	part.Parent=state.collisionFolder
end

local function addPocketVisual(index,position,radius)
	local hole=Instance.new('Part')
	hole.Name='PocketVisual_'..index
	hole.Shape=Enum.PartType.Cylinder
	hole.Size=Vector3.new(radius*2,.018,radius*2)
	hole.CFrame=state.surface.CFrame*CFrame.new(position.X,state.surface.Size.Y/2+.012,position.Y)*CFrame.Angles(0,0,math.rad(90))
	hole.Color=Color3.fromRGB(9,10,11)
	hole.Material=Enum.Material.SmoothPlastic
	hole.Anchored=true
	hole.CanCollide=false
	hole.CanTouch=false
	hole.CanQuery=false
	hole.CastShadow=false
	hole.Parent=state.visualFolder
end

local function buildPlayfield()
	state.collisionFolder=Instance.new('Folder')
	state.collisionFolder.Name='InvisiblePlayfield'
	state.collisionFolder.Parent=state.rootFolder
	state.visualFolder=Instance.new('Folder')
	state.visualFolder.Name='PocketDetails'
	state.visualFolder.Parent=state.rootFolder
	state.ballsFolder=Instance.new('Folder')
	state.ballsFolder.Name='Balls'
	state.ballsFolder.Parent=state.rootFolder

	local halfX=math.min(4.72,state.surface.Size.X/2-.72)
	local halfZ=math.min(1.95,state.surface.Size.Z/2-.72)
	assert(halfX>2.8 and halfZ>1.05,'Pool table dimensions are too small')
	local innerX=halfX-.58
	local innerZ=halfZ-.58
	state.playHalfX=halfX
	state.playHalfZ=halfZ
	state.pocketPositions={
		{point=Vector2.new(-halfX+.10,-halfZ+.10),radius=.39},
		{point=Vector2.new(0,-halfZ+.10),radius=.34},
		{point=Vector2.new(halfX-.10,-halfZ+.10),radius=.39},
		{point=Vector2.new(-halfX+.10,halfZ-.10),radius=.39},
		{point=Vector2.new(0,halfZ-.10),radius=.34},
		{point=Vector2.new(halfX-.10,halfZ-.10),radius=.39},
	}

	-- The center is one continuous lane; the side and end rails are split around
	-- the six pocket mouths so a ball can actually drop instead of disappearing.
	addTile('CenterLane',-innerX,innerX,-innerZ,innerZ)
	addTile('LeftEndLane',-halfX,-innerX,-innerZ,innerZ)
	addTile('RightEndLane',innerX,halfX,-innerZ,innerZ)
	for _,sign in ipairs({-1,1}) do
		local z0=sign<0 and -halfZ or innerZ
		local z1=sign<0 and -innerZ or halfZ
		addTile('SideLaneLeft',-innerX,-.52,z0,z1)
		addTile('SideLaneRight',.52,innerX,z0,z1)
		addCushion('LongRailLeft',Vector3.new(innerX-.48,.30,.13),Vector3.new(-(innerX+.48)/2,state.surface.Size.Y/2+.14,sign*(halfZ+.02)))
		addCushion('LongRailRight',Vector3.new(innerX-.48,.30,.13),Vector3.new((innerX+.48)/2,state.surface.Size.Y/2+.14,sign*(halfZ+.02)))
		addCushion('EndRail',Vector3.new(.13,.30,innerZ*2),Vector3.new(sign*(halfX+.02),state.surface.Size.Y/2+.14,0))
	end
	for index,pocket in ipairs(state.pocketPositions) do addPocketVisual(index,pocket.point,pocket.radius) end
	state.table:SetAttribute('PoolGameReady',true)
	state.surface:SetAttribute('PoolSurface',true)
end

local function makeCueBall()
	local top=state.surface.Size.Y/2+BALL_RADIUS+.012
	return makeBall('CueBall',Color3.fromRGB(244,242,233),Vector3.new(-2.65,top,0),true,0)
end

local function startGame()
	clearBalls()
	state.remaining=15
	state.cuePocketed=false
	state.shotActive=false
	state.lastShot=os.clock()
	makeCueBall()
	local order={1,2,3,4,8,5,6,7,9,10,11,12,13,14,15}
	local step=BALL_DIAMETER+0.004
	local slot=0
	for row=0,4 do
		for column=0,row do
			slot+=1
			local number=order[slot]
			local x=2.08+row*step
			local z=(column-row/2)*step
			makeBall('Ball_'..number,COLORS[number],Vector3.new(x,state.surface.Size.Y/2+BALL_RADIUS+.012,z),false,number)
		end
	end
end

local function markFallingBalls()
	local localTop=state.surface.Size.Y/2+BALL_RADIUS*.55
	for _,ball in ipairs(state.balls) do
		if ball.Parent and not ball:GetAttribute('Pocketed') then
			local point=state.surface.CFrame:PointToObjectSpace(ball.Position)
			if point.Y<-0.72 then
				ball:SetAttribute('Pocketed',true)
			elseif point.Y<localTop then
				for _,pocket in ipairs(state.pocketPositions) do
					if (Vector2.new(point.X,point.Z)-pocket.point).Magnitude<=pocket.radius*.92 then
						ball:SetAttribute('Pocketed',true)
						ball.CanCollide=false
						ball.AssemblyLinearVelocity+=Vector3.new(0,-2.2,0)
						break
					end
				end
			end
		end
	end
end

local function removePocketedBalls()
	local survivors={}
	for _,ball in ipairs(state.balls) do
		if ball.Parent then
			local point=state.surface.CFrame:PointToObjectSpace(ball.Position)
			if ball:GetAttribute('Pocketed') and point.Y<-0.35 then
				if ball:GetAttribute('IsCueBall') then state.cuePocketed=true
				else state.remaining=math.max(0,state.remaining-1) end
				ball:Destroy()
			elseif point.Y<-2.5 then
				if ball:GetAttribute('IsCueBall') then state.cuePocketed=true
				else state.remaining=math.max(0,state.remaining-1) end
				ball:Destroy()
			else
				table.insert(survivors,ball)
			end
		end
	end
	state.balls=survivors
end

local function resetCueIfPocketed()
	if not state.cuePocketed then return end
	local cue=makeCueBall()
	cue.CFrame=state.surface.CFrame*CFrame.new(-2.65,state.surface.Size.Y/2+BALL_RADIUS+.012,0)
	state.cuePocketed=false
end

local function clearPlayerMode(player)
	if player and player.Parent==Players then player:SetAttribute('HotelInteractionMode',nil) end
end

local function closeSession(reason)
	local participants=playersInSession()
	state.session=nil
	state.shotActive=false
	for _,player in ipairs(participants) do
		clearPlayerMode(player)
		state.remote:FireClient(player,'pool_close',{reason=reason})
	end
end

local function validStart(player)
	local root=characterRoot(player)
	if not root then return false end
	local receptionist=workspace:FindFirstChild('HotelActors')
		receptionist=receptionist and receptionist:FindFirstChild('HotelReceptionist')
	local nearTable=(root.Position-state.surface.Position).Magnitude<=15
	local npcRoot=receptionist and (receptionist:FindFirstChild('HumanoidRootPart') or receptionist.PrimaryPart)
	local nearNPC=npcRoot and (root.Position-npcRoot.Position).Magnitude<=10
	return nearTable or nearNPC
end

local function openFor(player,message)
	player:SetAttribute('HotelInteractionMode','Pool')
	state.remote:FireClient(player,'pool_open',{
		remaining=state.remaining,
		surface=state.surface,
		size=state.surface.Size,
		halfX=state.playHalfX,
		halfZ=state.playHalfZ,
		mode=state.session.mode,
		waiting=state.session.waiting==true,
		message=message,
	})
end

local function hasAllBallsStopped()
	for _,ball in ipairs(state.balls) do
		if ball.Parent and ball.AssemblyLinearVelocity.Magnitude>.24 then return false end
	end
	return true
end

local function ballDirection(fromBall,toBall)
	local offset=toBall.Position-fromBall.Position
	local flat=Vector3.new(offset.X,0,offset.Z)
	if flat.Magnitude<.05 then return state.surface.CFrame.RightVector end
	return flat.Unit
end

local function fireShot(direction,power)
	local cue
	for _,ball in ipairs(state.balls) do
		if ball.Parent and ball:GetAttribute('IsCueBall') and not ball:GetAttribute('Pocketed') then cue=ball;break end
	end
	if not cue then return false end
	local horizontal=Vector3.new(direction.X,0,direction.Z)
	if horizontal.Magnitude<.05 then return false end
	horizontal=horizontal.Unit
	local speed=7+math.clamp(power,.08,1)*19
	state.lastShot=os.clock()
	state.shotActive=true
	cue:ApplyImpulse(horizontal*cue.AssemblyMass*speed)
	state.remote:FireAllClients('pool_strike',{position=cue.Position,speed=speed/26})
	return true
end

local function takeNpcTurn(sessionToken)
	task.wait(.9)
	local session=state.session
	if not session or session.token~=sessionToken or session.mode~='npc' or session.turn~='npc' or state.shotActive then return end
	local cue
	local objects={}
	for _,ball in ipairs(state.balls) do
		if ball.Parent and not ball:GetAttribute('Pocketed') then
			if ball:GetAttribute('IsCueBall') then cue=ball else table.insert(objects,ball) end
		end
	end
	if not cue or #objects==0 then
		session.turn=session.host
		sendUpdate(state.remaining==0 and 'MESA LIMPA — REINICIE PARA JOGAR DE NOVO' or 'SUA VEZ')
		return
	end
	local target=objects[1]
	local closest=(target.Position-cue.Position).Magnitude
	for index=2,#objects do
		local distance=(objects[index].Position-cue.Position).Magnitude
		if distance<closest then target=objects[index];closest=distance end
	end
	local direction=ballDirection(cue,target)
	sendUpdate('O RECEPCIONISTA ESTÁ PREPARANDO A TACADA')
	fireShot(direction,.43+math.random()*.24)
end

local function inviteFriend(session,player)
	if not session or session~=state.session or session.mode~='friend' or not session.waiting then return false end
	if not player or player==session.host or player.Parent~=Players or not session.invitedIds[player.UserId] then return false end
	local isFriend=false
	local ok,result=pcall(function() return session.host:IsFriendsWithAsync(player.UserId) end)
	if ok then isFriend=result end
	if not isFriend then return false end
	local hostRoot=characterRoot(session.host)
	if not hostRoot then return false end
	local deadline=os.clock()+12
	while player.Parent==Players and not player.Character and os.clock()<deadline do task.wait(.1) end
	local character=player.Character
	local friendRoot=character and character:FindFirstChild('HumanoidRootPart')
	if not friendRoot and character then friendRoot=character:WaitForChild('HumanoidRootPart',10) end
	if not friendRoot or state.session~=session or not session.waiting then return false end
	local side=hostRoot.CFrame.RightVector*3
	local spawnPosition=hostRoot.Position+side
	friendRoot.AssemblyLinearVelocity=Vector3.zero
	friendRoot.CFrame=CFrame.lookAt(spawnPosition,hostRoot.Position+Vector3.new(0,1.3,0))
	session.friend=player
	session.waiting=false
	session.turn=session.host
	player:SetAttribute('HotelInteractionMode','Pool')
	openFor(player,'Você chegou! O recepcionista acompanha a partida.')
	sendUpdate('AMIGO CONECTADO — VEZ DE QUEM CONVIDOU')
	return true
end

local function checkPendingFriends(session)
	for _,candidate in ipairs(Players:GetPlayers()) do
		if session.invitedIds[candidate.UserId] then inviteFriend(session,candidate);return end
	end
end

local function isValidInviteId(value)
	local id=tonumber(value)
	if not id or id<1 or id%1~=0 then return nil end
	return id
end

function PoolGame.Initialize(map,remote)
	assert(not state.initialized,'Pool game already initialized')
	local tableModel=assert(map:FindFirstChild('PoolTable1',true),'Hotel pool table is missing')
	local surface
	for _,part in ipairs(tableModel:GetDescendants()) do
		if part:IsA('BasePart') and part.Size.X>10 and part.Size.Z>5 and part.Size.Y<.01 then surface=part;break end
	end
	assert(surface,'Pool table felt surface is missing')
	for _,part in ipairs(tableModel:GetDescendants()) do
		if part:IsA('BasePart') and part.Size.X>10 and part.Size.Z>5 and part.Size.Y<.2 then part.CanCollide=false end
	end
	if not tableModel.PrimaryPart then tableModel.PrimaryPart=surface end
	tableModel:SetAttribute('InteractionKind','PoolTable')
	tableModel:SetAttribute('IsOpen',false)
	state.table=tableModel
	state.surface=surface
	state.remote=remote
	state.balls={}
	state.session=nil
	state.initialized=true
	state.rootFolder=Instance.new('Folder')
	state.rootFolder.Name='StillHerePoolGame'
	state.rootFolder.Parent=workspace
	buildPlayfield()
	startGame()

	RunService.Heartbeat:Connect(function()
		if not state.shotActive then return end
		markFallingBalls()
		removePocketedBalls()
		if hasAllBallsStopped() and os.clock()-(state.lastShot or 0)>.72 then
			resetCueIfPocketed()
			state.shotActive=false
			local session=state.session
			if not session then return end
			if session.mode=='npc' then
				if session.turn=='npc' then
					session.turn=session.host
					sendUpdate(state.remaining==0 and 'MESA LIMPA — PULE PARA ENCERRAR OU REINICIE' or 'SUA VEZ')
				else
					session.turn='npc'
					sendUpdate(state.remaining==0 and 'MESA LIMPA — ÚLTIMA TACADA DO RECEPCIONISTA' or 'VEZ DO RECEPCIONISTA')
					task.spawn(takeNpcTurn,session.token)
				end
			elseif session.mode=='friend' then
				session.turn=session.turn==session.host and session.friend or session.host
				local active=session.turn
				sendUpdate((active and active.DisplayName or 'JOGADOR')..' — SUA VEZ')
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local session=state.session
		if session and (session.host==player or session.friend==player) then closeSession('O outro jogador saiu da partida.') end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local session=state.session
			if not session or not session.waiting then return end
			if session.invitedIds[player.UserId] then
				inviteFriend(session,player)
			elseif os.clock()<session.inviteUntil then
				local ok,isFriend=pcall(function() return session.host:IsFriendsWithAsync(player.UserId) end)
				if ok and isFriend and state.session==session and session.waiting then
					table.insert(session.unselectedFriends,player)
				end
			end
		end)
	end)
end

function PoolGame.StartNPC(player)
	if not state.initialized or not validStart(player) then return false end
	if state.session then state.remote:FireClient(player,'pool_busy');return false end
	startGame()
	local session={host=player,mode='npc',turn=player,waiting=false,token={},unselectedFriends={}}
	state.session=session
	openFor(player,'OLA! MIRE, SEGURE O BOTÃO CIRCULAR E SOLTE PARA TACAR.')
	return true
end

function PoolGame.StartFriend(player)
	if not state.initialized or not validStart(player) then return false end
	if state.session then state.remote:FireClient(player,'pool_busy');return false end
	startGame()
	local session={host=player,mode='friend',turn=nil,waiting=true,token={},inviteUntil=os.clock()+120,invitedIds={},unselectedFriends={}}
	state.session=session
	openFor(player,'ESCOLHA SEU AMIGO NO CONVITE PADRÃO DO ROBLOX.')
	state.remote:FireClient(player,'pool_invite_ready')
	task.delay(120,function()
		if state.session==session and session.waiting then
			state.remote:FireClient(player,'pool_wait_timeout')
			closeSession('O convite expirou. Fale comigo novamente para tentar outra vez.')
		end
	end)
	return true
end

function PoolGame.SetInviteRecipients(player,values)
	local session=state.session
	if not session or session.host~=player or session.mode~='friend' or not session.waiting then return false end
	if typeof(values)~='table' then return false end
	local count=0
	for _,value in ipairs(values) do
		local userId=isValidInviteId(value)
		if userId then session.invitedIds[userId]=true;count+=1 end
		if count>=50 then break end
	end
	if count==0 then
		closeSession('Nenhum amigo foi selecionado no convite.')
		return true
	end
	checkPendingFriends(session)
	for _,candidate in ipairs(session.unselectedFriends) do
		if state.session==session then inviteFriend(session,candidate);if session.friend then break end end
	end
	return true
end

function PoolGame.CancelFriend(player)
	local session=state.session
	if session and session.host==player and session.mode=='friend' and session.waiting then
		closeSession('Convite cancelado.')
		return true
	end
	return false
end

function PoolGame.Shoot(player,data)
	local session=state.session
	if not session or session.turn~=player or state.shotActive or typeof(data)~='table' then return false end
	local root=characterRoot(player)
	if not root or (root.Position-state.surface.Position).Magnitude>15 then return false end
	local angle=math.clamp(tonumber(data.angle) or 0,-48,48)
	local power=math.clamp(tonumber(data.power) or .52,.08,1)
	local radians=math.rad(angle)
	local direction=(state.surface.CFrame.RightVector*math.cos(radians)+state.surface.CFrame.LookVector*math.sin(radians)).Unit
	local success=fireShot(direction,power)
	if success then sendUpdate('TACADA EM ANDAMENTO') end
	return success
end

function PoolGame.Restart(player)
	local session=state.session
	if not session or session.host~=player or state.shotActive then return false end
	local root=characterRoot(player)
	if not root or (root.Position-state.surface.Position).Magnitude>15 then return false end
	startGame()
	session.turn=session.host
	sendUpdate('NOVA PARTIDA — MIRE E SOLTE PARA TACAR')
	return true
end

function PoolGame.Exit(player)
	local session=state.session
	if not session or (session.host~=player and session.friend~=player) then return false end
	closeSession('Partida encerrada pelo jogador.')
	return true
end

return PoolGame
