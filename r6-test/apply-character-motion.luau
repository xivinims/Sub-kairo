local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde');local L=require('@lune/luau')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'))
local naruto=R.deserializePlace(fs.readFile('../upload/WallWalkNarutoV1(3).rbxl'))
local sc=g.StarterPlayer.StarterCharacterScripts
local uploaded=(g.ReplicatedStorage:FindFirstChild('R6AnimationCatalog') or sc.Animations.UploadedMotion):Clone()
local function new(c,n,p)local x=R.Instance.new(c);x.Name=n;x.Parent=p;return x end
local function copy(x,p)local y=x:Clone();y.Parent=p;return y end
local function remove(p,n)local x=p:FindFirstChild(n);if x then x:Destroy() end end
remove(sc,'Animate')
local animate=copy(naruto.StarterPlayer.StarterCharacterScripts.Animate,sc)
-- Select the supplied R6 module's own working defaults, rather than the inaccessible
-- custom Animation objects on the demo controller. No source text or IDs are changed.
for _,x in ipairs(animate:GetChildren()) do
 if x:IsA('StringValue') or x.Name=='R15' then x:Destroy() end
end
for _,x in ipairs(animate.R6:GetChildren()) do if x:IsA('StringValue') then copy(x,animate) end end
local loaded=animate:FindFirstChild('Loaded') or new('BoolValue','Loaded',animate);loaded.Value=false
local library=sc:FindFirstChild('Animations');if library then library:Destroy() end
library=new('Folder','Animations',sc)
local motion=new('Folder','UploadedMotion',library)
for _,x in ipairs(uploaded:GetChildren()) do copy(x,motion) end
local emotes=new('Folder','Emotes',library);local sequenceCount=0
for _,x in ipairs(g.ReplicatedStorage.OriginalR6Emotes:GetDescendants()) do if x:IsA('KeyframeSequence') then copy(x,emotes);sequenceCount+=1 end end
assert(sequenceCount==19)
remove(g.ReplicatedStorage,'R6AnimationCatalog')
g.StarterPlayer.StarterPlayerScripts:ClearAllChildren()
remove(sc,'MotionInput');remove(sc,'CharacterEmotes')
local function add(file,name,p,c)local x=new(c or 'LocalScript',name,p);x.Source=fs.readFile('r6-test/'..file);L.compile(x.Source) end
-- Rebuild the exact-source archive from installed originals only.
remove(g.ServerStorage,'OriginalSources');local archive=new('Folder','OriginalSources',g.ServerStorage)
local manifest={build='r6-character-motion-v3',originals={},characterEmotes=sequenceCount,rawEmoteSHA256=S.hash('sha256',R.serializeModel({g.ReplicatedStorage.OriginalR6Emotes})),unavailableCustomIDs={135979869186041,73997618195368,137454594998955,137711855043043,131232629152198,100251055326558,77852689958686,89651256350359,131725558168717,95937026088317}}
local index=0
for _,root in ipairs({sc,g.ReplicatedStorage.Modules}) do
 for _,x in ipairs(root:GetDescendants()) do if x:IsA('LuaSourceContainer') then
  index+=1;local id='Motion_'..index;local hash=S.hash('sha256',x.Source)
  x:SetAttribute('OriginalId',id);x:SetAttribute('OriginalSHA256',hash)
  local source=new('ModuleScript',id,archive);source.Source=x.Source
  table.insert(manifest.originals,{id=id,path=x:GetFullName(),sha256=hash})
 end end
end
add('motion-input.luau','MotionInput',sc)
add('character-emotes.luau','CharacterEmotes',sc)
-- R6 module is byte-identical to the upload; its defaults drive actual Humanoid states.
assert(animate.Source==naruto.StarterPlayer.StarterCharacterScripts.Animate.Source)
assert(animate.Controller.Source==naruto.StarterPlayer.StarterCharacterScripts.Animate.Controller.Source)
assert(animate.R6.Source==naruto.StarterPlayer.StarterCharacterScripts.Animate.R6.Source)
g.Workspace:SetAttribute('R6TestBuild','r6-character-motion-v3');g.Workspace:SetAttribute('AnimationCatalogCount',nil)
fs.writeFile('r6-test/animation-manifest.json',S.encode('json',manifest,true))
fs.writeFile('r6-test/arena.rbxl',R.serializePlace(g))
print('CHARACTER_MOTION_BUILD',index,sequenceCount)
