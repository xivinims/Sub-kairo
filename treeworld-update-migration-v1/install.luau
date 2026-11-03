local AssetService=game:GetService("AssetService")
local ServerScriptService=game:GetService("ServerScriptService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
local sourceVersion=game.PlaceVersion

for _,name in ipairs({"OveryardUpdateEvent"}) do
	local old=ReplicatedStorage:FindFirstChild(name)
	if old then old:Destroy() end
end
for _,name in ipairs({"OveryardUpdateMigrationServer"}) do
	local old=ServerScriptService:FindFirstChild(name)
	if old then old:Destroy() end
end
for _,name in ipairs({"OveryardUpdateMigrationClient"}) do
	local old=ReplicatedFirst:FindFirstChild(name)
	if old then old:Destroy() end
end

local event=Instance.new("RemoteEvent")
event.Name="OveryardUpdateEvent"
event.Parent=ReplicatedStorage

local server=Instance.new("Script")
server.Name="OveryardUpdateMigrationServer"
server.Source=[=[
local Players=game:GetService("Players")
local MessagingService=game:GetService("MessagingService")
local TeleportService=game:GetService("TeleportService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")

local TOPIC="Overyard_Update_v1"
local PLACE_ID=game.PlaceId
local remote=ReplicatedStorage:WaitForChild("OveryardUpdateEvent")

local migrating=false
local activeRelease=nil
local retrying={}

local function decode(data)
	if type(data)=="table" then return data end
	if type(data)~="string" then return nil end
	local ok,value=pcall(function()
		return HttpService:JSONDecode(data)
	end)
	if ok and type(value)=="table" then return value end
	return nil
end

local function retryPlayer(player,placeId,options)
	if retrying[player] or not player.Parent then return end
	retrying[player]=true
	remote:FireClient(player,{
		phase="retry",
		title="Reconectando...",
		subtitle="Mantendo você no servidor da atualização."
	})
	task.wait(1.5)
	if player.Parent then
		local ok,err=pcall(function()
			TeleportService:TeleportAsync(placeId,{player},options)
		end)
		if not ok then
			warn("[Overyard Update] retry failed:",err)
			remote:FireClient(player,{
				phase="failed",
				title="Não foi possível atualizar agora",
				subtitle="Tentaremos novamente na próxima atualização."
			})
		end
	end
	retrying[player]=nil
end

TeleportService.TeleportInitFailed:Connect(function(player,result,errorMessage,placeId,teleportOptions)
	if not migrating then return end
	if placeId~=PLACE_ID then return end
	warn("[Overyard Update] teleport failed:",player.Name,tostring(result),errorMessage)
	task.spawn(retryPlayer,player,placeId,teleportOptions)
end)

local function migrate(payload)
	if migrating then return end
	if type(payload)~="table" then return end
	if payload.placeId and tonumber(payload.placeId)~=PLACE_ID then return end

	local targetVersion=tonumber(payload.targetPlaceVersion)
	if targetVersion and game.PlaceVersion>=targetVersion then
		return
	end

	migrating=true
	activeRelease=tostring(payload.releaseId or targetVersion or os.time())

	local players=Players:GetPlayers()
	if #players==0 then
		migrating=false
		return
	end

	remote:FireAllClients({
		phase="begin",
		title="Atualizando Overyard",
		subtitle="Levando todo mundo para o servidor novo...",
		targetPlaceVersion=targetVersion,
		releaseId=activeRelease
	})

	task.wait(2.25)

	players=Players:GetPlayers()
	if #players==0 then
		migrating=false
		return
	end

	local options=Instance.new("TeleportOptions")
	options.ShouldReserveServer=true
	options:SetTeleportData({
		overyardUpdate=true,
		releaseId=activeRelease,
		targetPlaceVersion=targetVersion,
		fromJobId=game.JobId,
	})

	local ok,result=pcall(function()
		return TeleportService:TeleportAsync(PLACE_ID,players,options)
	end)

	if not ok then
		warn("[Overyard Update] group teleport failed:",result)
		remote:FireAllClients({
			phase="failed",
			title="A atualização demorou um pouco",
			subtitle="O servidor continua aberto; vamos tentar de novo em instantes."
		})
		task.wait(3)
		migrating=false
	end
end

local ok,subscription=pcall(function()
	return MessagingService:SubscribeAsync(TOPIC,function(message)
		local payload=decode(message.Data)
		if payload then
			task.spawn(migrate,payload)
		end
	end)
end)

if not ok then
	warn("[Overyard Update] MessagingService subscription failed:",subscription)
else
	game:BindToClose(function()
		if subscription then
			pcall(function() subscription:Disconnect() end)
		end
	end)
end
]=]
server.Parent=ServerScriptService

local client=Instance.new("LocalScript")
client.Name="OveryardUpdateMigrationClient"
client.Source=[=[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TeleportService=game:GetService("TeleportService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("OveryardUpdateEvent")
local LOGO="rbxassetid://138675502621883"

local currentGui=nil
local spinConnection=nil

local function destroyGui()
	if spinConnection then
		spinConnection:Disconnect()
		spinConnection=nil
	end
	if currentGui then
		currentGui:Destroy()
		currentGui=nil
	end
end

local function build(titleText,subtitleText)
	destroyGui()

	local gui=Instance.new("ScreenGui")
	gui.Name="OveryardUpdating"
	gui.IgnoreGuiInset=true
	gui.ResetOnSpawn=false
	gui.DisplayOrder=20000
	gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

	local bg=Instance.new("Frame")
	bg.Size=UDim2.fromScale(1,1)
	bg.BorderSizePixel=0
	bg.BackgroundColor3=Color3.fromRGB(15,18,19)
	bg.Parent=gui

	local grad=Instance.new("UIGradient")
	grad.Rotation=90
	grad.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(42,50,50)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(12,15,16))
	})
	grad.Parent=bg

	local logo=Instance.new("ImageLabel")
	logo.AnchorPoint=Vector2.new(.5,.5)
	logo.Position=UDim2.fromScale(.5,.35)
	logo.Size=UDim2.new(.62,0,.25,0)
	logo.BackgroundTransparency=1
	logo.Image=LOGO
	logo.ScaleType=Enum.ScaleType.Fit
	logo.Parent=bg

	local title=Instance.new("TextLabel")
	title.AnchorPoint=Vector2.new(.5,.5)
	title.Position=UDim2.fromScale(.5,.58)
	title.Size=UDim2.new(.86,0,0,38)
	title.BackgroundTransparency=1
	title.Font=Enum.Font.GothamBold
	title.Text=titleText or "Atualizando Overyard"
	title.TextColor3=Color3.fromRGB(240,244,242)
	title.TextSize=22
	title.Parent=bg

	local sub=Instance.new("TextLabel")
	sub.AnchorPoint=Vector2.new(.5,.5)
	sub.Position=UDim2.fromScale(.5,.635)
	sub.Size=UDim2.new(.86,0,0,42)
	sub.BackgroundTransparency=1
	sub.Font=Enum.Font.Gotham
	sub.Text=subtitleText or "Levando todo mundo para o servidor novo..."
	sub.TextColor3=Color3.fromRGB(175,184,181)
	sub.TextSize=14
	sub.TextWrapped=true
	sub.Parent=bg

	local ring=Instance.new("Frame")
	ring.Name="Spinner"
	ring.AnchorPoint=Vector2.new(.5,.5)
	ring.Position=UDim2.fromScale(.5,.735)
	ring.Size=UDim2.fromOffset(34,34)
	ring.BackgroundTransparency=1
	ring.Parent=bg

	local stroke=Instance.new("UIStroke")
	stroke.Thickness=4
	stroke.Color=Color3.fromRGB(94,171,107)
	stroke.Transparency=.05
	stroke.Parent=ring

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(1,0)
	corner.Parent=ring

	local mask=Instance.new("Frame")
	mask.Size=UDim2.new(.5,7,.5,7)
	mask.Position=UDim2.fromOffset(-6,-6)
	mask.BackgroundColor3=bg.BackgroundColor3
	mask.BorderSizePixel=0
	mask.Parent=ring

	spinConnection=RunService.RenderStepped:Connect(function(dt)
		if ring.Parent then ring.Rotation=(ring.Rotation+dt*210)%360 end
	end)

	currentGui=gui
	gui.Parent=player:WaitForChild("PlayerGui")
	return gui,title,sub
end

local function fadeAndDestroy(gui)
	for _,obj in ipairs(gui:GetDescendants()) do
		if obj:IsA("TextLabel") then
			TweenService:Create(obj,TweenInfo.new(.35),{TextTransparency=1}):Play()
		elseif obj:IsA("ImageLabel") then
			TweenService:Create(obj,TweenInfo.new(.35),{ImageTransparency=1}):Play()
		elseif obj:IsA("Frame") and obj.Name~="Spinner" then
			TweenService:Create(obj,TweenInfo.new(.35),{BackgroundTransparency=1}):Play()
		elseif obj:IsA("UIStroke") then
			TweenService:Create(obj,TweenInfo.new(.35),{Transparency=1}):Play()
		end
	end
	task.wait(.4)
	destroyGui()
end

remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" then return end
	if data.phase=="begin" then
		local gui=build(data.title,data.subtitle)
		local teleportGui=gui:Clone()
		teleportGui.Name="OveryardUpdateTeleport"
		pcall(function()
			TeleportService:SetTeleportGui(teleportGui)
		end)
	elseif data.phase=="retry" then
		if currentGui then
			local sub=currentGui:FindFirstChild("Background") and currentGui.Background:FindFirstChildWhichIsA("TextLabel")
		end
	elseif data.phase=="failed" then
		local gui=build(data.title,data.subtitle)
		task.delay(2.5,function()
			if gui==currentGui then fadeAndDestroy(gui) end
		end)
	end
end)

local teleportData=nil
pcall(function()
	teleportData=TeleportService:GetLocalPlayerTeleportData()
end)

if type(teleportData)=="table" and teleportData.overyardUpdate then
	local gui=build("Aplicando atualização...","Servidor novo encontrado. Carregando a versão atualizada.")
	if not game:IsLoaded() then game.Loaded:Wait() end
	task.wait(.75)
	if gui==currentGui then
		fadeAndDestroy(gui)
	end
end
]=]
client.Parent=ReplicatedFirst

Workspace:SetAttribute("UpdateMigrationSystemVersion","1.0")
Workspace:SetAttribute("UpdateMigrationTopic","Overyard_Update_v1")
Workspace:SetAttribute("UpdateMigrationInstalledAtPlaceVersion",sourceVersion)

AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	topic="Overyard_Update_v1",
	serverScript=server.Name,
	clientScript=client.Name,
	logoAssetId=138675502621883,
}
