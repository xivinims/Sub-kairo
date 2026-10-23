local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local AS=game:GetService("AssetService")
local runtime=RS:WaitForChild("SweanRuntime")
local config=require(RS:WaitForChild("Survival"):WaitForChild("Config"))
local spawn=workspace:WaitForChild("IslandSpawn")

if workspace:FindFirstChild("JediLibrary") and RS:FindFirstChild("MenuSceneTemplate") and SS:FindFirstChild("SurvivalAssets") then
 runtime:SetAttribute("AssetsReady",true)
 return
end

runtime:SetAttribute("AssetsReady",false)
runtime:SetAttribute("AssetBootstrapError",nil)
pcall(function() AS.AllowInsertFreeAssets=true end)
runtime:SetAttribute("ThirdPartyAssetsAllowed",AS.AllowInsertFreeAssets)

local function load(id)
 local last
 for attempt=1,4 do
  local ok,a=pcall(function() return AS:LoadAssetAsync(id) end)
  if ok and a then return a end
  last=a task.wait(attempt)
 end
 error("Runtime asset "..id.." failed: "..tostring(last))
end

local function countParts(root)
 local n=0
 if root:IsA("BasePart") then n+=1 end
 for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
 return n
end

local function largestVisual(asset)
 local best,bestScore=nil,-1
 for _,d in ipairs(asset:GetDescendants()) do
  if d:IsA("Model") then
   local parts=countParts(d)
   if parts>0 then
    local score=parts
    local ok,_,size=pcall(function() local cf,sz=d:GetBoundingBox() return cf,sz end)
    if ok and size then score+=math.min(100000,size.X*size.Y*size.Z/100) end
    if score>bestScore then best,bestScore=d,score end
   end
  end
 end
 return best or asset:FindFirstChildWhichIsA("BasePart",true)
end

local function asModel(inst)
 if inst:IsA("Model") then return inst end
 local model=Instance.new("Model") inst.Parent=model return model
end

local function sanitize(root,anchored)
 for _,d in ipairs(root:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=anchored d.CanTouch=false
  end
 end
end

local function stripBroken(root)
 for _,d in ipairs(root:GetDescendants()) do
  local function bad(v) return type(v)=="string" and v:find("720367485",1,true)~=nil end
  if d:IsA("Decal") or d:IsA("Texture") then
   if bad(d.Texture) then d:Destroy() end
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
   if bad(d.Texture) then d.Texture="" end
  elseif d:IsA("Sound") then
   if bad(d.SoundId) then d:Destroy() end
  elseif d:IsA("Animation") then
   if bad(d.AnimationId) then d:Destroy() end
  elseif d:IsA("SpecialMesh") then
   if bad(d.MeshId) or bad(d.TextureId) then d:Destroy() end
  end
 end
end

-- Real lobby, loaded only when the server starts so it does not bloat the saved place.
if not workspace:FindFirstChild("JediLibrary") then
 local asset=load(852951140)
 local source=assert(largestVisual(asset),"Jedi Library visual missing")
 local lobby=asModel(source:Clone()) lobby.Name="JediLibrary" lobby:SetAttribute("SourceAssetId",852951140)
 sanitize(lobby,true) stripBroken(lobby) lobby.Parent=workspace
 local cf,size=lobby:GetBoundingBox()
 local bottom=cf.Position.Y-size.Y/2
 lobby:PivotTo(lobby:GetPivot()+Vector3.new(-cf.Position.X,-bottom,-cf.Position.Z))
 cf,size=lobby:GetBoundingBox()
 asset:Destroy()
 local authored=lobby:FindFirstChildWhichIsA("SpawnLocation",true)
 local spawnPos
 if authored then
  spawnPos=authored.Position+Vector3.new(0,authored.Size.Y/2+.2,0)
  authored.Enabled=false authored.Transparency=1 authored.CanCollide=false
 else
  local floor,best=nil,-math.huge
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={lobby}
  for _,p in ipairs(lobby:GetDescendants()) do
   if p:IsA("BasePart") and p.CanCollide and p.Transparency<.98 and p.CFrame.UpVector.Y>.88 and p.Size.X>=5 and p.Size.Z>=5 then
    local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
    local score=p.Size.X*p.Size.Z-Vector2.new(top.X-cf.X,top.Z-cf.Z).Magnitude*2
    if score>best then best=score floor=p spawnPos=top+Vector3.new(0,.2,0) end
   end
  end
  assert(floor and spawnPos,"Runtime lobby floor missing")
 end
 spawn.CFrame=CFrame.new(spawnPos)
 runtime:SetAttribute("VoidThreshold",math.min(-30,(cf.Position.Y-size.Y/2)-18))
 local temp=workspace:FindFirstChild("BootstrapFloor") if temp then temp:Destroy() end
end

-- Private menu background template. Clients clone this locally, so other users never see their menu scene/avatar.
if not RS:FindFirstChild("MenuSceneTemplate") then
 local asset=load(13327565335)
 local source=assert(largestVisual(asset),"Doors menu visual missing")
 local menu=asModel(source:Clone()) menu.Name="MenuSceneTemplate" menu:SetAttribute("SourceAssetId",13327565335)
 sanitize(menu,true) stripBroken(menu)
 for _,d in ipairs(menu:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide=false d.CanTouch=false d.CanQuery=false end end
 menu.Parent=RS asset:Destroy()
end

local old=SS:FindFirstChild("SurvivalAssets") if old then old:Destroy() end
local storage=Instance.new("Folder",SS) storage.Name="SurvivalAssets"
local maps=Instance.new("Folder",storage) maps.Name="Maps"
local rigs=Instance.new("Folder",storage) rigs.Name="Killers"

-- Maps remain server-only. Only the chosen map is cloned into Workspace each round.
for _,spec in ipairs(config.Maps) do
 local a=load(spec.id) sanitize(a,true)
 local map
 if spec.id==13366963505 then
  map=a:FindFirstChild("Map",true) assert(map and map:IsA("Model"),"House map geometry missing")
  local spawnGroup=a:FindFirstChild("Spawns",true) if spawnGroup then spawnGroup.Parent=map end
 elseif spec.id==13967333450 then map=a:FindFirstChild("Map_MilitaryBase",true)
 else map=a:FindFirstChildWhichIsA("Model") end
 assert(map,"Runtime map missing: "..spec.name) map.Parent=nil a:Destroy() map.Name=spec.name
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("Humanoid") then d.Parent:Destroy()
  elseif d:IsA("ScreenGui") or d:IsA("BillboardGui") then d:Destroy() end
 end
 local cf2,sz=map:GetBoundingBox()
 map:PivotTo(map:GetPivot()+Vector3.new(2200-cf2.X,30-(cf2.Y-sz.Y/2),-cf2.Z))
 map.Parent=workspace
 local candidates={}
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function candidate(pos)
  local hit=workspace:Raycast(pos+Vector3.new(0,2,0),Vector3.new(0,-8,0),params)
  if not hit or not hit.Instance.CanCollide or hit.Normal.Y<.8 then return end
  local p=hit.Position+Vector3.new(0,3,0)
  if workspace:Raycast(p-Vector3.new(0,2,0),Vector3.new(0,6,0),params) then return end
  for _,other in ipairs(candidates) do if (p-other).Magnitude<10 then return end end
  candidates[#candidates+1]=p
 end
 local markers=map:FindFirstChild("Spawns",true)
 if markers then for _,d in ipairs(markers:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide=false d.CanQuery=false d.Transparency=1 candidate(d.Position) end end end
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart") and d.CanCollide and d.Transparency<.95 and d.Size.X>=8 and d.Size.Z>=8 and math.abs(d.CFrame.UpVector.Y)>.97 then
   candidate(d.Position+Vector3.new(0,d.Size.Y/2+.1,0))
  end
 end
 assert(#candidates>=9,"Runtime safe points missing in "..spec.name)
 local selected={}
 local pf=game:GetService("PathfindingService")
 local function reachable(x,y)
  local path=pf:CreatePath({AgentRadius=1.5,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
  path:ComputeAsync(x,y) local ok=path.Status==Enum.PathStatus.Success path:Destroy() return ok
 end
 for seed=1,math.min(12,#candidates) do
  local cluster={candidates[seed]}
  for _,pos in ipairs(candidates) do
   if (pos-candidates[seed]).Magnitude>8 and reachable(candidates[seed],pos) then cluster[#cluster+1]=pos end
   if #cluster>=20 then break end
  end
  if #cluster>#selected then selected=cluster end
  if #selected>=9 then break end
 end
 assert(#selected>=9,"Runtime map disconnected: "..spec.name)
 local points=Instance.new("Folder",map) points.Name="SafePoints"
 for i=1,9 do local v=Instance.new("Vector3Value",points) v.Name=tostring(i) v.Value=selected[i] end
 local partCount=0 for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then partCount+=1 end end
 map:SetAttribute("PartCount",partCount) map:SetAttribute("SourceAssetId",spec.id) map:SetAttribute("FloorY",30)
 map.Parent=maps
end

__RIG_INSTALL__

runtime:SetAttribute("RuntimeMapCount",#maps:GetChildren())
runtime:SetAttribute("RuntimeKillerCount",#rigs:GetChildren())
runtime:SetAttribute("AssetsReady",true)
