assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local b=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
assert(b and b.Name=='FalloutBundle','Missing candidate bundle')
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local SS=game:GetService('ServerStorage')
local SP=game:GetService('StarterPlayer')
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting','MaterialService','Teams'}) do
 local service=game:GetService(name);service:ClearAllChildren()
 if b:FindFirstChild(name) then for _,child in ipairs(b[name]:GetChildren()) do child.Parent=service end end
end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do
 SP[name]:ClearAllChildren()
 if b:FindFirstChild(name) then for _,child in ipairs(b[name]:GetChildren()) do child.Parent=SP[name] end end
end
for _,v in ipairs(SP:GetChildren()) do if v.Name=='StarterCharacter' or v.Name=='StarterHumanoid' then v:Destroy() end end
game:GetService('StarterPack'):ClearAllChildren()
for _,child in ipairs(workspace:GetChildren()) do if not child:IsA('Terrain') and not child:IsA('Camera') then child:Destroy() end end
workspace.Terrain:Clear()
for key in pairs(workspace:GetAttributes()) do workspace:SetAttribute(key,nil) end
for _,child in ipairs(b.Workspace:GetChildren()) do child.Parent=workspace end
local C=require(RS.FalloutConfig)
workspace:SetAttribute('DeadSignalBuildId',C.Build)
workspace:SetAttribute('FalloutPhase','Waiting')
workspace.StreamingEnabled=true
pcall(function()workspace.StreamingMinRadius=64;workspace.StreamingTargetRadius=256 end)
workspace.FallenPartsDestroyHeight=-500
SP.CameraMode=Enum.CameraMode.Classic;SP.CameraMinZoomDistance=8;SP.CameraMaxZoomDistance=18;SP.CharacterWalkSpeed=16
Players.CharacterAutoLoads=false
local Lighting=game:GetService('Lighting');Lighting.ClockTime=16.5;Lighting.Brightness=2.2;Lighting.GlobalShadows=true;Lighting.Ambient=Color3.fromRGB(100,107,110);Lighting.OutdoorAmbient=Color3.fromRGB(124,129,134)
local atmosphere=Instance.new('Atmosphere');atmosphere.Density=.18;atmosphere.Haze=.8;atmosphere.Color=Color3.fromRGB(206,213,209);atmosphere.Parent=Lighting
local bloom=Instance.new('BloomEffect');bloom.Intensity=.12;bloom.Size=20;bloom.Threshold=1.5;bloom.Parent=Lighting
local map,lobby,shop=workspace.CombatMap,workspace.Lobby,workspace.ReplacementShop
local mapCF,mapSize=map:GetBoundingBox()
map:PivotTo(CFrame.new(-mapCF.Position.X,-mapCF.Position.Y+mapSize.Y/2,-mapCF.Position.Z)*map:GetPivot())
local lobbyCF,lobbySize=lobby:GetBoundingBox()
lobby:PivotTo(CFrame.new(3000-lobbyCF.X,600-lobbyCF.Y,-lobbyCF.Z)*lobby:GetPivot())
local oldShop=assert(lobby:FindFirstChild('Shop',true),'Floating Lobby shop not found')
local oldContainer=Instance.new('Model');oldContainer.Parent=workspace
for _,child in ipairs(oldShop:GetChildren()) do child.Parent=oldContainer end
local oldCF,oldSize=oldContainer:GetBoundingBox()
local shopCF,shopSize=shop:GetBoundingBox()
local scale=math.clamp(math.min(oldSize.X/math.max(shopSize.X,1),oldSize.Z/math.max(shopSize.Z,1)),.35,1.5)
shop:ScaleTo(scale);shopCF,shopSize=shop:GetBoundingBox()
local destination=Vector3.new(oldCF.X,oldCF.Y-oldSize.Y/2+shopSize.Y/2,oldCF.Z)
shop:PivotTo(CFrame.new(destination-shopCF.Position)*shop:GetPivot())
oldContainer:Destroy();oldShop:Destroy();shop.Name='Shop';shop.Parent=lobby
local darkened=0
local island=lobby:FindFirstChild('Island',true) or lobby
for _,part in ipairs(island:GetDescendants()) do if part:IsA('BasePart') and (part.Material==Enum.Material.Grass or (part.Color.G>part.Color.R*1.15 and part.Color.G>part.Color.B*1.15)) then part.Color=Color3.fromRGB(46,76,39);darkened+=1 end end
for _,model in ipairs({map,lobby}) do model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent end
local effects=Instance.new('Folder');effects.Name='FalloutEffects';effects.Parent=workspace
local spawns=Instance.new('Folder');spawns.Name='FalloutSpawns';spawns.Parent=workspace
local function spawnPart(parent,name,cf)
 local p=Instance.new('Part');p.Name=name;p.Size=Vector3.new(2,1,2);p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CFrame=cf;p.Parent=parent;return p
end
local lobbySpawns=Instance.new('Folder');lobbySpawns.Name='Lobby';lobbySpawns.Parent=spawns
local originalSpawn=assert(lobby:FindFirstChildWhichIsA('SpawnLocation',true),'Lobby spawn missing')
for i=1,10 do spawnPart(lobbySpawns,tostring(i),originalSpawn.CFrame*CFrame.new(((i-1)%5-2)*2.3,4,math.floor((i-1)/5)*2.5)) end
originalSpawn.Enabled=false
local cf,size=map:GetBoundingBox()
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map};params.RespectCanCollide=true
local candidates,histogram={},{}
for ix=2,18 do for iz=2,18 do
 local x=cf.X-size.X*.5+size.X*ix/20;local z=cf.Z-size.Z*.5+size.Z*iz/20
 local hit=workspace:Raycast(Vector3.new(x,cf.Y+size.Y/2+40,z),Vector3.new(0,-size.Y-100,0),params)
 if hit and hit.Normal.Y>.85 then
  local center=hit.Position+Vector3.new(0,3.5,0);local clear=true
  for _,v in ipairs({Vector3.new(2,0,0),Vector3.new(-2,0,0),Vector3.new(0,0,2),Vector3.new(0,0,-2),Vector3.new(0,3,0)}) do if workspace:Raycast(center,v,params) then clear=false;break end end
  if clear then table.insert(candidates,center);local bin=math.floor(hit.Position.Y/4);histogram[bin]=(histogram[bin] or 0)+1 end
 end
end end
assert(#candidates>=20,'Map has too few verified spawn surfaces')
local ground,count=0,0;for y,n in pairs(histogram) do if n>count then ground=y*4;count=n end end
local low={};for _,p in ipairs(candidates) do if math.abs(p.Y-3.5-ground)<8 then table.insert(low,p) end end
assert(#low>=10,'Not enough ground level map spawns')
table.sort(low,function(a,b)return a.X<b.X end)
for team=1,2 do
 local folder=Instance.new('Folder');folder.Name='Team'..team;folder.Parent=spawns
 local taken={}
 for offset=1,#low do
  local p=low[team==1 and offset or #low-offset+1];local good=true
  for _,other in ipairs(taken) do if (other-p).Magnitude<6 then good=false end end
  if good then table.insert(taken,p);spawnPart(folder,tostring(#taken),CFrame.lookAt(p,Vector3.new(cf.X,p.Y,cf.Z)));if #taken==5 then break end end
 end
 assert(#taken==5,'Team spawn layout incomplete')
end
local templates=Instance.new('Folder');templates.Name='FalloutWeaponTemplates';templates.Parent=SS
local visuals=Instance.new('Folder');visuals.Name='FalloutItemVisuals';visuals.Parent=RS
for _,item in ipairs(C.Catalog) do
 local source=assert(SS.SourceWeaponMeshes:FindFirstChild(item.model,true),'Source mesh missing: '..item.model)
 local tool=Instance.new('Tool');tool.Name=item.id;tool.ToolTip=item.name;tool.RequiresHandle=true;tool.CanBeDropped=false;tool:SetAttribute('FalloutItem',item.id)
 local mesh=source:Clone();mesh.Name='Handle';mesh.Anchored=false;mesh.CanCollide=false;mesh.CanTouch=false;mesh.Massless=true
 local length=item.kind=='Gun' and 1.8 or item.kind=='Melee' and 2.6 or .9
 mesh.Size*=length/math.max(mesh.Size.X,mesh.Size.Y,mesh.Size.Z)
 local rotation=mesh.Size.X>mesh.Size.Z and item.kind=='Gun' and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
 mesh.CFrame=rotation;mesh.Parent=tool
 tool.Grip=CFrame.new(0,-.12,-.35)*rotation
 local muzzle=Instance.new('Attachment');muzzle.Name='Muzzle';muzzle.Position=Vector3.new(0,.1,-mesh.Size.Z/2);muzzle.Parent=mesh
 local visual=mesh:Clone();visual.Name=item.id;visual.Anchored=true;visual.CFrame=rotation;visual.Parent=visuals
 tool.Parent=templates
end
SS.SourceWeaponMeshes:Destroy()
local description=Players:GetHumanoidDescriptionFromUserIdAsync(C.OwnerUserId)
local npc=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
description:Destroy();npc.Name='Shopkeeper'
for _,v in ipairs(npc:GetDescendants()) do
 if v:IsA('LuaSourceContainer') then v:Destroy() elseif v:IsA('BasePart') then v.Anchored=false;v.CanCollide=false;v.CanTouch=false end
end
local humanoid=npc:FindFirstChildOfClass('Humanoid');assert(humanoid.RigType==Enum.HumanoidRigType.R6,'NPC must be R6');humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.AutoRotate=false
npc.PrimaryPart=npc.HumanoidRootPart;npc.PrimaryPart.Anchored=true
local floor=shop:FindFirstChild('Floor',true);assert(floor and floor:IsA('BasePart'),'Shop floor missing')
local front=(Vector3.new(originalSpawn.Position.X,0,originalSpawn.Position.Z)-Vector3.new(floor.Position.X,0,floor.Position.Z)).Unit
local npcPos=floor.Position+Vector3.new(0,floor.Size.Y/2+3,0)+front*math.min(2,math.min(floor.Size.X,floor.Size.Z)*.18)
npc:PivotTo(CFrame.lookAt(npcPos,npcPos+front));npc:SetAttribute('OwnerAvatarUserId',C.OwnerUserId);npc:SetAttribute('AnimationPackAssetId',86582491164528);npc.ModelStreamingMode=Enum.ModelStreamingMode.Persistent;npc.Parent=workspace
local headGui=SS.NpcDialogueGui:Clone();headGui.Name='gui';headGui:FindFirstChild('name').Text='ch_ckz2n';headGui.Adornee=npc.Head;headGui.Parent=npc.Head
local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Conversar';prompt.ObjectText='Armeiro';prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=npc
game:GetService('CollectionService'):AddTag(prompt,'NPCprompt')
workspace:SetAttribute('LobbyGrassDarkened',darkened)
workspace:SetAttribute('WorldReady',true)
b:Destroy()
