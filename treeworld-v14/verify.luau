local world=assert(workspace:FindFirstChild('OveryardPhotoWorld'))
local runtime=game.ReplicatedStorage.LivingForest
local npc=assert(world:FindFirstChild('Caio'));local hum=npc.Humanoid
assert(npc:GetAttribute('AppearanceRevision')=='slim-caio-v14')
assert(hum.RigType==Enum.HumanoidRigType.R15)
assert(npc:GetAttribute('AvatarBaseUserId')==8344738123)
assert(npc:GetAttribute('RightLegAsset')==139607718)
local d=npc.RequestedAppearance
assert(d.Head==107154176765760 and d.RightLeg==139607718)
assert(d.Shirt==135542921435071 and d.Pants==93944579042140)
assert(d.Torso==0 and d.LeftArm==0 and d.RightArm==0 and d.LeftLeg==0,'User base body changed')
for key,expected in pairs({BodyWidthScale=.7,BodyDepthScale=.7,BodyHeightScale=.9,HeadScale=.95}) do
 assert(math.abs(hum[key].Value-expected)<.001,'Wrong scale '..key)
end
assert(npc.AdventurerShirt.ShirtTemplate=='rbxassetid://86335294756983')
assert(npc.AdventurerPants.PantsTemplate=='rbxassetid://113082643230470')
assert(npc.Head:FindFirstChildOfClass('FaceControls'),'Shy dynamic head unavailable')
assert(not npc.Head:FindFirstChild('Expression'),'Old face overlay replaced requested shy face')
local expected={AdventurousHat=18654587595,ThinRimmedGlasses=18557389382,BlondeRintaroHair=124964364612906,PrideLanyard=15591115363}
local count,motors=0,0
for _,p in ipairs(npc:GetDescendants()) do
 if p:IsA('Accessory') then count+=1;assert(expected[p.Name]==p:GetAttribute('RequestedAssetId')) end
 if p:IsA('Motor6D') then assert(p.Part0 and p.Part1);motors+=1 end
 assert(not p:IsA('ProximityPrompt'),'Conversation still starts through proximity UI')
 if p:IsA('BasePart') then
  assert(p.CollisionGroup=='CaioNonBlocking','NPC collision group missing')
  assert(not game:GetService('PhysicsService'):CollisionGroupsAreCollidable(p.CollisionGroup,'OveryardPlayers'),'NPC blocks players')
  assert(game:GetService('PhysicsService'):CollisionGroupsAreCollidable(p.CollisionGroup,'Default'),'NPC is invisible to cursor raycasts')
 end
end
assert(count==4 and motors>=15)
for name in pairs(expected) do
 local handle=assert(npc[name].Handle);local weld=assert(handle:FindFirstChild('AccessoryWeld'))
 assert(weld.Part0==handle and weld.Part1 and weld.Part1:IsDescendantOf(npc))
 assert(((weld.Part0.CFrame*weld.C0).Position-(weld.Part1.CFrame*weld.C1).Position).Magnitude<.01,'Detached accessory '..name)
end
local click=assert(npc:FindFirstChild('TalkToCaio'));assert(click:IsA('ClickDetector') and click.MaxActivationDistance==14)
assert(npc:GetAttribute('ConversationStart')=='ClickOnly')
assert(game.ServerScriptService:FindFirstChild('CaioPlayerCollisions'),'Player collision assignment missing')
local source=game.StarterPlayer.StarterPlayerScripts.CaioDialogueClient.Source
assert(source:find('click.MouseClick:Connect',1,true),'Click handler missing')
assert(not source:find('greeted',1,true) and not source:find('prompt.Triggered',1,true),'Old auto greeting survived')
assert(source:find('voice:play',1,true) and source:find('faceControls.JawDrop',1,true))
local C=require(game.ReplicatedStorage.PhotoWorldConfig)
local ground=C.surface(C.NPC.X,C.NPC.Z)
local footBottom=npc.LeftFoot.Position.Y-npc.LeftFoot.Size.Y/2
assert(math.abs(footBottom-ground)<.65,'NPC left foot floats '..tostring(footBottom-ground))
assert(npc.ModelStreamingMode==Enum.ModelStreamingMode.Persistent)

local clips={}
for _,name in ipairs({'IdleAnimation','IdleVariation'}) do
 local animation=npc[name];local track=hum.Animator:LoadAnimation(animation)
 track:Play(.1);local deadline=os.clock()+15
 while track.Length<=0 and os.clock()<deadline do task.wait(.1) end
 assert(track.Length>0,'Selected animation cannot load '..name)
 clips[name]={id=animation.AnimationId,length=track.Length};track:Stop(0);track:Destroy()
end
local loaded=0;local voiceManifest=require(runtime.VoiceManifest)
local sounds={};local content=game:GetService('ContentProvider')
for _,id in pairs(voiceManifest) do local s=Instance.new('Sound');s.SoundId='rbxassetid://'..id;s.Parent=game.SoundService;table.insert(sounds,s) end
content:PreloadAsync(sounds)
for _,s in ipairs(sounds) do if s.IsLoaded then loaded+=1 end;s:Destroy() end
assert(loaded==7,'Voice assets unavailable')
assert(workspace:GetAttribute('VoiceTouchRevision')=='voice-touch-v13','Camera/backpack fix lost')
assert(not game.StarterGui:FindFirstChild('Custom Inventory'))
return {ok=true,placeVersion=game.PlaceVersion,revision='slim-caio-v14',accessories=count,motors=motors,
 scale={width=hum.BodyWidthScale.Value,depth=hum.BodyDepthScale.Value,height=hum.BodyHeightScale.Value},
 baseUser=8344738123,shyHead=true,korblox=true,clickOnly=true,loadedVoices=loaded,clips=clips,footGroundError=footBottom-ground}
