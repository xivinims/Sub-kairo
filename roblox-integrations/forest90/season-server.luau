local Controller={}
function Controller.start(runtime,world)
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local busy=false local parts={}local lights={}
 local function record(model,kind)
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   local n=p.Name:lower()local vegetation=n:find("leaf",1,true)or n:find("leaves",1,true)or n:find("fern",1,true)or n:find("flower",1,true)or n:find("clover",1,true)
   if vegetation or kind=="plants"then
    local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
    parts[#parts+1]={part=p,appearance=appearance,base=p:GetAttribute("SeasonBaseColor")or p.Color,transparency=p:GetAttribute("SeasonBaseTransparency")or p.Transparency,kind=kind,flower=model.Name:lower():find("flower",1,true)~=nil,accent=model:GetAttribute("SpringBlossom")==true}
   end
  end end
 end
 for _,m in ipairs(world.Decor.Trees:GetChildren())do record(m,"trees")end
 for _,m in ipairs(world.Decor.Plants:GetChildren())do record(m,"plants")end
 local function surface(index)
  for bx=-512,384,128 do for bz=-512,384,128 do
   local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))
   local channels=Terrain:ReadVoxelChannels(region,4,{"SolidMaterial"})local grid=channels.SolidMaterial
   for ix=1,32 do for iz=1,32 do
    for iy=1,54 do local old=grid[ix][iy][iz]
     if old==Enum.Material.Grass or old==Enum.Material.LeafyGrass or old==Enum.Material.Snow then grid[ix][iy][iz]=index==4 and Enum.Material.Snow or index==3 and Enum.Material.LeafyGrass or Enum.Material.Grass end
    end
   end end
   Terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})task.wait()
  end end
 end
 local function apply(index,instant)
  if busy then return false end busy=true local name=Seasons.Names[index]
  runtime:SetAttribute("SeasonName",name)runtime:SetAttribute("SeasonIndex",index)runtime:SetAttribute("SeasonChanging",true)
  local changes={}
  for _,entry in ipairs(parts)do
   local p=entry.part
   if p.Parent then
    local base=entry.base local color=base
    if index==1 and entry.accent then color=Color3.fromRGB(215,170,186)
    elseif index==2 then color=base:Lerp(Color3.fromRGB(64,122,53),.12)
    elseif index==3 then color=base:Lerp(Color3.fromRGB(191,134,63),entry.flower and .22 or .72)
    elseif index==4 then color=base:Lerp(Color3.fromRGB(144,165,153),.50)end
    local hidden=index==4 and entry.kind=="plants"or index==3 and entry.flower
    changes[#changes+1]={entry=entry,from=p.Color,to=color,fromTransparency=p.Transparency,toTransparency=hidden and 1 or entry.transparency}
   end
  end
  -- Eighteen bounded updates avoid thousands of per-frame replicated server tweens on mobile.
  local frames=instant and 1 or 18
  for frame=1,frames do
   local t=instant and 1 or(frame-1)/(frames-1)local alpha=t*t*(3-2*t)
   for i,c in ipairs(changes)do local e=c.entry
    if e.part.Parent then local color=c.from:Lerp(c.to,alpha)e.part.Color=color e.part.Transparency=c.fromTransparency+(c.toTransparency-c.fromTransparency)*alpha
     if e.appearance and e.appearance.Parent then e.appearance.Color=color end
    end
    if i%250==0 then task.wait()end
   end
   if frame<frames then task.wait(Seasons.Transition/(frames-1))end
  end
  surface(index)
  runtime:SetAttribute("SeasonChanging",false)runtime:SetAttribute("SeasonRevision",(runtime:GetAttribute("SeasonRevision")or 0)+1)busy=false return true
 end
 runtime:SetAttribute("SeasonEpoch",workspace:GetServerTimeNow())runtime:SetAttribute("SeasonSeconds",Seasons.Duration)
 -- Saved terrain is already spring; boot does not need to rewrite its geometry.
 runtime:SetAttribute("SeasonName","Primavera")runtime:SetAttribute("SeasonIndex",1)runtime:SetAttribute("SeasonRevision",0)runtime:SetAttribute("SeasonChanging",false)
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  if runtime:GetAttribute("SeasonTestMode")then return end
  elapsed+=dt if elapsed<2 then return end elapsed=0
  local index=Seasons.index(workspace:GetServerTimeNow(),runtime:GetAttribute("SeasonEpoch"))
  if not busy and index~=runtime:GetAttribute("SeasonIndex")then task.spawn(apply,index,false)end
 end)
 return{apply=apply,surface=surface,parts=#parts}
end
return Controller
