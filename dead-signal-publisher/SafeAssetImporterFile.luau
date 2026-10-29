-- Offline companion to base/server/SafeAssetImporter: never executes imported code.
local R=require('@lune/roblox')
local SafeAssetImporter={}
local approved={['76722373571113']=true,['186677844']=true,['5326950832']=true,['88883160098456']=true}
local visual={Decal=true,Texture=true,SurfaceAppearance=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,PointLight=true,SpotLight=true,SurfaceLight=true,Attachment=true}
function SafeAssetImporter.Parts(root,id,limit,predicate)
 assert(approved[id],'Unapproved source')
 local out=R.Instance.new('Model');out.Name=root.Name
 local list=root:IsA('BasePart') and {root} or root:GetDescendants()
 local n=0;local doorIds={};local doorCount=0;local helpers=0
 local function doorRoot(p)
  local a=p.Parent
  while a and a~=root.Parent do
   if a:IsA('Model') and a:FindFirstChild('middle') and a:FindFirstChild('Hinges') and a:FindFirstChild('Weld (Read)') then return a end
   a=a.Parent
  end
 end
 for _,p in ipairs(list) do
  if p:IsA('BasePart') and not p:IsA('Terrain') and not p:IsA('SpawnLocation') and p.Transparency<1 and (not predicate or predicate(p)) then
   local helper=false
   for _,child in ipairs(p:GetChildren()) do
    if child:IsA('Script') and child.Source:gsub('%s','')=='script.Parent.Transparency=1script.Parent.CanCollide=false' then helper=true end
   end
   local door= id=='186677844' and doorRoot(p) or nil
   if door and p:IsDescendantOf(door.Hinges) then helper=true end
   if helper then helpers+=1;continue end
   local c=p:Clone()
   if door then
    if not doorIds[door] then doorCount+=1;doorIds[door]=doorCount end
    local hinge=door.Hinges:FindFirstChildWhichIsA('BasePart',true)
    assert(hinge and door.middle:IsA('BasePart'),'Malformed source door')
    c:SetAttribute('IslandDoorId',doorIds[door])
    c:SetAttribute('IslandDoorPivot',R.CFrame.new(hinge.CFrame.Position.X,door.middle.CFrame.Position.Y,hinge.CFrame.Position.Z)*door.middle.CFrame.Rotation)
   end
   local descendants=c:GetDescendants()
   for i=#descendants,1,-1 do local d=descendants[i];if not visual[d.ClassName] then d:Destroy() end end
   -- Inspect original ancestry before flattening it: many canopy meshes have generic names.
   local a=p;local foliage=false
   while a and a~=root.Parent do
    local name=string.lower(a.Name)
    if name:find('leaf',1,true) or name:find('leav',1,true) or name:find('foliage',1,true) or name:find('fern',1,true) then foliage=true end
    a=a.Parent
   end
   if foliage then
    c:SetAttribute('IslandWind',true);c.CanCollide=false
    c.PivotOffset=R.CFrame.new(0,-c.Size.Y*.45,0)
   end
   for _,d in ipairs(c:GetDescendants()) do if d:IsA('Light') then d.Shadows=false;d.Range=math.min(d.Range,32);d.Brightness=math.min(d.Brightness,2.5) end end
   c.Anchored=true;c.CanTouch=false
   c.Parent=out;n+=1
  end
 end
 assert(n>0 and n<=limit,'Geometry budget exceeded: '..n)
 out:SetAttribute('DeadSignalSourceAssetId',id);out:SetAttribute('DeadSignalGeometryOnly',true)
 for _,d in ipairs(out:GetDescendants()) do assert(not d:IsA('LuaSourceContainer'),'Unsafe geometry') end
 print('SAFE IMPORT '..id..': doorGroups='..doorCount..', removedHelpers='..helpers)
 return out,n
end
return SafeAssetImporter
