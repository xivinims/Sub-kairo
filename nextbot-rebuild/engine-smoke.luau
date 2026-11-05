local S=game:GetService('ServerScriptService');local R=game:GetService('ReplicatedStorage');local Storage=game:GetService('ServerStorage')
local package=R:FindFirstChild('NextbotReference');assert(package,'Missing gameplay package')
local results={placeVersion=game.PlaceVersion,checks={},maps={}}
local function passed(name)table.insert(results.checks,name)end
for _,name in ipairs({'Settings','Emotes','Economy','Equipment','Movement','Rescue','MatchAction'})do assert(package:FindFirstChild(name)and package[name]:IsA('RemoteEvent'),'Missing '..name)end;passed('remotes')
assert(#package.EmoteClips:GetChildren()==19,'Emote count');assert(#package.MovementClips:GetChildren()>=10,'Movement animations');passed('animation payloads')
local Config=require(package.Config);assert(Config.Intermission==90 and Config.RoundDuration==180);passed('90/180 timing')
local policy=require(package.EmotePolicy);local v,status=policy.buy({coins=500},'test',250);assert(v.coins==250 and status=='purchased');assert(select(2,policy.buy(v,'test',250))=='owned');passed('no duplicate debit')
local settings=require(package.SettingsPolicy);local clamped=settings(Config.Settings,{FOV=1e6,GameMusic=-10});assert(clamped.FOV==100 and clamped.GameMusic==0);passed('settings validation')
local safe=true
for _,folder in ipairs({Storage.NBMaps,Storage.NextbotTemplates,package.EmoteClips,package.MovementClips})do
 for _,v in ipairs(folder:GetDescendants())do assert(not v:IsA('LuaSourceContainer'),'Imported executable '..v:GetFullName())end
end;passed('no imported scripts')
local starter=game:GetService('StarterPlayer'):FindFirstChild('StarterCharacter');assert(starter and starter:FindFirstChild('HumanoidRootPart'),'R6 starter rig')
assert(starter.Humanoid.RigType==Enum.HumanoidRigType.R6,'Wrong rig type')
local motors=0;for _,v in ipairs(starter:GetDescendants())do if v:IsA('Motor6D')then assert(v.Part0 and v.Part1,'Unbound joint');motors+=1 end end;assert(motors>=6,'Missing rig joints');passed('R6 joints')
local pose=require(package.PosePlayer);local dummy=starter:Clone();dummy.Parent=workspace;local motorMap=pose.Motors(dummy)
results.emotePoses=0
for _,clip in ipairs(package.EmoteClips:GetChildren())do
 for _,m in pairs(motorMap)do m.Transform=CFrame.identity end
 local data=pose.Decode(clip);assert(next(data.tracks),'Empty clip '..clip.Name);pose.Apply(data,motorMap,data.duration*.4,1)
 local changed=0;for _,m in pairs(motorMap)do if m.Transform~=CFrame.identity then changed+=1 end end
 assert(changed>0,'Emote does not affect rig '..clip.Name);results.emotePoses+=1
end
dummy:Destroy();passed('19 emotes drive R6 motors')
-- Regression: the imported custom rig has duplicate zero-weight editor helpers.
-- Playback must retain one active key per joint/time and survive avatar joint replacement.
local bindings=pose.Bindings(package.MovementSourceRig)
for _,clip in ipairs(package.MovementClips:GetChildren())do
 local data=pose.Decode(clip)
 for name,keys in pairs(data.tracks)do for i=2,#keys do assert(keys[i].t>keys[i-1].t,'Duplicate animation timestamp: '..clip.Name..'/'..name)end end
end
local crouch=pose.Decode(package.MovementClips['Crouch idle'])
assert(crouch.tracks.TorsoRot and crouch.tracks.TorsoRot[1].w>.9,'Active crouch pose lost to an editor helper')
assert(crouch.tracks.TorsoRot[1].c.Position.Y< -1,'Crouch root offset missing')
passed('movement keys preserve active source poses')
local standard=game:GetService('Players'):CreateHumanoidModelFromDescriptionAsync(Instance.new('HumanoidDescription'),Enum.HumanoidRigType.R6)
standard.Name='RetargetValidation';standard.Parent=workspace
local actual=pose.Motors(standard);assert(actual.Torso and actual.Head and actual['Right Arm'],'Avatar R6 joints missing')
local expected=pose.WorldPose(crouch,.4,bindings);pose.Apply(crouch,actual,.4,1,bindings)
local resolved={HumanoidRootPart=CFrame.identity}
local function jointWorld(name)
 if resolved[name]then return resolved[name]end
 local m=assert(actual[name],'Missing actual joint '..name)
 resolved[name]=jointWorld(m.Part0.Name)*m.C0*m.Transform*m.C1:Inverse();return resolved[name]
end
for _,name in ipairs({'Torso','Head','Right Arm','Left Arm','Right Leg','Left Leg'})do
 local difference=expected[name]:ToObjectSpace(jointWorld(name));local _,angle=difference:ToAxisAngle()
 assert(difference.Position.Magnitude<.001 and math.abs(angle)<.001,'Avatar appearance changed crouch pose: '..name)
end
standard:Destroy();passed('crouch retargets to standard avatar R6 joints')
local Inventory=require(package.InventoryPolicy)
local light,utility,unavailable,userEmote
for _,item in ipairs(Config.Catalog)do if item.id=='flashlight'then light=item elseif item.id=='compass'then utility=item elseif item.id=='catjam'then unavailable=item end end
userEmote=require(package.EmoteCatalog)[1]
assert(Inventory.Visible(light,'Equipamento','Light',true),'Owned light excluded')
assert(not Inventory.Visible(utility,'Equipamento','Light',true),'Utility offered in light slot')
assert(not Inventory.Visible(light,'Equipamento','Light',false),'Unowned item offered for equip')
assert(not Inventory.Visible(unavailable,'Animações',nil,false),'Unresolved animation offered in shop')
assert(Inventory.Visible(userEmote,'Animações','Emote',true),'User emote lost')
passed('inventory filters ownership slots and unavailable items')
results.motion={sourceAssetId=package.MovementClips:GetAttribute('SourceAssetId'),sourceUnmodified=true,officialEvadeScripts=false,downedOriginalAvailable=false,speedFormulaOriginalVerified=false}

local First=game:GetService('ReplicatedFirst')
assert(First:FindFirstChild('Boot.client')and First['Boot.client']:IsA('LocalScript'),'Early loading screen missing')
local Loading=require(package.LoadingPolicy)
assert(not Loading.CanReveal(false,true,2,2,true),'Boot bypass')
assert(not Loading.CanReveal(true,false,2,2,true),'Map bypass')
assert(not Loading.CanReveal(true,true,3,2,true),'Stale map bypass')
assert(not Loading.CanReveal(true,true,2,2,false),'Interface bypass')
assert(Loading.CanReveal(true,true,2,2,true),'Ready menu blocked')
local gui=Instance.new('Folder');gui.Parent=R
local view=require(First.LoadingView).Create(gui,'LoadingTest',1000)
view:Set('CARREGANDO JOGO',.5,'Test');assert(view.fill.Size.X.Scale==.5 and view.status.Text=='CARREGANDO JOGO')
assert(view.gui:FindFirstChild('ExactRunLogo',true),'Centered wordmark missing');gui:Destroy()
passed('two-stage loading gates and shared logo build')
for _,name in ipairs({'CommunityIdle','CommunityWalk','CommunityRun','CommunityJump','CommunityFall','Downed'})do
 local clip=assert(package.MovementClips:FindFirstChild(name),'Missing '..name)
 local bind=pose.Bindings(package.MovementSourceRigs[clip:GetAttribute('SourceRig')])
 local data=pose.Decode(clip);assert(data.duration>0 and data.tracks.Torso,'Empty community animation')
 local world=pose.WorldPose(data,0,bind)
 if name=='Downed'then
  assert(math.abs(world.Torso.UpVector.Y)<.4 and world.Torso.Position.Y< -1,'Downed pose must lie near the floor')
  local later=pose.WorldPose(data,.5,bind)
  assert(later['Right Arm']~=world['Right Arm'],'Crawl is not animated')
 end
 for _,v in ipairs(package.MovementSourceRigs:GetDescendants())do assert(not v:IsA('LuaSourceContainer'),'Source rig contains script')end
end
results.motion.downedCommunityAvailable=true
results.motion.communitySourceIds={'74987847468722','4951486910'}
passed('community movement and prone crawl poses')

local Maps=require(S.MapService)
assert(Storage.NBMaps:FindFirstChild('Desert Bus'),'Additional map missing')
local sources={};for _,entry in ipairs(require(package.MapCatalog))do sources[entry.name]=string.format('%.0f',entry.assetId)end
assert(not workspace:FindFirstChild('LobbyScene'),'Generated lobby must be absent')
for _,name in ipairs(Maps.Names())do
 assert(Maps.Load(name),'Map cannot load: '..name)
 task.wait(.5)
 assert(workspace.ActiveMap:GetAttribute('MapRevision')==package:GetAttribute('MapReadyRevision'),'Ready revision mismatch')
 local points=workspace.RoundSpawns:GetChildren();assert(#points>=2,'Insufficient spawns')
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.ActiveMap.Geometry};rp.RespectCanCollide=true
 for _,p in ipairs(points)do assert(workspace:Raycast(p.Position+Vector3.new(0,.2,0),Vector3.new(0,-1,0),rp),'Spawn has no supporting floor')end
 if name=='Desert Bus'then assert(#points>=6,'Desert Bus needs six connected spawn points')end
 local paths={}
 for i=2,math.min(#points,4)do
  local path=game:GetService('PathfindingService'):CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
  local ok,err=pcall(function()path:ComputeAsync(points[1].Position+Vector3.new(0,3,0),points[i].Position+Vector3.new(0,3,0))end)
  assert(ok and path.Status==Enum.PathStatus.Success,'Disconnected spawn on '..name)
  table.insert(paths,{ok=ok,status=ok and path.Status.Name or tostring(err),waypoints=ok and #path:GetWaypoints()or 0})
 end
 local locations={};for i=1,math.min(6,#points)do local p=points[i].Position;table.insert(locations,{p.X,p.Y,p.Z})end
 local source=Storage.NBMaps:FindFirstChild(name):GetAttribute('SourceAssetId')
 assert(source==sources[name],'Map asset ID lost precision during serialization: '..name)
 assert(package:GetAttribute('MapAssetId')==source,'Arena source mismatch')
 assert(package:GetAttribute('MenuSceneSource')=='ImportedMap','Menu uses generated scenery')
 for _,camera in ipairs(workspace.MenuCameras:GetChildren())do
  assert(camera:GetAttribute('SourceAssetId')==source,'Menu camera points at another source')
  assert(workspace:Raycast(camera.Position,Vector3.new(0,-6,0),rp),'Menu camera is outside the imported arena')
 end
 table.insert(results.maps,{name=name,assetId=source,spawns=#points,parts=#workspace.ActiveMap.Geometry:GetDescendants(),paths=paths,locations=locations})
end;passed('map load and grounded spawns')
passed('imported map menu without generated scenery')
-- Exercise the same admission and bot services used by the remote handler.
-- The adapter supplies player attributes around a real R6 rig; this is not a client click test.
local Arena=require(S.ArenaService);local Bots=require(S.NextbotService);local State=require(package.RoundState)
local character=starter:Clone();character.Name='AdmissionTestRig';character.Parent=workspace
local attrs={};local actor={Character=character,Parent=true}
function actor:GetAttribute(key)return attrs[key]end
function actor:SetAttribute(key,value)attrs[key]=value end
function actor:RequestStreamAroundAsync()end
local phase=State.new(0,90,180);package:SetAttribute('Phase',phase.phase)
assert(Bots.Start(phase)==0 and #game:GetService('CollectionService'):GetTagged('NBNextbot')==0,'Bots appeared during intermission')
Arena.Leave(actor)
assert(not attrs.NBInArena and character.HumanoidRootPart.Anchored and character:GetPivot().Y<0,'Menu parking failed')
local ok,status=Arena.Enter(actor,false);assert(ok and status=='entered','Intermission admission failed')
assert(attrs.NBInArena and not attrs.NBInRound and not character.HumanoidRootPart.Anchored,'Waiting players cannot explore the arena')
local placed=character:GetPivot();local originalMap=workspace.ActiveMap
local nearest=math.huge;for _,point in ipairs(workspace.RoundSpawns:GetChildren())do nearest=math.min(nearest,(placed.Position-(point.Position+Vector3.new(0,4,0))).Magnitude)end
assert(nearest<.01,'Entry did not place the rig on an arena spawn')
assert(not State.tick(phase,89,true)and not State.botsAllowed(phase),'Countdown ended early')
assert(State.tick(phase,90,true)and phase.deadline==270,'Countdown did not start a 180 second chase')
package:SetAttribute('Phase',phase.phase)
assert(Arena.Enter(actor,false)and attrs.NBInRound,'Waiting participant was not admitted to chase')
assert(character:GetPivot()==placed and workspace.ActiveMap==originalMap,'Countdown teleported the participant or replaced the map')
assert(Bots.Start(phase)==3 and #game:GetService('CollectionService'):GetTagged('NBNextbot')==3,'Bots did not appear at countdown zero')
assert(Arena.Enter(actor,false)and character:GetPivot()==placed,'Repeated Join moved an active participant')
Bots.Clear();assert(#game:GetService('CollectionService'):GetTagged('NBNextbot')==0,'Bots persisted after cleanup')
Arena.Leave(actor);assert(Arena.Enter(actor,false)and attrs.NBInRound,'Late entry failed')
assert(State.tick(phase,270,true)and phase.deadline==360,'Round did not return to 90 second intermission')
package:SetAttribute('Phase',phase.phase);Arena.PrepareMapChange(actor)
assert(not attrs.NBInRound and character.HumanoidRootPart.Anchored,'Map change did not suspend the participant')
assert(Maps.Load(Config.InitialMap),'Initial imported arena could not load')
assert(Arena.Enter(actor,true)and attrs.NBInArena and not attrs.NBInRound and not character.HumanoidRootPart.Anchored,'Next intermission admission failed')
Arena.Leave(actor);package:SetAttribute('MapReady',false)
assert(not Arena.Enter(actor,false)and not attrs.NBInArena,'Entry succeeded without a loaded arena')
package:SetAttribute('MapReady',true)
-- A menu action while streaming cancels the in-flight admission.
function actor:RequestStreamAroundAsync()Arena.Leave(self)end
assert(not Arena.Enter(actor,false)and not attrs.NBInArena and character.HumanoidRootPart.Anchored,'A stale Join overrode Leave')
character:Destroy();actor.Parent=nil
passed('intermission entry preserves arena on countdown end')
passed('bots appear only after countdown and clear after round')
results.admission={immediateArena=true,intermissionSeconds=90,chaseSeconds=180,sameMapAtZero=true,samePositionAtZero=true,lateEntry=true,cancelledEntry=true,clientClickTest=false}

results.botCount=#Storage.NextbotTemplates:GetChildren();assert(results.botCount>=60,'Nextbot pack was not imported')
for _,bot in ipairs(Storage.NextbotTemplates:GetChildren())do
 assert(bot:FindFirstChild('HumanoidRootPart')and bot:FindFirstChildOfClass('Humanoid'),'Invalid bot rig')
 for _,v in ipairs(bot:GetDescendants())do if v:IsA('BasePart')then assert(not v.Anchored,'Anchored bot')end end
end;passed('nextbot rigs')
assert(package:GetAttribute('MenuAtlas')and package:GetAttribute('MenuAtlas')~='','Missing menu art');passed('menu artwork binding')
-- These tests use the real Roblox DataModel and raycasts; no player data is written.
results.assets={}
local content=game:GetService('ContentProvider')
for _,id in ipairs({93112717809068,1836009626,1838591268,1839246711,1847238776})do
 local item=Instance.new('Sound');item.SoundId='rbxassetid://'..id
 local ok,info=pcall(function()return game:GetService('MarketplaceService'):GetProductInfoAsync(id,Enum.InfoType.Asset)end)
 table.insert(results.assets,{id=id,metadata=ok,name=ok and info.Name or tostring(info),assetType=ok and info.AssetTypeId or 0})
 item:Destroy()
end
results.serverStartup={};local threads={};local startupErrors={}
for _,original in ipairs(S:GetChildren())do if original:IsA('Script')then
 local module=Instance.new('ModuleScript');module.Name='Validate_'..original.Name;module.Source='return function()\n'..original.Source..'\nend';module.Parent=S
 local name=original.Name;results.serverStartup[name]='starting'
 table.insert(threads,task.spawn(function()
  local ok,err=pcall(function()require(module)()end)
  results.serverStartup[name]=ok and 'initialized'or tostring(err)
  if not ok then table.insert(startupErrors,name..': '..tostring(err))end
 end))
end end
task.wait(3)
assert(#startupErrors==0,table.concat(startupErrors,' | '))
assert(package:GetAttribute('Phase')=='Intermission','Round service did not initialize')
assert(workspace:FindFirstChild('NBDecoys'),'Equipment service did not initialize')
results.serverStartup['Rounds.server']='running'
for _,thread in ipairs(threads)do pcall(task.cancel,thread)end
passed('all server services initialize')
results.isRunning=game:GetService('RunService'):IsRunning()
return results
