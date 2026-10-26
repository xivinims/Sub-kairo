local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local house=assert(lobby:FindFirstChild("House"))
assert((lobby:GetAttribute("PassageRepairRevision") or 0)>=3,"Lobby passage repair v3 missing")
assert(lobby:GetAttribute("OutdoorGroundReady")==true,"Exterior lobby ground was not rebuilt")
local groundSize=lobby:GetAttribute("OutdoorGroundSize")
assert(typeof(groundSize)=="Vector3" and groundSize.X>=400 and groundSize.Z>=400,"Exterior lobby ground is too small")
local outdoorGround=assert(lobby:FindFirstChild("OutdoorGround"),"Persistent exterior grass floor missing")
assert(outdoorGround:IsA("BasePart") and outdoorGround.CanCollide and outdoorGround.Material==Enum.Material.Grass,"Exterior grass floor is not physical")
assert(outdoorGround:GetAttribute("PersistentOutdoorGround")==true,"Exterior grass floor persistence marker missing")

local openDoorParts,doorFrames,stairMeshes,visualStairs,stairSteps,supports,landingBridge=0,0,0,0,0,0,0
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
  if p:GetAttribute("WalkableReplacement") then stairMeshes+=1 end
  if p:GetAttribute("FoyerRailPassThrough") then
   assert(not p.CanCollide,"Foyer rail still blocks upper landing")
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
   if p:GetAttribute("UpperLandingBridge") then landingBridge+=1 end
   local source=p:GetAttribute("SourceStair") or "unknown"
   groups[source]=groups[source] or {}
   table.insert(groups[source],p)
   if not highest or p.Position.Y>highest.Position.Y then highest=p end
  end
 end
end

assert(openDoorParts>=7 and doorFrames>=3,"House doorway repairs missing")
assert(supports>=doorFrames*3,"Door frame supports are incomplete")
assert(visualStairs>=6,"Imported stair visuals were not made pass-through")
assert(stairMeshes>=1 and stairSteps>=14,"Walkable stair replacement missing")
assert(landingBridge>=5,"Upper foyer landing bridge is missing")
assert((lobby:GetAttribute("ClearedFoyerRails") or 0)>=1,"Blocking foyer rails were not cleared")

local usableStairs=0
for source,steps in pairs(groups) do
 if #steps>=8 then
  table.sort(steps,function(a,b)return a.Position.Y<b.Position.Y end)
  local rise=steps[#steps].Position.Y-steps[1].Position.Y
  local maxRise=0
  for i=2,#steps do maxRise=math.max(maxRise,steps[i].Position.Y-steps[i-1].Position.Y) end
  assert(maxRise<=1.35,"Stair step rise too high for player movement: "..source)
  if rise>=8 then usableStairs+=1 end
 end
end
assert(usableStairs>=1,"No full-height staircase has a continuous walkable step chain")
assert(highest,"No upstairs stair endpoint found")
local mainStair=nil
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") and string.find(string.lower(p.Name),"house_foyer_stairs_lower",1,true) then mainStair=p break end
end
assert(mainStair and highest.Position.Y>=mainStair.Position.Y+mainStair.Size.Y/2-1.2,"Stair path still stops below upper floor")
lobby:SetAttribute("VerifiedUpstairsPosition",highest.Position+Vector3.new(0,3,0))

local npc=assert(workspace:FindFirstChild("LobbyGuide"),"Fill missing")
assert(npc:GetAttribute("ReceptionAccessValidated")==true,"Fill table placement was not validated")
assert(npc:GetAttribute("ReceptionAccessMode")=="AuthoredTable","Fill is not using the authored lobby table")
assert(not lobby:FindFirstChild("FillGuideStool"),"Generated Fill stool returned")
local tabletop=assert(npc:FindFirstChild("Tabletop") and npc.Tabletop.Value,"Fill tabletop reference missing")
assert(tabletop:IsDescendantOf(house),"Fill table is outside the authored house")
assert(string.find(tabletop:GetFullName(),"Console Desk",1,true) and tabletop.Name=="Furniture_Console_A","Fill is not seated on the authored console table")
local point=npc:GetAttribute("VerifiedVisitorPosition")
assert(typeof(point)=="Vector3","Fill has no visitor position")
assert((point-npc.HumanoidRootPart.Position).Magnitude<=npc.ProximityPrompt.MaxActivationDistance,"Visitor point is outside Fill interaction range")

return {
 ok=true,
 exteriorGround=true,
 openDoorParts=openDoorParts,
 doorFrames=doorFrames,
 stairMeshes=stairMeshes,
 visualStairs=visualStairs,
 stairPathSteps=stairSteps,
 landingBridgeSteps=landingBridge,
 usableStairs=usableStairs,
 fillOnAuthoredTable=true,
 fillSurface=tabletop:GetFullName()
}
