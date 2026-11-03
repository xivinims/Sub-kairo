local SS=game:GetService('ServerStorage');local M={};local built={}
M.Limit=3072;M.Village=Vector3.new(0,128,-1120)
function M.Height(x,z) return 124+math.floor(math.noise(x/850,z/850,13)*2)*4 end
function M.Cell(x,z,parent)
 local cx,cz=(x+.5)*128,(z+.5)*128
 if math.abs(cx)>M.Limit or math.abs(cz)>M.Limit or (math.abs(cx)<512 and math.abs(cz)<640) then return nil end
 local key=x..'_'..z;local y=M.Height(cx,cz)
 if not built[key] then
  workspace.Terrain:FillBlock(CFrame.new(cx,y-24,cz),Vector3.new(128,40,128),Enum.Material.Rock)
  workspace.Terrain:FillBlock(CFrame.new(cx,y-4,cz),Vector3.new(128,8,128),Enum.Material.Grass);built[key]=true
 end
 local cell=Instance.new('Model');cell.Name='Cell_'..key
 local templates=SS:WaitForChild('AdventureTrees'):GetChildren();local rng=Random.new(x*73856093+z*19349663)
 local density=math.noise(cx/430,cz/430,61);local count=density>.15 and 19 or (density<-.18 and 4 or 11)
 for i=1,count do
  local pos=Vector3.new(x*128+rng:NextNumber(8,120),y,z*128+rng:NextNumber(8,120))
  if (Vector3.new(pos.X,0,pos.Z)-Vector3.new(M.Village.X,0,M.Village.Z)).Magnitude>190 then
   local tree=templates[rng:NextInteger(1,#templates)]:Clone();tree:ScaleTo(rng:NextNumber(.8,1.2))
   tree:PivotTo(CFrame.new(pos)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0));local bounds,size=tree:GetBoundingBox();tree:PivotTo(tree:GetPivot()+Vector3.new(0,y-(bounds.Y-size.Y/2),0));tree.Parent=cell
  end
 end
 cell.Parent=parent;return cell
end
function M.BuildVillage()
 local center=M.Village;local chunks=require(script.Parent.IslandChunks)
 for x=-2,2 do for z=-2,2 do chunks.Warm('forestCurrent',center+Vector3.new(x*128,0,z*128),64) end end
 local old=workspace.Islands.forestCurrent:FindFirstChild('AdventureVillage');if old then return old end
 local village=Instance.new('Model');village.Name='AdventureVillage';village.Parent=workspace.Islands.forestCurrent
 local groups={}
 for _,p in ipairs(SS.IslandGeometryCatalog.city:GetDescendants()) do if p:IsA('BasePart') then
  local id=p:GetAttribute('DisasterStructureId');if id then groups[id]=groups[id] or {};table.insert(groups[id],p) end
 end end
 local keys={};for id,parts in pairs(groups) do if #parts>=60 then table.insert(keys,id) end end;table.sort(keys)
 assert(#keys>=4,'Not enough village building groups')
 for i=1,4 do
  local parts=groups[keys[i]];local pivot
  for _,p in ipairs(parts) do if p:GetAttribute('IslandDoorPivot') then pivot=p:GetAttribute('IslandDoorPivot');break end end
  pivot=pivot or parts[1].CFrame
  local target=center+Vector3.new((i%2==0 and 1 or -1)*65,0,(i>2 and 1 or -1)*65)
  local height=M.Height(target.X,target.Z);local delta=Vector3.new(target.X-pivot.X,height+4-pivot.Y,target.Z-pivot.Z)
  local house=Instance.new('Model');house.Name='VillageHouse_'..i;house.Parent=village
  for _,p in ipairs(parts) do local c=p:Clone();c.CFrame+=delta
   local door=c:GetAttribute('IslandDoorPivot');if door then c:SetAttribute('IslandDoorPivot',door+delta);c:SetAttribute('IslandDoorId',i*1000+c:GetAttribute('IslandDoorId')) end
   c:SetAttribute('DisasterStructureId',nil);c.Parent=house
  end
 end
 local spawn=workspace.IslandDestinations.forestCurrent;spawn.CFrame=CFrame.new(center+Vector3.new(0,6,0))
 workspace:SetAttribute('VillageCenter',center);workspace:SetAttribute('AdventureForestSize',6144)
 return village
end
return M
