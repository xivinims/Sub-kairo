local Players=game:GetService('Players')
assert(workspace:GetAttribute('R6TestBuild')=='r6-animation-test-v2')
assert(not game.StarterPlayer:FindFirstChild('StarterCharacter'),'Fixed character remains')
assert(not workspace:FindFirstChild('TrainingBots'),'Bots remain')
assert(#game.StarterPack:GetChildren()==0,'Weapons remain')
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild('DynamicMenu'))
assert(game.StarterPlayer.StarterPlayerScripts.R6AnimationTest:IsA('LocalScript'))
assert(Players.CharacterAutoLoads==false)
local unchanged=0;local sequences=0;local poses=0
for _,x in ipairs(game:GetDescendants()) do
 if x:IsA('Humanoid') then assert(x.RigType==Enum.HumanoidRigType.R6) end
 if x:IsA('LuaSourceContainer') and x:GetAttribute('OriginalId') then
  assert(x.Source==game.ServerStorage.OriginalSources[x:GetAttribute('OriginalId')].Source,'Modified original: '..x:GetFullName());unchanged+=1
 end
end
for _,x in ipairs(game.ReplicatedStorage.OriginalR6Emotes:GetDescendants()) do
 if x:IsA('KeyframeSequence') then sequences+=1;assert(#x:GetKeyframes()>0) end
 if x:IsA('Pose') then poses+=1;assert(x.EasingStyle==Enum.PoseEasingStyle.Linear or x.EasingStyle==Enum.PoseEasingStyle.Constant) end
end
assert(sequences==19)
local animationCount=#game.ReplicatedStorage.R6AnimationCatalog:GetChildren()
assert(animationCount==workspace:GetAttribute('AnimationCatalogCount') and animationCount>0)
local floor=workspace:Raycast(Vector3.new(0,30,0),Vector3.new(0,-60,0));assert(floor and floor.Instance.Name=='Floor')
-- Exercise the exact R6 avatar creation API used by the server, in the native engine.
local desc=Instance.new('HumanoidDescription')
local character=Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)
assert(character.Humanoid.RigType==Enum.HumanoidRigType.R6 and character:FindFirstChild('Torso') and not character:FindFirstChild('UpperTorso'))
character:Destroy();desc:Destroy()
local runner=Instance.new('ModuleScript');runner.Source=game.ServerScriptService.R6AvatarServer.Source..'\nreturn true';runner.Parent=game.ServerStorage;require(runner)
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build='r6-animation-test-v2',originalScriptsUnchanged=unchanged,originalSequences=sequences,poses=poses,animationCatalog=animationCount,nativeR6Creation=true,floor=true,fixedAvatar=false,menu=false,bots=false,renderedPlaytest=false,rawEmotePreview='local'})
