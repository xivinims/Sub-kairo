local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde');local L=require('@lune/luau')
local I=R.Instance;local V=R.Vector3;local C=R.CFrame;local Color=R.Color3;local E=R.Enum
local function load(name) local b=fs.readFile('../upload/'..name);return name:match('%.rbxl$') and R.deserializePlace(b) or R.deserializeModel(b)[1] end
local bow=load('Bow.rbxm');local lantern=load('Lantern System(1).rbxl');local sprint=load('Sprint System With Stamina Bar(1).rbxl');local wall=load('FREE R6 Wall Run(1).rbxm');local boogie=load('BoogieWoogieV1(1).rbxl');local naruto=load('WallWalkNarutoV1(1).rbxl');local dialogue=load('18835619908(1).rbxm');local luminos=load('Luminos(1).rbxmx')
local game=lantern -- retains the original CSG shared data for the lantern
for _,svc in ipairs(game:GetChildren()) do if svc.ClassName~='Workspace' then svc:ClearAllChildren() else for _,x in ipairs(svc:GetChildren()) do if x.ClassName~='Terrain' then x:Destroy() end end end end
-- Reload after clearing the base.
lantern=load('Lantern System(1).rbxl')
local function service(n) return game:GetService(n) end
local function new(c,n,p) local x=I.new(c);x.Name=n;x.Parent=p;return x end
local ws=service('Workspace');local rs=service('ReplicatedStorage');local ss=service('ServerStorage');local sss=service('ServerScriptService');local sp=service('StarterPlayer');local sg=service('StarterGui')
local sc=new('StarterCharacterScripts','StarterCharacterScripts',sp);local ps=new('StarterPlayerScripts','StarterPlayerScripts',sp)
local archive=new('Folder','OriginalSources',ss);local sources={};local count=0
local function stamp(root,pack)
 local all=root:GetDescendants();table.insert(all,root)
 for _,x in ipairs(all) do if x:IsA('LuaSourceContainer') then
  count+=1;local id=pack..'_'..count;local hash=S.hash('sha256',x.Source);sources[id]={pack=pack,path=x:GetFullName(),sha256=hash}
  x:SetAttribute('OriginalId',id);x:SetAttribute('OriginalSHA256',hash)
  local copy=I.new('ModuleScript');copy.Name=id;copy.Source=x.Source;copy.Parent=archive
 end end
end
for name,root in pairs({Bow=bow,Lantern=lantern,Sprint=sprint,Wallrun=wall,Boogie=boogie,Naruto=naruto,Dialogue=dialogue,Luminos=luminos}) do stamp(root,name) end
local function copy(src,dest) local x=src:Clone();x.Parent=dest;return x end
local function merge(src,dest)
 for _,x in ipairs(src:GetChildren()) do
  local old=dest:FindFirstChild(x.Name)
  if old and old:IsA('Folder') and x:IsA('Folder') then merge(x,old) else assert(not old,'Collision '..dest.Name..'.'..x.Name);copy(x,dest) end
 end
end
merge(bow.ReplicatedStorage,rs);merge(bow.SoundService,service('SoundService'));merge(bow.ServerScriptService,sss);merge(bow.StarterPlayerScripts,ps);merge(bow.StarterCharacterScripts,sc)
merge(lantern.ReplicatedStorage,rs);merge(lantern.ServerScriptService,sss);merge(lantern.StarterPlayer.StarterCharacterScripts,sc)
merge(sprint.ReplicatedStorage,rs);merge(sprint.StarterPlayer.StarterCharacterScripts,sc)
merge(wall.StarterCharacterScripts,sc)
for _,n in ipairs({'ClapVFX','ClapAnimation','BoogieWoogie','SwapSound'}) do copy(boogie.ReplicatedStorage[n],rs) end
copy(boogie.ServerScriptService.Server,sss).Name='BoogieServer';merge(boogie.StarterPack,service('StarterPack'))
local rig=copy(naruto.StarterPlayer.StarterCharacter,sp);rig.Name='StarterCharacter'
assert(rig.Humanoid.RigType==E.HumanoidRigType.R6)
for _,x in ipairs(rig:GetDescendants()) do if x:IsA('BasePart') then x.Anchored=false end end
rig.Humanoid.MaxHealth=100;rig.Humanoid.Health=100
local dk=dialogue['Dialogue Kit V2.5']
for _,x in ipairs(dk:GetChildren()) do if x:IsA('ScreenGui') then copy(x,sg) elseif x:IsA('SoundGroup') then copy(x,service('SoundService')) end end
local prompts=copy(dk.DialoguePrompts,ws)
local p=prompts.TestPrompt1.PromptPart;p.CFrame=C.new(-12,3,18)
local stored=new('Folder','StudioPacks',ss);copy(luminos,stored)
local nstore=new('Folder','WallWalkNaruto_R6',stored)
for _,sn in ipairs({'ReplicatedStorage','StarterPlayer','StarterGui'}) do local f=new('Folder',sn,nstore);for _,x in ipairs(naruto[sn]:GetChildren()) do if x:IsA('StarterPlayerScripts') or x:IsA('StarterCharacterScripts') then local bucket=new('Folder',x.Name,f);merge(x,bucket) else copy(x,f) end end end
nstore:SetAttribute('Status','Original preserved; inactive: old PlayerScriptsLoader incompatible with current camera API')
local env=service('Lighting');env.Ambient=Color.fromRGB(83,100,67);env.Brightness=2;env.ColorShift_Bottom=Color.new(0,0,0);env.ColorShift_Top=Color.fromRGB(201,229,255);env.EnvironmentDiffuseScale=1;env.EnvironmentSpecularScale=0;env.GlobalShadows=true;env.OutdoorAmbient=Color.fromRGB(67,125,109);env.ClockTime=9.55;env.GeographicLatitude=22.8;env.ExposureCompensation=.5
local a=new('Atmosphere','AfterRain',env);a.Density=.25;a.Offset=.25;a.Color=Color.new(0,0,0);a.Decay=Color.new(0,0,0);a.Glare=0;a.Haze=0
local cc=new('ColorCorrectionEffect','AfterRain',env);cc.Saturation=.25
local sun=new('SunRaysEffect','AfterRain',env);sun.Intensity=.01;sun.Spread=.25
local sky=new('Sky','AfterRain',env);sky.SkyboxBk='rbxassetid://17149898869';sky.SkyboxDn='rbxassetid://17149898563';sky.SkyboxFt='rbxassetid://17149898110';sky.SkyboxLf='rbxassetid://17149897629';sky.SkyboxRt='rbxassetid://17149897313';sky.SkyboxUp='rbxassetid://17149896893';sky.StarCount=0;sky.MoonAngularSize=0;sky.MoonTextureId='';sky.SunAngularSize=2.5;sky.SunTextureId='rbxassetid://6196665106'
local arena=new('Model','TestArena',ws)
local function part(n,size,pos,color)
 local x=new('Part',n,arena);x.Anchored=true;x.Size=size;x.CFrame=C.new(pos);x.Color=color or Color.fromRGB(62,72,88);x.Material=E.Material.Concrete;x.TopSurface=E.SurfaceType.Smooth;x.BottomSurface=E.SurfaceType.Smooth;return x
end
part('Floor',V.new(220,2,200),V.new(0,-1,0),Color.fromRGB(136,147,156))
part('NorthWall',V.new(220,30,3),V.new(0,15,-100));part('SouthWall',V.new(220,30,3),V.new(0,15,100));part('WestWall',V.new(3,30,200),V.new(-110,15,0));part('EastWall',V.new(3,30,200),V.new(110,15,0))
part('WallRunLeft',V.new(3,24,70),V.new(-68,12,-20),Color.fromRGB(60,133,146));part('WallRunRight',V.new(3,24,70),V.new(-52,12,-20),Color.fromRGB(60,133,146))
for i=1,5 do part('Step'..i,V.new(13,2*i,6),V.new(-60,i,41-i*6),Color.fromRGB(84,151,163)) end
for i=1,4 do part('Cover'..i,V.new(12,6,5),V.new(5+i*19,3,-20),Color.fromRGB(87,99,118)) end
part('Platform',V.new(24,12,18),V.new(-22,6,-60))
local spawn=new('SpawnLocation','Spawn',arena);spawn.Anchored=true;spawn.Size=V.new(10,1,10);spawn.CFrame=C.new(0,.5,40);spawn.Duration=0;spawn.Neutral=true;spawn.Color=Color.fromRGB(77,211,165);spawn.Material=E.Material.Neon
local function sign(n,text,pos,width)
 local board=part(n,V.new(width,7,1),pos,Color.fromRGB(22,29,43));local ui=new('SurfaceGui','Sign',board);ui.Face=E.NormalId.Front;ui.CanvasSize=R.Vector2.new(width*35,245)
 local t=new('TextLabel','Text',ui);t.Size=R.UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=Color.fromRGB(240,246,255);t.TextScaled=true
end
sign('Welcome','ARENA TESTE • R6\nARCO  /  BOTS  /  PARKOUR',V.new(0,8,-88),42)
sign('WallrunSign','WALL RUN R6\nPule perto da parede e segure PULAR',V.new(-60,28,-54),32)
sign('BotsSign','ALVOS • 100 HP\nRenascem depois de 5 segundos',V.new(55,12,-75),36)
sign('DialogueSign','DIÁLOGO\nUse o prompt aqui',V.new(-12,7,18),14)
new('Folder','Debris',ws);local bots=new('Folder','TrainingBots',ws)
local template=copy(boogie.Workspace.Dummys:GetChildren()[1],ss);template.Name='R6BotTemplate'
for _,x in ipairs(template:GetDescendants()) do if x:IsA('LuaSourceContainer') then x:Destroy() elseif x:IsA('BasePart') then x.Anchored=false;x.CanTouch=true end end
template.HumanoidRootPart.Anchored=true;template.PrimaryPart=template.HumanoidRootPart
assert(template.Humanoid.RigType==E.HumanoidRigType.R6)
for i=1,6 do local b=copy(template,bots);b.Name='Bot '..i;b:SetAttribute('TrainingBot',true);b:SetAttribute('BotIndex',i);local cf=C.new(15+(i-1)*15,3,-48);local delta=cf*b.HumanoidRootPart.CFrame:Inverse();for _,x in ipairs(b:GetDescendants()) do if x:IsA('BasePart') then x.CFrame=delta*x.CFrame end end;b.Humanoid.Health=100;b.Humanoid.MaxHealth=100;b.Humanoid.DisplayName='ALVO '..i;b.Humanoid.HealthDisplayType=E.HumanoidHealthDisplayType.AlwaysOn;b.Humanoid.DisplayDistanceType=E.HumanoidDisplayDistanceType.Viewer;b.Humanoid.BreakJointsOnDeath=true end
local function scriptFile(file,name,dest,class) local x=new(class or 'Script',name,dest);x.Source=fs.readFile('r6-test/'..file);L.compile(x.Source);return x end
scriptFile('arena-server.luau','ArenaServer',sss);scriptFile('controls-client.luau','ArenaControls',ps,'LocalScript')
ws:SetAttribute('R6TestBuild','r6-arena-v1');ws.FallenPartsDestroyHeight=-80;sp.EnableMouseLockOption=true
local checked=0
for _,x in ipairs(game:GetDescendants()) do
 if x:IsA('Humanoid') then assert(x.RigType==E.HumanoidRigType.R6,'R15 rig '..x:GetFullName()) end
 if x:IsA('LuaSourceContainer') and x:GetAttribute('OriginalId') then assert(x.Source==archive[x:GetAttribute('OriginalId')].Source,'Changed source');checked+=1 end
end
fs.writeFile('r6-test/source-manifest.json',S.encode('json',{originals=sources,installedScripts=checked,excluded={'FREE Swim System','Free Advanced R15 Wall Climb System'}},true))
fs.writeFile('r6-test/arena.rbxl',R.serializePlace(game));print('BUILD_OK original scripts verified: '..checked)
