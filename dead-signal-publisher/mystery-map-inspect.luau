local HttpService=game:GetService('HttpService')
local CollectionService=game:GetService('CollectionService')
local SS=game:GetService('ServerStorage')
local world=workspace:FindFirstChild('Content') or (SS:FindFirstChild('OriginalWorld') and SS.OriginalWorld:FindFirstChild('Content'))
assert(world,'Original mystery map content not found')
local categories={chairs={},seats={},triggers={},rituals={},clouds={},keys={},doors={},vehicles={}}
local counts={chairs=0,seats=0,triggers=0,rituals=0,clouds=0,keys=0,doors=0,vehicles=0}
local function record(category,instance)
 counts[category]+=1
 if #categories[category]>=80 then return end
 local r={name=instance.Name,path=instance:GetFullName(),class=instance.ClassName}
 if instance:IsA('BasePart') then
  local p=instance.Position;local s=instance.Size
  r.position={math.floor(p.X*100)/100,math.floor(p.Y*100)/100,math.floor(p.Z*100)/100}
  r.size={math.floor(s.X*100)/100,math.floor(s.Y*100)/100,math.floor(s.Z*100)/100}
  r.transparency=instance.Transparency;r.collide=instance.CanCollide;r.touch=instance.CanTouch
 end
 local tags=CollectionService:GetTags(instance);if #tags>0 then r.tags=tags end
 table.insert(categories[category],r)
end
for _,instance in ipairs(world:GetDescendants()) do
 local n=string.lower(instance.Name)
 local selected=instance:IsA('BasePart') or instance:IsA('Model') or instance:IsA('Folder') or instance:IsA('LuaSourceContainer') or instance:IsA('Seat')
 if selected and (n:find('chair',1,true) or n:find('sofa',1,true) or n:find('couch',1,true) or n:find('bench',1,true)) then record('chairs',instance) end
 if instance:IsA('Seat') then record('seats',instance) end
 if selected and (n:find('trigger',1,true) or n:find('mission',1,true) or n:find('event',1,true)) then record('triggers',instance) end
 if n:find('ritual',1,true) then record('rituals',instance) end
 if selected and (n:find('cloud',1,true) or n:find('storm',1,true) or instance:IsA('Clouds')) then record('clouds',instance) end
 if selected and (n:find('key',1,true) or n:find('chave',1,true)) then record('keys',instance) end
 if CollectionService:HasTag(instance,'Door') then record('doors',instance) end
 if selected and (n:find('suv_damaged',1,true) or n:find('wreck',1,true)) then record('vehicles',instance) end
end
local foyer=world:FindFirstChild('Interior') and world.Interior:FindFirstChild('Foyer')
local rooms={}
for _,name in ipairs({'Interior','Exterior','Lobby'}) do local d=world:FindFirstChild(name);if d then for _,c in ipairs(d:GetChildren()) do table.insert(rooms,c.Name) end end end
local globalClouds=workspace.Terrain:FindFirstChildOfClass('Clouds')
local allTags={}
for _,tag in ipairs(CollectionService:GetAllTags()) do
 local count=0
 for _,d in ipairs(world:GetDescendants()) do if CollectionService:HasTag(d,tag) then count+=1 end end
 if count>0 then allTags[tag]=count end
end
return HttpService:JSONEncode({place=game.PlaceId,version=game.PlaceVersion,gameMode=workspace:GetAttribute('GameMode'),map=world:GetFullName(),directRooms=rooms,foyerChildren=foyer and (function() local a={} for _,d in ipairs(foyer:GetChildren()) do table.insert(a,d.Name) end return a end)() or {},globalClouds=globalClouds~=nil,counts=counts,candidates=categories,tagCounts=allTags})
