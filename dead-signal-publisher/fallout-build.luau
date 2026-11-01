local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local function instance(class,name,parent)
 local o=R.Instance.new(class);o.Name=name;o.Parent=parent;return o
end
local bundle=instance('Model','FalloutBundle')
local folders={}
for _,name in ipairs({'Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterPlayerScripts','StarterGui'}) do folders[name]=instance('Folder',name,bundle) end
local W,RS,SS=folders.Workspace,folders.ReplicatedStorage,folders.ServerStorage
local function modelFrom(id,name)
 local roots=R.deserializeModel(fs.readFile('/tmp/fallout-input-'..id))
 local root=instance('Model',name)
 for _,v in ipairs(roots) do v.Parent=root end
 for _,v in ipairs(root:GetDescendants()) do
  if v:IsA('LuaSourceContainer') or v:IsA('Camera') or v:IsA('Humanoid') or v:IsA('ProximityPrompt') then v:Destroy()
  elseif v:IsA('BasePart') then v.Anchored=true end
 end
 root:SetAttribute('SourceAssetId',id)
 return root
end
local map=modelFrom(8438960542,'CombatMap');map.Parent=W
local lobby=modelFrom(95512398319263,'Lobby');lobby.Parent=W
local shop=modelFrom(12987749061,'ReplacementShop');shop.Parent=W
local animations=R.deserializePlace(fs.readFile('/tmp/fallout-input-86582491164528'))
local npc=assert(animations:GetService('Workspace'):FindFirstChild('NPC1'),'Animation NPC1 missing')
local sourceClips=npc:FindFirstChild('AnimSaves') or npc:FindFirstChild('MA2AnimSaves')
local clips=instance('Folder','FalloutNpcClips',RS)
for _,name in ipairs({'Idle','IdleToActive','ActiveIdle','ActiveToIdle'}) do
 local clip=assert(sourceClips:FindFirstChild(name),'NPC clip missing: '..name):Clone();clip.Parent=clips
 assert(clip:IsA('KeyframeSequence') and #clip:GetChildren()>1,'Empty NPC animation')
end
clips:SetAttribute('SourceAssetId',86582491164528)
local dialogue=R.deserializeModel(fs.readFile('/tmp/fallout-input-80608769509945'))[1]
local module=assert(dialogue:FindFirstChild('DialogModule',true)):Clone();module.Parent=RS
-- The source owns response creation; keep its look and sounds, add bounded cleanup.
module.Source=module.Source:gsub('self.connections = {heartbeatConnection}[^\n]*','self.connections = {heartbeatConnection, shownConnection, hiddenConnection}')
module.Source=module.Source:gsub('self%.npcGui%.name','self.npcGui:WaitForChild("name")')
module.Source=module.Source:gsub('function DialogModule:triggerDialog%(player, questionNumber%)','function DialogModule:triggerDialog(player, questionNumber)\n self.generation=(self.generation or 0)+1\n local generation=self.generation')
module.Source=module.Source:gsub('function DialogModule:hideGui%(exitQuip, notActuallyAnExitQuip%)','function DialogModule:hideGui(exitQuip, notActuallyAnExitQuip)\n self.generation=(self.generation or 0)+1')
module.Source=module.Source:gsub('while self.active do','while self.active and player.Character and player.Character.PrimaryPart and self.npc.Parent do')
module.Source=module.Source:gsub('repeat task.wait%(%) until responseNum ~= nil','repeat task.wait() until responseNum ~= nil or self.generation ~= generation or not self.npc.Parent')
module.Source=module.Source:gsub('self.active = true','if self.generation ~= generation then return end\n self.active = true')
module.Source=module.Source:gsub('for i, letter in string.split%(dialog.text,""%) do','for i, letter in string.split(dialog.text,"") do\n if self.generation ~= generation then return end')
local screen=assert(dialogue:FindFirstChild('dialog',true)):Clone();screen.ResetOnSpawn=false;screen.Parent=folders.StarterGui
local originalNpc=assert(dialogue:FindFirstChild('showcase npc',true))
local headGui=assert(originalNpc.Head:FindFirstChild('gui')):Clone();headGui.Name='NpcDialogueGui';headGui.Parent=SS
local rawWeapons=R.deserializeModel(fs.readFile('/tmp/fallout-input-110602808776017'))[1]
rawWeapons.Name='SourceWeaponMeshes';rawWeapons.Parent=SS
local function scriptFile(parent,name,class,file)
 local source=fs.readFile(file);luau.load(source,{debugName=file})
 local o=instance(class,name,parent);o.Source=source;return o
end
local config=scriptFile(RS,'FalloutConfig','ModuleScript','fallout-config.luau')
local runtime=instance('Folder','FalloutRuntime',folders.ServerScriptService)
scriptFile(runtime,'Rules','ModuleScript','fallout-rules.luau')
scriptFile(runtime,'Profiles','ModuleScript','fallout-profiles.luau')
scriptFile(runtime,'Server','Script','fallout-server.luau')
scriptFile(folders.StarterPlayerScripts,'FalloutClient','LocalScript','fallout-client.luau')
scriptFile(folders.StarterPlayerScripts,'FalloutNpcClient','LocalScript','fallout-npc-client.luau')
local net=instance('Folder','FalloutNet',RS)
for _,name in ipairs({'Action','State','Fx'}) do instance('RemoteEvent',name,net) end
instance('RemoteFunction','Query',net)
-- Reuse only an audited gun sound from the creator-provided FPS demo, not its systems.
local demo=R.deserializePlace(fs.readFile('/tmp/fallout-input-15864801103'))
local glock=demo:GetService('ReplicatedStorage'):FindFirstChild('Glock 17',true)
local sound
if glock then for _,v in ipairs(glock:GetDescendants()) do if v:IsA('Sound') and (v.Name:lower():find('fire') or v.Name:lower():find('shoot')) then sound=v;break end end end
if not sound then for _,v in ipairs(demo:GetService('ReplicatedStorage'):GetDescendants()) do if v:IsA('Sound') and (v.Name:lower():find('fire') or v.Name:lower():find('shoot') or v.Name:lower():find('shot')) then sound=v;break end end end
if not sound then local paths={};for _,v in ipairs(demo:GetService('ReplicatedStorage'):GetDescendants()) do if v:IsA('Sound') and #paths<60 then table.insert(paths,v:GetFullName()) end end;print('SOUND_CANDIDATES '..serde.encode('json',paths)) end
if sound then sound=sound:Clone();sound.Name='FalloutShotSound';sound.Parent=RS end
local scripts=0
for _,v in ipairs(bundle:GetDescendants()) do if v:IsA('LuaSourceContainer') then luau.load(v.Source,{debugName=v:GetFullName()});scripts+=1 end end
fs.writeFile('/tmp/fallout-bundle.rbxm',R.serializeModel({bundle}))
local Rules=luau.load(fs.readFile('fallout-rules.luau'))()
local C=luau.load(fs.readFile('fallout-config.luau'))()
assert(C.RoundSeconds==600 and C.IntermissionSeconds==90 and C.TeamSize==5 and C.MaxPlayers==10)
local counts={0,0};for i=1,10 do local t=Rules.team(counts,5,i);assert(t);counts[t]+=1 end;assert(counts[1]==5 and counts[2]==5 and not Rules.team(counts,5,11))
assert(Rules.damage(100,24,false,20)=='hit');assert(Rules.damage(40,24,false,20)=='downed');assert(Rules.damage(10,5,true,20)=='eliminated');assert(Rules.damage(100,103.2,false,20)=='eliminated')
assert(not Rules.canDamage({id=1,team=1,active=true},{id=2,team=1,active=true},'Match'))
assert(not Rules.canDamage({id=1,team=1,active=true},{id=2,team=2,active=true},'Intermission'))
assert(not Rules.canDamage({id=1,team=1,active=true},{id=2,team=2,active=true,protected=true},'Match'))
local p={coins=400,owned={}};assert(Rules.purchase(p,C.ById.service));assert(p.coins==0);assert(Rules.purchase(p,C.ById.service));assert(p.coins==0);assert(not Rules.purchase(p,C.ById.heavy))
local ranked=Rules.rank({{userId=2,kills=3,downs=4},{userId=1,kills=5,downs=5},{userId=3,kills=3,downs=1}});assert(ranked[1].userId==1 and ranked[2].userId==3)
print('FALLOUT_BUILD '..serde.encode('json',{scripts=scripts,instances=#bundle:GetDescendants(),rulesPassed=true,sourceClips=#clips:GetChildren(),shotSound=sound~=nil}))
