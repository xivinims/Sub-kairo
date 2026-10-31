local Players=game:GetService('Players')
local PianoGame={}
local state={joined=setmetatable({},{__mode='k'}),lastNote=setmetatable({},{__mode='k'}),songToken=0,songId=nil}
local WHITE_NOTES={0,2,4,5,7,9,11,12}
local BLACK_NOTES={1,3,6,8,10}
local HEAVEN_SAYS_AUDIO='rbxassetid://72980269840928'
local songs={
	VALSA={title='VALSA DO HOTEL',step=.34,notes={{0,4,7},4,7,9,7,4,{2,5,9},5,9,7,4,2,{0,4,7},5,9,12,9,7,{2,5,9},4}},
	CAIXA={title='CAIXINHA',step=.27,notes={{0,4,7},12,9,7,{4,7,11},9,7,4,{5,9,12},11,9,7,{2,5,9},7,9,12,{0,4,7},9,7,4}},
	LUAR={title='CANÇÃO DO LUAR',step=.39,notes={{0,4,7},2,4,7,9,7,{2,5,9},4,2,{0,4,7},4,7,12,9,7,{2,5,9},4,2,0}},
	MISTERIO={title='MISTÉRIO',step=.31,notes={{0,3,7},3,7,10,9,7,{2,5,9},3,0,{0,3,7},2,5,9,10,9,{2,5,9},5,3,0}},
	HEAVEN_SAYS={title='HEAVEN SAYS',audio=true},
}

local function make(class,parent,props)
	local object=Instance.new(class)
	for name,value in pairs(props or {}) do object[name]=value end
	object.Parent=parent
	return object
end

local function rootOf(player)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass('Humanoid')
	local root=character and character:FindFirstChild('HumanoidRootPart')
	return humanoid and humanoid.Health>0 and root or nil
end

local function nearby(player,distance)
	local root=rootOf(player)
	return root and state.keyboard and (root.Position-state.keyboard.Position).Magnitude<=(distance or 13)
end

local function createPhysicalKeys(piano)
	local pianoFrame,pianoSize=piano:GetBoundingBox()
	local runtime=Instance.new('Folder')
	runtime.Name='HotelPianoRuntime'
	runtime.Parent=workspace
	local keys=Instance.new('Folder')
	keys.Name='PlayableKeys'
	keys.Parent=runtime
	local matched={}
	for _,object in ipairs(piano:GetDescendants()) do
		if object:IsA('BasePart') and string.find(string.lower(object.Name),'key',1,true) then
			local short=math.min(object.Size.X,object.Size.Z)
			local long=math.max(object.Size.X,object.Size.Z)
			if object.Size.Y<=.55 and short>=.12 and long<=2.4 then table.insert(matched,object) end
		end
	end
	table.sort(matched,function(a,b)
		return pianoFrame:PointToObjectSpace(a.Position).X<pianoFrame:PointToObjectSpace(b.Position).X
	end)
	local whiteByNote={}
	local keyboardFrame
	if #matched>=13 then
		local center=Vector3.zero
		for _,part in ipairs(matched) do center+=part.Position end
		center/= #matched
		keyboardFrame=pianoFrame*CFrame.new(pianoFrame:PointToObjectSpace(center))
		for index,part in ipairs(matched) do
			local note=math.clamp(math.floor((index-1)*12/(#matched-1)+.5),0,12)
			part:SetAttribute('PianoNoteIndex',note)
			part:SetAttribute('PianoKeyKind',table.find(BLACK_NOTES,note) and 'Black' or 'White')
			whiteByNote[note]=part
		end
	else
		local upright=pianoSize.Y>pianoSize.Z*1.45
		local width=math.clamp(pianoSize.X*.70,3.2,7.2)
		local whiteWidth=width/8
		local keyY,keyZ
		if upright then
			keyY=-pianoSize.Y/2+math.clamp(pianoSize.Y*.28,1,1.65)
			keyZ=-pianoSize.Z/2-.28
		else
			keyY=pianoSize.Y/2+.09
			keyZ=-pianoSize.Z/2+.62
		end
		keyboardFrame=pianoFrame*CFrame.new(0,keyY,keyZ)
		for slot,note in ipairs(WHITE_NOTES) do
			local x=(slot-4.5)*whiteWidth
			local key=make('Part',keys,{Name='PianoWhiteKey_'..note,Size=Vector3.new(whiteWidth-.025,.13,.76),CFrame=keyboardFrame*CFrame.new(x,0,0),Color=Color3.fromRGB(235,229,214),Material=Enum.Material.SmoothPlastic,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=true,CastShadow=false,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth})
			key:SetAttribute('PianoNoteIndex',note);key:SetAttribute('PianoKeyKind','White');whiteByNote[note]=key
		end
		local blackPositions={1.5,2.5,4.5,5.5,6.5}
		for slot,note in ipairs(BLACK_NOTES) do
			local x=(blackPositions[slot]-4.5)*whiteWidth
			local key=make('Part',keys,{Name='PianoBlackKey_'..note,Size=Vector3.new(whiteWidth*.54,.23,.48),CFrame=keyboardFrame*CFrame.new(x,.17,-.12),Color=Color3.fromRGB(24,23,22),Material=Enum.Material.SmoothPlastic,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=true,CastShadow=false,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth})
			key:SetAttribute('PianoNoteIndex',note);key:SetAttribute('PianoKeyKind','Black');whiteByNote[note]=key
		end
	end
	local surface=next(whiteByNote)
	local anchor=whiteByNote[surface] or piano.PrimaryPart
	assert(anchor,'Piano keyboard could not be built')
	return runtime,keys,whiteByNote,pianoFrame,pianoSize,anchor,keyboardFrame
end

local function createSongCards(runtime,keyboardFrame)
	local album=make('Part',runtime,{Name='HotelPianoSongbook',Size=Vector3.new(5.1,.12,.88),CFrame=keyboardFrame*CFrame.new(0,.30,.94),Color=Color3.fromRGB(54,39,29),Material=Enum.Material.Wood,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=true,CastShadow=true})
	local ids={'HEAVEN_SAYS','VALSA','CAIXA','LUAR','MISTERIO','STOP'}
	local titles={'HEAVEN SAYS','VALSA','CAIXINHA','LUAR','MISTÉRIO','PARAR'}
	local width=4.8/#ids
	local cards={}
	for index,id in ipairs(ids) do
		local card=make('Part',runtime,{Name='PianoSongCard_'..id,Size=Vector3.new(width-.035,.07,.72),CFrame=album.CFrame*CFrame.new((index-(#ids+1)/2)*width,.12,0),Color=Color3.fromRGB(93,76,55),Material=Enum.Material.WoodPlanks,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=true,CastShadow=false})
		card:SetAttribute('PianoSongId',id)
		local gui=make('SurfaceGui',card,{Name='PrintedTitle',Face=Enum.NormalId.Top,AlwaysOnTop=false,LightInfluence=.8,SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud,PixelsPerStud=34})
		local label=make('TextLabel',gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=titles[index],Font=Enum.Font.RobotoCondensed,TextSize=18,TextColor3=Color3.fromRGB(239,225,194),TextWrapped=true,TextScaled=true})
		make('UIPadding',label,{PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3)})
		cards[id]=card
	end
	return cards
end

local function stopSong()
	state.songToken+=1
	state.songId=nil
	if state.heavenSound then state.heavenSound:Stop() end
	if state.remote then state.remote:FireAllClients('piano_song_visual',{id='STOP',playing=false}) end
	for _,card in pairs(state.songCards or {}) do card.Color=Color3.fromRGB(93,76,55) end
end

local function playNote(index)
	local part=state.noteParts[index]
	local sound=state.noteSounds[index]
	if not part or not sound then return end
	sound:Stop();sound.TimePosition=0;sound:Play()
	state.remote:FireAllClients('piano_note_visual',{index=index})
end

local function playStep(step)
	if typeof(step)=='table' then
		for _,index in ipairs(step) do playNote(index) end
	else
		playNote(step)
	end
end

function PianoGame.Initialize(map,remote)
	assert(not state.initialized,'Piano game already initialized')
	local piano=assert(map:FindFirstChild('Piano',true),'Hotel piano not found')
	state.remote=remote;state.piano=piano
	piano:SetAttribute('InteractionKind','Piano')
	state.runtime,state.keys,state.noteParts,state.frame,state.bounds,state.keyboard,state.keyboardFrame=createPhysicalKeys(piano)
	state.songCards=createSongCards(state.runtime,state.keyboardFrame)
	state.noteSounds={}
	for index=0,12 do
		local part=assert(state.noteParts[index],'Piano key missing at note '..index)
		local sound=make('Sound',part,{Name='HotelPianoNote'..index,SoundId='rbxassetid://122098201042601',PlaybackSpeed=2^((index-7)/12),Volume=.48,RollOffMode=Enum.RollOffMode.InverseTapered,RollOffMinDistance=7,RollOffMaxDistance=56})
		local reverb=make('ReverbSoundEffect',sound,{DecayTime=2.05,Density=.78,Diffusion=.75,DryLevel=-2,WetLevel=-9})
		state.noteSounds[index]=sound
	end
	state.heavenSound=make('Sound',state.piano.PrimaryPart or state.keyboard,{Name='HeavenSaysAtHotelPiano',SoundId=HEAVEN_SAYS_AUDIO,Volume=.36,RollOffMode=Enum.RollOffMode.InverseTapered,RollOffMinDistance=8,RollOffMaxDistance=76,Looped=true})
	state.heavenSound:SetAttribute('AudioCredit','HEAVEN SAYS (MANDELA MIX) — xxusrnm / Z Sharp Studios')
	state.initialized=true
	piano:SetAttribute('PlayableKeysReady',true)
	piano:SetAttribute('PhysicalSongCards',6)
end

function PianoGame.Join(player)
	if not state.initialized or not nearby(player,11) then return false end
	state.joined[player]=true
	player:SetAttribute('HotelInteractionMode','Piano')
	state.remote:FireClient(player,'piano_open',{piano=state.piano,keyboard=state.runtime,surface=state.keyboard})
	return true
end

function PianoGame.Note(player,data)
	local index=typeof(data)=='table' and tonumber(data.index)
	if not state.joined[player] or not nearby(player,14) or not index or index%1~=0 or index<0 or index>12 then return false end
	local now=os.clock()
	if now-(state.lastNote[player] or 0)<.075 then return false end
	state.lastNote[player]=now
	playNote(index)
	return true
end

function PianoGame.Song(player,data)
	local id=typeof(data)=='table' and data.id
	local song=songs[id]
	if not state.joined[player] or not nearby(player,14) or (id~='STOP' and not song) then return false end
	if id=='STOP' or state.songId==id then stopSong();return true end
	stopSong();state.songId=id
	state.songToken+=1
	local token=state.songToken
	local card=state.songCards[id]
	if card then card.Color=Color3.fromRGB(158,129,82) end
	state.remote:FireAllClients('piano_song_visual',{id=id,playing=true})
	if song.audio then
		state.heavenSound.TimePosition=0;state.heavenSound.Looped=true;state.heavenSound:Play()
		return true
	end
	task.spawn(function()
		while state.songToken==token and state.songId==id do
			for _,index in ipairs(song.notes) do
				if state.songToken~=token or state.songId~=id then return end
				playStep(index)
				task.wait(song.step)
			end
			task.wait(.7)
		end
	end)
	return true
end

function PianoGame.Exit(player)
	if not state.joined[player] then return false end
	state.joined[player]=nil
	player:SetAttribute('HotelInteractionMode',nil)
	state.remote:FireClient(player,'piano_close')
	return true
end

Players.PlayerRemoving:Connect(function(player)
	state.joined[player]=nil;state.lastNote[player]=nil
end)

return PianoGame
