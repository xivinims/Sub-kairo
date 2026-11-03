local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde');local L=require('@lune/luau')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'))
local function load(n) local b=fs.readFile('../upload/'..n);return n:match('rbxl$') and R.deserializePlace(b) or R.deserializeModel(b)[1] end
local sprint=load('Sprint System With Stamina Bar(3).rbxl');local wall=load('FREE R6 Wall Run(2).rbxm');local naruto=load('WallWalkNarutoV1(3).rbxl');local bow=load('Bow.rbxm');local boogie=load('BoogieWoogieV1(3).rbxl')
local animate=g.StarterPlayer.StarterCharacterScripts.Animate:Clone()
local emotes=g.ReplicatedStorage.OriginalR6Emotes:Clone()
local emoteHash=S.hash('sha256',R.serializeModel({emotes}))
local arena=g.Workspace.TestArena:Clone()
for _,x in ipairs(arena:GetChildren()) do if x.Name~='Floor' and x.Name~='Spawn' and not x.Name:match('WallRun') then x:Destroy() end end
for _,svc in ipairs(g:GetChildren()) do
 if svc.ClassName=='Workspace' then for _,x in ipairs(svc:GetChildren()) do if x.ClassName~='Terrain' then x:Destroy() end end
 else svc:ClearAllChildren() end
end
local function new(c,n,p) local x=R.Instance.new(c);x.Name=n;x.Parent=p;return x end
local function copy(x,p) local y=x:Clone();y.Parent=p;return y end
local sp=g:GetService('StarterPlayer');local rs=g:GetService('ReplicatedStorage');local ss=g:GetService('ServerStorage')
local sc=new('StarterCharacterScripts','StarterCharacterScripts',sp);local ps=new('StarterPlayerScripts','StarterPlayerScripts',sp)
animate.Parent=sc;arena.Parent=g.Workspace;emotes.Parent=rs
local modules=new('Folder','Modules',rs);copy(sprint.ReplicatedStorage.Modules.Run,modules);copy(sprint.ReplicatedStorage.Modules.Shared,modules)
for _,x in ipairs(sprint.StarterPlayer.StarterCharacterScripts:GetChildren()) do copy(x,sc) end
for _,x in ipairs(wall.StarterCharacterScripts:GetChildren()) do copy(x,sc) end
local catalog=new('Folder','R6AnimationCatalog',rs)
local function animations(root,pack)
 for _,x in ipairs(root:GetDescendants()) do if x:IsA('Animation') then
  local ok,id=pcall(function()return tostring(x.AnimationContent) end)
  if ok and id:find('Uri=') then local clone=copy(x,catalog);clone:SetAttribute('SourcePack',pack) end
 end end
end
animations(naruto.StarterPlayer.StarterCharacterScripts.Animate,'Naruto R6')
animations(sprint.ReplicatedStorage,'Sprint R6')
animations(wall,'Wallrun R6')
animations(bow.ReplicatedStorage.Assets.Animations,'Bow R6')
copy(boogie.ReplicatedStorage.ClapAnimation,catalog):SetAttribute('SourcePack','Boogie R6')
local archive=new('Folder','OriginalSources',ss);local index=0
local manifest={build='r6-animation-test-v2',originals={},animations=#catalog:GetChildren(),rawSequences=19,excluded={'R15 Wall Climb','Swim (R15)','Maps','Weapons','Bots','Menu'},inactive={'Naruto WallWalk camera loader: ApplyVRTransform incompatibility'}}
for _,x in ipairs(g:GetDescendants()) do
 if x:IsA('LuaSourceContainer') then
  index+=1;local id='R6_'..index;local hash=S.hash('sha256',x.Source)
  x:SetAttribute('OriginalId',id);x:SetAttribute('OriginalSHA256',hash)
  local original=new('ModuleScript',id,archive);original.Source=x.Source
  table.insert(manifest.originals,{id=id,path=x:GetFullName(),sha256=hash})
 end
end
local conflicts=new('Folder','Conflicts',ss)
local conflict=copy(naruto.StarterPlayer.StarterPlayerScripts.PlayerScriptsLoader,conflicts);conflict.Disabled=true
conflict:SetAttribute('Reason','Calls ApplyVRTransform in original camera override. Kept inactive and unmodified.')
fs.writeFile('r6-test/naruto-camera-original.luau',conflict.Source)
local function add(file,name,parent,class)
 local x=new(class or 'Script',name,parent);x.Source=fs.readFile('r6-test/'..file);L.compile(x.Source)
end
add('avatar-server.luau','R6AvatarServer',g:GetService('ServerScriptService'))
add('animation-test-client.luau','R6AnimationTest',ps,'LocalScript')
g.Players.CharacterAutoLoads=false
g.Workspace:SetAttribute('R6TestBuild','r6-animation-test-v2');g.Workspace:SetAttribute('DynamicMenuRevision',nil)
g.Workspace:SetAttribute('OriginalR6EmoteCount',19);g.Workspace:SetAttribute('AnimationCatalogCount',manifest.animations)
g.Workspace.FallenPartsDestroyHeight=-80
local lighting=g:GetService('Lighting');lighting.Brightness=2;lighting.ClockTime=14;lighting.GlobalShadows=true
lighting.Ambient=R.Color3.fromRGB(130,130,130);lighting.OutdoorAmbient=R.Color3.fromRGB(150,150,150)
assert(S.hash('sha256',R.serializeModel({emotes}))==emoteHash,'Original emotes modified')
manifest.rawEmoteSHA256=emoteHash
fs.writeFile('r6-test/animation-manifest.json',S.encode('json',manifest,true))
fs.writeFile('r6-test/arena.rbxl',R.serializePlace(g))
print('CLEAN_BUILD_OK',index,manifest.animations,emoteHash)
