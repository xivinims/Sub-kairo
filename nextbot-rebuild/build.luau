local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local dm=R.Instance.new('DataModel')
local package=R.Instance.new('Folder');package.Name='NextbotReference';package.Parent=dm:GetService('ReplicatedStorage')
local scripts={}
for _,entry in ipairs({{'Config','ModuleScript',package},{'Settings.server','Script',dm:GetService('ServerScriptService')},{'Settings.client','LocalScript',dm:GetService('StarterPlayer'):GetChildren()[1]}}) do
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
assert(config.Intermission==90 and config.RoundDuration==180)
local ids={}
for _,item in ipairs(config.Catalog) do
	assert(not ids[item.id],'duplicate catalog ID');ids[item.id]=true
	if item.category=='Animações' and item.available then assert(item.animationId>0,'unresolved animation sold as available') end
end
local remote=R.Instance.new('RemoteEvent');remote.Name='Settings';remote.Parent=package
local W=dm:GetService('Workspace')
local floor=R.Instance.new('Part');floor.Name='PreviewFloor';floor.Size=R.Vector3.new(120,1,120);floor.Anchored=true;floor.Parent=W
local spawn=R.Instance.new('SpawnLocation');spawn.Name='PreviewSpawn';spawn.Anchored=true;spawn.Position=R.Vector3.new(0,2,0);spawn.Parent=W
W:SetAttribute('ReferencePreviewOnly',true)
W:SetAttribute('ExactReplicaVerified',false)
for _,name in ipairs({'GameMusic','LobbyMusic','BoomboxVolume','NextbotVolume','EmoteVolume'}) do
	local group=R.Instance.new('SoundGroup');group.Name='NB_'..name;group.Parent=dm:GetService('SoundService')
end
fs.writeFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl',R.serializePlace(dm))
print(serde.encode('json',{compiled=scripts,intermission=config.Intermission,roundDuration=config.RoundDuration,previewOnly=true,published=false}))
