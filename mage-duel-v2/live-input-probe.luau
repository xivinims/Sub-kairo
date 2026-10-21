local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterPack=game:GetService("StarterPack")
local ServerScriptService=game:GetService("ServerScriptService")
local world=workspace:FindFirstChild("MageDuelWorld")
local boss=world and world:FindFirstChild("AstraVeyra")
local tool=StarterPack:FindFirstChild("AstralStaff")
local remoteFolder=ReplicatedStorage:FindFirstChild("MageDuelRemotes")
local cast=remoteFolder and remoteFolder:FindFirstChild("Cast")
local server=ServerScriptService:FindFirstChild("MageDuelServer")
local client=tool and tool:FindFirstChild("MageDuelClient")
return {
 placeVersion=game.PlaceVersion,
 build=workspace:GetAttribute("BuildVersion"),
 boss= boss~=nil,
 bossHRP= boss and boss:FindFirstChild("HumanoidRootPart")~=nil or false,
 tool=tool~=nil,
 requiresHandle=tool and tool.RequiresHandle or nil,
 handle=tool and tool:FindFirstChild("Handle")~=nil or false,
 client=client~=nil,
 clientDisabled=client and client.Disabled or nil,
 castRemote=cast~=nil,
 server=server~=nil,
 serverDisabled=server and server.Disabled or nil,
 serverSourceLen=server and #server.Source or 0,
 clientSourceLen=client and #client.Source or 0,
 serverHasStorm=server and string.find(server.Source,'ability=="Storm"',1,true)~=nil or false,
 serverHasSingularity=server and string.find(server.Source,'ability=="Singularity"',1,true)~=nil or false,
 clientHasActivated=client and string.find(client.Source,'b.Activated:Connect',1,true)~=nil or false,
 clientHasFire=client and string.find(client.Source,'cast:FireServer',1,true)~=nil or false,
}