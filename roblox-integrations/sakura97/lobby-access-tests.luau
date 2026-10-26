local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local house=assert(lobby:FindFirstChild("House"))
assert((lobby:GetAttribute("PassageRepairRevision") or 0)>=2,"Lobby passage repair v2 missing")

local openDoorParts,doorFrames,stairMeshes,visualStairs,stairSteps,supports=0,0,0,0,0,0
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  if p.Transparency>=.98 then
   assert(not p.CanCollide,"Invisible interior blocker: "..p:GetFullName())
  end
  if p:GetAttribute("OpenPassage") then
   assert(not p.CanCollide,"Open doorway still collides: "..p:GetFullName())
   openDoorParts+=1
   if p:GetAttribute("PassageWidth") then
    assert((p:GetAttribute("PassageWidth") or 0)>=2.4,"Door passage is too narrow")
    assert((p:GetAttribute("PassageHeight") or 0)>=5,"Door passage is too short")
    doorFrames+=1
   end
  end
  if p:GetAttribute("VisualOnlyStair") then
   assert(not p.CanCollide,"Original stair/rail mesh still collides: "..p:GetFullName())
   visualStairs+=1
  end
  if p:GetAttribute("WalkableReplacement") then
   stairMeshes+=1
  end
 end
end

local access=assert(lobby:FindFirstChild("PassageColliders"),"PassageColliders missing")
local groups={}
local highest=nil
for _,p in ipairs(access:GetDescendants()) do
 if p:IsA("BasePart") then
  if p:GetAttribute("PassageSupport") then
   supports+=1
   assert(p.CanCollide and p.Transparency>=.98,"Door support must be invisible and solid")
  end
  if p:GetAttribute("WalkableStairStep") then
   assert(p.CanCollide and p.Transparency>=.98,"Walkable stair support must be invisible and solid")
   stairSteps+=1
   local source=p:GetAttribute("SourceStair") or "unknown"
   groups[source]=groups[source] or {}
   table.insert(groups[source],p)
   if not highest or p.Position.Y>highest.Position.Y then highest=p end
  end
 end
end

assert(openDoorParts>=7 and doorFrames>=3,"House doorway repairs missing")
assert(supports>=doorFrames*3,"Door frame supports are incomplete")
assert(visualStairs>=6,"Not all imported stair pieces were made visual-only: "..visualStairs)
assert(stairMeshes>=1 and stairSteps>=8,"Walkable stair replacement missing meshes="..stairMeshes.." steps="..stairSteps)

local usableStairs=0
for source,steps in pairs(groups) do
 if #steps>=8 then
  table.sort(steps,function(a,b)return a.Position.Y<b.Position.Y end)
  local rise=steps[#steps].Position.Y-steps[1].Position.Y
  local maxRise=0
  for i=2,#steps do maxRise=math.max(maxRise,steps[i].Position.Y-steps[i-1].Position.Y) end
  assert(maxRise<=1.35,"Stair step rise too high for player movement: "..source)
  if rise>=1.2 then usableStairs+=1 end
 end
end
assert(usableStairs>=1,"No staircase has a continuous walkable step chain")
assert(highest,"No upstairs stair endpoint found")
lobby:SetAttribute("VerifiedUpstairsPosition",highest.Position+Vector3.new(0,3,0))

local npc=assert(workspace:FindFirstChild("LobbyGuide"),"Fill missing")
assert(npc:GetAttribute("ReceptionAccessValidated")==true,"Fill reception was not access-validated")
assert(npc:GetAttribute("ReceptionAccessMode")=="SpawnRoomDirect","Fill must remain directly accessible in spawn room")
local point=npc:GetAttribute("VerifiedVisitorPosition")
assert(typeof(point)=="Vector3","Fill has no verified visitor position")
local spawn=lobby:GetAttribute("VerifiedSpawn")
assert(typeof(spawn)=="Vector3","Verified lobby spawn missing")
local flatDistance=(Vector2.new(point.X,point.Z)-Vector2.new(spawn.X,spawn.Z)).Magnitude
assert(flatDistance<=1.5,"Fill visitor point moved away from lobby spawn")
assert((point-npc.HumanoidRootPart.Position).Magnitude<=npc.ProximityPrompt.MaxActivationDistance,"Fill is outside interaction range from spawn")

return {
 ok=true,
 openDoorParts=openDoorParts,
 doorFrames=doorFrames,
 stairMeshes=stairMeshes,
 visualStairs=visualStairs,\n stairPathSteps=stairSteps,
 usableStairs=usableStairs,
 fillDirectFromSpawn=true,
 fillSurface=npc:GetAttribute("ReceptionSurface")
}
