-- A concrete tabletop is required. Never fall back to lobby spawn/floor.
return function(npc,tabletop)
 assert(npc:GetAttribute("AppearanceVerified")==true,"Guide outfit has not been verified")
 assert(tabletop and tabletop:IsA("BasePart") and tabletop:IsDescendantOf(workspace),"Select the actual lobby tabletop")
 assert(tabletop.Anchored and tabletop.CanCollide,"Tabletop must be a stable solid surface")
 assert(tabletop.CFrame.UpVector.Y>.98,"Guide requires a level tabletop")
 local original=npc:GetPivot()
 local relative=tabletop.CFrame:ToObjectSpace(original)
 local rotation=relative.Rotation
 npc:PivotTo(tabletop.CFrame*rotation)
 local box,size=npc:GetBoundingBox()
 if size.X>tabletop.Size.X-.2 or size.Z>tabletop.Size.Z-.2 then
  npc:PivotTo(original)
  error("Tabletop is too small for the exact pose")
 end
 local top=tabletop.Position.Y+tabletop.Size.Y/2
 local bottom=box.Position.Y-size.Y/2
 npc:PivotTo(npc:GetPivot()+Vector3.new(tabletop.Position.X-box.Position.X,top-bottom+.02,tabletop.Position.Z-box.Position.Z))
 npc:SetAttribute("Placement","TabletopOnly")
 local reference=npc:FindFirstChild("Tabletop") or Instance.new("ObjectValue")
 reference.Name="Tabletop" reference.Value=tabletop reference.Parent=npc
 npc.HumanoidRootPart.Anchored=true
 return npc
end
