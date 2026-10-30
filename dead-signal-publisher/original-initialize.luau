-- Decorative menu copies must never register as campaign interactables.
local backdrop=game:GetService('ReplicatedStorage'):FindFirstChild('MenuBackdrop')
if backdrop then
 local tags=game:GetService('CollectionService')
 for _,d in ipairs(backdrop:GetDescendants()) do for _,tag in ipairs(tags:GetTags(d)) do tags:RemoveTag(d,tag) end end
end
local W=workspace;local SS=game:GetService('ServerStorage');local P=game:GetService('Players')
local selectedChapter=1
if game.PrivateServerId~='' then
 local serviceOk,Memory=pcall(function()
  return game:GetService('MemoryStoreService'):GetHashMap('StillHereSessions_v1')
 end)
 local session
 if serviceOk then
  for attempt=1,12 do
   local ok,value=pcall(function() return Memory:GetAsync(game.PrivateServerId) end)
   if ok and value then session=value;break end
   task.wait(.5)
  end
 end
 if session then selectedChapter=tonumber(session.chapter)==2 and 2 or 1 end
end
W:SetAttribute('SelectedChapter',selectedChapter)
local mode=W:GetAttribute('OriginalPreflight') and 'Match' or (game.PrivateServerId=='' and 'Menu' or 'Match')
if mode=='Menu' then W:SetAttribute('GameMode','Menu');return end
if selectedChapter==2 then
 local chapterMap=require(game:GetService('ReplicatedStorage'):WaitForChild('ChapterTwoMap'))
 chapterMap.Build(W)
else
 local world=SS:FindFirstChild('OriginalWorld')
 if world then for _,c in ipairs(world:GetChildren()) do c.Parent=W end;world:Destroy() end
 local region=SS:FindFirstChild('OriginalTerrain')
 if region then W.Terrain:Clear();W.Terrain:PasteRegion(region,Vector3int16.new(-144,-64,-192),false);region:Destroy() end
 W.SpawnLocationLobby.Enabled=false;W.SpawnLocationHouse.Enabled=false;W.SpawnLocation.Enabled=true
end
W:SetAttribute('IslandWorldReady',true);W:SetAttribute('GameMode','Match')
if game:GetService('RunService'):IsRunning() then P.CharacterAutoLoads=true;for _,p in ipairs(P:GetPlayers()) do if not p.Character then p:LoadCharacterAsync() end end end
