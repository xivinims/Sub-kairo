assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong experience')
assert(workspace:GetAttribute('DeadSignalBuildId')=='still-here-hotel-instruments-v4','Wrong release')
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
assert(interfaceSource:find('Position=UDim2.fromScale(0,0)',1,true) and interfaceSource:find('scheduleSave',1,true),'Settings are not anchored left with autosave')
assert(not interfaceSource:find('APLICAR',1,true),'Manual apply button remains')
for _,label in ipairs({'JOGO','CONTROLES','TELA','ÁUDIO','IDIOMA','RESTAURAR PADRÕES','SALVANDO AUTOMATICAMENTE'}) do
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
local runtime=game:GetService('ServerScriptService').StillHereRuntime
local poolScript=assert(runtime:FindFirstChild('PoolGame'))
local poolClient=assert(game:GetService('ReplicatedFirst'):FindFirstChild('PoolGameClient'))
assert(poolScript.Source:find('function PoolGame.Shoot',1,true) and poolScript.Source:find(':ApplyImpulse(',1,true),'Pool shot logic is missing')
assert(poolClient.Source:find('pool_shoot',1,true) and poolClient.Source:find('InputEnded',1,true),'Direct pool controls are missing')
assert(poolClient.Source:find('CameraType.Scriptable',1,true) and poolClient.Source:find('HotelPoolAimBeam',1,true) and poolClient.Source:find('HotelPoolCue_',1,true),'Pool camera, world aim, or cue presentation missing')
assert(not poolClient.Source:find('ScreenGui',1,true) and not poolClient.Source:find('PoolGameControls',1,true),'Pool still uses a fake on-screen table')
local piano=assert(map:FindFirstChild('Piano',true),'Hotel piano missing')
assert(piano:GetAttribute('InteractionKind')=='Piano' and piano:GetAttribute('PlayableKeysReady') and piano:GetAttribute('PhysicalSongCards')==6,'Physical piano interaction is missing')
local pianoGame=assert(runtime:FindFirstChild('PianoGame'))
local pianoClient=assert(game:GetService('ReplicatedFirst'):FindFirstChild('PianoGameClient'))
assert(pianoGame.Source:find('HotelPianoNote',1,true) and pianoGame.Source:find('122098201042601',1,true),'Piano notes are missing')
assert(pianoGame.Source:find('HEAVEN_SAYS_AUDIO',1,true) and pianoGame.Source:find('72980269840928',1,true),'Requested Heaven Says song is missing')
assert(pianoClient.Source:find('ViewportPointToRay',1,true) and pianoClient.Source:find('PianoNoteIndex',1,true) and pianoClient.Source:find('CameraType.Scriptable',1,true),'Direct piano keys or camera are missing')
assert(not pianoClient.Source:find('ScreenGui',1,true) and not pianoClient.Source:find('HotelPianoControls',1,true),'Piano still uses a fake on-screen keyboard')
local pianoRuntime=assert(workspace:FindFirstChild('HotelPianoRuntime'),'Physical piano keys/cards are missing')
local heavenSound=assert(pianoRuntime:FindFirstChild('HeavenSaysAtHotelPiano',true),'Heaven Says audio is not attached to the piano')
assert(heavenSound.Looped and heavenSound.SoundId=='rbxassetid://72980269840928','Heaven Says does not loop from the requested audio asset')
assert(pianoGame.Source:find('playStep',1,true),'Original piano melodies are missing')
local pianoNotes,pianoCards=0,0
for _,object in ipairs(piano:GetDescendants()) do if object:IsA('BasePart') and object:GetAttribute('PianoNoteIndex')~=nil then pianoNotes+=1 end end
for _,object in ipairs(pianoRuntime:GetDescendants()) do
	if object:IsA('BasePart') and object:GetAttribute('PianoNoteIndex')~=nil then pianoNotes+=1 end
	if object:IsA('BasePart') and object:GetAttribute('PianoSongId')~=nil then pianoCards+=1 end
end
assert(pianoNotes>=13 and pianoCards==6,'The in-world piano keyboard or songbook is incomplete')
local receptionist=assert(workspace:FindFirstChild('HotelActors') and workspace.HotelActors:FindFirstChild('HotelReceptionist'),'Receptionist is missing')
assert(receptionist:GetAttribute('InteractionKind')=='Receptionist' and receptionist:FindFirstChild('Head') and receptionist:FindFirstChildWhichIsA('Shirt') and receptionist:FindFirstChildWhichIsA('Pants'),'Reference receptionist model is incomplete')
local poolSurface
for _,part in ipairs(pool:GetDescendants()) do if part:IsA('BasePart') and part:GetAttribute('PoolSurface') then poolSurface=part;break end end
assert(poolSurface,'Pool surface is missing')
local receptionistSpawn=receptionist:GetAttribute('ReceptionistSpawnPosition')
assert(typeof(receptionistSpawn)=='Vector3' and (receptionistSpawn-poolSurface.Position).Magnitude<14,'Receptionist spawn target is not beside the pool table')
assert(receptionist.PrimaryPart and receptionist.PrimaryPart.Name=='ReceptionistAnchor','Receptionist pivot is missing')
local settingsClient=assert(game:GetService('ReplicatedFirst'):FindFirstChild('HotelReceptionistClient'))
assert(settingsClient.Source:find('Hola',1,true),'Receptionist dialogue is missing')
assert(#CollectionService:GetTagged('StillHereInteractable')>=7,'Map objects are not using the corner interaction button')
for _,object in ipairs(CollectionService:GetTagged('StillHereInteractable')) do
	assert(object:GetAttribute('InteractionKind')=='Door' or object:GetAttribute('InteractionKind')=='PoolTable' or object:GetAttribute('InteractionKind')=='Piano' or object:GetAttribute('InteractionKind')=='Receptionist' or object:GetAttribute('InteractionKind')=='Light','Unexpected interaction type')
end
assert(interfaceSource:find('Position=UDim2.fromScale(0,0)',1,true) and interfaceSource:find('scheduleSave',1,true),'Settings are not left-anchored with autosave')
assert(not interfaceSource:find('APLICAR',1,true),'Manual apply button remains')
for _,object in ipairs(ui:GetDescendants()) do assert(not object:IsA('BasePart') and not object:IsA('LuaSourceContainer'),'UI package depends on map') end
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId'),parts=parts,screens=#ui:GetChildren(),doors=doors,spawns=spawns,removedRainModels=map:GetAttribute('RemovedOrphanedRainModels'),poolBalls=#poolWorld.Balls:GetChildren(),poolPocketObjects=#poolWorld.InvisiblePlayfield:GetChildren(),poolShotLogic=true,interactables=#CollectionService:GetTagged('StillHereInteractable'),separateMapAndUI=true})
