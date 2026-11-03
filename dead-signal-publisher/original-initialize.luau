local W=workspace
local SS=game:GetService('ServerStorage')
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
-- This experience contains one playable place: the original mystery mansion.
W:SetAttribute('ExperienceChapter',1)
W:SetAttribute('SelectedChapter',1)
local world=assert(SS:FindFirstChild('OriginalWorld'),'Mystery mansion package missing')
for _,child in ipairs(world:GetChildren()) do child.Parent=W end
world:Destroy()
local region=SS:FindFirstChild('OriginalTerrain')
if region then
 W.Terrain:Clear()
 W.Terrain:PasteRegion(region,Vector3int16.new(-144,-64,-192),false)
 region:Destroy()
end
if W:FindFirstChild('SpawnLocationLobby') then W.SpawnLocationLobby.Enabled=false end
if W:FindFirstChild('SpawnLocationHouse') then W.SpawnLocationHouse.Enabled=false end
if W:FindFirstChild('SpawnLocation') then W.SpawnLocation.Enabled=true end
W:SetAttribute('MysteryWorldReady',true)
W:SetAttribute('GameMode','Match')
if RunService:IsRunning() then
 Players.CharacterAutoLoads=true
 for _,player in ipairs(Players:GetPlayers()) do
  if not player.Character then player:LoadCharacterAsync() end
 end
end
