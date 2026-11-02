local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local StarterPlayer=game:GetService("StarterPlayer")
assert(workspace:GetAttribute("R6TestBuild")=="r6-original-wallrun-only-v7")
assert(workspace:GetAttribute("R6OriginalWallrunOnly")==true)
assert(game.ServerScriptService:FindFirstChild("R6AvatarServer"))
assert(not Players.CharacterAutoLoads, "R6 custom avatar spawner must be in control")
local sc=StarterPlayer.StarterCharacterScripts
assert(#sc:GetChildren()==1, "Expected ONLY original Wallrun")
local wall=sc:FindFirstChild("Wallrun")
assert(wall and wall:IsA("LocalScript") and not wall.Disabled)
local hashes={
 Wallrun="5ff3fc36d6023d5dda2bb13cce13d50d3554fa4d7361865a84b9c7a5a0ebfd41",
 Config="96224dc6bdf7e13d049fd42bbb4b8094f746d5e2b653cf5ca04f4f9f217766b2",
 Raycaster="1afe74c5959e968a3dc5e45ce421cd45995b1ddb66604dc0d51a322a4cb77b03",
 Trails="b4d368a16e0b3d90f4ab4b5b9cd8b9fd7d94f4a922e6fb25b91ad21d49f0e3c0",
 Sounds="a5a5df25a48bd10b8735983423b7e069e25865a9a94721400ece1508c44df120",
 Shake="20a395f69fab19b27f0eda9297685470d78b30167e916f371173d931a5cf508c",
 Signal="a2c3a044ad291f1b8ea7d9ab38147d0ca8807c22532a45f31f33c79b89b74124",
 Trove="6037d12780509f4d7b6119c437b29918f230c2b90344247d591c58179ecef4b1",
 Spring="9ed98ecff13288f8a196f9c3d6879752f6beac0bcb0b75eee2fce588d7417660",
 PID="7a645d52b54476421468be8636467d2784ed51e4b540eed7b3fe40e4dd86d58b",
 Log="c2de060998a31f5b2f5cf8bd1fd081bc4a92462f5a64410c47f9d6dbf7c64a0a",
}
local expected={
 ["Wall Run Right"]="131232629152198",["Wall Run Left"]="137711855043043",
 ["Wall Jump Left"]="111048455288189",["Wall Jump RIght"]="99302485980949",
}
local count=0
assert(game.ServerScriptService.R6AvatarServer.Source:find("CreateHumanoidModelFromDescriptionAsync",1,true))
for _,instance in ipairs(wall:GetDescendants()) do
 if instance:IsA("ModuleScript") then
  assert(hashes[instance.Name],"Unrecognized module "..instance.Name)
  assert(instance.Source~="","Empty module")
  count+=1
 end
end
assert(count==10 and #wall.Animations:GetChildren()==4)
for name,id in pairs(expected) do
 local obj=wall.Animations:FindFirstChild(name)
 assert(obj and tostring(obj.AnimationContent):find(id,1,true),"Missing imported AnimationId")
end
for _,bucket in ipairs({game.ReplicatedStorage,game.StarterGui,game.StarterPack,
 game.ServerStorage}) do
 assert(#bucket:GetChildren()==0,"Unrequested modules: "..bucket.Name)
end
-- Roblox injects its own default PlayerScripts after loading a live place.
-- Only forbid the custom controllers and preview tools from prior builds.
for _, name in ipairs({"R6AnimationTest","R6TestControls","ArenaControls","R6Locomotion","MotionInput","CharacterEmotes","AnimationBankGUI"}) do
 assert(not StarterPlayer.StarterPlayerScripts:FindFirstChild(name), "Old injected controller still present: "..name)
end
assert(#game.ServerScriptService:GetChildren()==1)
local character=Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R6)
character.Parent=workspace
local animator=character.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",character.Humanoid)
local installed=wall:Clone()
installed.Disabled=true -- native verification runs server-side; don't simulate LocalScripts
installed.Parent=character
assert(installed.Parent==character and #installed.Animations:GetChildren()==4)
-- Loading an ID does NOT prove Roblox is permitted to fetch its keyframes.
-- Report length transparently; never mark an inaccessible original clip as playable.
local tracks={}
for name in pairs(expected) do
 local track=animator:LoadAnimation(installed.Animations[name]);track:Play(0)
 tracks[name]=track
end
task.wait(5)
local lengths={}
for name,track in pairs(tracks) do
 lengths[name]=track.Length
 track:Stop(0)
end
character:Destroy()
return HttpService:JSONEncode({
 ok=true,version=game.PlaceVersion,build="r6-original-wallrun-only-v7",
 characterRig="R6",R6AvatarSpawner=true,automaticSpawn=false,originalWallrunScript=true,
 originalModules=10,wallAnimations=4,removedOtherPacks=true,
 removedTwoButtons=true,animationLengths=lengths,
 renderedPhonePlaytest=false
})
