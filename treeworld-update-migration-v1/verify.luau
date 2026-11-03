local ServerScriptService=game:GetService("ServerScriptService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
assert(Workspace:GetAttribute("UpdateMigrationSystemVersion")=="1.0","Migration version missing")
assert(Workspace:GetAttribute("UpdateMigrationTopic")=="Overyard_Update_v1","Migration topic mismatch")

local remote=ReplicatedStorage:FindFirstChild("OveryardUpdateEvent")
assert(remote and remote:IsA("RemoteEvent"),"Update RemoteEvent missing")

local server=ServerScriptService:FindFirstChild("OveryardUpdateMigrationServer")
assert(server and server:IsA("Script"),"Update server script missing")
assert(string.find(server.Source,'MessagingService:SubscribeAsync(TOPIC',1,true),"Messaging subscription missing")
assert(string.find(server.Source,'options.ShouldReserveServer=true',1,true),"Reserved server migration missing")
assert(string.find(server.Source,'TeleportService:TeleportAsync(PLACE_ID,players,options)',1,true),"Group teleport missing")
assert(string.find(server.Source,'game.PlaceVersion>=targetVersion',1,true),"New-server version guard missing")

local client=ReplicatedFirst:FindFirstChild("OveryardUpdateMigrationClient")
assert(client and client:IsA("LocalScript"),"Update client script missing")
assert(string.find(client.Source,'OveryardUpdating',1,true),"Update loading GUI missing")
assert(string.find(client.Source,'rbxassetid://138675502621883',1,true),"Overyard logo missing")
assert(string.find(client.Source,'TeleportService:SetTeleportGui',1,true),"Teleport loading GUI missing")
assert(string.find(client.Source,'teleportData.overyardUpdate',1,true),"Arrival update loading missing")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	systemVersion=Workspace:GetAttribute("UpdateMigrationSystemVersion"),
	topic=Workspace:GetAttribute("UpdateMigrationTopic"),
	logoAssetId=138675502621883,
}
