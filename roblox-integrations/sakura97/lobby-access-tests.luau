local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local house=assert(lobby:FindFirstChild("House"))
local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={lobby} params.RespectCanCollide=true
local doorCount,stairCount=0,0
local stairs=nil
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  if p.Transparency>=.98 then assert(not p.CanCollide,"Invisible interior blocker: "..p:GetFullName()) end
  if p:GetAttribute("OpenPassage") then
   local center=p.CFrame*CFrame.new(0,-p.Size.Y/2+3.4,-p.Size.Z/2-1.5)
   local hit=workspace:Blockcast(center,Vector3.new(1.8,4.8,.1),p.CFrame.LookVector*-(p.Size.Z+3),params)
   assert(not hit,"Door opening blocked: "..p:GetFullName().." by "..(hit and hit.Instance:GetFullName() or ""))
   doorCount+=1
  end
  if p:GetAttribute("PrecisePassageCollision") then
   assert(p.CollisionFidelity==Enum.CollisionFidelity.PreciseConvexDecomposition,"Stair collision not rebuilt") stairCount+=1
   if p.Name:find("House_Foyer_Stairs",1,true) then stairs=p end
  end
 end
end
assert(doorCount>=7 and stairCount>=6,"House doorway/stair repairs missing")
local nav=game:GetService("PathfindingService")
local origin=lobby:GetAttribute("VerifiedSpawn")+Vector3.new(0,3,0)
local function reachableAround(center,radius,minFloor)
 local failures={}
 for i=0,7 do
  local theta=i*math.pi/4
  local x=center+Vector3.new(math.cos(theta)*radius,0,math.sin(theta)*radius)
  local hit=workspace:Raycast(x+Vector3.new(0,6,0),Vector3.new(0,-18,0),params)
  if hit and hit.Normal.Y>.8 and hit.Position.Y>=minFloor and not workspace:Raycast(hit.Position+Vector3.new(0,.2,0),Vector3.new(0,5.2,0),params) then
   local target=hit.Position+Vector3.new(0,3,0)
   local path=nav:CreatePath({AgentRadius=1.4,AgentHeight=5,AgentCanJump=false,WaypointSpacing=3})
   path:ComputeAsync(origin,target)
   if path.Status==Enum.PathStatus.Success then
    local waypoints=path:GetWaypoints()
    if #waypoints>=2 then path:Destroy() return target,#waypoints end
   end
   table.insert(failures,tostring(target)..":"..path.Status.Name) path:Destroy()
  end
 end
 return nil,table.concat(failures,";")
end
local npc=workspace.LobbyGuide
local point,steps=reachableAround(npc.Torso.Position,6,origin.Y-5)
assert(point,"No walking route from lobby spawn to Fill: "..tostring(steps))
assert((point-npc.HumanoidRootPart.Position).Magnitude<=npc.ProximityPrompt.MaxActivationDistance,"Reachable Fill point is outside dialogue range")
npc:SetAttribute("VerifiedVisitorPosition",point)
local upper,upperSteps=reachableAround(stairs.Position+Vector3.new(0,stairs.Size.Y/2,0),14,origin.Y+9)
assert(upper,"No walking route up the lobby stairs: "..tostring(upperSteps))
lobby:SetAttribute("VerifiedUpstairsPosition",upper)
return {ok=true,openDoorways=doorCount,preciseStairMeshes=stairCount,npcWalkingRoute=steps,upstairsWalkingRoute=upperSteps}
