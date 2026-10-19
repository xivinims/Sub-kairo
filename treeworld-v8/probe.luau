assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local t=workspace.Terrain
local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Include;p.FilterDescendantsInstances={t}
local function sample()
 local rows={}
 for _,z in ipairs({-1030,-970,-945,-910,-850,-790,-755,-730,-650}) do
  local row={z=z,points={}}
  for _,x in ipairs({-400,-220,-180,-154,-118,-94,-80,0,80,94,118,154,180,220,400}) do
   local h=workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-500,0),p)
   table.insert(row.points,{x=x,y=h and h.Position.Y,material=h and tostring(h.Material)})
  end
  table.insert(rows,row)
 end
 return rows
end
local samples=sample()
task.wait(3)
local region=Region3.new(Vector3.new(116,-52,-852),Vector3.new(120,32,-848)):ExpandToGrid(4)
local materials,occupancies=t:ReadVoxels(region,4)
local voxels={}
for y=1,#materials[1] do table.insert(voxels,{y=region.CFrame.Position.Y-region.Size.Y/2+(y-.5)*4,m=tostring(materials[1][y][1]),o=occupancies[1][y][1]}) end
return {placeVersion=game.PlaceVersion,initial=samples,afterWait=sample(),voxels=voxels}
