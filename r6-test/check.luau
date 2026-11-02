local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde');local L=require('@lune/luau')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'));local m=S.decode('json',fs.readFile('r6-test/animation-manifest.json'))
assert(g.Workspace:GetAttribute('R6TestBuild')=='r6-character-motion-v5')
assert(#g.StarterPlayer.StarterPlayerScripts:GetChildren()==0,'Preview controller remains')
assert(not g.ReplicatedStorage:FindFirstChild('R6AnimationCatalog'))
assert(not g.StarterPlayer:FindFirstChild('StarterCharacter'))
local sc=g.StarterPlayer.StarterCharacterScripts
assert(sc.Animate.Controller and sc.Animate.R6 and sc.Animate.Loaded and not sc.Animate:FindFirstChild('R15'))
print('R6_SCRIPT_DISABLED',sc.Animate.Disabled,sc.R6Locomotion.Disabled,sc.MotionInput.Disabled,sc.CharacterEmotes.Disabled)
assert(sc.Animate.Disabled, 'Original Animate must be disabled')
assert(not sc.R6Locomotion.Disabled, 'Avatar R6Locomotion must be enabled')
assert(sc.AnimationBankGUI and not sc.AnimationBankGUI.Disabled, 'Missing two-button top HUD')
assert(sc.AnimationBankGUI.Source==fs.readFile('r6-test/animation-bank-gui.luau'))
assert(sc.AnimationBankGUI.Source:find('R6 PADRÃO',1,true) and sc.AnimationBankGUI.Source:find('R6 ARQUIVOS',1,true))
assert(sc.R6Locomotion.Source:find('UploadedMotion',1,true) and sc.R6Locomotion.Source:find('R6AnimationGroup',1,true))
assert(sc.CharacterEmotes.Source:find('R6AnimationGroup',1,true))
assert(not sc.MotionInput.Disabled and not sc.CharacterEmotes.Disabled, 'Avatar companion controllers disabled')
assert(sc.R6Locomotion.Source==fs.readFile('r6-test/locomotion-client.luau'))
assert(sc.R6Locomotion.Source:find('RunService.PreSimulation',1,true))
assert(not sc.R6Locomotion.Source:find('ScreenGui',1,true))
assert(not sc.CharacterEmotes.Source:find('animate.Enabled',1,true))
assert(#sc.Animations.Emotes:GetChildren()==19)
assert(sc.Animations.UploadedMotion and sc.Run and sc.Wallrun)
local count=0
for _,x in ipairs(g:GetDescendants()) do
 if x:IsA('LuaSourceContainer') then
  L.compile(x.Source)
  if x:GetAttribute('OriginalId') then
   assert(x.Source==g.ServerStorage.OriginalSources[x:GetAttribute('OriginalId')].Source)
   assert(S.hash('sha256',x.Source)==x:GetAttribute('OriginalSHA256'));count+=1
  end
 elseif x:IsA('Humanoid') then assert(x.RigType==R.Enum.HumanoidRigType.R6) end
end
assert(count==#m.originals)
assert(S.hash('sha256',R.serializeModel({g.ReplicatedStorage.OriginalR6Emotes}))==m.rawEmoteSHA256)
for _,entry in ipairs({{'idle','Animation1','180435571'},{'walk','WalkAnim','180426354'},{'jump','JumpAnim','125750702'}}) do
 assert(tostring(sc.Animate[entry[1]][entry[2]].AnimationContent):find(entry[3],1,true))
end
assert(g.ServerScriptService.R6AvatarServer.Source==fs.readFile('r6-test/avatar-server.luau'))
assert(sc.MotionInput.Source==fs.readFile('r6-test/motion-input.luau'))
assert(sc.CharacterEmotes.Source==fs.readFile('r6-test/character-emotes.luau'))
assert(g.Workspace:GetAttribute('R6LocomotionInstalled')==true)
assert(g.Workspace:GetAttribute('R6ExclusiveAnimationBanks')==true)
assert(#m.bankButtons==2 and m.exclusiveBanks.Padrao and m.exclusiveBanks.Arquivos)
assert(m.build=='r6-character-motion-v5')
print(S.encode('json',{ok=true,characterOwnedMotion=true,unchangedSources=count,emotes=19,previewUI=false},true))
