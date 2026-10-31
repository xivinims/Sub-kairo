local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local dm=R.Instance.new('DataModel')
local W=dm:GetService('Workspace')
local RS=dm:GetService('ReplicatedStorage')
local SS=dm:GetService('ServerStorage')
local RF=dm:GetService('ReplicatedFirst')
local SP=dm:GetService('StarterPlayer')
local interface=R.deserializeModel(fs.readFile('assets/ui/mystery-interface.rbxm'))[1]
assert(interface and interface.Name=='MysteryInterface','Separated Mystery UI package missing')
-- Export the interface before attaching a map or any runtime controller.
fs.writeFile('/tmp/still-here-mystery-ui.rbxm',R.serializeModel({interface}))
interface.Parent=RS
local map=require('./hotel-map-extract')(dm)
fs.writeFile('/tmp/still-here-hotel-map.rbxm',R.serializeModel({map}))
map.Parent=SS
local function install(parent,name,class,file)
 local source=fs.readFile(file);luau.load(source,{debugName=file})
 local script=R.Instance.new(class);script.Name=name;script.Source=source;script.Parent=parent
end
local runtime=R.Instance.new('Folder');runtime.Name='StillHereRuntime';runtime.Parent=dm:GetService('ServerScriptService')
install(runtime,'MapInteractions','ModuleScript','mystery-map-interactions.luau')
install(runtime,'WorldInitializer','Script','hotel-initialize.luau')
install(runtime,'PlayerSettings','Script','settings-server.luau')
install(RS,'SettingsSchema','ModuleScript','settings-schema.luau')
install(RS,'SessionInterface','ModuleScript','session-interface.luau')
install(RF,'MysteryUIClient','LocalScript','mystery-ui-client.luau')
install(RF,'SessionLoadingClient','LocalScript','session-loading-client.luau')
install(RF,'PortugueseText','LocalScript','original-portuguese-text.luau')
local settings=R.Instance.new('RemoteFunction');settings.Name='PlayerSettings';settings.Parent=RS
local actions=R.Instance.new('RemoteEvent');actions.Name='MysteryUIAction';actions.Parent=RS
W:SetAttribute('DeadSignalBuildId','still-here-hotel-mystery-ui-v1')
W:SetAttribute('SceneDisplayName','HOTEL')
W:SetAttribute('ActiveMap','1940sHotelLobby')
W:SetAttribute('InterfaceSource','7902470429')
W:SetAttribute('WorldReady',false)
W.StreamingEnabled=true;W.StreamingMinRadius=64;W.StreamingTargetRadius=192
SP.CameraMode=R.Enum.CameraMode.Classic;SP.CameraMinZoomDistance=8;SP.CameraMaxZoomDistance=18
SP.CharacterWalkSpeed=12
dm:GetService('Players').CharacterAutoLoads=false
local lighting=dm:GetService('Lighting')
lighting.GlobalShadows=true
pcall(function() lighting.LightingStyle=R.Enum.LightingStyle.Realistic;lighting.PrioritizeLightingQuality=true end)
fs.writeFile('/tmp/still-here-hotel.rbxl',R.serializePlace(dm))
local bundle=R.Instance.new('Model');bundle.Name='HotelBundle'
for k,v in pairs(W:GetAttributes()) do bundle:SetAttribute(k,v) end
for _,service in ipairs({'ServerStorage','ServerScriptService','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting','MaterialService'}) do
 local folder=R.Instance.new('Folder');folder.Name=service;folder.Parent=bundle
 for _,child in ipairs(dm:GetService(service):GetChildren()) do child.Parent=folder end
end
fs.writeFile('/tmp/hotel-payload.rbxm',R.serializeModel({bundle}))
print('HOTEL_ASSEMBLED '..serde.encode('json',{parts=map:GetAttribute('SourcePartCount'),doors=map:GetAttribute('InteractiveDoorCount'),spawns=map:GetAttribute('SourceSpawnCount'),screens=#interface:GetChildren()}))
