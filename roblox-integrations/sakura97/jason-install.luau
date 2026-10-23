assert(game.PlaceId==79738710219521 and game.GameId==9419478735,"Wrong place")
local SS=game:GetService("ServerStorage") local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService") local SP=game:GetService("StarterPlayer").StarterPlayerScripts
local AS=game:GetService("AssetService")
local function replace(parent,name,class)
 local old=parent:FindFirstChild(name) if old then old:Destroy() end
 local obj=Instance.new(class) obj.Name=name obj.Parent=parent return obj
end
local function load(id)
 local last
 for attempt=1,3 do
  local ok,a=pcall(function() return AS:LoadAssetAsync(id) end)
  if ok and a then return a end last=a task.wait(attempt*2)
 end
 error("Cannot load exact asset "..id..": "..tostring(last))
end
local function sanitize(m,anchored)
 for _,v in ipairs(m:GetDescendants()) do
  if v:IsA("LuaSourceContainer") or v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then v:Destroy()
  elseif v:IsA("BasePart") then v.Anchored=anchored v.CanTouch=false end
 end
 for _,v in ipairs(m:GetDescendants()) do if v:IsA("SpawnLocation") then v.Enabled=false v.Transparency=1 v.CanCollide=false v.CanQuery=false end end
end
-- Preserve the actual published lobby and all user edits. Never reload its asset.
local lobby=assert(workspace:FindFirstChild("JediLibrary"),"Existing lobby is required; abort rather than overwrite")
local door=assert(lobby:FindFirstChild("Door"),"Existing lobby door missing")
local doorCF,doorSize=door:GetBoundingBox()
local original=door:GetAttribute("OriginalCenter") or doorCF.Position door:SetAttribute("OriginalCenter",original)
local lobbyParams=RaycastParams.new() lobbyParams.FilterType=Enum.RaycastFilterType.Include lobbyParams.FilterDescendantsInstances={lobby} lobbyParams.RespectCanCollide=true
local inside=original-Vector3.new(12,0,0)
local floor=assert(workspace:Raycast(inside,Vector3.new(0,-30,0),lobbyParams),"Lobby entry floor missing")
assert(floor.Normal.Y>.8,"Lobby spawn slope")
local spawn=assert(workspace:FindFirstChild("IslandSpawn"))
spawn.CFrame=CFrame.lookAt(floor.Position+Vector3.new(0,.2,0),Vector3.new(original.X,floor.Position.Y+.2,original.Z))
spawn.Enabled=true spawn.Neutral=true spawn.Transparency=1 spawn.CanCollide=false spawn.Duration=0
-- Slide the original shutters away while retaining the frame.
if not door:GetAttribute("HeldOpen") then
 for _,v in ipairs(door:GetDescendants()) do if v:IsA("BasePart") then
  if v.Size.X<1.1 and v.Size.Z>7 and v.Size.Y>7 then
   v.CFrame+=Vector3.new(0,v.Position.Y<original.Y and -8 or 8,0) v.CanCollide=false
  elseif v.Size.X<3.2 and v.Size.Y>10 then v.CanCollide=false v.Transparency=1 end
 end end
 door:SetAttribute("HeldOpen",true)
end
local gate=replace(workspace,"LobbyJoinPortal","Part")
gate.Size=Vector3.new(5,9,10) gate.CFrame=CFrame.new(original.X-5,floor.Position.Y+4.5,original.Z)
gate.Anchored=true gate.CanCollide=false gate.CanTouch=false gate.CanQuery=false gate.Transparency=1
local sign=Instance.new("BillboardGui",gate) sign.Name="EntrySign" sign.Size=UDim2.fromOffset(220,42) sign.StudsOffset=Vector3.new(0,5,0) sign.MaxDistance=55
local label=Instance.new("TextLabel",sign) label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text="ENTRE PARA JOGAR" label.TextColor3=Color3.fromRGB(225,208,208) label.Font=Enum.Font.GothamMedium label.TextSize=18
local runtime=assert(RS:FindFirstChild("SweanRuntime")) runtime:SetAttribute("Version",120) runtime:SetAttribute("PreservedLobby",true)
runtime:SetAttribute("SpawnX",spawn.Position.X) runtime:SetAttribute("SpawnY",spawn.Position.Y) runtime:SetAttribute("SpawnZ",spawn.Position.Z)
workspace.StreamingEnabled=false
local storage=replace(SS,"SurvivalAssets","Folder")
local maps=Instance.new("Folder",storage) maps.Name="Maps"
local rigs=Instance.new("Folder",storage) rigs.Name="Killers"
local net=replace(RS,"Survival","Folder")
replace(net,"Action","RemoteEvent") replace(net,"Update","RemoteEvent")
local config=replace(net,"Config","ModuleScript") config.Source=__CONFIG_SOURCE__
local bridge=replace(SSS,"SurvivalBridge","Folder")
for _,n in ipairs({"DeathRequest","DeathFinished","RoundEliminate"}) do replace(bridge,n,"BindableEvent") end
local a=load(79671648850902) sanitize(a,true)
local map=assert(a:FindFirstChild("MAP THING"),"Exact Horror Map geometry missing") map.Parent=nil a:Destroy() map.Name="HorrorMap"
local cf,size=map:GetBoundingBox() map:PivotTo(map:GetPivot()+Vector3.new(2200-cf.X,30-(cf.Y-size.Y/2),-cf.Z)) map.Parent=workspace
local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={map} params.RespectCanCollide=true
local candidates={} local authored={}
for _,v in ipairs(map:GetDescendants()) do if v:IsA("SpawnLocation") then table.insert(authored,v.Position) end end
local function candidate(pos)
 local hit=workspace:Raycast(pos+Vector3.new(0,2,0),Vector3.new(0,-8,0),params)
 if not hit or hit.Normal.Y<.9 then return end
 local ground=hit.Position
 if workspace:Raycast(ground+Vector3.new(0,.2,0),Vector3.new(0,6,0),params) then return end
 -- Capsule clearance: reject walls and cramped starts, not just overhead obstructions.
 for _,off in ipairs({Vector3.new(2,0,0),Vector3.new(-2,0,0),Vector3.new(0,0,2),Vector3.new(0,0,-2)}) do
  if workspace:Raycast(ground+Vector3.new(0,2,0),off,params) then return end
 end
 local p=ground+Vector3.new(0,3,0)
 for _,o in ipairs(candidates) do if (o-p).Magnitude<12 then return end end
 table.insert(candidates,p)
end
for _,p in ipairs(authored) do candidate(p) end
local base=assert(map:FindFirstChild("floor",true),"Horror map floor missing")
for x=-base.Size.X/2+8,base.Size.X/2-8,20 do for z=-base.Size.Z/2+8,base.Size.Z/2-8,20 do candidate(base.CFrame:PointToWorldSpace(Vector3.new(x,base.Size.Y/2+.2,z))) end end
assert(#candidates>=9,"Insufficient clear floor positions")
local pf=game:GetService("PathfindingService") local selected={candidates[1]}
for i=2,#candidates do
 local path=pf:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
 local ok=pcall(function() path:ComputeAsync(candidates[1],candidates[i]) end)
 if ok and path.Status==Enum.PathStatus.Success then table.insert(selected,candidates[i]) end path:Destroy()
 if #selected>=30 then break end
end
assert(#selected>=9,"Horror map needs nine connected spawn/patrol positions")
local points=Instance.new("Folder",map) points.Name="SafePoints"
for i,p in ipairs(selected) do local v=Instance.new("Vector3Value",points) v.Name=tostring(i) v.Value=p end
local start=selected[1] local far=start local dist=0
for _,p in ipairs(selected) do if (p-start).Magnitude>dist then far=p dist=(p-start).Magnitude end end
assert(dist>45,"Jason spawn too near entrance")
map:SetAttribute("KillerSpawn",far) map:SetAttribute("EntranceSpawn",start)
local toward=Vector3.new(base.Position.X-start.X,0,base.Position.Z-start.Z)
if toward.Magnitude<1 then toward=Vector3.new(0,0,-1) end toward=toward.Unit
local entrance=Instance.new("Model",map) entrance.Name="ArenaEntrance"
local entranceCF=CFrame.lookAt(start-toward*4, start)
entrance:SetAttribute("DoorCFrame",entranceCF)
for _,spec in ipairs({{"Left",Vector3.new(-3.5,1,0),Vector3.new(1,8,1)},{"Right",Vector3.new(3.5,1,0),Vector3.new(1,8,1)},{"Top",Vector3.new(0,5,0),Vector3.new(8,1,1)}}) do
 local p=Instance.new("Part",entrance) p.Name=spec[1] p.Size=spec[3] p.CFrame=entranceCF*CFrame.new(spec[2]) p.Anchored=true p.Color=Color3.fromRGB(45,35,34) p.Material=Enum.Material.Wood p.CanCollide=false
end
-- Door leaf is created locally after the entrant steps through; server blocks crossing back.
map:SetAttribute("PartCount",0) local count=0 for _,v in ipairs(map:GetDescendants()) do if v:IsA("BasePart") then count+=1 end end
map:SetAttribute("PartCount",count) map:SetAttribute("SourceAssetId",79671648850902) map:SetAttribute("DisplayName","Horror Map") map:SetAttribute("FloorY",30) map.Parent=maps
-- Keep original Jason body and all of its own animation clips; discard showcase and guest rigs.
a=load(125165599816440)
local source=assert(a:FindFirstChild("Jason",true),"Jason rig not found")
assert(source:IsA("Model") and source:FindFirstChildOfClass("Humanoid"),"Invalid Jason rig")
local rig=source:Clone() rig.Parent=nil a:Destroy() sanitize(rig,false)
rig.Name="Jason" rig:SetAttribute("SourceAssetId",125165599816440)
local root=assert(rig:FindFirstChild("HumanoidRootPart")) rig.PrimaryPart=root
local hum=rig:FindFirstChildOfClass("Humanoid") hum.RequiresNeck=false hum.BreakJointsOnDeath=false hum.MaxHealth=1000 hum.Health=1000 hum.HipHeight=0 hum.WalkSpeed=11 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
for _,p in ipairs(rig:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false p.Massless=p~=root end end
root.CanCollide=true root.Size=Vector3.new(2,2,1)
-- Compact exact poses as JSON, avoiding tens of thousands of replicated Instances.
local function compact(folder,destination)
 for _,seq in ipairs(folder:GetChildren()) do if seq:IsA("KeyframeSequence") then
  local frames=seq:GetKeyframes() table.sort(frames,function(x,y) return x.Time<y.Time end)
  local data={length=frames[#frames].Time,frames={}}
  for _,f in ipairs(frames) do
   local poses={}
   for _,p in ipairs(f:GetDescendants()) do if p:IsA("Pose") and p.Weight>0 then poses[p.Name]={p.CFrame:GetComponents()} end end
   table.insert(data.frames,{time=f.Time,poses=poses})
  end
  local json=game:GetService("HttpService"):JSONEncode(data)
  local encoder=game:GetService("EncodingService")
  local packed=buffer.tostring(encoder:Base64Encode(encoder:CompressBuffer(buffer.fromstring(json),Enum.CompressionAlgorithm.Zstd,19)))
  local clip=Instance.new("Folder",destination) clip.Name=seq.Name clip:SetAttribute("ChunkCount",math.ceil(#packed/100000))
  for offset=1,#packed,100000 do local value=Instance.new("StringValue",clip) value.Name=string.format("%04d",math.floor((offset-1)/100000)+1) value.Value=packed:sub(offset,offset+99999) end
 end end
 destination:SetAttribute("ClipCount",#destination:GetChildren())
end
local clips=Instance.new("Folder",rig) clips.Name="MotionClips"
local saves=assert(rig:FindFirstChild("AnimSaves")) compact(saves,clips) saves:Destroy()
rig.Parent=rigs
local crouchAsset=load(134326820545987)
local crouch=Instance.new("Folder",net) crouch.Name="CrouchClips" crouch:SetAttribute("SourceAssetId",134326820545987)
compact(assert(crouchAsset:FindFirstChild("AnimSaves",true)),crouch) crouchAsset:Destroy()
local function scriptAt(parent,name,class,sourceCode) local s=replace(parent,name,class) s.Source=sourceCode return s end
scriptAt(SSS,"RoundRules","ModuleScript",__RULES_SOURCE__)
scriptAt(SSS,"PursuerAI","ModuleScript",__AI_SOURCE__)
scriptAt(SSS,"KillerFactory","ModuleScript",__KILLER_FACTORY_SOURCE__)
scriptAt(SSS,"SurvivalServer","Script",__SURVIVAL_SERVER_SOURCE__)
scriptAt(SP,"SurvivalClient","LocalScript",__SURVIVAL_CLIENT_SOURCE__)
scriptAt(SP,"PursuerAnimation","LocalScript",__ANIMATION_SOURCE__)
net:SetAttribute("Version",120) net:SetAttribute("MaxParticipants",8)
local light=game:GetService("Lighting") light.ClockTime=0 light.Brightness=2 light.Ambient=Color3.fromRGB(65,63,72) light.OutdoorAmbient=Color3.fromRGB(82,84,96) light.ExposureCompensation=.1
local grade=replace(light,"SurviversGrade","ColorCorrectionEffect") grade.Contrast=.12 grade.Saturation=-.18 grade.TintColor=Color3.fromRGB(236,231,241)
-- Avoid expensive blur and depth-of-field on mobile.
for _,v in ipairs(light:GetChildren()) do if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then v:Destroy() end end
return {mapParts=count,connectedPoints=#selected,jasonClips=#clips:GetChildren(),lobbyPreserved=true}
