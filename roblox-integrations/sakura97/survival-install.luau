local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local AS=game:GetService("AssetService")
local function replace(parent,name,class)
 local old=parent:FindFirstChild(name) if old then old:Destroy() end
 local v=Instance.new(class) v.Name=name v.Parent=parent return v
end
local storage=replace(SS,"SurvivalAssets","Folder")
local maps=Instance.new("Folder",storage) maps.Name="Maps"
local rigs=Instance.new("Folder",storage) rigs.Name="Killers"
local net=replace(RS,"Survival","Folder")
replace(net,"Action","RemoteEvent") replace(net,"Update","RemoteEvent")
local bridge=replace(SSS,"SurvivalBridge","Folder")
for _,n in ipairs({"DeathRequest","DeathFinished","RoundEliminate"}) do replace(bridge,n,"BindableEvent") end
local config=replace(net,"Config","ModuleScript") config.Source=__CONFIG_SOURCE__
local rules=replace(SSS,"RoundRules","ModuleScript") rules.Source=__RULES_SOURCE__
local function load(id)
 local last
 for attempt=1,3 do local ok,a=pcall(function() return AS:LoadAssetAsync(id) end) if ok then return a end last=a task.wait(1) end
 error("Asset "..id..": "..tostring(last))
end
local function sanitize(a,anchored)
 for _,d in ipairs(a:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=anchored d.CanTouch=false
  elseif d:IsA("SpawnLocation") then d.Enabled=false end
 end
 for _,d in ipairs(a:GetDescendants()) do if d:IsA("SpawnLocation") then d.Enabled=false d.Transparency=1 d.CanCollide=false end end
end
-- Tree House: preserve the supplied model, ground its lowest geometry.
local house=load(15761692261) sanitize(house,true) house.Name="LobbyTreeHouse"
local old=workspace:FindFirstChild(house.Name) if old then old:Destroy() end
local ground=game:GetService("CollectionService"):GetTagged("IslandGreenGround")
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances=ground
local tc=workspace.BigCenterTree:GetPivot().Position
local hit=workspace:Raycast(Vector3.new(tc.X+58,500,tc.Z+30),Vector3.new(0,-1000,0),rp)
assert(hit,"Tree house needs green ground")
local cf,size=house:GetBoundingBox()
house:PivotTo(house:GetPivot()+Vector3.new(hit.Position.X-cf.X,hit.Position.Y-(cf.Y-size.Y/2)-.15,hit.Position.Z-cf.Z))
house:SetAttribute("SourceAssetId",15761692261) house.Parent=workspace
-- Keep all inactive maps server-only. Imported legacy scripts never execute.
for _,spec in ipairs(require(config).Maps) do
 local a=load(spec.id) sanitize(a,true)
 local map
 if spec.id==13366963505 then
  map=a:FindFirstChild("Map",true) assert(map and map:IsA("Model"),"House map geometry missing")
  local spawnGroup=a:FindFirstChild("Spawns",true) if spawnGroup then spawnGroup.Parent=map end
 elseif spec.id==13967333450 then map=a:FindFirstChild("Map_MilitaryBase",true)
 else map=a:FindFirstChildWhichIsA("Model") end
 assert(map,"Map missing") map.Parent=nil a:Destroy() map.Name=spec.name
 -- Remove showroom characters, map coin zones, and imported interactive UI.
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("Humanoid") then d.Parent:Destroy()
  elseif d:IsA("ScreenGui") or d:IsA("BillboardGui") then d:Destroy() end
 end
 local cf2,sz=map:GetBoundingBox()
 map:PivotTo(map:GetPivot()+Vector3.new(2200-cf2.X,30-(cf2.Y-sz.Y/2),-cf2.Z))
 map.Parent=workspace
 local candidates={}
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={map}
 local function candidate(pos)
  local hit2=workspace:Raycast(pos+Vector3.new(0,2,0),Vector3.new(0,-8,0),params)
  if not hit2 or not hit2.Instance.CanCollide or hit2.Normal.Y<.8 then return end
  local p=hit2.Position+Vector3.new(0,3,0)
  if workspace:Raycast(p-Vector3.new(0,2,0),Vector3.new(0,6,0),params) then return end
  for _,other in ipairs(candidates) do if (p-other).Magnitude<10 then return end end
  table.insert(candidates,p)
 end
 local markers=map:FindFirstChild("Spawns",true)
 if markers then for _,d in ipairs(markers:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide=false d.Transparency=1 candidate(d.Position) end end end
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart") and d.CanCollide and d.Transparency<.95 and d.Size.X>=8 and d.Size.Z>=8 and math.abs(d.CFrame.UpVector.Y)>.97 then
   candidate(d.Position+Vector3.new(0,d.Size.Y/2+.1,0))
  end
 end
 assert(#candidates>=9,"Too few safe spawn candidates in "..spec.name)
 -- Prefer low, separated walkable points, avoid rooftop starts.
 table.sort(candidates,function(x,y) return x.Y<y.Y end)
 local selected={candidates[1]}
 while #selected<math.min(20,#candidates) do
  local best,score=nil,-1
  for _,p in ipairs(candidates) do
   if p.Y<candidates[1].Y+22 then
    local nearest=math.huge for _,q in ipairs(selected) do nearest=math.min(nearest,(p-q).Magnitude) end
    if nearest>score then best=p score=nearest end
   end
  end
  if not best or score<8 then break end table.insert(selected,best)
 end
 assert(#selected>=9,"Need 9 separated floor positions in "..spec.name)
 local points=Instance.new("Folder",map) points.Name="SafePoints"
 for i,p in ipairs(selected) do local v=Instance.new("Vector3Value",points) v.Name=tostring(i) v.Value=p end
 map:SetAttribute("SourceAssetId",spec.id) map:SetAttribute("FloorY",30) map.Parent=maps
end
-- Models and animation extraction are completed below.
__RIG_INSTALL__
local ai=replace(SSS,"PursuerAI","ModuleScript") ai.Source=__AI_SOURCE__
local server=replace(SSS,"SurvivalServer","Script") server.Source=__SURVIVAL_SERVER_SOURCE__
local client=replace(game:GetService("StarterPlayer").StarterPlayerScripts,"SurvivalClient","LocalScript") client.Source=__SURVIVAL_CLIENT_SOURCE__
local animation=replace(game:GetService("StarterPlayer").StarterPlayerScripts,"PursuerAnimation","LocalScript") animation.Source=__ANIMATION_SOURCE__
net:SetAttribute("Version",1) net:SetAttribute("MaxParticipants",8)
