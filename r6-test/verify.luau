local Players=game:GetService('Players')
assert(workspace:GetAttribute('R6TestBuild')=='r6-character-motion-v4')
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild('R6AnimationTest'),'Old preview remains')
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild('R6TestControls'),'Old UI remains')
assert(not game.ReplicatedStorage:FindFirstChild('R6AnimationCatalog'))
assert(not game.StarterPlayer:FindFirstChild('StarterCharacter'))
local sc=game.StarterPlayer.StarterCharacterScripts
assert(sc.Animate.Controller and sc.Animate.R6 and sc.Animate.Loaded)
assert(sc.Animate.Disabled and sc.R6Locomotion and not sc.R6Locomotion.Disabled,'R6 local movement driver missing')
assert(sc.R6Locomotion.Source:find('RunService.PreSimulation',1,true))
assert(workspace:GetAttribute('R6LocomotionInstalled')==true)
assert(not sc.Animate:FindFirstChild('R15'))
local unchanged=0
for _,x in ipairs(game:GetDescendants()) do
 if x:IsA('LuaSourceContainer') and x:GetAttribute('OriginalId') then
  assert(x.Source==game.ServerStorage.OriginalSources[x:GetAttribute('OriginalId')].Source,'Modified original: '..x:GetFullName());unchanged+=1
 end
end
local desc=Instance.new('HumanoidDescription')
local character=Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)
character:PivotTo(CFrame.new(0,6,0));character.Parent=workspace
local humanoid=character.Humanoid
assert(humanoid.RigType==Enum.HumanoidRigType.R6)
for _,child in ipairs(sc:GetChildren()) do
 local old=character:FindFirstChild(child.Name);if old then old:Destroy() end
 local clone=child:Clone();if clone:IsA('LocalScript') then clone.Disabled=true end;clone.Parent=character
end
assert(character.Animate.R6 and character.Run and character.Wallrun and character.Animations)
assert(character.R6Locomotion and not character.R6Locomotion.Enabled,'Locomotion must be inside the avatar but disabled only in server-side probe')
assert(#character.Animations.Emotes:GetChildren()==19)
local animator=humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator',humanoid)
local tracks={};local results={}
for _,entry in ipairs({{'idle','Animation1'},{'walk','WalkAnim'},{'jump','JumpAnim'},{'fall','FallAnim'},{'climb','ClimbAnim'}}) do
 local animation=character.Animate[entry[1]][entry[2]]
 local track=animator:LoadAnimation(animation);track.Looped=true;track:Play(0);track:AdjustWeight(0);tracks[entry[1]]=track
end
task.wait(6)
for name,track in pairs(tracks) do
 assert(track.Length>0,'Character animation failed to load: '..name)
 results[name]={length=track.Length,loaded=true};track:Stop(0)
end
local walk=tracks.walk;walk:Play(0);walk:AdjustWeight(1)
task.wait(.5)
results.walk.playing=walk.IsPlaying;results.walk.weight=walk.WeightCurrent;results.walk.time=walk.TimePosition
assert(walk.IsPlaying,'Walk track not playing')
local jointSamples={}
for _,motor in ipairs(character:GetDescendants()) do if motor:IsA('Motor6D') then jointSamples[motor.Name]={motor.Transform:GetComponents()} end end
walk:Stop(0);character:Destroy();desc:Destroy()
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build='r6-character-motion-v4',characterOwnedAnimationController=true,automaticR6ControllerInsideAvatar=true,previewUI=false,originalScriptsUnchanged=unchanged,emotesInsideCharacter=19,nativeAnimationLoads=results,jointSamples=jointSamples,renderedPlaytest=false,customPackIDsUnavailable=true})
