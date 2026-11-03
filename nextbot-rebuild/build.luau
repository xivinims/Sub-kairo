local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local dm=R.Instance.new('DataModel')
local package=R.Instance.new('Folder');package.Name='NextbotReference';package.Parent=dm:GetService('ReplicatedStorage')
local scripts={}
for _,entry in ipairs({{'Config','ModuleScript',package},{'SettingsPolicy','ModuleScript',package},{'RoundState','ModuleScript',package},{'Rounds.server','Script',dm:GetService('ServerScriptService')},{'Match.client','LocalScript'},{'Settings.server','Script',dm:GetService('ServerScriptService')},{'Settings.client','LocalScript'}}) do
	local name,class,parent=table.unpack(entry)
	if class=='LocalScript' then
		parent=dm:GetService('StarterPlayer'):FindFirstChild('StarterPlayerScripts')
		if not parent then parent=R.Instance.new('StarterPlayerScripts');parent.Parent=dm:GetService('StarterPlayer') end
	end
	local source=fs.readFile(name..'.luau')
	local ok,err=pcall(luau.load,source,{debugName=name});assert(ok,err)
	local script=R.Instance.new(class);script.Name=name;script.Source=source;script.Parent=parent
	table.insert(scripts,name)
end
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
local ids={}
for _,item in ipairs(config.Catalog) do
	assert(not ids[item.id],'duplicate catalog ID');ids[item.id]=true
	if item.category=='Animações' and item.available then assert(item.animationId>0,'unresolved animation sold as available') end
end
local remote=R.Instance.new('RemoteEvent');remote.Name='Settings';remote.Parent=package
local matchRemote=R.Instance.new('RemoteEvent');matchRemote.Name='MatchAction';matchRemote.Parent=package
local W=dm:GetService('Workspace')
local floor=R.Instance.new('Part');floor.Name='PreviewFloor';floor.Size=R.Vector3.new(120,1,120);floor.Anchored=true;floor.Parent=W
local spawn=R.Instance.new('SpawnLocation');spawn.Name='PreviewSpawn';spawn.Anchored=true;spawn.Position=R.Vector3.new(0,2,0);spawn.Parent=W
W:SetAttribute('ReferencePreviewOnly',true)
W:SetAttribute('ExactReplicaVerified',false)
for _,name in ipairs({'GameMusic','LobbyMusic','BoomboxVolume','NextbotVolume','EmoteVolume'}) do
	local group=R.Instance.new('SoundGroup');group.Name='NB_'..name;group.Parent=dm:GetService('SoundService')
end
fs.writeFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl',R.serializePlace(dm))
local roundtrip=R.deserializePlace(fs.readFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl'))
assert(roundtrip.ReplicatedStorage.NextbotReference.Settings:IsA('RemoteEvent'))
assert(roundtrip.StarterPlayer.StarterPlayerScripts:FindFirstChild('Settings.client'))
print(serde.encode('json',{compiled=scripts,settingsPolicyTests='passed',roundStateTests='passed',placeRoundtrip='passed',intermission=config.Intermission,roundDuration=config.RoundDuration,previewOnly=true,published=false}))
