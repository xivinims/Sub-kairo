local fs=require("@lune/fs")
local R=require("@lune/roblox")
local S=require("@lune/serde")
local L=require("@lune/luau")
local g=R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local m=S.decode("json",fs.readFile("r6-test/animation-manifest.json"))
assert(g.Workspace:GetAttribute("R6TestBuild")=="r6-chakra-boogie-v10")
assert(g.Workspace:GetAttribute("R6ChakraWallWalk")==true)
assert(m.source=="WallWalkNarutoV1(5).rbxl")
local sc=g.StarterPlayer.StarterCharacterScripts
assert(#sc:GetChildren()==4 and sc:FindFirstChild("Animate")
 and sc:FindFirstChild("ChakraWallWalk") and sc:FindFirstChild("NarutoSprintInput") and sc:FindFirstChild("BoogieSwapInput"))
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
assert(sc.ChakraWallWalk.Source:find('Enum.KeyCode.B',1,true))
assert(not sc:FindFirstChild("Wallrun") and not sc:FindFirstChild("R6Locomotion"))
local ps=g.StarterPlayer.StarterPlayerScripts
assert(#ps:GetChildren()==2 and ps.RbxCharacterSounds and ps.PlayerScriptsLoader)
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
assert(#g.ServerScriptService:GetChildren()==2 and g.ServerScriptService.R6AvatarServer)
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
 playerCharacterScripts=4,accessibleR6Animations=7,runningMode=true,boogieSwap=true,lightweightSoloDummy=true,touchButton=true},true))
