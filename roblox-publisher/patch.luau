
local AS=game:GetService("AssetService")
local SS=game:GetService("ServerStorage")

local out={version=game.PlaceVersion,maps={},asset={sequences={},animations={},humanoids={}}}

local asset=AS:LoadAssetAsync(14026023204)
for _,d in ipairs(asset:GetDescendants()) do
 if d:IsA("KeyframeSequence") then
  table.insert(out.asset.sequences,{
   path=d:GetFullName(),
   name=d.Name,
   frames=#d:GetKeyframes(),
   loop=d.Loop,
   priority=tostring(d.Priority)
  })
 elseif d:IsA("Animation") then
  table.insert(out.asset.animations,{path=d:GetFullName(),id=d.AnimationId})
 elseif d:IsA("Humanoid") then
  table.insert(out.asset.humanoids,{path=d:GetFullName(),rig=tostring(d.RigType),walk=d.WalkSpeed})
 end
end
asset:Destroy()

local maps=SS:FindFirstChild("NB_Maps")
for _,m in ipairs(maps and maps:GetChildren() or {}) do
 if m:IsA("Model") then
  local cf,size=m:GetBoundingBox()
  local entry={
   name=m.Name,
   center={cf.Position.X,cf.Position.Y,cf.Position.Z},
   size={size.X,size.Y,size.Z},
   spawns={},
   surfaces={}
  }

  for _,d in ipairs(m:GetDescendants()) do
   if d:IsA("SpawnLocation") then
    local lp=cf:PointToObjectSpace(d.Position)
    table.insert(entry.spawns,{
     name=d.Name,
     pos={d.Position.X,d.Position.Y,d.Position.Z},
     localPos={lp.X,lp.Y,lp.Z},
     size={d.Size.X,d.Size.Y,d.Size.Z}
    })
   elseif d:IsA("BasePart")
    and d.CanCollide
    and d.Transparency<.98
    and d.CFrame.UpVector.Y>.72
    and d.Size.X*d.Size.Z>=16 then

    local lp=cf:PointToObjectSpace(d.Position)
    table.insert(entry.surfaces,{
     name=d.Name,
     class=d.ClassName,
     y=d.Position.Y,
     localY=lp.Y,
     localX=lp.X,
     localZ=lp.Z,
     sx=d.Size.X,sy=d.Size.Y,sz=d.Size.Z,
     area=d.Size.X*d.Size.Z,
     material=tostring(d.Material)
    })
   end
  end

  table.sort(entry.surfaces,function(a,b)
   if math.abs(a.localY-b.localY)>.25 then return a.localY<b.localY end
   return a.area>b.area
  end)

  local filtered={}
  for _,s in ipairs(entry.surfaces) do
   if math.abs(s.localX)<=size.X*.42 and math.abs(s.localZ)<=size.Z*.42 then
    table.insert(filtered,s)
    if #filtered>=60 then break end
   end
  end
  entry.surfaces=filtered
  out.maps[m.Name]=entry
 end
end

return out
