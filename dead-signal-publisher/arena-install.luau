local BUILD_ID="dead-signal-bramble-map-v2"
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Dead Signal target")
local W=game:GetService("Workspace")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local Lighting=game:GetService("Lighting")
local Http=game:GetService("HttpService")
local sourceImporter=Instance.new("ModuleScript")
sourceImporter.Source=__IMPORTER__
local Importer=require(sourceImporter)
local bundle,report=Importer.Load({id=115602504342753,importMode="rig",stripScripts=true})
local selected=bundle:FindFirstChild("LiveEntityBramble",true)
assert(selected and selected:IsA("Model"),"Requested Bramble rig not found")
local rig=selected:Clone(); bundle:Destroy()
rig.Name="Bramble"
local root=rig:FindFirstChild("Root")
assert(root and root:IsA("BasePart"),"Bramble Root missing")
rig.PrimaryPart=root
for _,d in ipairs(rig:GetDescendants()) do
    if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("Animation") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("PackageLink") then d:Destroy()
    elseif d:IsA("BasePart") then
        d.Anchored=d==root; d.CanCollide=false; d.CanTouch=false; d.CanQuery=true; d.Massless=true
    elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=false end
end
root.Transparency=1
local collider=rig:FindFirstChild("RootCollider")
if collider then collider.Transparency=1; collider.CanQuery=false end
rig:SetAttribute("SourceAssetId",115602504342753)
rig:SetAttribute("RemovedExternalScripts",report.removedScripts)
rig:SetAttribute("State","Idle")
rig:SetAttribute("AnimationDriver","OriginalMotor6D")
rig:SetAttribute("SupportedStates","Idle,Walk,Run,Attack")
-- Clear only this place's active game. Prior chapter source remains recoverable in git history.
for _,child in ipairs(W:GetChildren()) do if child~=W.Terrain and not child:IsA("Camera") then child:Destroy() end end
W.Terrain:Clear()
for _,service in ipairs({RS,SSS,game:GetService("ReplicatedFirst"),game:GetService("StarterGui"),SP.StarterPlayerScripts,SP.StarterCharacterScripts,Lighting,game:GetService("SoundService")}) do
    for _,d in ipairs(service:GetChildren()) do d:Destroy() end
end
for key in pairs(W:GetAttributes()) do W:SetAttribute(key,nil) end
W.StreamingEnabled=true
-- Radius properties are editor-only on this execution-session engine; use the place defaults.
Lighting.ClockTime=0; Lighting.Brightness=0.6; Lighting.Ambient=Color3.fromRGB(45,49,57); Lighting.OutdoorAmbient=Color3.fromRGB(52,58,68)
Lighting.GlobalShadows=true
local function part(name,size,cf)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true; p.Material=Enum.Material.Concrete; p.Color=Color3.fromRGB(150,154,158); p.Parent=W; return p
end
__TEST_MAP__
sourceImporter:Destroy()
rig.Parent=W
rig.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
rig:PivotTo(CFrame.new(0,0,0))
local cf,size=rig:GetBoundingBox()
local lift=-(cf.Position.Y-size.Y/2)+0.12
rig:PivotTo(CFrame.lookAt(monsterPoint+Vector3.new(0,lift,0),Vector3.new(spawnPoint.X,monsterPoint.Y+lift,spawnPoint.Z)))
rig:SetAttribute("HomePosition",root.Position)
local spawn=Instance.new("SpawnLocation"); spawn.Name="ArenaSpawn"; spawn.Size=Vector3.new(6,1,6); spawn.CFrame=CFrame.lookAt(spawnPoint+Vector3.new(0,0.5,0),Vector3.new(monsterPoint.X,spawnPoint.Y+0.5,monsterPoint.Z))
spawn.Anchored=true; spawn.CanCollide=false; spawn.Transparency=1; spawn.Neutral=true; spawn.Duration=0; spawn.Parent=W
SP.CameraMode=Enum.CameraMode.LockFirstPerson; SP.CameraMinZoomDistance=0.5; SP.CameraMaxZoomDistance=0.5
SP.CharacterWalkSpeed=18
local remote=Instance.new("RemoteEvent"); remote.Name="ArenaControl"; remote.Parent=RS
local event=Instance.new("RemoteEvent"); event.Name="BrambleScare"; event.Parent=RS
local module=Instance.new("ModuleScript"); module.Name="ArenaAnimation"; module.Source=__ANIMATION__; module.Parent=RS
local server=Instance.new("Script"); server.Name="BrambleArenaServer"; server.Enabled=false; server.Source=__SERVER__; server.Parent=SSS
local client=Instance.new("LocalScript"); client.Name="BrambleArenaClient"; client.Source=__CLIENT__; client.Parent=SP.StarterPlayerScripts
W:SetAttribute("DeadSignalBuildId",BUILD_ID)
W:SetAttribute("ArenaOnly",false)
-- Validate executable poses on the actual imported joints before publishing.
local animation=require(module)
local savedParts={}
for _,p in ipairs(rig:GetDescendants()) do if p:IsA("BasePart") then savedParts[p]=p.CFrame end end
local driver=animation.new(rig)
assert(#driver.joints>=30,"Incomplete Bramble rig")
for _,state in ipairs({"Idle","Walk","Run","Attack"}) do animation.Step(driver,state,0.8,0.1,true) end
for _,record in ipairs(driver.joints) do record.joint.C0=record.base end
for p,cf in pairs(savedParts) do p.CFrame=cf end
__PREPUBLISH_VALIDATE__
server.Enabled=true
local prior=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return Http:JSONEncode({ok=true,published=true,build=BUILD_ID,sourceVersion=prior,removedExternalScripts=report.removedScripts,joints=#driver.joints})
