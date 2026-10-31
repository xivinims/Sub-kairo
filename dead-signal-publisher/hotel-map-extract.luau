local R=require('@lune/roblox')
local fs=require('@lune/fs')
return function(dm)
 local roots=R.deserializeModel(fs.readFile('assets/hotel/1940sHotelLobby.rbxm'))
 assert(#roots==1,'Unexpected hotel file roots')
 local source=roots[1]
 local world=assert(source:FindFirstChild('---- Ungroup In Workspace ----'),'Hotel scenery folder missing')
 local materials=assert(source:FindFirstChild('Materials ---- MaterialService'),'Hotel materials missing')
 local effects=assert(source:FindFirstChild('--- Ungroup in Lighting ----'),'Hotel lighting missing')
 local map=R.Instance.new('Model');map.Name='HotelMap'
 map:SetAttribute('SourceFile','1940sHotelLobby - VoidAssets.rbxm')
 map:SetAttribute('SourceSha256','03520ce828d3a652b58133424577df2fd1125497dc2a40d2b9fdc45b786b3700')
 local sourceId=0
 for _,d in ipairs(world:GetDescendants()) do
  sourceId+=1
  if d:IsA('BasePart') then d:SetAttribute('HotelSourceId',sourceId) end
 end
 local weapon=assert(world:FindFirstChild('AK-47 Spawner',true),'Audited weapon spawner changed')
 weapon:Destroy()
 for _,d in ipairs(world:GetDescendants()) do
  if d:IsA('LuaSourceContainer') or d:IsA('Tool') or d:IsA('ScreenGui') or d:IsA('RemoteEvent') or d:IsA('RemoteFunction') then d:Destroy() end
 end
 for _,child in ipairs(world:GetChildren()) do child.Parent=map end
 local doors,parts,spawns=0,0,0
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA('Model') and d:FindFirstChild('Hinge') and d:FindFirstChild('Hitbox') and d:FindFirstChild('Open') then
   d:SetAttribute('InteractionKind','Door')
   doors+=1
  end
  if d:IsA('BasePart') then
   parts+=1
   local parent=d.Parent
   local movingDoor=parent and parent:IsA('Model') and parent:FindFirstChild('Hinge') and parent:FindFirstChild('Open')
   -- Retain welded moving door panels; keep loose decorative pieces in place.
   if not movingDoor then d.Anchored=true end
  end
  if d:IsA('SpawnLocation') then
   spawns+=1;d.Enabled=true;d.Neutral=true;d.Duration=0
  end
 end
 assert(doors==4 and spawns==10,'Hotel interactive door/spawn layout changed')
 -- Import named materials into the service; folders are packaging instructions.
 local seen={};local used={}
 for _,d in ipairs(map:GetDescendants()) do if d:IsA('BasePart') and d.MaterialVariant~='' then used[d.MaterialVariant]=true end end
 for _,d in ipairs(materials:GetDescendants()) do
  if d:IsA('MaterialVariant') then
   seen[d.Name]=true;d:Clone().Parent=dm:GetService('MaterialService')
  end
 end
 for name in pairs(used) do assert(seen[name],'Missing hotel material '..name) end
 for _,d in ipairs(effects:GetChildren()) do d:Clone().Parent=dm:GetService('Lighting') end
 map:SetAttribute('SourcePartCount',parts)
 map:SetAttribute('InteractiveDoorCount',doors)
 map:SetAttribute('SourceSpawnCount',spawns)
 return map
end
