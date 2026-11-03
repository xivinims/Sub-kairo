local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local dm=R.Instance.new('DataModel')
local package=R.Instance.new('Folder');package.Name='NextbotReference';package.Parent=dm:GetService('ReplicatedStorage')
local scripts={}
local server=dm:GetService('ServerScriptService')
for _,entry in ipairs({{'ProfileService','ModuleScript',server},{'MapService','ModuleScript',server},{'RescueService','ModuleScript',server},{'Economy.server','Script',server},{'Config','ModuleScript',package},{'EmotePolicy','ModuleScript',package},{'Emotes.server','Script',dm:GetService('ServerScriptService')},{'Emotes.client','LocalScript'},{'EquipmentRules','ModuleScript',package},{'Equipment.server','Script',dm:GetService('ServerScriptService')},{'Equipment.client','LocalScript'},{'SettingsPolicy','ModuleScript',package},{'RoundState','ModuleScript',package},{'Rounds.server','Script',dm:GetService('ServerScriptService')},{'Match.client','LocalScript'},{'Menu.client','LocalScript'},{'Settings.server','Script',dm:GetService('ServerScriptService')},{'Settings.client','LocalScript'}}) do
	local name,class,parent=table.unpack(entry)
	if class=='LocalScript' then
		parent=dm:GetService('StarterPlayer'):FindFirstChild('StarterPlayerScripts')
		if not parent then parent=R.Instance.new('StarterPlayerScripts');parent.Parent=dm:GetService('StarterPlayer') end
	end
	local source=fs.readFile(name..'.luau')
	local ok,err=pcall(luau.load,source,{debugName=name});assert(ok,name..": "..tostring(err))
	local script=R.Instance.new(class);script.Name=name;script.Source=source;script.Parent=parent
	table.insert(scripts,name)
end
local clips=R.Instance.new('Folder');clips.Name='EmoteClips';clips.Parent=package
local emoteCatalog={}
local emoteRoots=R.deserializeModel(fs.readFile('assets/user-r6-emotes.rbxm'))
for _,root in ipairs(emoteRoots) do
 for _,sequence in ipairs(root:GetDescendants())do
  if sequence:IsA('KeyframeSequence') then
   local duration=0;for _,frame in ipairs(sequence:GetChildren())do if frame:IsA('Keyframe') then duration=math.max(duration,frame.Time)end end
   local id='pack_'..sequence.Name:lower():gsub('[^%w]+','_')
   local original=sequence:Clone();original.Name=id;original.Parent=clips
   table.insert(emoteCatalog,{id=id,name=sequence.Name,category='Animações',price=250,available=true,soundId=sequence.Name=='Jumpstyle' and 1839246711 or 0,duration=duration,loop=sequence.Loop,description=sequence.Name=='Jumpstyle' and 'Emote R6 do pacote enviado. Música Jumpstyle do Creator Store; teste de áudio pendente.' or 'Emote R6 do pacote enviado. Música pendente.',source='user-r6-emotes.rbxm'})
  end
 end
end
assert(#emoteCatalog==19,'uploaded pack count changed')
table.sort(emoteCatalog,function(a,b)return a.id<b.id end)
local catalogModule=R.Instance.new('ModuleScript');catalogModule.Name='EmoteCatalog'
local catalogJson=serde.encode('json',emoteCatalog)
catalogModule.Source="return game:GetService('HttpService'):JSONDecode([==["..catalogJson.."]==])";catalogModule.Parent=package
assert(pcall(luau.load,catalogModule.Source),'generated catalog must compile')
local emoteRemote=R.Instance.new('RemoteEvent');emoteRemote.Name='Emotes';emoteRemote.Parent=package
fs.writeFile('/tmp/nb-assets/emote-catalog.json',serde.encode('json',emoteCatalog,true))
local Policy=luau.load(fs.readFile('EmotePolicy.luau'))()
local profile={coins=500}
local bought,status=Policy.buy(profile,'pack_jumpstyle',250)
assert(status=='purchased' and bought.coins==250 and profile.coins==500)
local again,duplicate=Policy.buy(bought,'pack_jumpstyle',250)
assert(duplicate=='owned' and again.coins==250)
assert(select(2,Policy.buy({coins=0},'x',250))=='funds')
assert(select(2,Policy.buy(profile,'x',0/0))=='invalid')
local equipped=Policy.equip(bought,'pack_jumpstyle',1)
assert(equipped.slots['1']=='pack_jumpstyle')
assert(select(2,Policy.equip(bought,'unknown',1))=='invalid')
assert(select(2,Policy.equip(bought,'pack_jumpstyle',7))=='invalid')
local config=luau.load(fs.readFile('Config.luau'))()
local policy=luau.load(fs.readFile('SettingsPolicy.luau'))()
local hostile=policy(config.Settings,{FOV=math.huge,GameMusic=0/0,MapShadows='false',UntrustedKey='ignored'})
assert(hostile.FOV==70 and hostile.GameMusic==1 and hostile.MapShadows==true and hostile.UntrustedKey==nil)
local clamped=policy(config.Settings,{FOV=300,GameMusic=-2,LobbyMusic=5,LowGraphics=true})
assert(clamped.FOV==100 and clamped.GameMusic==0 and clamped.LobbyMusic==1 and clamped.LowGraphics)
assert(config.Settings.LowGraphics==false,'policy mutated defaults')
assert(policy(config.Settings,nil).FOV==70,'missing payload must restore defaults')
assert(config.Intermission==90 and config.RoundDuration==180)
local RoundState=luau.load(fs.readFile('RoundState.luau'))()
local state=RoundState.new(100,90,180)
assert(not RoundState.tick(state,189,true) and state.phase=='Intermission')
assert(not RoundState.tick(state,190,false) and state.round==0)
assert(RoundState.tick(state,191,true) and state.deadline==371 and state.round==1)
assert(not RoundState.tick(state,370,true))
assert(RoundState.tick(state,371,false) and state.phase=='Intermission' and state.deadline==461)
assert(RoundState.tick(state,461,true) and state.round==2 and state.deadline==641)
local Rules=luau.load(fs.readFile('EquipmentRules.luau'))()
local owned={flashlight=1,timer=2};local used={}
assert(not Rules.canEquip('unknown',owned) and not Rules.canEquip({},owned))
assert(Rules.consume(owned,'timer',1,used) and owned.timer==1)
assert(Rules.consume(owned,'timer',1,used) and owned.timer==1)
assert(Rules.consume(owned,'timer',2,used) and owned.timer==0)
assert(Rules.consume(owned,'timer',2,used) and owned.timer==0)
assert(not Rules.consume(owned,'timer',3,used))
assert(Rules.consume(owned,'flashlight',3,used) and owned.flashlight==1)
assert(Rules.remaining(180,180)==0 and Rules.remaining(180,190)==0)
assert(Rules.pulse(10)<Rules.pulse(100))
local ids={}
for _,item in ipairs(config.Catalog) do
	assert(not ids[item.id],'duplicate catalog ID');ids[item.id]=true
	if item.category=='Animações' and item.available then assert(item.animationId>0,'unresolved animation sold as available') end
end
local remote=R.Instance.new('RemoteEvent');remote.Name='Settings';remote.Parent=package
local matchRemote=R.Instance.new('RemoteEvent');matchRemote.Name='MatchAction';matchRemote.Parent=package
local equipmentRemote=R.Instance.new('RemoteEvent');equipmentRemote.Name='Equipment';equipmentRemote.Parent=package
local W=dm:GetService('Workspace')
for _,name in ipairs({'Economy','Rescue','Movement'})do local e=R.Instance.new('RemoteEvent');e.Name=name;e.Parent=package end
local mapCatalog=require('./SceneBuild')(dm,package)
W:SetAttribute('ReferencePreviewOnly',false)
W:SetAttribute('ExactReplicaVerified',false)
for _,name in ipairs({'GameMusic','LobbyMusic','BoomboxVolume','NextbotVolume','EmoteVolume'}) do
	local group=R.Instance.new('SoundGroup');group.Name='NB_'..name;group.Parent=dm:GetService('SoundService')
end
fs.writeFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl',R.serializePlace(dm))
local roundtrip=R.deserializePlace(fs.readFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl'))
assert(roundtrip.ReplicatedStorage.NextbotReference.Settings:IsA('RemoteEvent'))
assert(roundtrip.StarterPlayer.StarterPlayerScripts:FindFirstChild('Settings.client'))
print(serde.encode('json',{compiled=scripts,settingsPolicyTests='passed',roundStateTests='passed',equipmentTests='passed',emotePolicyTests='passed',uploadedEmotes=#emoteCatalog,placeRoundtrip='passed',intermission=config.Intermission,roundDuration=config.RoundDuration,maps=#mapCatalog,previewOnly=false,published=false}))
