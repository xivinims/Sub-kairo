local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde');local L=require('@lune/luau')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'));local manifest=S.decode('json',fs.readFile('r6-test/animation-manifest.json'))
assert(g.Workspace:GetAttribute('R6TestBuild')=='r6-animation-test-v2')
assert(not g.StarterPlayer:FindFirstChild('StarterCharacter'),'Fixed avatar remains')
assert(not g.StarterPlayer.StarterPlayerScripts:FindFirstChild('DynamicMenu'),'Old menu remains')
assert(not g.Workspace:FindFirstChild('TrainingBots'),'Bots remain')
assert(#g.StarterPack:GetChildren()==0,'Tools remain')
assert(#g.ServerScriptService:GetChildren()==1 and g.ServerScriptService.R6AvatarServer,'Unexpected server controller')
assert(g.Players.CharacterAutoLoads==false)
local scripts=0;local raw=0;local catalog=g.ReplicatedStorage.R6AnimationCatalog
assert(#catalog:GetChildren()==manifest.animations and manifest.animations>0)
for _,x in ipairs(g:GetDescendants()) do
 if x:IsA('LuaSourceContainer') then
  L.compile(x.Source)
  if x:GetAttribute('OriginalId') then
   assert(x.Source==g.ServerStorage.OriginalSources[x:GetAttribute('OriginalId')].Source)
   assert(S.hash('sha256',x.Source)==x:GetAttribute('OriginalSHA256'));scripts+=1
  end
 elseif x:IsA('Humanoid') then assert(x.RigType==R.Enum.HumanoidRigType.R6)
 elseif x:IsA('KeyframeSequence') then
  raw+=1;local frames={};for _,f in ipairs(x:GetChildren()) do if f:IsA('Keyframe') then table.insert(frames,f) end end;assert(#frames>0,'Empty sequence')
 end
 if x:IsA('Pose') then
  assert(x.EasingStyle==R.Enum.PoseEasingStyle.Linear or x.EasingStyle==R.Enum.PoseEasingStyle.Constant,'Unsupported easing')
 end
end
assert(raw==19 and scripts==#manifest.originals)
assert(S.hash('sha256',R.serializeModel({g.ReplicatedStorage.OriginalR6Emotes}))==manifest.rawEmoteSHA256)
assert(g.StarterPlayer.StarterPlayerScripts.R6AnimationTest.Source==fs.readFile('r6-test/animation-test-client.luau'))
assert(g.ServerScriptService.R6AvatarServer.Source==fs.readFile('r6-test/avatar-server.luau'))
assert(g.ServerStorage.Conflicts.PlayerScriptsLoader.Source==fs.readFile('r6-test/naruto-camera-original.luau'))
assert(g.ServerStorage.Conflicts.PlayerScriptsLoader.Disabled)
assert(g.Workspace.TestArena.Floor.TestGrid)
print(S.encode('json',{ok=true,originalScriptsUnchanged=scripts,originalSequenceHash=manifest.rawEmoteSHA256,rawSequences=raw,publishedAnimations=#catalog:GetChildren(),fixedAvatar=false,menu=false,bots=false},true))
