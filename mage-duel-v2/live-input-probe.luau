local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterPack=game:GetService("StarterPack")
local ServerScriptService=game:GetService("ServerScriptService")
local world=workspace:FindFirstChild("MageDuelWorld")
local boss=world and world:FindFirstChild("AstraVeyra")
local tool=StarterPack:FindFirstChild("AstralStaff")
local client=tool and tool:FindFirstChild("MageDuelClient")
local server=ServerScriptService:FindFirstChild("MageDuelServer")
local cs=client and client.Source or ""
local ss=server and server.Source or ""
return {
 placeVersion=game.PlaceVersion,
 build=workspace:GetAttribute("BuildVersion"),
 standardJump=workspace:GetAttribute("StandardRobloxJump"),
 boss=boss~=nil,
 bossActive=boss and boss:GetAttribute("Active") or nil,
 tool=tool~=nil,
 toolEnabled=tool and tool.Enabled or nil,
 manualActivationOnly=tool and tool.ManualActivationOnly or nil,
 client=client~=nil,
 server=server~=nil,
 clientGuardRemoved=not string.find(cs,"if not equipped or not ready(name) then return end",1,true),
 keyboardGuardRemoved=not string.find(cs,"if gp or not equipped then return end",1,true),
 autoEquip=string.find(cs,"ensureStaffEquipped()",1,true)~=nil,
 singleActivated=string.find(cs,"b.Activated:Connect",1,true)~=nil and string.find(cs,"MouseButton1Click",1,true)==nil,
 noCustomJump=string.find(cs,'"Pulo"',1,true)==nil and string.find(cs,'fire("Jump")',1,true)==nil,
 realBossDodge=string.find(ss,"local missedPoint=endpoint",1,true)~=nil,
 singularityEscape=string.find(ss,"(current-pos).Magnitude<=13",1,true)~=nil,
 individualRunes=string.find(ss,'d:FindFirstChildWhichIsA("Decal")',1,true)~=nil,
 heavyImpactThrottle=string.find(ss,"lastHeavyImpact",1,true)~=nil,
 activeSync=string.find(ss,'boss:SetAttribute("Active",true)',1,true)~=nil,
}