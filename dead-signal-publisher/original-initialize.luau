local W=workspace;local SS=game:GetService('ServerStorage');local P=game:GetService('Players')
local mode=W:GetAttribute('OriginalPreflight') and 'Match' or (game.PrivateServerId=='' and 'Menu' or 'Match')
if mode=='Menu' then W:SetAttribute('GameMode','Menu');return end
local world=SS:FindFirstChild('OriginalWorld')
if world then for _,c in ipairs(world:GetChildren()) do c.Parent=W end;world:Destroy() end
local region=SS:FindFirstChild('OriginalTerrain')
if region then W.Terrain:Clear();W.Terrain:PasteRegion(region,Vector3int16.new(-144,-64,-192),false);region:Destroy() end
W.SpawnLocationLobby.Enabled=false;W.SpawnLocationHouse.Enabled=false;W.SpawnLocation.Enabled=true
W:SetAttribute('IslandWorldReady',true);W:SetAttribute('GameMode','Match')
if game:GetService('RunService'):IsRunning() then P.CharacterAutoLoads=true;for _,p in ipairs(P:GetPlayers()) do if not p.Character then p:LoadCharacterAsync() end end end
