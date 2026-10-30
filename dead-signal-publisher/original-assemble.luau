local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau');local J=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'))
local fps=R.deserializePlace(fs.readFile('/tmp/asset-15864801103.rbxl'))
local W=dm:GetService('Workspace');local SS=dm:GetService('ServerStorage');local RS=dm:GetService('ReplicatedStorage');local SSS=dm:GetService('ServerScriptService');local RF=dm:GetService('ReplicatedFirst');local SP=dm:GetService('StarterPlayer')
local guard="while not workspace:GetAttribute('GameMode') do task.wait(.1) end\nif workspace:GetAttribute('GameMode')~='Match' then return end\n"
local records={};local function mark(root,id)
 for _,s in ipairs(root:GetDescendants()) do if s:IsA('LuaSourceContainer') then
  s:SetAttribute('OriginalAsset',id);s:SetAttribute('OriginalPath',s:GetFullName());s:SetAttribute('OriginalLength',#s.Source)
  assert(not s.Source:match('require%s*%(%s*%d') and not s.Source:match('loadstring%s*%('),'Unreviewed external loader '..s:GetFullName())
 end end
end
mark(dm,'7902470429');mark(fps,'15864801103')
local function change(s,source,reason) s.Source=source;s:SetAttribute('CompatibilityChange',reason) end
local function transfer(src,dst) for _,c in ipairs(src:GetChildren()) do assert(not dst:FindFirstChild(c.Name),'Asset name collision '..c.Name);c.Parent=dst end end
-- Preserve the complete mansion hierarchy, tags, collision groups, puzzles and source GUI.
local social=SSS:FindFirstChild('SocialInteractions');if social then social:Destroy() end -- Studio installer / unrelated dev module
local editor=W:FindFirstChild('EditorOnly');if editor then editor:Destroy() end
-- Original FPS runtime and every module it loads; no shooter sample map imported.
transfer(fps:GetService('ReplicatedStorage'),RS)
local fpsSS=fps:GetService('ServerStorage');fpsSS.Library.Parent=SS
fps:GetService('ServerScriptService').Weapons.Parent=SSS
fps:GetService('ServerScriptService').Other.Parent=SSS
for _,name in ipairs({'Debris','WeaponToolsRespawn','Dummies'}) do local o=fps:GetService('Workspace'):FindFirstChild(name);if o then o.Parent=W end end
-- Retain the original dummy script but not the shooting range's dummy models.
for _,c in ipairs(W.Dummies:GetChildren()) do c:Destroy() end
for _,c in ipairs(W.WeaponToolsRespawn:GetChildren()) do c:Destroy() end
transfer(fps:GetService('SoundService'),dm:GetService('SoundService'))
transfer(fps:GetService('StarterPlayer').StarterPlayerScripts,SP.StarterPlayerScripts)
transfer(fps:GetService('StarterPlayer').StarterCharacterScripts,SP.StarterCharacterScripts)
transfer(fps:GetService('StarterGui'),dm:GetService('StarterGui'))
for _,name in ipairs({'ADS','DamageCorrection'}) do local o=fps:GetService('Lighting'):FindFirstChild(name);if o then o.Parent=dm:GetService('Lighting') end end
-- Original FPS expects R6 torso/joint names. Keep mansion R15 and map only these references.
for _,s in ipairs(dm:GetDescendants()) do if s:IsA('LuaSourceContainer') and s:GetAttribute('OriginalAsset')=='15864801103' then
 local source=s.Source
 source=source:gsub('char:WaitForChild%("Torso"%)','(char:FindFirstChild("UpperTorso") or char:WaitForChild("Torso"))')
 source=source:gsub('Character:WaitForChild%("Torso"%)','(Character:FindFirstChild("LowerTorso") or Character:WaitForChild("Torso"))')
 source=source:gsub('self%.Character%.Torso','(self.Character:FindFirstChild("UpperTorso") or self.Character.Torso)')
 if s.Name=='MouseTilt' then source=source:gsub('Right Shoulder','RightShoulder'):gsub('Left Shoulder','LeftShoulder') end
 if s.Name=='ContextActionUtility' then source=source:gsub('FixDefaultJumpButton%(%) %-%-Little','if isMobile then FixDefaultJumpButton() end --Little') end
 if s.Name=='Movement' and s.Parent==SP.StarterCharacterScripts then source="if game:GetService('UserInputService').TouchEnabled then return end\n"..source end
 if s.Name=='ClientHandler' then source=source:gsub('local function RenderStepped%(deltaTime%)','local function RenderStepped(deltaTime)\n if camera.CameraType == Enum.CameraType.Scriptable then return end') end
 if source~=s.Source then change(s,source,'R15 joint compatibility, touch movement or cinematic camera ownership') end
end end
-- Demo place-id checks otherwise enable cheats in every copied game.
local settings=RS.DemoGlobalSettings
change(settings,"return {gameplayEnabled=true,cheatsEnabled=false,skipGameCountdown=true,skipStartingEvent=true,forceSpawnInTheLobby=false,missionCompleteCheatEnabled=false,unlockFinalMissionEarly=false}",'Production settings for this universe; original campaign active')
-- Source game creates a second reserved lobby; this universe already has its own session menu.
local utils=RF.DemoUtils
change(utils,utils.Source:gsub('return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0','return workspace:GetAttribute("GameMode") == "Match"'),'Use current reserved match for original campaign')
local weaponServer=SSS.Weapons.WeaponsServer
change(weaponServer,weaponServer.Source:gsub('physicsServce:RegisterCollisionGroup%("(.-)"%)','pcall(function() physicsServce:RegisterCollisionGroup("%1") end)'),'Idempotent collision group registration shared with mansion')
-- Disable demo/admin/intro entry points; retain their original source for inspection.
for _,path in ipairs({SSS.Weapons.givecmd,SSS.Weapons.StarterWeapons,SSS.Other.Gamemode}) do path.Disabled=true;path:SetAttribute('DisabledReason','Demo entry point; mansion weapon pickups and campaign own progression') end
for _,s in ipairs(dm:GetService('StarterGui'):GetDescendants()) do if s:IsA('LocalScript') and (s.Name=='Gamemode' or s.Name=='GiveWeaponFrame' or s:GetFullName():find('.Intro.',1,true)) then s.Disabled=true;s:SetAttribute('DisabledReason','Shooting range UI/demo intro; original gameplay HUD remains active') end end
-- R15 uses the engine's standard locomotion; original FPS viewmodel animations remain unchanged.
local anim=SP.StarterCharacterScripts:FindFirstChild('Animate');if anim then anim.Disabled=true;anim.Name='FPSAnimateR6Archive';anim:SetAttribute('DisabledReason','R6 locomotion conflicts with mansion R15; source retained') end
local originalGui=R.Instance.new('Folder');originalGui.Name='OriginalStarterGui';originalGui.Parent=RS
for _,c in ipairs(dm:GetService('StarterGui'):GetChildren()) do c.Parent=originalGui end
-- Keep transition targets for source scripts, but suppress the imported title/white arrival.
local blackout=originalGui:FindFirstChild('Screenspace_Blackout')
if blackout then for _,d in ipairs(blackout:GetDescendants()) do
 if d.Name=='Title_01' or d.Name=='Quote_01' or d.Name=='Credits_01' then if d:IsA('GuiObject') then d.Visible=false end end
 if d.Name=='Black_Screen_A' then
  if d:IsA('GuiObject') then d.BackgroundColor3=R.Color3.new(0,0,0);d.BackgroundTransparency=1 end
  if d:IsA('ImageLabel') then d.ImageColor3=R.Color3.new(0,0,0);d.ImageTransparency=1 end
 end
end end
-- Static, script-free source foyer for the menu; no campaign geometry is changed.
local backdrop=R.Instance.new('Model');backdrop.Name='MenuBackdrop';backdrop.Parent=RS
for _,part in ipairs(W.Content.Interior.Foyer:GetDescendants()) do
 if part:IsA('BasePart') and part.Transparency<1 then
  local copy=part:Clone()
  for _,d in ipairs(copy:GetDescendants()) do
   if not (d:IsA('DataModelMesh') or d:IsA('SurfaceAppearance') or d:IsA('Texture') or d:IsA('Decal')) then d:Destroy() end
  end
  copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false;copy.Parent=backdrop
 end
end
local low=R.Vector3.new(math.huge,math.huge,math.huge);local high=R.Vector3.new(-math.huge,-math.huge,-math.huge)
for _,p in ipairs(backdrop:GetChildren()) do
 local pos=p.CFrame.Position;low=R.Vector3.new(math.min(low.X,pos.X-p.Size.X/2),math.min(low.Y,pos.Y-p.Size.Y/2),math.min(low.Z,pos.Z-p.Size.Z/2));high=R.Vector3.new(math.max(high.X,pos.X+p.Size.X/2),math.max(high.Y,pos.Y+p.Size.Y/2),math.max(high.Z,pos.Z+p.Size.Z/2))
end
assert(#backdrop:GetChildren()>20,'Menu source room missing')
local center=(low+high)/2
local eye=R.Vector3.new(center.X-3,low.Y+6,center.Z+(high.Z-low.Z)*.22)
backdrop:SetAttribute('CameraCFrame',R.CFrame.lookAt(eye,R.Vector3.new(center.X,low.Y+7,low.Z+2))*R.CFrame.Angles(0,0,math.rad(-3)))
backdrop:SetAttribute('DesignVersion','horror-reference-v1')
require('./original-gameplay-fixes')(dm)
require('./original-weapon-fixes')(dm)
require('./original-door-fixes')(dm)
-- Gate source scripts by mode without replacing their bodies.
for _,s in ipairs(dm:GetDescendants()) do if s:IsA('LuaSourceContainer') and s:GetAttribute('OriginalAsset') then
 local before=s.Source
 if s:IsA('Script') or s:IsA('LocalScript') then s.Source=guard..before end
 luau.load(s.Source,{debugName=s:GetFullName()})
 table.insert(records,{asset=s:GetAttribute('OriginalAsset'),path=s:GetAttribute('OriginalPath'),current=s:GetFullName(),originalLength=s:GetAttribute('OriginalLength'),change=s:GetAttribute('CompatibilityChange'),disabled=s:IsA('BaseScript') and s.Disabled or nil})
 end end
local function install(parent,name,class,file)
 local s=R.Instance.new(class);s.Name=name;s.Source=fs.readFile(file);luau.load(s.Source,{debugName=file});s.Parent=parent;return s
end
local runtime=R.Instance.new('Folder');runtime.Name='StillHereRuntime';runtime.Parent=SSS
install(runtime,'SessionProfile','ModuleScript','session-profile.luau');install(runtime,'SessionRuntime','Script','session-server.luau')
install(RS,'SettingsSchema','ModuleScript','settings-schema.luau')
install(RS,'SessionInterface','ModuleScript','session-interface.luau')
install(runtime,'PlayerSettings','Script','settings-server.luau')
install(RF,'SessionLoadingClient','LocalScript','session-loading-client.luau')
install(RF,'SessionMenuClient','LocalScript','session-menu-client.luau')
install(RF,'MenuAvatarClient','LocalScript','menu-avatar-client.luau')
install(RF,'OriginalUIBootstrap','LocalScript','original-ui-bootstrap.luau')
install(RF,'OriginalMissionHUD','LocalScript','original-mission-hud.luau')
install(runtime,'OriginalWeaponPickups','Script','original-weapon-pickups.luau')
for _,item in ipairs({{'SessionMenu','RemoteFunction'},{'SessionNotice','RemoteEvent'},{'PlayerSettings','RemoteFunction'}}) do local o=R.Instance.new(item[2]);o.Name=item[1];o.Parent=RS end
require('./blackhole-extract')(dm)
W:SetAttribute('DeadSignalBuildId','still-here-blackhole-repair-v7');W:SetAttribute('OriginalMansionAsset','7902470429');W:SetAttribute('OriginalFPSAsset','15864801103');W:SetAttribute('OriginalScriptCount',#records)
W:SetAttribute('IslandWorldReady',false)
local manifest=R.Instance.new('StringValue');manifest.Name='OriginalScriptManifest';manifest.Value=J.encode('json',records);manifest.Parent=SS
local region=R.Instance.new('TerrainRegion');region.Name='OriginalTerrain';region.SmoothGrid=W.Terrain.SmoothGrid;region.ExtentsMin=R.Vector3int16.new(-144,-64,-192);region.ExtentsMax=R.Vector3int16.new(144,100,144);region.Parent=SS
local city=R.deserializePlace(fs.readFile('/tmp/asset-186677844.rbxl'));W.Terrain.SmoothGrid=city:GetService('Workspace').Terrain.SmoothGrid
local world=R.Instance.new('Folder');world.Name='OriginalWorld';world.Parent=SS
for _,c in ipairs(W:GetChildren()) do if not c:IsA('Terrain') and not c:IsA('Camera') then c.Parent=world end end
-- Source layout and all source dependency names remain intact when entering a match.
local init=fs.readFile('original-initialize.luau');luau.load(init,{debugName='original-initialize'})
local boot=R.Instance.new('Script');boot.Name='OriginalInitializer';boot.Source=init;boot.Parent=runtime
W.StreamingEnabled=true;W.StreamingMinRadius=64;W.StreamingTargetRadius=192
SP.CameraMode=R.Enum.CameraMode.LockFirstPerson;SP.CameraMinZoomDistance=.5;SP.CameraMaxZoomDistance=.5
SP.CharacterWalkSpeed=12
dm:GetService('Players').CharacterAutoLoads=false
fs.writeFile('/tmp/still-here-original.rbxl',R.serializePlace(dm))
local bundle=R.Instance.new('Model');bundle.Name='OriginalBundle';for k,v in pairs(W:GetAttributes()) do bundle:SetAttribute(k,v) end
for _,service in ipairs({'ServerStorage','ServerScriptService','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting'}) do local f=R.Instance.new('Folder');f.Name=service;f.Parent=bundle;for _,c in ipairs(dm:GetService(service):GetChildren()) do c.Parent=f end end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do local f=R.Instance.new('Folder');f.Name=name;f.Parent=bundle;for _,c in ipairs(SP[name]:GetChildren()) do c.Parent=f end end
fs.writeFile('/tmp/original-payload.rbxm',R.serializeModel({bundle}))
print('ORIGINAL SYSTEMS ASSEMBLED '..J.encode('json',{scripts=#records,sourceMansion='7902470429',sourceFPS='15864801103'}))
