local Storage=game:GetService('ServerStorage')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local templates=Storage:WaitForChild('NBMaps')
local Service={current=nil}
local function marker(folder,cf,index)
 local v=Instance.new('Part');v.Name=tostring(index);v.Size=Vector3.one;v.CFrame=cf;v.Transparency=1;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.Parent=folder
end
function Service.Names()
 local names={};for _,m in ipairs(templates:GetChildren())do table.insert(names,m.Name)end;table.sort(names);return names
end
function Service.Load(name)
 local template=templates:FindFirstChild(name);if not template then return false end
 package:SetAttribute('MapReady',false)
 local old=workspace:FindFirstChild('ActiveMap');if old then old:Destroy()end
 for _,n in ipairs({'RoundSpawns','NextbotSpawns'})do local f=workspace:FindFirstChild(n);if f then f:Destroy()end end
 local map=template:Clone();map.Name='ActiveMap';map.Parent=workspace
 local geometry=map:WaitForChild('Geometry')
 require(script.Parent.DoorService).Load(geometry)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={geometry};rp.RespectCanCollide=true
 local points={}
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={geometry};overlap.RespectCanCollide=true
 local function add(position)
  local below=workspace:Raycast(position+Vector3.new(0,1,0),Vector3.new(0,-8,0),rp)
  if not below or below.Normal.Y<.8 then return end
  local ground=below.Position
  if workspace:Raycast(ground+Vector3.new(0,.2,0),Vector3.new(0,6,0),rp)then return end
  if #workspace:GetPartBoundsInBox(CFrame.new(ground+Vector3.new(0,3,0)),Vector3.new(4,5.4,4),overlap)>0 then return end
  for _,p in ipairs(points)do if (p-ground).Magnitude<16 then return end end
  table.insert(points,ground)
 end
 for _,v in ipairs(map.Candidates:GetChildren())do add(v.Position)end
 if #points<6 then
  local width=math.min(map:GetAttribute('Width')or 300,1000);local depth=math.min(map:GetAttribute('Depth')or 300,1000);local top=(map:GetAttribute('Height')or 100)+8
  for x=-width/2+12,width/2-12,32 do for z=-depth/2+12,depth/2-12,32 do
   local hit=workspace:Raycast(Vector3.new(x,top,z),Vector3.new(0,-top-20,0),rp)
   if hit then add(hit.Position+Vector3.new(0,3,0))end
  end end
 end
 if #points<2 then map:Destroy();return false end
 local players=Instance.new('Folder');players.Name='RoundSpawns';players.Parent=workspace
 local bots=Instance.new('Folder');bots.Name='NextbotSpawns';bots.Parent=workspace
 for i,p in ipairs(points)do marker(players,CFrame.new(p),i);marker(bots,CFrame.new(p),i)end
 map.Candidates:Destroy();Service.current=name;package:SetAttribute('MapName',name);package:SetAttribute('MapReady',true)
 return true
end
return Service
