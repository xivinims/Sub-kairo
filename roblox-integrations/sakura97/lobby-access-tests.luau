local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local house=assert(lobby:FindFirstChild("House"))
assert((lobby:GetAttribute("PassageRepairRevision") or 0)>=4,"Lobby passage repair v4 missing")

local ground=assert(lobby:FindFirstChild("OutdoorGround"),"Exterior ground missing")
assert(ground:IsA("BasePart") and ground.CanCollide and ground.Transparency==0,"Exterior ground must be visible and physical")
assert(ground.Material==Enum.Material.Ground,"Exterior ground must not be grass")
local topY=ground.Position.Y+ground.Size.Y/2
assert(math.abs(topY-625.031494140625)<.25,"Exterior ground is below the authored props")
assert(lobby:GetAttribute("OutdoorGroundMaterial")=="Ground","Exterior ground material metadata missing")

local openDoorParts,doorFrames,supports,outdoorStairs=0,0,0,0
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
  if p:GetAttribute("AuthoredStairCollision") then
   assert(p.CanCollide,"Authored outdoor stair collision missing: "..p:GetFullName())
   outdoorStairs+=1
  end
 end
end

local access=assert(lobby:FindFirstChild("PassageColliders"),"PassageColliders missing")
for _,p in ipairs(access:GetDescendants()) do
 if p:IsA("BasePart") then
  assert(not p:GetAttribute("WalkableStairStep"),"Invisible stair step returned: "..p:GetFullName())
  assert(not p:GetAttribute("UpperLandingBridge"),"Invisible upper stair bridge returned: "..p:GetFullName())
  if p:GetAttribute("PassageSupport") then
   supports+=1
   assert(p.CanCollide and p.Transparency>=.98,"Door frame support invalid")
  end
 end
end

assert(openDoorParts>=7 and doorFrames>=3,"House doorway repairs missing")
assert(supports>=doorFrames*3,"Door frame supports are incomplete")
assert(outdoorStairs>=1,"Outdoor authored stair collision was not restored")

assert(lobby:GetAttribute("StairAccessClosed")==true,"Upper stair closure metadata missing")
assert(lobby:GetAttribute("StairWarningAssetId")==17143448214,"Wrong stair warning asset")
local sign=assert(lobby:FindFirstChild("StairClosedSign"),"Construction sign missing")
assert(sign:GetAttribute("SourceAssetId")==17143448214 and sign:GetAttribute("BlocksUpperFloor")==true,"Construction sign metadata invalid")
assert(sign:FindFirstChild("NoUpstairsLabel",true),"NÃO SUBA warning label missing")
assert((lobby:GetAttribute("WalkableStairSteps") or 0)==0,"Invisible stair path count is not zero")

local npc=assert(workspace:FindFirstChild("LobbyGuide"),"Fill missing")
assert(npc:GetAttribute("ReceptionAccessValidated")==true and npc:GetAttribute("ReceptionAccessMode")=="AuthoredTable","Fill table placement invalid")
assert(not lobby:FindFirstChild("FillGuideStool"),"Generated Fill stool returned")
local tabletop=assert(npc:FindFirstChild("Tabletop") and npc.Tabletop.Value,"Fill tabletop missing")
assert(tabletop:IsDescendantOf(house),"Fill table is outside the authored house")
assert(tabletop.Name=="Furniture_Console_A" and string.find(tabletop:GetFullName(),"Console Desk",1,true),"Fill is not on the authored console table")

local point=npc:GetAttribute("VerifiedVisitorPosition")
assert(typeof(point)=="Vector3","Fill visitor position missing")
assert((point-npc.HumanoidRootPart.Position).Magnitude<=npc.ProximityPrompt.MaxActivationDistance,"Visitor point is outside Fill interaction range")

assert(npc:GetAttribute("OutfitPants")==110421904136844,"Requested Fill pants missing")
assert(npc:GetAttribute("CrossbodyBagAssetId")==97665507839365,"Requested Fill satchel metadata missing")
assert(npc:FindFirstChild("FillCrossbodySatchel",true),"Requested Fill satchel accessory missing")
assert(npc:GetAttribute("OutfitFrozen")==true,"Fill outfit is not frozen")

assert(npc:GetAttribute("NonBlockingGuide")==true,"Fill nonblocking guide flag missing")
assert(npc:GetAttribute("CollisionGroup")=="LobbyGuideGhost","Fill ghost collision metadata missing")
local PhysicsService=game:GetService("PhysicsService")
assert(not PhysicsService:CollisionGroupsAreCollidable("LobbyGuideGhost","Default"),"Fill ghost group still collides with Default")
local guard=assert(npc:FindFirstChild("NonBlockingGuard"),"Fill nonblocking guard missing")
assert(guard:IsA("LuaSourceContainer"),"Fill nonblocking guard is not a script")
for _,p in ipairs(npc:GetDescendants()) do
 if p:IsA("BasePart") then
  assert(p.CollisionGroup=="LobbyGuideGhost","Fill part is outside ghost group: "..p:GetFullName())
  assert(not p.CanTouch and not p.CanQuery,"Fill touch/query returned: "..p:GetFullName())
 end
end

return {
 ok=true,
 exteriorGround=true,
 groundTopY=topY,
 openDoorParts=openDoorParts,
 doorFrames=doorFrames,
 outdoorStairs=outdoorStairs,
 stairClosed=true,
 stairWarning=true,
 invisibleStairSteps=0,
 fillOnAuthoredTable=true,
 fillUpdatedOutfit=true,
 fillNonBlocking=true,
 fillSurface=tabletop:GetFullName()
}
