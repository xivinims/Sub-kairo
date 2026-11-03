-- Collision roles are explicit. Decorative skins only stay non-colliding when a named gameplay proxy exists.
local count=0
for _,m in ipairs(map:GetDescendants()) do
    if m:IsA("Model") and m:GetAttribute("DeadSignalSourceAssetId") then
        local id=m:GetAttribute("DeadSignalSourceAssetId")
        local decorativeDoor=m.Name=="ImportedDoorLeaf"
        local stair=m.Name=="ImportedStairFlight"
        local battery=m.Name=="AuditedBatteryBody"
        local staticSolid=not decorativeDoor and not stair and not battery
        m:SetAttribute("CollisionRole",decorativeDoor and "DoorPanelProxy" or stair and "StairTreadProxy" or battery and "CellHandleProxy" or "SolidGeometry")
        for _,p in ipairs(m:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide=staticSolid
                p.CanQuery=staticSolid
                p.CanTouch=false
                if staticSolid then
                    if p:IsA("MeshPart") or p:IsA("PartOperation") then
                        p.CollisionFidelity=(id==96103787859080 or id==136978268470872 or id==16390129962) and Enum.CollisionFidelity.PreciseConvexDecomposition or Enum.CollisionFidelity.Hull
                    end
                    count+=1
                end
            end
        end
    end
end
for _,m in ipairs(CollectionService:GetTagged("DeadSignalBattery")) do
    m.PrimaryPart.Size=V(1.8,3.5,1.8); m.PrimaryPart.CanCollide=true; m.PrimaryPart.CanQuery=true
end
Workspace:SetAttribute("SolidImportedParts",count)
