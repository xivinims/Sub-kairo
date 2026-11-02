local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
assert(workspace:GetAttribute("R6TestBuild")=="r6-chakra-wallwalk-v8")
assert(workspace:GetAttribute("R6ChakraWallWalk")==true)
local sc=game.StarterPlayer.StarterCharacterScripts
assert(sc:FindFirstChild("Animate") and sc:FindFirstChild("ChakraWallWalk"))
assert(not sc:FindFirstChild("Wallrun") and not sc:FindFirstChild("R6Locomotion"))
assert(not sc.ChakraWallWalk.Disabled)
assert(sc.ChakraWallWalk.Source:find('SetTitle("ToggleChakraFeet"',1,true))
assert(sc.Animate.Controller and sc.Animate.R6)
local ps=game.StarterPlayer.StarterPlayerScripts
assert(ps.RbxCharacterSounds and ps.PlayerScriptsLoader.Loaded.Value)
assert(game.ReplicatedStorage.GravityController.InitObjects)
assert(game.ReplicatedStorage.DrawClass)
assert(game.ReplicatedStorage.VFX.ChakraFeet)
assert(#game.StarterPack:GetChildren()==0 and #game.StarterGui:GetChildren()==0)
assert(game.ServerScriptService.R6AvatarServer)
local desc=Instance.new("HumanoidDescription")
local character=Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)
character.Parent=workspace
for _,item in ipairs(sc:GetChildren()) do
 local existing=character:FindFirstChild(item.Name)
 if existing then existing:Destroy() end
 local clone=item:Clone()
 if clone:IsA("LocalScript") then clone.Disabled=true end
 clone.Parent=character
end
assert(character.Animate and character.ChakraWallWalk)
assert(character.Humanoid.RigType==Enum.HumanoidRigType.R6)
assert(character:FindFirstChild("Left Leg") and character:FindFirstChild("Right Leg"))
local animator=character.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",character.Humanoid)
local clips={}
for _,item in ipairs(character.Animate:GetDescendants()) do
 if item:IsA("Animation") and item.Name=="WalkAnim" then
  local track=animator:LoadAnimation(item)
  track:Play(0)
  table.insert(clips,track)
  break
 end
end
task.wait(3)
local ordinaryWalkLength=#clips>0 and clips[1].Length or 0
for _,track in ipairs(clips) do track:Stop(0) end
character:Destroy()
desc:Destroy()
return HttpService:JSONEncode({
 ok=true,version=game.PlaceVersion,build="r6-chakra-wallwalk-v8",
 installedCharacterScripts={"Animate","ChakraWallWalk"},
 chakraFeetAsset=true,originalGravityController=true,
 existingWallRunRemoved=true,onlyNarutoPack=true,originalNarutoScriptAdaptedForTouch=true,
 ordinaryWalkAssetLength=ordinaryWalkLength,
 nativeScriptsVerified=true,renderedPhonePlaytest=false
})
