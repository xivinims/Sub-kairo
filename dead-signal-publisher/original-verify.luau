local W=workspace;local RS=game:GetService('ReplicatedStorage');local SS=game:GetService('ServerStorage');local SSS=game:GetService('ServerScriptService');local SP=game:GetService('StarterPlayer')
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
assert(W:GetAttribute('ExperienceChapter')==1,'Chapter 1 experience marker missing')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-chapter-two-greenhouse-v2','Wrong build')
assert(W.Content.Interior.Foyer and W.Content.Interior.Kitchen and SS.Corrupt.Grandfather,'Original mansion dependencies missing')
assert(SSS.GameStateManager.Enabled and SSS.MissionsLogic.Enabled and SSS.EventManager.Enabled,'Original campaign scripts disabled')
assert(SSS.Weapons.WeaponsServer.Enabled,'Original weapon server disabled')
assert(RS.OriginalStarterGui.HUD and RS.OriginalStarterGui.MainHud and RS.OriginalStarterGui.MobileButtons,'Source GUI incomplete')
assert(SP.StarterPlayerScripts.GameStateClient.Enabled and SP.StarterPlayerScripts.EventManagerClient.Enabled,'Original UI controllers missing')
assert(SP.StarterCharacterScripts.GrabSystem.GrabClient.Enabled,'Original grab control missing')
assert(not SP.StarterPlayerScripts:FindFirstChild('MansionUIClient') and not SSS:FindFirstChild('AtriumRuntime'),'Adapted controllers still active')
assert(RS.MenuBackdrop:GetAttribute('DesignVersion')=='horror-reference-v1','Menu design missing')
assert(#RS.MenuBackdrop:GetChildren()>20,'Menu scene empty')
for _,d in ipairs(RS.MenuBackdrop:GetDescendants()) do assert(not d:IsA('LuaSourceContainer'),'Menu scene contains executable code') end
assert(W:GetAttribute('GameplayFixVersion')=='r15-stability-v3','Movement fixes missing')
assert(not W.Content.Exterior.Props.Vechicles:FindFirstChild('SUV_Damaged'),'Wreck still present')
assert(not SP.StarterCharacterScripts.Movement.Enabled and not SP.StarterCharacterScripts.BodyVisible.Enabled,'Competing locomotion/body scripts enabled')
assert(not RS.OriginalStarterGui.Scripts.Game.MouseTilt.Enabled,'R6 joint writer active')
assert(game:GetService('ReplicatedFirst').OriginalMissionHUD.Enabled,'Top mission HUD missing')
assert(RS.ChapterTwoMap:IsA('ModuleScript'),'Chapter 2 map module missing')
assert(SSS.StillHereRuntime:FindFirstChild('ChapterTwoRuntime'),'Chapter 2 gameplay runtime missing')
assert(game:GetService('ReplicatedFirst').ChapterTwoHUD.Enabled,'Chapter 2 objective HUD missing')
assert(game:GetService('ReplicatedFirst').OriginalWeaponHoldPrompt.Enabled,'Touch weapon hold button missing')
assert(RS.PlayerSettings:IsA('RemoteFunction') and RS.SessionInterface and RS.SettingsSchema,'Preferences infrastructure missing')
assert(require(RS.DemoGlobalSettings).skipStartingEvent,'Imported title sequence still enabled')
assert(game:GetService('ReplicatedFirst').SessionLoadingClient.Enabled,'Unified loading missing')
assert(game:GetService('ReplicatedFirst').MenuAvatarClient.Enabled,'Floating menu avatar missing')
local visualClient=game:GetService('ReplicatedFirst'):FindFirstChild('CinematicEnvironmentClient')
assert(visualClient and visualClient.Enabled,'Heavy cinematic lighting controller missing')
assert(visualClient.Source:find('9045936046',1,true),'Massive Black Hole menu audio missing')
assert(visualClient.Source:find('Light',1,true),'Cinematic effects missing')
assert(W:GetAttribute('WeaponFixVersion')=='original-touch-v5','Weapon fixes missing')
assert(W:GetAttribute('OriginalWeaponPickupCount')==2,'Pickup spawn failed')
for _,name in ipairs({'M4A1','Deagle'}) do local tool=W.WeaponToolsRespawn:FindFirstChild(name);local prompt=tool and tool.Weapon.PrimaryPart:FindFirstChild('OriginalWeaponPickup');assert(prompt,'Missing world pickup '..name);assert(prompt.Style==Enum.ProximityPromptStyle.Custom and prompt.HoldDuration>=.4,'Weapon pickup hold interaction not configured') end
local cfg=require(game:GetService('ReplicatedFirst').DemoConfig)
local missions=0;for name,mission in pairs(cfg.Missions) do assert(mission.MissionRoot,'Mission root missing '..name);missions+=1 end
local parts,tagged=0,0;for _,d in ipairs(W.Content:GetDescendants()) do if d:IsA('BasePart') then parts+=1 end;if #game:GetService('CollectionService'):GetTags(d)>0 then tagged+=1 end end
assert(parts>13000 and tagged>10,'Original geometry/tags incomplete')
local sources=0;for _,d in ipairs(game:GetDescendants()) do if d:IsA('LuaSourceContainer') and d:GetAttribute('OriginalAsset') then sources+=1 end end
assert(sources>250,'Original scripts incomplete')
assert(RS.Library.Shared.WeaponsHandler.BaseWeapon.Gun.Hitscan and SS.Library.WeaponsServerModule,'Original FPS dependency tree missing')
assert(RS.SkyBlackHoleTemplate:GetAttribute('SourceAsset')=='7208091524','Black hole missing')
local originalView=RS.SkyBlackHoleTemplate:GetAttribute('SourceViewDirection')
assert(typeof(originalView)=='Vector3' and originalView.X>.9,'Original black-hole viewing angle absent')
assert(RS.SkyBlackHoleTemplate:GetAttribute('SourceHaloDiameter')>210,'Original halo diameter missing')
assert(RS.SkyBlackHoleTemplate:GetAttribute('OriginalDebrisAnimationId')=='7239753826','Original rock animation absent')
assert(RS.SkyBlackHoleTemplate:GetAttribute('OriginalDebrisBoneCount')==162,'Not all original 160 rocks were preserved')
local originalField=RS.SkyBlackHoleTemplate:FindFirstChild('DebrisField')
assert(originalField and originalField:FindFirstChildOfClass('AnimationController'),'Original DebrisField controller missing')
local rockBones=0;for _,d in ipairs(originalField:GetDescendants()) do if d:IsA('Bone') then rockBones+=1 end end
assert(rockBones==162,'The source DebrisField skeleton was reduced')
assert(RS.SkyBlackHoleTemplate.BlackHole.Model.Singularity.Halo:IsA('BasePart'),'Original singularity not mounted')
local beams=0;for _,v in ipairs(RS.SkyBlackHoleTemplate:GetDescendants()) do if v:IsA('Beam') then beams+=1 end end
assert(beams>=20,'Original black-hole rays were dropped')
-- Only the mansion's original campaign doors remain; never impose player-made locks.
local doors=require(SSS.DoorManager);doors.Init()
local originalDoors=0
assert(W:GetAttribute('DoorLockVersion')=='original-only-v2','Custom locks were not removed')
assert(not SSS.DoorManager.Source:find('InstallPlayerLock',1,true),'Custom door-lock script still installed')
for _,door in ipairs(game:GetService('CollectionService'):GetTagged('Door')) do
 if door:IsDescendantOf(W) then
  originalDoors+=1
  assert(not door.TargetR_Closed:FindFirstChild('DoubleClickLock'),'Custom double-click door detector remains')
  assert(not door.TargetR_Closed:FindFirstChild('PlayerDoorLock'),'Custom player lock prompt remains')
  doors.EnableDoor(door,false)
  assert(not doors.IsEnabled(door),'Campaign-locked door opened')
  doors.EnableDoor(door,true)
 end
end
assert(originalDoors>0,'Original mansion doors missing')
local fpsLoaded=false
if game:GetService('RunService'):IsServer() then
 local lib=require(RS.Library);local deadline=os.clock()+40
 repeat task.wait(.1) until lib.Loaded or os.clock()>deadline
 assert(lib.Loaded,'Original FPS server library initialization timed out')
 assert(lib.WeaponsHandler.CreateWeapon,'Original weapon factory missing')
 for _,group in ipairs({'Player','NonPlayer'}) do pcall(function() game:GetService('PhysicsService'):RegisterCollisionGroup(group) end) end
 for _,name in ipairs({'M4A1','Deagle'}) do local tool=lib.WeaponsHandler.CreateWeapon(name);assert(tool and tool.Weapon.PrimaryPart,'Original weapon factory failed '..name);tool:Destroy() end
 fpsLoaded=true
end
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=W:GetAttribute('DeadSignalBuildId'),originalScripts=sources,missions=missions,parts=parts,tagged=tagged,gameplayFixes=W:GetAttribute('GameplayFixVersion'),wreckRemoved=true,preferences=true,originalDoors=originalDoors,customDoorLocks=false,weaponFixes=W:GetAttribute('WeaponFixVersion'),pickups=W:GetAttribute('OriginalWeaponPickupCount'),importedIntroDisabled=true,menuDesign=RS.MenuBackdrop:GetAttribute('DesignVersion'),originalHUD=true,originalFPS=true,fpsServerLoaded=fpsLoaded})
