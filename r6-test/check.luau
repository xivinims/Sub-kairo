local fs=require("@lune/fs")
local R=require("@lune/roblox")
local S=require("@lune/serde")
local L=require("@lune/luau")
local g=R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local m=S.decode("json",fs.readFile("r6-test/animation-manifest.json"))
assert(g.Workspace:GetAttribute("R6TestBuild")=="r6-original-best-run-v15")
assert(g.Workspace:GetAttribute("R6ChakraWallWalk")==true)
assert(m.source=="WallWalkNarutoV1(5).rbxl")
local sc=g.StarterPlayer.StarterCharacterScripts
assert(#sc:GetChildren()==9 and sc:FindFirstChild("Animate")
 and sc:FindFirstChild("ChakraWallWalk") and sc:FindFirstChild("NarutoSprintInput") and sc:FindFirstChild("BoogieSwapInput") and sc:FindFirstChild("NaturalR6Climb")
 and sc:FindFirstChild("R6CombatInput") and sc:FindFirstChild("R6PoseController") and sc:FindFirstChild("CombatAnimations")
 and sc:FindFirstChild("R6RunSource"))
assert(#sc.R6RunSource:GetChildren()==3)
for title,count in pairs({["Run1 [by M0rsDev]"]=40,["Run2 [by Gusthabuo777]"]=41,
 ["Run3 [by Newb1e27]"]=17}) do
 local original=sc.R6RunSource:FindFirstChild(title)
 assert(original and original:IsA("KeyframeSequence"),"Missing source R6 run clip: "..title)
 assert(#original:GetChildren()==count,"Original R6 run keyframes modified: "..title)
end
assert(m.originalR6Run and m.originalR6Run.assetId==136548520660837)
assert(m.originalR6Run.modifiedOriginals==false)
assert(m.originalR6Run.selected=="Run3 [by Newb1e27]")
assert(m.originalR6Run.sourceHash==S.hash("sha256",fs.readFile("r6-test/free-r6-run-model.rbxm")))
assert(sc.R6PoseController.Source:find("originalR6RunCF",1,true))
assert(sc.R6PoseController.Source:find("originals[name]*originalPose",1,true))
assert(sc.R6PoseController:IsA("LocalScript") and not sc.R6PoseController.Disabled)
assert(sc.R6PoseController.Source==fs.readFile("r6-test/r6-pose-controller.luau"))
assert(sc.R6PoseController.Source:find("RunService.PreSimulation",1,true))
assert(sc.R6PoseController.Source:find("joint.C0=originals[name]",1,true))
assert(sc.R6PoseController.Source:find("Motor6D",1,true))
assert(sc.R6PoseController.Source:find("M1_4",1,true))
assert(sc.R6PoseController.Source:find("R6CombatAction",1,true))
assert(not sc.R6CombatInput.Disabled and sc.R6CombatInput:IsA("LocalScript"))
assert(sc.R6CombatInput.Source==fs.readFile("r6-test/combat-client.luau"))
assert(sc.R6CombatInput.Source:find("M1_4",1,true))
assert(sc.R6CombatInput.Source:find("UIS.TouchEnabled",1,true))
assert(sc.R6CombatInput.Source:find("CombatBlocking",1,true))
assert(sc.NaturalR6Climb.StaminaBar and not sc.NaturalR6Climb.Disabled)
assert(sc.NaturalR6Climb.Source==fs.readFile("r6-test/natural-climb-r6.luau"))
assert(sc.NaturalR6Climb.StaminaBar.Source==fs.readFile("r6-test/climb-stamina-original.luau"))
assert(sc.NaturalR6Climb.Source:find("humanoid.MoveDirection",1,true))
assert(sc.NaturalR6Climb.Source:find("ChakraActive",1,true))
assert(not sc.NaturalR6Climb.Source:find("BindAction",1,true), "Natural climbing must have NO button")
assert(sc.BoogieSwapInput.Source==fs.readFile("r6-test/boogie-input.luau"))
assert(not sc.BoogieSwapInput.Disabled)
assert(sc.BoogieSwapInput.Source:find("Enum.KeyCode.G",1,true))
assert(not sc.NarutoSprintInput.Disabled)
assert(sc.NarutoSprintInput.Source==fs.readFile("r6-test/sprint-input.luau"))
assert(sc.Animate.R6.Source:find('runningSpeed >= 19',1,true))
assert(not sc.Animate.R6.Source:find('run.xml',1,true))
assert(m.patchedNarutoR6Motion and m.selectedAnimationIds)
local animNames={idle="Animation1",walk="WalkAnim",run="RunAnim",jump="JumpAnim",fall="FallAnim",climb="ClimbAnim",sit="SitAnim"}
for mode,name in pairs(animNames) do
 local target=sc.Animate:FindFirstChild(mode)
 assert(target and #target:GetChildren()==1 and target:FindFirstChild(name), "R6 mode missing: "..mode)
 local id=m.selectedAnimationIds[mode]
 assert(id and tostring(target[name].AnimationContent):find(tostring(id),1,true),"R6 selected ID mismatch: "..mode)
 local details=m.nativeCandidateMeasurements[tostring(id)]
 assert(details and details.loaded and details.length>0.07,"Unplayable R6 animation selected for "..mode)
end
assert(sc.Animate.Source and sc.Animate.R6 and sc.Animate.Controller)
assert(S.hash("sha256",sc.Animate.Source)==m.originalSHA256.Animate)
assert(not sc.ChakraWallWalk.Disabled)
assert(sc.ChakraWallWalk.Source:find('SetTitle("ToggleChakraFeet"',1,true))
assert(sc.ChakraWallWalk.Source:find('"CHAKRA OFF"',1,true))
assert(sc.ChakraWallWalk.Source:find('"CHAKRA ON"',1,true))
assert(sc.ChakraWallWalk.Source:find('script.Parent:SetAttribute("ChakraActive", ChakraFeetEnabled)',1,true))
assert(sc.ChakraWallWalk.Source:find('Enum.KeyCode.B',1,true))
assert(not sc:FindFirstChild("Wallrun") and not sc:FindFirstChild("R6Locomotion"))
local ps=g.StarterPlayer.StarterPlayerScripts
assert(#ps:GetChildren()==3 and ps.RbxCharacterSounds and ps.PlayerScriptsLoader and ps.R6CinematicMenu)
assert(ps.PlayerScriptsLoader.Loaded.Value==true and ps.PlayerScriptsLoader.Disabled)
assert(g.ReplicatedStorage.GravityController and g.ReplicatedStorage.DrawClass and g.ReplicatedStorage.VFX.ChakraFeet)
for name, hash in pairs(m.originalSHA256) do
 if name~="WallWalk" then
  local src=(name=="Animate" and sc.Animate)
   or (name=="RbxCharacterSounds" and ps.RbxCharacterSounds)
   or g.ReplicatedStorage:FindFirstChild(name)
  assert(src and S.hash("sha256",src.Source)==hash,"Original Naruto script changed: "..name)
 end
end
local count=0
for _,obj in ipairs(g:GetDescendants()) do
 if obj:IsA("LuaSourceContainer") then L.compile(obj.Source);count+=1 end
end
assert(#g.ServerScriptService:GetChildren()==3 and g.ServerScriptService.R6AvatarServer)
assert(g.ServerScriptService.R6AvatarServer.Source==fs.readFile("r6-test/avatar-server.luau"))
assert(g.ServerScriptService.R6AvatarServer.Source:find("respawnRemote.OnServerEvent",1,true))
assert(g.ServerScriptService.NPCWanderServer and
 g.ServerScriptService.NPCWanderServer.Source==fs.readFile("r6-test/npc-wander-server.luau"))
assert(g.ServerScriptService.NPCWanderServer.Source:find("MoveTo(",1,true))
local ps=g.StarterPlayer.StarterPlayerScripts
assert(ps.R6CinematicMenu and ps.R6CinematicMenu.Source==fs.readFile("r6-test/cinematic-menu-client.luau"))
assert(not ps.R6CinematicMenu.Disabled)
for _,text in ipairs({"YOU DIED","RESPAWN","RETURN TO MENU","UPDATE LOG",
 "Settings","Credits","Camera Banking","Neon Glow Pulse","createBackground"}) do
 if text~="createBackground" then
  assert(ps.R6CinematicMenu.Source:find(text,1,true),"Cinematic GUI missing: "..text)
 end
end
assert(g.ReplicatedStorage.R6MenuRespawn and g.ReplicatedStorage.R6MenuRespawn:IsA("RemoteEvent"))
local walkers=g.Workspace:FindFirstChild("NPCWanderers")
assert(walkers and #walkers:GetChildren()==4)
for _,npc in ipairs(walkers:GetChildren()) do
 assert(npc.Humanoid.RigType==R.Enum.HumanoidRigType.R6)
 assert(npc:GetAttribute("NPCWanderer")==true)
 assert(npc.HumanoidRootPart.Anchored==false)
end
assert(g.Workspace:GetAttribute("R6DynamicCinematicMenu")==true)
assert(g.Workspace:GetAttribute("R6WanderingNPCCount")==4)
assert(g.Workspace:GetAttribute("R6DeathMenuInstalled")==true)
assert(g.Workspace:GetAttribute("NaturalR6ClimbingInstalled")==true)
assert(g.Workspace:GetAttribute("R6CombatAnimationsInstalled")==true)
local tracked = {}
local supplied = 0
for name,id in pairs(m.combat.allSuppliedAnimationIds) do
 supplied += 1
 local entry=sc.CombatAnimations:FindFirstChild(name)
 local measurement=m.combat.measuredInUniverse[tostring(id)]
 local canLoad=measurement and measurement.loaded and measurement.length>0.07
 if canLoad then
  assert(entry and entry:IsA("Animation"),"Missing verified R6 combat track: "..name)
  assert(tostring(entry.AnimationContent):find(tostring(id),1,true),"Wrong ID for "..name)
  assert(entry:GetAttribute("NativeVerifiedR6")==true)
  tracked[name]=true
 else
  assert(not entry, "Blocked combat animation must not be represented as playable: "..name)
  assert(m.combat.unavailableAnimationIds[name]==id)
 end
end
assert(supplied==13)
assert(#m.combat.mobileButtons==5)
assert(m.combat.networkAttacks==false and m.combat.onlyR6==true)
assert(m.selectedAnimationIds.run==180426354,"Run base must be genuine R6, never R15 Ninja")
assert(m.locomotionPoseDriver and m.locomotionPoseDriver.rig=="R6")
assert(m.locomotionPoseDriver.sharedWithCombat==true)
assert(g.Workspace:GetAttribute("R6RealJointPoseInstalled")==true)
assert(g.Workspace:GetAttribute("OriginalUnmodifiedR6RunInstalled")==true)
assert(sc.R6CombatInput.Source:find("R6CombatStarted",1,true))
assert(not sc.R6CombatInput.Source:find("TweenService",1,true),
 "Combat input must not have a second, competing pose system")
assert(g.Workspace:GetAttribute("OptionalChakraToggle")==true)
assert(m.naturalClimb.rig=="R6" and m.naturalClimb.usesJoystick)
assert(m.naturalClimb.blockedWhenChakraActive and m.naturalClimb.button==false)
assert(m.chakraToggle.initialState==false and m.chakraToggle.stateAttribute=="ChakraActive")
assert(m.walkingNPCs.count==4 and m.dynamicMenu.deathRespawn=="R6MenuRespawn")
assert(m.runCatalogCandidateIds[1]==72900620651167
 and m.runCatalogCandidateIds[2]==107952007153363
 and m.runCatalogCandidateIds[3]==93499989310243)
assert(g.ServerScriptService.BoogieSwapServer
 and g.ServerScriptService.BoogieSwapServer.Source==fs.readFile("r6-test/boogie-server.luau"))
assert(g.ReplicatedStorage.BoogieSwap and g.ReplicatedStorage.ClapAnimation
 and g.ReplicatedStorage.ClapVFX and g.ReplicatedStorage.SwapSound)
assert(g.Workspace:GetAttribute("BoogieWoogieInstalled")==true)
local dummy=g.Workspace:FindFirstChild("BoogieTestDummy")
assert(dummy and dummy.HumanoidRootPart and dummy.Humanoid)
assert(dummy.Humanoid.RigType==R.Enum.HumanoidRigType.R6)
assert(m.boogieWoogie and m.boogieWoogie.testDummy=="BoogieTestDummy")
assert(#g.StarterGui:GetChildren()==0 and #g.StarterPack:GetChildren()==0)
print(S.encode("json",{ok=true,build=m.build,checked=count,chakraFeet=true,
 playerCharacterScripts=7,R6PoseMotorController=true,rawOriginalR6Run3=true,originalRunKeyframesUnmodified=true,visualRunFixed=true,combatActions=13,verifiedCombatTracks=#sc.CombatAnimations:GetChildren(),
 ninjaRunReplacedBecauseR15=true,automaticClimb=true,chakraOptional=true,accessibleR6Animations=7,runningMode=true,
 boogieSwap=true,walkingNPCs=4,cinematicMenu=true,deathMenu=true,touchButton=true},true))
