local W=workspace;local RS=game:GetService('ReplicatedStorage');local SS=game:GetService('ServerStorage');local SSS=game:GetService('ServerScriptService');local SP=game:GetService('StarterPlayer')
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-interface-v4','Wrong build')
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
assert(RS.PlayerSettings:IsA('RemoteFunction') and RS.SessionInterface and RS.SettingsSchema,'Preferences infrastructure missing')
assert(require(RS.DemoGlobalSettings).skipStartingEvent,'Imported title sequence still enabled')
assert(game:GetService('ReplicatedFirst').SessionLoadingClient.Enabled,'Unified loading missing')
local cfg=require(game:GetService('ReplicatedFirst').DemoConfig)
local missions=0;for name,mission in pairs(cfg.Missions) do assert(mission.MissionRoot,'Mission root missing '..name);missions+=1 end
local parts,tagged=0,0;for _,d in ipairs(W.Content:GetDescendants()) do if d:IsA('BasePart') then parts+=1 end;if #game:GetService('CollectionService'):GetTags(d)>0 then tagged+=1 end end
assert(parts>13000 and tagged>10,'Original geometry/tags incomplete')
local sources=0;for _,d in ipairs(game:GetDescendants()) do if d:IsA('LuaSourceContainer') and d:GetAttribute('OriginalAsset') then sources+=1 end end
assert(sources>250,'Original scripts incomplete')
assert(RS.Library.Shared.WeaponsHandler.BaseWeapon.Gun.Hitscan and SS.Library.WeaponsServerModule,'Original FPS dependency tree missing')
assert(RS.SkyBlackHoleTemplate:GetAttribute('SourceAsset')=='7208091524','Black hole missing')
-- Run the original config/door setup, not an imitation of the source controller.
require(SSS.DoorManager).Init()
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
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=W:GetAttribute('DeadSignalBuildId'),originalScripts=sources,missions=missions,parts=parts,tagged=tagged,gameplayFixes=W:GetAttribute('GameplayFixVersion'),wreckRemoved=true,preferences=true,importedIntroDisabled=true,menuDesign=RS.MenuBackdrop:GetAttribute('DesignVersion'),originalHUD=true,originalFPS=true,fpsServerLoaded=fpsLoaded})
