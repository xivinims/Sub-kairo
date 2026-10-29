local Players=game:GetService('Players')
local catalog=game:GetService('ServerStorage'):WaitForChild('IslandGeometryCatalog')
local world=workspace:WaitForChild('Islands')
local M={};local loaded={};local started=false;local converted={}
local function cellKey(id,x,z) return id..':'..x..':'..z end
local function load(id,x,z)
 local key=cellKey(id,x,z);local existing=loaded[key]
 if existing and existing.Parent then return end
 local source=catalog:FindFirstChild(id);local parent=world:FindFirstChild(id)
 if not source or not parent then return end
 local name='Cell_'..x..'_'..z
 local template=source:FindFirstChild(name);if not template then return end
 if id~='city' and not converted[key] then
  converted[key]=true
  local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain};rp.IgnoreWater=true
  local hit=workspace:Raycast(Vector3.new((x+.5)*128,2400,(z+.5)*128),Vector3.new(0,-4800,0),rp)
  if hit then
   workspace.Terrain:ReplaceMaterial(Region3.new(Vector3.new(x*128,hit.Position.Y-96,z*128),Vector3.new((x+1)*128,hit.Position.Y+96,(z+1)*128)):ExpandToGrid(4),4,Enum.Material.LeafyGrass,Enum.Material.Grass)
  end
 end
 local clone=parent:FindFirstChild(name)
 if not clone then clone=template:Clone();clone.Parent=parent end
 loaded[key]=clone
end
function M.Warm(id,position,radius)
 local span=math.ceil((radius or 128)/128)
 local x,z=math.floor(position.X/128),math.floor(position.Z/128)
 for dx=-span,span do for dz=-span,span do load(id,x+dx,z+dz);task.wait() end end
end
local function addDesired(desired,id,pos,radius)
 local x,z=math.floor(pos.X/128),math.floor(pos.Z/128);local span=math.ceil(radius/128)
 for dx=-span,span do for dz=-span,span do
  local cx,cz=x+dx,z+dz
  if (Vector2.new((cx+.5)*128,(cz+.5)*128)-Vector2.new(pos.X,pos.Z)).Magnitude<radius+91 then
   desired[cellKey(id,cx,cz)]={id,cx,cz}
  end
 end end
end
function M.Start()
 if workspace:GetAttribute('IslandWorldReady')~=true then
  task.spawn(function() repeat workspace:GetAttributeChangedSignal('IslandWorldReady'):Wait() until workspace:GetAttribute('IslandWorldReady')==true;M.Start() end);return
 end
 if started then return end;started=true
 for _,folder in ipairs(world:GetChildren()) do for _,m in ipairs(folder:GetChildren()) do
  local x,z=m.Name:match('^Cell_(-?%d+)_(-?%d+)$')
  if x then loaded[cellKey(folder.Name,tonumber(x),tonumber(z))]=m end
 end end
 task.spawn(function()
  while task.wait(1) do
   local desired={}
   -- Small arrival neighborhoods remain ready for respawns.
   for _,spawn in ipairs(workspace.IslandDestinations:GetChildren()) do addDesired(desired,spawn.Name,spawn.Position,64) end
   for _,p in ipairs(Players:GetPlayers()) do
    local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local id=p:GetAttribute('IslandDestination')
    if root and typeof(id)=='string' then addDesired(desired,id,root.Position,192) end
   end
   local count=0
   for _,spec in pairs(desired) do load(unpack(spec));count+=1;if count%3==0 then task.wait() end end
   for key,m in pairs(loaded) do if not desired[key] then m:Destroy();loaded[key]=nil end end
  end
 end)
end
return M
