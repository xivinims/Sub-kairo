local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local house=assert(lobby:FindFirstChild("House"))
assert((lobby:GetAttribute("PassageRepairRevision") or 0)>=2,"Lobby passage repair v2 missing")
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={lobby}
params.RespectCanCollide=true

local openDoorParts,doorFrames,stairMeshes,stairSteps=0,0,0,0
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  if p.Transparency>=.98 then assert(not p.CanCollide,"Invisible interior blocker: "..p:GetFullName()) end
  if p:GetAttribute("OpenPassage") then
   assert(not p.CanCollide,"Open doorway still collides: "..p:GetFullName())
   openDoorParts+=1
   if p:GetAttribute("PassageWidth") then
    local center=p.CFrame*CFrame.new(0,-p.Size.Y/2+3.4,-p.Size.Z/2-1.5)
    local hit=workspace:Blockcast(center,Vector3.new(1.8,4.8,.1),p.CFrame.LookVector*-(p.Size.Z+3),params)
    assert(not hit,"Door opening blocked: "..p:GetFullName().." by "..(hit and hit.Instance:GetFullName() or ""))
    doorFrames+=1
   end
  end
  if p:GetAttribute("WalkableReplacement") then
   assert(not p.CanCollide,"Original stair mesh still collides: "..p:GetFullName())
   stairMeshes+=1
  end
 end
end

local access=assert(lobby:FindFirstChild("PassageColliders"),"PassageColliders missing")
local topSteps={}
for _,p in ipairs(access:GetDescendants()) do
 if p:IsA("BasePart") and p:GetAttribute("WalkableStairStep") then
  assert(p.CanCollide and p.Transparency>=.98,"Walkable stair support must be invisible and solid")
  stairSteps+=1
  local source=p:GetAttribute("SourceStair") or "unknown"
  local old=topSteps[source]
  if not old or p.Position.Y>old.Position.Y then topSteps[source]=p end
 end
end
assert(openDoorParts>=7 and doorFrames>=3,"House doorway repairs missing")
assert(stairMeshes>=3 and stairSteps>=20,"Walkable stair replacement missing")

local nav=game:GetService("PathfindingService")
local origin=lobby:GetAttribute("VerifiedSpawn")+Vector3.new(0,3,0)
local function route(target)
 local path=nav:CreatePath({AgentRadius=1.4,AgentHeight=5,AgentCanJump=false,AgentCanClimb=true,WaypointSpacing=3})
 local ok=pcall(function() path:ComputeAsync(origin,target) end)
 local status=path.Status
 local waypoints=ok and path:GetWaypoints() or {}
 path:Destroy()
 return ok and status==Enum.PathStatus.Success and #waypoints>=2,#waypoints,status.Name
end

local npc=assert(workspace:FindFirstChild("LobbyGuide"),"Fill missing")
assert(npc:GetAttribute("ReceptionAccessValidated")==true,"Fill reception was not access-validated")
local point=npc:GetAttribute("VerifiedVisitorPosition")
assert(typeof(point)=="Vector3","Fill has no verified visitor position")
local npcOk,steps,npcStatus=route(point)
assert(npcOk,"No walking route from lobby spawn to Fill: "..npcStatus)
assert((point-npc.HumanoidRootPart.Position).Magnitude<=npc.ProximityPrompt.MaxActivationDistance,"Reachable Fill point is outside dialogue range")

local upper=nil local upperSteps=0 local upperStatus="NoCandidate"
local ordered={}
for source,p in pairs(topSteps) do table.insert(ordered,{source=source,part=p}) end
table.sort(ordered,function(a,b)return a.part.Position.Y>b.part.Position.Y end)
for _,entry in ipairs(ordered) do
 local target=entry.part.Position+Vector3.new(0,3,0)
 local ok,count,status=route(target)
 upperStatus=status
 if ok then upper=target upperSteps=count break end
end
assert(upper,"No walking route up the lobby stairs: "..upperStatus)
lobby:SetAttribute("VerifiedUpstairsPosition",upper)
return {
 ok=true,
 openDoorParts=openDoorParts,
 doorFrames=doorFrames,
 stairMeshes=stairMeshes,
 stairPathSteps=stairSteps,
 npcWalkingRoute=steps,
 upstairsWalkingRoute=upperSteps,
 fillSurface=npc:GetAttribute("ReceptionSurface")
}
