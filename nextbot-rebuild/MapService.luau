local Storage=game:GetService('ServerStorage')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local templates=Storage:WaitForChild('NBMaps')
local Service={current=nil};local validated={}
local Pathfinding=game:GetService('PathfindingService')
local function marker(folder,cf,index)
 local v=Instance.new('Part');v.Name=tostring(index);v.Size=Vector3.one;v.CFrame=cf;v.Transparency=1;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.Parent=folder
end
local function frameMenu(points,rp,assetId)
 local views={}
 for _,ground in ipairs(points)do
  local eye=ground+Vector3.new(0,4.5,0);local best,score=nil,-1
  for angle=0,330,30 do
   local direction=Vector3.new(math.sin(math.rad(angle)),0,math.cos(math.rad(angle)))
   local distance=0
   for _,spread in ipairs({-24,0,24})do
    local ray=CFrame.Angles(0,math.rad(spread),0):VectorToWorldSpace(direction)*100
    local hit=workspace:Raycast(eye,ray,rp);distance+=hit and hit.Distance or 100
   end
   if distance>score then best=direction;score=distance end
  end
  table.insert(views,{eye=eye,direction=best,score=score})
 end
 table.sort(views,function(a,b)return a.score>b.score end)
 local anchors=workspace:FindFirstChild('MenuCameras');if not anchors then return end
 local home=views[1];local selected={home}
 for _,view in ipairs(views)do
  local d=(view.eye-home.eye).Magnitude
  if d>12 and d<100 then table.insert(selected,view);if #selected==3 then break end end
 end
 for i,name in ipairs({'Home','Shop','Inventory'})do
  local view=selected[i]or home;local anchor=anchors:FindFirstChild(name)
  if anchor then anchor.CFrame=CFrame.lookAt(view.eye,view.eye+view.direction*30);anchor:SetAttribute('SourceAssetId',assetId)end
 end
 local spawn=workspace:FindFirstChild('InitialSpawn');if spawn then spawn.CFrame=CFrame.new(home.eye-Vector3.new(0,4,0))end
 package:SetAttribute('MenuSceneSource','ImportedMap')
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
 if validated[name]then points=validated[name]else
  local connected={points[1]}
  for i=2,math.min(#points,80)do
   if #connected>=32 then break end
   local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
   local ok=pcall(function()path:ComputeAsync(points[1]+Vector3.new(0,3,0),points[i]+Vector3.new(0,3,0))end)
   if ok and path.Status==Enum.PathStatus.Success then table.insert(connected,points[i])end
  end
  if #connected<2 then map:Destroy();return false end
  points=connected;validated[name]=points
 end
 local players=Instance.new('Folder');players.Name='RoundSpawns';players.Parent=workspace
 local bots=Instance.new('Folder');bots.Name='NextbotSpawns';bots.Parent=workspace
 for i,p in ipairs(points)do marker(players,CFrame.new(p),i);marker(bots,CFrame.new(p),i)end
 local assetId=map:GetAttribute('SourceAssetId')
 frameMenu(points,rp,assetId)
 map.Candidates:Destroy();Service.current=name;package:SetAttribute('MapName',name)
 package:SetAttribute('MapAssetId',assetId);package:SetAttribute('MapSourceUrl','https://create.roblox.com/store/asset/'..tostring(assetId))
 package:SetAttribute('MapReady',true)
 return true
end
return Service
