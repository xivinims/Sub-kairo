-- Lobby v116 — CWA Jedi Library + survival systems
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local AssetService=game:GetService("AssetService")
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Terrain=workspace.Terrain

local LOBBY_ID=852951140
local MENU_SCENE_ID=13327565335

local function loadAsset(id)
 local last
 for attempt=1,3 do
  local ok,res=pcall(function() return AssetService:LoadAssetAsync(id) end)
  if ok and res then return res end
  last=res task.wait(1)
 end
 error("Asset "..id.." failed: "..tostring(last))
end

local function countParts(root)
 local n=0
 if root:IsA("BasePart") then n+=1 end
 for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
 return n
end

local function largestVisual(asset)
 local best,bestScore=nil,-1
 for _,d in ipairs(asset:GetDescendants()) do
  if d:IsA("Model") then
   local parts=countParts(d)
   if parts>0 then
    local score=parts
    local ok,_,size=pcall(function() local cf,sz=d:GetBoundingBox() return cf,sz end)
    if ok and size then score+=math.min(100000,size.X*size.Y*size.Z/100) end
    if score>bestScore then best,bestScore=d,score end
   end
  end
 end
 return best or asset:FindFirstChildWhichIsA("BasePart",true)
end

local function asModel(inst)
 if inst:IsA("Model") then return inst end
 local model=Instance.new("Model") inst.Parent=model return model
end

local function sanitize(root)
 for _,d in ipairs(root:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=true d.CanTouch=false
  end
 end
end

-- Remove the old floating-island lobby and every old world decoration.
for _,child in ipairs(workspace:GetChildren()) do
 if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()
for _,container in ipairs({
 ServerScriptService,
 StarterPlayer.StarterPlayerScripts,
 game:GetService("ReplicatedFirst"),
 game:GetService("StarterGui")
}) do
 for _,child in ipairs(container:GetChildren()) do child:Destroy() end
end
for _,name in ipairs({"SweanRuntime","SakuraRuntime","ForestRuntime","XNMedia","SweanVoidEvent","SweanMenuConfig","Survival","MenuSceneTemplate"}) do
 local old=ReplicatedStorage:FindFirstChild(name) if old then old:Destroy() end
end

workspace.StreamingEnabled=false
workspace.FallenPartsDestroyHeight=-500
workspace.GlobalWind=Vector3.zero

local runtime=Instance.new("Folder")
runtime.Name="SweanRuntime"
runtime:SetAttribute("Version",115)
runtime:SetAttribute("LobbyAssetId",LOBBY_ID)
runtime:SetAttribute("IslandAssetId",0)
runtime:SetAttribute("FullMapLoaded",true)
runtime:SetAttribute("LogoAssetId",89648072626653)
runtime.Parent=ReplicatedStorage

-- Exact replacement lobby.
local lobbyAsset=loadAsset(LOBBY_ID)
local source=assert(largestVisual(lobbyAsset),"CWA Jedi Library visual not found")
local lobby=asModel(source:Clone())
lobby.Name="JediLibrary"
lobby:SetAttribute("SourceAssetId",LOBBY_ID)
sanitize(lobby)

-- The library contains one legacy cosmetic reference that Roblox no longer serves.
-- Remove it where the property is writable so it cannot poison menu/lobby preload.
local unavailableId="720367485"
local contentProps={"Texture","TextureID","TextureId","Image","SoundId","AnimationId","ShirtTemplate","PantsTemplate","Graphic","ColorMap","MetalnessMap","NormalMap","RoughnessMap","Video"}
for _,d in ipairs(lobby:GetDescendants()) do
 for _,prop in ipairs(contentProps) do
  pcall(function()
   local value=d[prop]
   if typeof(value)=="string" and value:find(unavailableId,1,true) then d[prop]="" end
  end)
 end
end

lobby.Parent=workspace

local cf,size=lobby:GetBoundingBox()
local bottom=cf.Position.Y-size.Y/2
lobby:PivotTo(lobby:GetPivot()+Vector3.new(-cf.Position.X,-bottom,-cf.Position.Z))
cf,size=lobby:GetBoundingBox()
lobbyAsset:Destroy()
runtime:SetAttribute("LobbyParts",countParts(lobby))
runtime:SetAttribute("LobbySizeX",size.X)
runtime:SetAttribute("LobbySizeY",size.Y)
runtime:SetAttribute("LobbySizeZ",size.Z)

-- Non-playable menu set. It never enters the server Workspace.
local menuAsset=loadAsset(MENU_SCENE_ID)
local menuSource=assert(largestVisual(menuAsset),"Doors menu scene missing")
local menuTemplate=asModel(menuSource:Clone())
menuTemplate.Name="MenuSceneTemplate"
menuTemplate:SetAttribute("SourceAssetId",MENU_SCENE_ID)
sanitize(menuTemplate)
for _,d in ipairs(menuTemplate:GetDescendants()) do
 if d:IsA("BasePart") then
  d.CanCollide=false d.CanTouch=false d.CanQuery=false
 end
end
menuTemplate.Parent=ReplicatedStorage
menuAsset:Destroy()
runtime:SetAttribute("MenuSceneAssetId",MENU_SCENE_ID)

-- Prefer an authored spawn if the library has one. Otherwise choose a large,
-- low, horizontal floor with enough headroom near the center.
local authored=nil
for _,d in ipairs(lobby:GetDescendants()) do
 if d:IsA("SpawnLocation") then authored=d break end
end
local spawnPos=nil
if authored then
 spawnPos=authored.Position+Vector3.new(0,authored.Size.Y/2+.2,0)
 authored.Enabled=false authored.Transparency=1 authored.CanCollide=false
else
 local floor,best=nil,-math.huge
 local low=cf.Position.Y-size.Y/2
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={lobby}
 for _,p in ipairs(lobby:GetDescendants()) do
  if p:IsA("BasePart") and p.CanCollide and p.Transparency<.98 and p.CFrame.UpVector.Y>.88 and p.Size.X>=5 and p.Size.Z>=5 then
   local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
   local clear=not workspace:Raycast(top+Vector3.new(0,.3,0),Vector3.new(0,7,0),params)
   if clear then
    local area=p.Size.X*p.Size.Z
    local centerPenalty=Vector2.new(top.X-cf.Position.X,top.Z-cf.Position.Z).Magnitude*2
    local heightPenalty=math.max(0,top.Y-low)*3
    local score=area-centerPenalty-heightPenalty
    if score>best then best=score floor=p spawnPos=top+Vector3.new(0,.2,0) end
   end
  end
 end
 assert(floor and spawnPos,"No safe lobby floor found")
end

local spawn=Instance.new("SpawnLocation")
spawn.Name="IslandSpawn"
spawn.Size=Vector3.new(7,.4,7)
spawn.CFrame=CFrame.new(spawnPos)
spawn.Anchored=true spawn.CanCollide=false spawn.CanTouch=false spawn.Transparency=1
spawn.Neutral=true spawn.Enabled=true spawn.Duration=0 spawn.Parent=workspace

runtime:SetAttribute("SpawnAssetId",0)
runtime:SetAttribute("SpawnX",spawn.Position.X)
runtime:SetAttribute("SpawnY",spawn.Position.Y)
runtime:SetAttribute("SpawnZ",spawn.Position.Z)
-- Keep legacy camera attributes so the existing menu controller stays compatible.
runtime:SetAttribute("TreeGroundX",spawn.Position.X)
runtime:SetAttribute("TreeGroundY",spawn.Position.Y)
runtime:SetAttribute("TreeGroundZ",spawn.Position.Z)
runtime:SetAttribute("VoidThreshold",math.min(-30,(cf.Position.Y-size.Y/2)-18))
workspace.FallenPartsDestroyHeight=math.min(-500,runtime:GetAttribute("VoidThreshold")-120)

Lighting.ClockTime=18
Lighting.Brightness=2
Lighting.GlobalShadows=true
Lighting.Ambient=Color3.fromRGB(118,119,126)
Lighting.OutdoorAmbient=Color3.fromRGB(132,132,140)
for _,d in ipairs(Lighting:GetChildren()) do
 if d:IsA("BlurEffect") or d:IsA("DepthOfFieldEffect") then d:Destroy() end
end

local remote=Instance.new("RemoteEvent") remote.Name="SweanVoidEvent" remote.Parent=ReplicatedStorage
local void=Instance.new("LocalScript") void.Name="VoidSequence" void.Source=__VOID_SOURCE__ void.Parent=StarterPlayer.StarterPlayerScripts
local server=Instance.new("Script") server.Name="IslandServer" server.Source=__SERVER_SOURCE__ server.Parent=ServerScriptService

-- Keep the nametag and social/UI services used by the current game.
local nameAsset=loadAsset(123212555736117)
local tag=assert(nameAsset:FindFirstChild("Nametag",true),"Nametag asset missing")
assert(tag:IsA("BillboardGui") and tag:FindFirstChild("Username"))
local names=Instance.new("Script") names.Name="NametagService" names.Source=__NAMETAG_SOURCE__
tag:Clone().Parent=names names:SetAttribute("AssetId",123212555736117) names.Parent=ServerScriptService
nameAsset:Destroy()
runtime:SetAttribute("NametagAssetId",123212555736117)

local media=Instance.new("Folder") media.Name="XNMedia" media.Parent=ReplicatedStorage
for name,id in pairs({MenuClick=12221967,VoidMusic=110526913527016,FriendJoined=87437544236708,Regenerate=73292002268424}) do
 local sound=Instance.new("Sound") sound.Name=name sound.SoundId="rbxassetid://"..id
 sound.Volume=name=="VoidMusic" and .28 or .4 sound.Looped=name=="VoidMusic" sound.Parent=media
end
local friends=Instance.new("LocalScript") friends.Name="FriendPresence" friends.Source=__FRIENDS_SOURCE__ friends.Parent=StarterPlayer.StarterPlayerScripts

return {
 version=116,
 lobbyAsset=LOBBY_ID,
 lobbyParts=countParts(lobby),
 spawn=tostring(spawn.Position)
}
