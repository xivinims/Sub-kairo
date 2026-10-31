local HttpService=game:GetService('HttpService')
local CollectionService=game:GetService('CollectionService')
local roots={workspace,game:GetService('ServerStorage')}
local categories={chairs={},triggers={},rituals={},clouds={},keys={},vehicles={},events={}}
local counts={chairs=0,triggers=0,rituals=0,clouds=0,keys=0,vehicles=0,events=0}
local function record(category,instance)
 counts[category]+=1
 if #categories[category]>=50 then return end
 local result={name=instance.Name,path=instance:GetFullName(),class=instance.ClassName}
 if instance:IsA('BasePart') then
  local p=instance.Position;local s=instance.Size
  result.position={math.floor(p.X*100)/100,math.floor(p.Y*100)/100,math.floor(p.Z*100)/100}
  result.size={math.floor(s.X*100)/100,math.floor(s.Y*100)/100,math.floor(s.Z*100)/100}
  result.transparency=instance.Transparency;result.collide=instance.CanCollide;result.touch=instance.CanTouch
 end
 local tags=CollectionService:GetTags(instance)
 if #tags>0 then result.tags=tags end
 table.insert(categories[category],result)
end
for _,root in ipairs(roots) do
 for _,instance in ipairs(root:GetDescendants()) do
  local n=string.lower(instance.Name)
  if n:find('chair',1,true) or n:find('sofa',1,true) or n:find('couch',1,true) or n:find('bench',1,true) or n:find('seat',1,true) then record('chairs',instance) end
  if n:find('trigger',1,true) or n:find('mission',1,true) or n:find('event',1,true) then record('triggers',instance) end
  if n:find('ritual',1,true) then record('rituals',instance) end
  if n:find('cloud',1,true) or n:find('nuvem',1,true) or instance:IsA('Clouds') then record('clouds',instance) end
  if n:find('key',1,true) or n:find('chave',1,true) then record('keys',instance) end
  if n:find('suv',1,true) or n:find('wreck',1,true) or n:find('carro',1,true) or n:find('vehicle',1,true) then record('vehicles',instance) end
  local tags=CollectionService:GetTags(instance)
  for _,tag in ipairs(tags) do
   local low=string.lower(tag)
   if low:find('trigger',1,true) or low:find('mission',1,true) or low:find('event',1,true) then
    if not n:find('trigger',1,true) and not n:find('mission',1,true) and not n:find('event',1,true) then record('events',instance) end
    break
   end
  end
 end
end
local map=workspace:FindFirstChild('Content') or game:GetService('ServerStorage'):FindFirstChild('OriginalWorld')
local rootsSummary={}
if map then for _,d in ipairs(map:GetChildren()) do table.insert(rootsSummary,d.Name) end end
local allTags={}
for _,tag in ipairs(CollectionService:GetAllTags()) do allTags[tag]=#CollectionService:GetTagged(tag) end
local terrainClouds=workspace.Terrain:FindFirstChildOfClass('Clouds')
return HttpService:JSONEncode({place=game.PlaceId,version=game.PlaceVersion,gameMode=workspace:GetAttribute('GameMode'),displayEpisode=workspace:GetAttribute('DisplayEpisodeNumber'),workspaceRoots=rootsSummary,terrainClouds=terrainClouds~=nil,tagCounts=allTags,counts=counts,candidates=categories})
