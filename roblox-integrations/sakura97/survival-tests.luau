local SS=game:GetService("ServerStorage") local SSS=game:GetService("ServerScriptService")
local Rules=require(SSS.RoundRules)
local AI=require(SSS.PursuerAI) local configs=require(game.ReplicatedStorage.Survival.Config).Killers
assert(not AI.visible("Figure",configs.Figure,2,20,true,1,false))
assert(not AI.visible("Guerreiro",configs.Guerreiro,2,0,true,1,false))
assert(AI.visible("Guerreiro",configs.Guerreiro,6,8,true,-1,false))
assert(not AI.visible("Guerreiro",configs.Guerreiro,20,16,false,1,false))
assert(AI.visible("Scarlat",configs.Scarlat,60,8,false,-1,true))
assert(not AI.visible("Scarlat",configs.Scarlat,60,0,false,-1,true))
local s=Rules.new() assert(not Rules.join(s,1)) Rules.begin(s)
for i=1,8 do assert(Rules.join(s,i)) s.entries[i].status="alive" end
assert(not Rules.join(s,9),"Arena capacity exceeded")
assert(Rules.down(s,1,100)) assert(not Rules.down(s,1,101))
assert(Rules.revive(s,1,1,103)) assert(not s.entries[1].kit)
assert(Rules.down(s,1,104)) assert(not Rules.revive(s,1,1,105),"Kit reused")
assert(Rules.revive(s,2,1,108)) assert(s.entries[2].points==10)
assert(Rules.down(s,3,110)) assert(not Rules.revive(s,4,3,136),"Revived after deadline")
s.entries[3].status="eliminated" assert(not Rules.join(s,3),"Eliminated player rejoined")
assert(Rules.join(s,9),"Mid-round admission failed")
Rules.begin(s) assert(Rules.join(s,3),"New round should reset elimination")
local assets=SS.SurvivalAssets
assert(#assets.Maps:GetChildren()==4,"Expected 4 maps, got "..#assets.Maps:GetChildren())
assert(#assets.Killers:GetChildren()==5,"Expected 5 killers, got "..#assets.Killers:GetChildren())
local maps={}
for _,m in ipairs(assets.Maps:GetChildren()) do
 local points=m.SafePoints:GetChildren() assert(#points>=9,"Too few safe points in "..m.Name)
 local parts=0 for _,d in ipairs(m:GetDescendants()) do assert(not d:IsA("LuaSourceContainer"),"Imported map script") if d:IsA("BasePart") then parts+=1 assert(d.Anchored,"Unanchored map part in "..m.Name..": "..d.Name) end end
 maps[#maps+1]={name=m.Name,parts=parts,spawns=#points}
end
local rigs={}
for _,m in ipairs(assets.Killers:GetChildren()) do
 assert(m.PrimaryPart,"Missing PrimaryPart in "..m.Name) assert(m:FindFirstChildOfClass("Humanoid"),"Missing Humanoid in "..m.Name)
 local joints=0 local names={}
 for _,d in ipairs(m:GetDescendants()) do
  assert(not d:IsA("LuaSourceContainer"),"Imported rig script")
  if d:IsA("Motor6D") then joints+=1 table.insert(names,{name=d.Name,part=d.Part1 and d.Part1.Name}) end
 end
 assert(joints>0,"No Motor6D joints in "..m.Name) table.insert(rigs,{name=m.Name,joints=names,clips=#m.MotionClips:GetChildren()})
end
local pathChecks={}
for _,template in ipairs(assets.Maps:GetChildren()) do
 local map=template:Clone() map.Parent=workspace
 task.wait(.2)
 local pts=map.SafePoints:GetChildren() local paths={}
 for i=2,#pts do
  local path=game:GetService("PathfindingService"):CreatePath({AgentRadius=1.5,AgentHeight=5,AgentCanJump=true})
  path:ComputeAsync(pts[1].Value,pts[i].Value)
  assert(path.Status==Enum.PathStatus.Success,"Unreachable spawn "..template.Name.."/"..pts[i].Name)
  table.insert(paths,{index=pts[i].Name,status=path.Status.Name,waypoints=#path:GetWaypoints()}) path:Destroy()
 end
 table.insert(pathChecks,{map=template.Name,paths=paths}) map:Destroy()
end
local warrior=assert(assets.Killers:FindFirstChild("Guerreiro"))
assert(warrior:GetAttribute("AnimationAssetId")==125165599816440)
assert(#warrior.MotionClips:GetChildren()==3,"Warrior movement clips missing")
assert(warrior:GetAttribute("AvatarItems")=="109013223175977,131536373946103,108562010348687,78897239250220,10982591410,10982519012,206119001888066")
assert((warrior:GetAttribute("AppliedItemCount") or 0)>=6,"Warrior cosmetic set did not load")
local freddyJoints={}
local f=assets.Killers.Freddy
for _,d in ipairs(f:GetDescendants()) do if d:IsA("Motor6D") then
 table.insert(freddyJoints,{p0=d.Part0 and d.Part0.Name,p1=d.Part1 and d.Part1.Name,pos=d.Part1 and tostring(f.PrimaryPart.CFrame:PointToObjectSpace(d.Part1.Position))})
end end
local mediaFailures={}
local roots={workspace.JediLibrary,assets.Maps,assets.Killers}
game:GetService("ContentProvider"):PreloadAsync(roots,function(id,status)
 if status~=Enum.AssetFetchStatus.Success then table.insert(mediaFailures,{id=id,status=status.Name}) end
end)
local lobby=workspace.JediLibrary assert(lobby:GetAttribute("SourceAssetId")==852951140)
local cf,size=lobby:GetBoundingBox()
return {ok=true,mediaFailures=mediaFailures,pathChecks=pathChecks,freddyJoints=freddyJoints,capacity=8,roundSeconds=Rules.Duration,intermission=Rules.Intermission,reviveRules=true,maps=maps,rigs=rigs,lobbyAsset=852951140,lobbyBottom=cf.Y-size.Y/2,warriorPending=false,warriorItems=7}
