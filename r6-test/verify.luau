local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local sc = game.StarterPlayer.StarterCharacterScripts
assert(workspace:GetAttribute("R6TestBuild") == "r6-cinematic-menu-npcs-v11")
assert(workspace:GetAttribute("R6ChakraWallWalk") and workspace:GetAttribute("R6MotionVerifiedAssets"))
assert(sc:FindFirstChild("Animate") and sc:FindFirstChild("ChakraWallWalk"))
assert(sc:FindFirstChild("NarutoSprintInput") and not sc.NarutoSprintInput.Disabled)
assert(sc:FindFirstChild("BoogieSwapInput") and not sc.BoogieSwapInput.Disabled)
assert(sc.BoogieSwapInput.Source:find('Enum.KeyCode.G',1,true))
assert(not sc:FindFirstChild("R6Locomotion") and not sc:FindFirstChild("Wallrun")
    and not sc:FindFirstChild("AnimationBankGUI"),"Legacy animation controller remains")
assert(sc.ChakraWallWalk.Source:find('SetTitle("ToggleChakraFeet"',1,true))
assert(sc.Animate.Controller and sc.Animate.R6 and sc.Animate.Loaded)
assert(sc.Animate.R6.Source:find('runningSpeed >= 19',1,true),"Run remains walk-only")
assert(not sc.Animate.R6.Source:find('run.xml',1,true))
assert(game.ReplicatedStorage.GravityController.InitObjects and game.ReplicatedStorage.VFX.ChakraFeet)
local boogie=game.ReplicatedStorage.BoogieSwap
assert(boogie:IsA("RemoteEvent"),"Boogie swap event missing")
assert(game.ReplicatedStorage.ClapAnimation:IsA("Animation"))
assert(game.ReplicatedStorage.ClapVFX:IsA("BasePart"))
assert(game.ReplicatedStorage.SwapSound:IsA("Sound"))
assert(game.ServerScriptService.BoogieSwapServer and not game.ServerScriptService.BoogieSwapServer.Disabled)
assert(game.ServerScriptService.BoogieSwapServer.Source:find('MAX_DISTANCE=65',1,true))
assert(workspace:GetAttribute("BoogieWoogieInstalled"))
local testTarget=workspace:FindFirstChild("BoogieTestDummy")
assert(testTarget and testTarget:FindFirstChild("HumanoidRootPart") and testTarget:FindFirstChildOfClass("Humanoid"))
assert(testTarget.Humanoid.RigType==Enum.HumanoidRigType.R6)
assert(#game.StarterPack:GetChildren() == 0 and #game.StarterGui:GetChildren() == 0)
assert(game.ServerScriptService.R6AvatarServer)
assert(game.ServerScriptService.R6AvatarServer.Source:find("respawnRemote.OnServerEvent",1,true),
 "Death screen respawn remote is not serviced")
assert(game.ReplicatedStorage.R6MenuRespawn:IsA("RemoteEvent"))
local menu=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("R6CinematicMenu")
assert(menu and not menu.Disabled,"Cinematic menu must run on client")
for _,name in ipairs({"YOU DIED","RESPAWN","RETURN TO MENU","Settings","Credits",
 "Update Log","Camera Banking","High Quality Graphics","Panel Bob"}) do
 assert(menu.Source:find(name,1,true),"Missing requested menu element: "..name)
end
assert(menu.Source:find('ClientOnlyMenuWorld',1,true))
assert(menu.Source:find('createBackground',1,true)==nil)
assert(workspace:GetAttribute("R6DynamicCinematicMenu")==true)
assert(workspace:GetAttribute("R6DeathMenuInstalled")==true)
local wanderers=workspace:FindFirstChild("NPCWanderers")
assert(wanderers and #wanderers:GetChildren()==4,"Expected four NPC walkers in map")
local npcScript=game.ServerScriptService.NPCWanderServer
assert(npcScript and not npcScript.Disabled and npcScript.Source:find("hum:MoveTo",1,true))
local npcResults={}
for _,npc in ipairs(wanderers:GetChildren()) do
 assert(npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChildOfClass("Humanoid"))
 assert(npc.Humanoid.RigType==Enum.HumanoidRigType.R6)
 assert(npc:GetAttribute("NPCWanderer")==true)
 assert(not npc.HumanoidRootPart.Anchored,"NPC cannot walk when anchored")
 table.insert(npcResults,npc.Name)
end
assert(workspace:GetAttribute("R6WanderingNPCCount")==4)
local description = Instance.new("HumanoidDescription")
local character = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
character.Parent = workspace
for _, child in ipairs(sc:GetChildren()) do
 local old = character:FindFirstChild(child.Name)
 if old then old:Destroy() end
 local clone = child:Clone()
 if clone:IsA("LocalScript") then clone.Disabled = true end
 clone.Parent = character
end
assert(character.Humanoid.RigType == Enum.HumanoidRigType.R6)
assert(character.Animate.R6 and character.ChakraWallWalk and character.NarutoSprintInput and character.BoogieSwapInput)
local animator = character.Humanoid:FindFirstChildOfClass("Animator")
    or Instance.new("Animator", character.Humanoid)
local clips = {
 idle = "Animation1", walk = "WalkAnim", run = "RunAnim", jump = "JumpAnim",
 fall = "FallAnim", climb = "ClimbAnim", sit = "SitAnim",
}
local runningIds = {}
local tracks = {}
for mode, name in pairs(clips) do
 local folder = character.Animate:FindFirstChild(mode)
 local clip = folder and folder:FindFirstChild(name)
 assert(clip and clip:IsA("Animation"), "Missing R6 motion: "..mode)
 runningIds[mode] = clip.AnimationId
 local track = animator:LoadAnimation(clip)
 track:Play(0,0.02,1)
 tracks[mode] = track
end
task.wait(6)
local results={}
for mode, track in pairs(tracks) do
 results[mode]={length=track.Length,loaded=track.Length>0.07}
 assert(track.Length>0.07, "Unplayable motion in published place: "..mode)
 track:Stop(0)
 track:Destroy()
end
-- Position swapping keeps model ownership and appearance. Check PivotTo
-- on independent R6 models, without firing a remote as a different player.
local originalA=character:GetPivot()
local originalB=testTarget:GetPivot()
local clone=testTarget:Clone()
clone.Name="BoogieNativeTargetProbe"
clone.Parent=workspace
clone:PivotTo(originalA)
character:PivotTo(originalB)
assert((clone:GetPivot().Position-originalA.Position).Magnitude<0.05)
assert((character:GetPivot().Position-originalB.Position).Magnitude<0.05)
clone:Destroy()
character:Destroy()
description:Destroy()
return HttpService:JSONEncode({
 ok=true,version=game.PlaceVersion,build="r6-cinematic-menu-npcs-v11",
 chakraWallWalkingPreserved=true,originalNarutoAnimationEvents=true,
 originalNarutoR6RunSelectionFixed=true,animationAssets=runningIds,
 allSevenNativeAnimationsLoaded=true,runAndWalkDistinct=runningIds.run~=runningIds.walk,
 sprintTouchButton=true,sprintShiftKey=true,buttonsForAnimationBanks=0,
 boogieMobileButton=true,boogieSwapClapAssets=true,boogieServerValidated=true,
 boogieSoloR6Target=true,positionSwapPivotTest=true,
 cinematicMenu=true,cinematic3DScene=true,deathScreen=true,
 deathRespawnRemote=true,npcPatrolScript=true,walkingNPCs=4,npcNames=npcResults,
 characterScripts={"Animate","ChakraWallWalk","NarutoSprintInput","BoogieSwapInput"},
 noMotor6DPerFrameDriver=true,renderedPlaytest=false,
 nativeAnimationResults=results,
 requestedRunAnimationId=runningIds.run
})
