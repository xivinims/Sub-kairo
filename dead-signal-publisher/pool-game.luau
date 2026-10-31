local Players=game:GetService('Players')
local RunService=game:GetService('RunService')

local PoolGame={}
local state={}
local BALL_RADIUS=.21
local POCKET_RADIUS=.36
local BALL_COLORS={
	Color3.fromRGB(247,198,57),Color3.fromRGB(45,105,213),Color3.fromRGB(212,49,47),
	Color3.fromRGB(115,65,157),Color3.fromRGB(231,117,39),Color3.fromRGB(42,137,75),
	Color3.fromRGB(120,39,49),Color3.fromRGB(20,20,22),Color3.fromRGB(245,188,42),
	Color3.fromRGB(38,97,193),Color3.fromRGB(195,39,37),Color3.fromRGB(107,52,150),
	Color3.fromRGB(223,103,31),Color3.fromRGB(31,123,64),Color3.fromRGB(111,35,42),
}

local function characterRoot(player)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass('Humanoid')
	local root=character and character:FindFirstChild('HumanoidRootPart')
	if not humanoid or humanoid.Health<=0 or not root then return nil end
	return root
end

local function sendToOwner(action,payload)
	if state.owner and state.owner.Parent==Players then
		state.remote:FireClient(state.owner,action,payload)
	end
end

local function clearBalls()
	if not state.ballsFolder then return end
	for _,ball in ipairs(state.ballsFolder:GetChildren()) do ball:Destroy() end
	table.clear(state.balls)
end

local function makeBall(name,color,localPosition,isCue,number)
	local ball=Instance.new('Part')
	ball.Name=name
	ball.Shape=Enum.PartType.Ball
	ball.Size=Vector3.new(BALL_RADIUS*2,BALL_RADIUS*2,BALL_RADIUS*2)
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
	ball.CustomPhysicalProperties=PhysicalProperties.new(.8,.1,.86,1,1)
	ball:SetAttribute('IsCueBall',isCue)
	ball:SetAttribute('PoolNumber',number or 0)
	ball.Parent=state.ballsFolder
	pcall(function() ball:SetNetworkOwner(nil) end)
	table.insert(state.balls,ball)
	return ball
end

local function addTile(name,x0,x1,z0,z1)
	if x1-x0<.04 or z1-z0<.04 then return end
	local part=Instance.new('Part')
	part.Name=name
	part.Size=Vector3.new(x1-x0,.10,z1-z0)
	part.CFrame=state.surface.CFrame*CFrame.new((x0+x1)/2,-.05,(z0+z1)/2)
	part.Transparency=1
	part.Anchored=true
	part.CanCollide=true
	part.CanTouch=false
	part.CanQuery=false
	part.CastShadow=false
	part.Parent=state.collisionFolder
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
	part.Parent=state.collisionFolder
end

local function buildPlayfield()
	state.collisionFolder=Instance.new('Folder')
	state.collisionFolder.Name='InvisiblePlayfield'
	state.collisionFolder.Parent=state.rootFolder
	state.ballsFolder=Instance.new('Folder')
	state.ballsFolder.Name='Balls'
	state.ballsFolder.Parent=state.rootFolder
	local halfX=math.min(4.72,state.surface.Size.X/2-.9)
	local halfZ=math.min(1.95,state.surface.Size.Z/2-1.05)
	local innerX=halfX-.30
	local innerZ=halfZ-.30
	state.playHalfX=halfX
	state.playHalfZ=halfZ
	state.pocketPositions={
		Vector2.new(-halfX+.10,-halfZ+.10),Vector2.new(0,-halfZ+.10),Vector2.new(halfX-.10,-halfZ+.10),
		Vector2.new(-halfX+.10,halfZ-.10),Vector2.new(0,halfZ-.10),Vector2.new(halfX-.10,halfZ-.10),
	}
	addTile('PlayfieldCenter',-innerX,innerX,-innerZ,innerZ)
	addTile('PlayfieldLeftEnd',-halfX,-innerX,-innerZ,innerZ)
	addTile('PlayfieldRightEnd',innerX,halfX,-innerZ,innerZ)
	for _,sign in ipairs({-1,1}) do
		local z0=sign<0 and -halfZ or innerZ
		local z1=sign<0 and -innerZ or halfZ
		addTile('PlayfieldSideLeft',-innerX,-.39,z0,z1)
		addTile('PlayfieldSideRight',.39,innerX,z0,z1)
		addCushion('SideCushionLeft',Vector3.new(innerX-.39,.36,.14),Vector3.new(-(innerX+.39)/2,.18,sign*(halfZ+.02)))
		addCushion('SideCushionRight',Vector3.new(innerX-.39,.36,.14),Vector3.new((innerX+.39)/2,.18,sign*(halfZ+.02)))
		addCushion('EndCushion',Vector3.new(.14,.36,innerZ*2),Vector3.new(sign*(halfX+.02),.18,0))
	end
	for index,position in ipairs(state.pocketPositions) do
		local pocket=Instance.new('Part')
		pocket.Name='Pocket_'..index
		pocket.Shape=Enum.PartType.Cylinder
		pocket.Size=Vector3.new(POCKET_RADIUS*2,.018,POCKET_RADIUS*2)
		pocket.CFrame=state.surface.CFrame*CFrame.new(position.X,.009,position.Y)*CFrame.Angles(0,0,math.rad(90))
		pocket.Color=Color3.fromRGB(12,13,15)
		pocket.Material=Enum.Material.SmoothPlastic
		pocket.Anchored=true
		pocket.CanCollide=false
		pocket.CanTouch=false
		pocket.CanQuery=false
		pocket.CastShadow=false
		pocket.Parent=state.collisionFolder
	end
	state.table:SetAttribute('PoolGameReady',true)
	state.surface:SetAttribute('PoolSurface',true)
end

local function startGame()
	clearBalls()
	state.remaining=15
	state.cuePocketed=false
	state.shotActive=false
	local topOffset=state.surface.Size.Y/2+BALL_RADIUS+.012
	makeBall('CueBall',Color3.fromRGB(245,243,233),Vector3.new(-2.65,topOffset,0),true,0)
	local number=0
	for row=0,4 do
		for column=0,row do
			number+=1
			local x=2.25+row*(BALL_RADIUS*2+.018)
			local z=(column-row/2)*(BALL_RADIUS*2+.018)
			makeBall('Ball_'..number,BALL_COLORS[number],Vector3.new(x,topOffset,z),false,number)
		end
	end
end

local function isPocketed(ball)
	local localPoint=state.surface.CFrame:PointToObjectSpace(ball.Position)
	if localPoint.Y<-.65 or localPoint.Y>1.1 then return localPoint.Y<-.65 end
	for _,pocket in ipairs(state.pocketPositions) do
		if (Vector2.new(localPoint.X,localPoint.Z)-pocket).Magnitude<=POCKET_RADIUS then return true end
	end
	return false
end

local function removePocketedBalls()
	local remainingBalls={}
	for _,ball in ipairs(state.balls) do
		if ball.Parent and isPocketed(ball) then
			if ball:GetAttribute('IsCueBall') then state.cuePocketed=true
			else state.remaining=math.max(0,state.remaining-1) end
			ball:Destroy()
		elseif ball.Parent then
			table.insert(remainingBalls,ball)
		end
	end
	state.balls=remainingBalls
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
		if part:IsA('BasePart') and part.Size.X>10 and part.Size.Z>5 and part.Size.Y<.2 then
			part.CanCollide=false
		end
	end
	if not tableModel.PrimaryPart then tableModel.PrimaryPart=surface end
	tableModel:SetAttribute('InteractionKind','PoolTable')
	tableModel:SetAttribute('IsOpen',false)
	state.table=tableModel
	state.surface=surface
	state.remote=remote
	state.balls={}
	state.owner=nil
	state.initialized=true
	state.rootFolder=Instance.new('Folder')
	state.rootFolder.Name='StillHerePoolGame'
	state.rootFolder.Parent=workspace
	buildPlayfield()
	startGame()
	RunService.Heartbeat:Connect(function()
		if not state.shotActive then return end
		removePocketedBalls()
		local moving=false
		for _,ball in ipairs(state.balls) do
			if ball.Parent and ball.AssemblyLinearVelocity.Magnitude>.32 then moving=true;break end
		end
		if not moving and os.clock()-state.lastShot>.7 then
			if state.cuePocketed then
				local topOffset=state.surface.Size.Y/2+BALL_RADIUS+.012
				makeBall('CueBall',Color3.fromRGB(245,243,233),Vector3.new(-2.65,topOffset,0),true,0)
				state.cuePocketed=false
			end
			state.shotActive=false
			local message=state.remaining==0 and 'MESA LIMPA — NOVA PARTIDA DISPONÍVEL' or ('BOLAS RESTANTES: '..state.remaining)
			sendToOwner('pool_update',{remaining=state.remaining,message=message})
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if state.owner==player then state.owner=nil;state.shotActive=false end
	end)
end

function PoolGame.Join(player)
	if not state.initialized then return false end
	local root=characterRoot(player)
	if not root or (root.Position-state.surface.Position).Magnitude>11 then return false end
	if state.owner and state.owner~=player then
		state.remote:FireClient(player,'pool_busy')
		return false
	end
	state.owner=player
	startGame()
	state.remote:FireClient(player,'pool_open',{remaining=state.remaining,message='MIRE E AJUSTE A FORÇA DA TACADA'})
	return true
end

function PoolGame.Shoot(player,data)
	if state.owner~=player or state.shotActive or typeof(data)~='table' then return false end
	local root=characterRoot(player)
	if not root or (root.Position-state.surface.Position).Magnitude>14 then return false end
	local angle=math.clamp(tonumber(data.angle) or 0,-75,75)
	local power=math.clamp(tonumber(data.power) or .55,.12,1)
	local cue
	for _,ball in ipairs(state.balls) do if ball.Parent and ball:GetAttribute('IsCueBall') then cue=ball;break end end
	if not cue then return false end
	local radians=math.rad(angle)
	local direction=(state.surface.CFrame.RightVector*math.cos(radians)+state.surface.CFrame.LookVector*math.sin(radians)).Unit
	state.lastShot=os.clock()
	state.shotActive=true
	cue:ApplyImpulse(direction*cue.AssemblyMass*(12+power*40))
	sendToOwner('pool_update',{remaining=state.remaining,message='TACADA EM ANDAMENTO'})
	return true
end

function PoolGame.Restart(player)
	if state.owner~=player or state.shotActive then return false end
	local root=characterRoot(player)
	if not root or (root.Position-state.surface.Position).Magnitude>14 then return false end
	startGame()
	sendToOwner('pool_update',{remaining=state.remaining,message='MIRE E AJUSTE A FORÇA DA TACADA'})
	return true
end

function PoolGame.Exit(player)
	if state.owner~=player then return false end
	state.owner=nil
	state.shotActive=false
	state.remote:FireClient(player,'pool_close')
	return true
end

return PoolGame
