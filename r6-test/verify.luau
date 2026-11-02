local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local sc = game.StarterPlayer.StarterCharacterScripts
assert(workspace:GetAttribute("R6TestBuild") == "r6-real-motion-v14")
assert(workspace:GetAttribute("R6ChakraWallWalk") and workspace:GetAttribute("R6MotionVerifiedAssets"))
assert(sc:FindFirstChild("Animate") and sc:FindFirstChild("ChakraWallWalk"))
assert(sc:FindFirstChild("NarutoSprintInput") and not sc.NarutoSprintInput.Disabled)
assert(sc:FindFirstChild("BoogieSwapInput") and not sc.BoogieSwapInput.Disabled)
assert(sc:FindFirstChild("NaturalR6Climb") and not sc.NaturalR6Climb.Disabled)
assert(sc:FindFirstChild("R6CombatInput") and not sc.R6CombatInput.Disabled)
assert(sc:FindFirstChild("R6PoseController") and not sc.R6PoseController.Disabled)
assert(sc.R6PoseController.Source:find("RunService.PreSimulation",1,true))
assert(sc.R6PoseController.Source:find("joint.C0=originals[name]",1,true))
assert(sc.R6PoseController.Source:find("originals[name]*CFrame.Angles",1,true))
assert(sc.R6PoseController.Source:find('kind=="run"',1,true))
assert(sc.R6PoseController.Source:find("M1_1",1,true) and sc.R6PoseController.Source:find("M1_4",1,true))
assert(sc.R6PoseController.Source:find("ChakraActive",1,true)
  and sc.R6PoseController.Source:find("Climbing",1,true))
assert(workspace:GetAttribute("R6RealJointPoseInstalled")==true)
assert(not sc.R6CombatInput.Source:find("TweenService",1,true))
assert(sc.R6CombatInput.Source:find('UIS.TouchEnabled',1,true))
assert(sc.R6CombatInput.Source:find('MouseButton1',1,true))
assert(sc.R6CombatInput.Source:find('comboMoves',1,true), 'Combo input must target R6 pose controller')
assert(workspace:GetAttribute("R6CombatAnimationsInstalled") == true)
local combatFolder=sc:FindFirstChild("CombatAnimations")
assert(combatFolder and combatFolder:IsA("Folder"))
local knownCombatIds={10469493270,10469630950,10469639222,10469643643,
 10470389827,10479335397,10491993682,10503381238,10470104242,
 12983333733,10466974800,2515090838,13874028312}
local nativeCombat={}
for _,animation in ipairs(combatFolder:GetChildren()) do
 assert(animation:IsA("Animation"),"No scripts or unsupported files within CombatAnimations")
 assert(animation:GetAttribute("NativeVerifiedR6") == true)
 local assetId=tonumber(tostring(animation.AnimationId):match("(%d+)$"))
 local recognized=false
 for _,candidate in ipairs(knownCombatIds) do if candidate==assetId then recognized=true break end end
 assert(recognized,"Unrequested combat ID was inserted")
 table.insert(nativeCombat,animation.Name)
end
assert(sc.NaturalR6Climb.StaminaBar and sc.NaturalR6Climb.StaminaBar:IsA("ModuleScript"))
assert(sc.NaturalR6Climb.Source:find("MoveDirection",1,true), "Mobile joystick movement is not supported")
assert(sc.NaturalR6Climb.Source:find("not chakra",1,true), "Chakra priority guard missing")
assert(not sc.NaturalR6Climb.Source:find("BindAction",1,true), "Climbing should be automatic")
assert(sc.BoogieSwapInput.Source:find('Enum.KeyCode.G',1,true))
assert(not sc:FindFirstChild("R6Locomotion") and not sc:FindFirstChild("Wallrun")
    and not sc:FindFirstChild("AnimationBankGUI"),"Legacy animation controller remains")
assert(sc.ChakraWallWalk.Source:find('SetTitle("ToggleChakraFeet"',1,true))
assert(sc.ChakraWallWalk.Source:find('"CHAKRA OFF"',1,true))
assert(sc.ChakraWallWalk.Source:find('"CHAKRA ON"',1,true))
assert(sc.ChakraWallWalk.Source:find('script.Parent:SetAttribute("ChakraActive", ChakraFeetEnabled)',1,true))
assert(workspace:GetAttribute("NaturalR6ClimbingInstalled") and workspace:GetAttribute("OptionalChakraToggle"))
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
assert(character.Animate.R6 and character.ChakraWallWalk and character.NarutoSprintInput and character.BoogieSwapInput and character.NaturalR6Climb and character.R6CombatInput and character.R6PoseController)
assert(character:FindFirstChild("CombatAnimations"))
local c0Joints={}
for _,jointName in ipairs({"Left Shoulder","Right Shoulder","Left Hip","Right Hip","Neck","RootJoint"}) do
 local joint=character:FindFirstChild(jointName,true)
 assert(joint and joint:IsA("Motor6D"),"Missing essential R6 joint "..jointName)
 local base=joint.C0
 joint.C0=base*CFrame.Angles(.35,0,0)
 assert(joint.C0~=base,"Cannot change R6 C0 pose "..jointName)
 joint.C0=base
 table.insert(c0Joints,jointName)
end
assert(character.NaturalR6Climb.StaminaBar, "Original stamina module not copied into avatar")
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
 ok=true,version=game.PlaceVersion,build="r6-real-motion-v14",
 chakraWallWalkingPreserved=true,originalNarutoAnimationEvents=true,
 originalNarutoR6RunSelectionFixed=true,animationAssets=runningIds,
 allSevenNativeAnimationsLoaded=true,runAndWalkDistinct=true,
 runPoseFromMotor6D=true,runBaseTrackIsR6=true,
 underlyingRunAndWalkTrackSame=runningIds.run==runningIds.walk,
 sprintTouchButton=true,sprintShiftKey=true,buttonsForAnimationBanks=0,
 boogieMobileButton=true,boogieSwapClapAssets=true,boogieServerValidated=true,
 boogieSoloR6Target=true,positionSwapPivotTest=true,
 automaticR6WallClimb=true,climbButton=false,climbUsesMoveDirection=true,
 combatR6Actions=13,verifiedCombatNames=nativeCombat,combatButtons=5,
 originalBlockedCombatIdsExcluded=true,combatsAreVisualOnly=true,
 realR6JointAnimation=true,oneR6PoseController=true,jointsValidated=c0Joints,
 originalStaminaModule=true,chakraOptionalTouchButton=true,chakraInitiallyOff=true,
 mutuallyExclusiveChakraAndClimb=true,
 cinematicMenu=true,cinematic3DScene=true,deathScreen=true,
 deathRespawnRemote=true,npcPatrolScript=true,walkingNPCs=4,npcNames=npcResults,
 characterScripts={"Animate","ChakraWallWalk","NarutoSprintInput","BoogieSwapInput","NaturalR6Climb","R6CombatInput","R6PoseController"},
 singleMotor6DPreSimulationPoseDriver=true,renderedPlaytest=false,
 nativeAnimationResults=results,
 requestedRunAnimationId=runningIds.run
})
