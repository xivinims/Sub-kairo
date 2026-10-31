assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong experience')
assert(workspace:GetAttribute('DeadSignalBuildId')=='still-here-hotel-gameplay-settings-v2','Wrong release')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local CollectionService=game:GetService('CollectionService')
local map=assert(workspace:FindFirstChild('HotelMap'))
local ui=assert(ReplicatedStorage:FindFirstChild('MysteryInterface'))
assert(not workspace:FindFirstChild('Content') and not workspace:FindFirstChild('Islands'),'Old map is still active')
assert(workspace:GetAttribute('WorldReady') and workspace:GetAttribute('GameMode')=='Match','World not ready')
assert(ui.HUD.Frame.HeadlampButton:IsA('ImageButton') and ui.HUD.Frame.GrabReleaseButton:IsA('ImageButton'),'Source buttons missing')
assert(game:GetService('StarterPlayer').CharacterWalkSpeed==16,'Default walking speed mismatch')
local interfaceSource=assert(ReplicatedStorage:FindFirstChild('SessionInterface')).Source
assert(interfaceSource:find('IgnoreGuiInset=true',1,true),'Settings are not full-screen')
for _,label in ipairs({'JOGO','CONTROLES','TELA','ÁUDIO','IDIOMA','RESTAURAR','APLICAR'}) do
	assert(interfaceSource:find(label,1,true),'Settings section missing '..label)
end

local interactions=require(game:GetService('ServerScriptService').StillHereRuntime.MapInteractions)
local doors,spawns,parts,rain=0,0,0,0
for _,object in ipairs(map:GetDescendants()) do
	assert(not object:IsA('ScreenGui') and not object:IsA('LuaSourceContainer') and not object:IsA('Tool'),'Map/UI separation broken')
	assert(not object:IsA('ProximityPrompt') and not object:IsA('ClickDetector'),'Legacy interaction still exists')
	if object:IsA('Model') and object.Name=='Rain' then rain+=1 end
	if object:IsA('BasePart') then parts+=1 end
	if object:IsA('SpawnLocation') and object.Enabled then
		spawns+=1
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={object};params.RespectCanCollide=true
		local hit=workspace:Raycast(object.Position+Vector3.new(0,2,0),Vector3.new(0,-10,0),params)
		assert(hit and hit.Normal.Y>.6,'Unsupported hotel spawn '..object:GetFullName())
	end
	if object:GetAttribute('InteractionKind')=='Door' then
		doors+=1
		local before=object.Hinge.CFrame
		assert(interactions.SetDoorOpen(object,true,true),'Door open rejected')
		assert(object.Open.Value and not object.Hitbox.CanCollide and object.Hinge.CFrame~=before,'Door did not open')
		assert(interactions.SetDoorOpen(object,false,true),'Door close rejected')
		assert(not object.Open.Value and object.Hitbox.CanCollide,'Door did not close')
		assert(not object.Hitbox:FindFirstChild('StillHereInteract'),'Door has an extra prompt')
	end
end
assert(doors==4 and spawns==10,'Door/spawn count mismatch')
assert(parts==map:GetAttribute('SourcePartCount'),'Source geometry count mismatch')
assert(rain==0 and map:GetAttribute('RemovedOrphanedRainModels')>0,'Stray rain models were not removed')

local pool=assert(map:FindFirstChild('PoolTable1',true),'Pool table is missing')
assert(pool:GetAttribute('InteractionKind')=='PoolTable' and pool:GetAttribute('PoolGameReady'),'Pool table is not interactive')
assert(pool.PrimaryPart and pool.PrimaryPart:GetAttribute('PoolSurface') and not pool.PrimaryPart.CanCollide,'Pool felt is not ready for the physics game')
local poolWorld=assert(workspace:FindFirstChild('StillHerePoolGame'),'Pool physics are missing')
assert(#poolWorld.InvisiblePlayfield:GetChildren()>=13,'Pool pockets/playfield are missing')
assert(#poolWorld.Balls:GetChildren()==16,'Pool rack is missing its cue ball and 15 object balls')
local cueBall=assert(poolWorld.Balls:FindFirstChild('CueBall'))
assert(not cueBall.Anchored and cueBall.CanCollide,'Pool cue ball is not a physical ball')
local poolScript=assert(game:GetService('ServerScriptService').StillHereRuntime:FindFirstChild('PoolGame'))
local poolClient=assert(game:GetService('ReplicatedFirst'):FindFirstChild('PoolGameClient'))
assert(poolScript.Source:find('function PoolGame.Shoot',1,true) and poolScript.Source:find(':ApplyImpulse(',1,true),'Pool shot logic is missing')
assert(poolClient.Source:find('pool_shoot',1,true) and poolClient.Source:find('pool_restart',1,true),'Pool controls are missing')
assert(#CollectionService:GetTagged('StillHereInteractable')>=7,'Map objects are not using the corner interaction button')
for _,object in ipairs(CollectionService:GetTagged('StillHereInteractable')) do
	assert(object:GetAttribute('InteractionKind')=='Door' or object:GetAttribute('InteractionKind')=='PoolTable' or object:GetAttribute('InteractionKind')=='Light','Unexpected interaction type')
end
for _,object in ipairs(ui:GetDescendants()) do assert(not object:IsA('BasePart') and not object:IsA('LuaSourceContainer'),'UI package depends on map') end
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId'),parts=parts,screens=#ui:GetChildren(),doors=doors,spawns=spawns,removedRainModels=map:GetAttribute('RemovedOrphanedRainModels'),poolBalls=#poolWorld.Balls:GetChildren(),poolPocketObjects=#poolWorld.InvisiblePlayfield:GetChildren(),poolShotLogic=true,interactables=#CollectionService:GetTagged('StillHereInteractable'),separateMapAndUI=true})
