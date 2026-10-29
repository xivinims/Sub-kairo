-- Offline companion to base/server/SafeAssetImporter: never executes imported code.
local R=require('@lune/roblox')
local SafeAssetImporter={}
local approved={['76722373571113']=true,['186677844']=true,['5326950832']=true,['88883160098456']=true}
local visual={Decal=true,Texture=true,SurfaceAppearance=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,PointLight=true,SpotLight=true,SurfaceLight=true,Attachment=true}
function SafeAssetImporter.Parts(root,id,limit,predicate)
 assert(approved[id],'Unapproved source')
 local out=R.Instance.new('Model');out.Name=root.Name
 local list=root:IsA('BasePart') and {root} or root:GetDescendants()
 local structures={};local structureIds={};local structureCount=0
 if id=='186677844' then
  for _,part in ipairs(list) do if part:IsA('BasePart') and not part:IsA('Terrain') then
   local a=part.Parent
   while a and a~=root do
    if a:IsA('Model') then
     local st=structures[a] or {n=0,lo=R.Vector3.new(math.huge,math.huge,math.huge),hi=R.Vector3.new(-math.huge,-math.huge,-math.huge),door=false};structures[a]=st;st.n+=1
     local pos=part.CFrame.Position;local half=part.Size*.5
     st.lo=R.Vector3.new(math.min(st.lo.X,pos.X-half.X),math.min(st.lo.Y,pos.Y-half.Y),math.min(st.lo.Z,pos.Z-half.Z));st.hi=R.Vector3.new(math.max(st.hi.X,pos.X+half.X),math.max(st.hi.Y,pos.Y+half.Y),math.max(st.hi.Z,pos.Z+half.Z))
     if a:FindFirstChild('middle') and a:FindFirstChild('Hinges') then st.door=true end
    end
    a=a.Parent
   end
  end end
  -- Only building-sized groups containing an authored swing-door descendant qualify.
  for model,st in pairs(structures) do if model:FindFirstChild('middle') and model:FindFirstChild('Hinges') then local a=model.Parent;while a and a~=root do if structures[a] then structures[a].door=true end;a=a.Parent end end end
 end
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
   if id=='186677844' then
    local a=p.Parent;local chosen
    while a and a~=root do local st=structures[a]
     if st then local size=st.hi-st.lo;if st.door and st.n>=60 and st.n<=350 and size.X>14 and size.Z>14 and size.Y>15 and size.X<130 and size.Z<130 and size.Y<85 then chosen=a end end
     a=a.Parent
    end
    if chosen then if not structureIds[chosen] then structureCount+=1;structureIds[chosen]=structureCount end;c:SetAttribute('DisasterStructureId',structureIds[chosen]) end
   end
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
 print('SAFE IMPORT '..id..': doorGroups='..doorCount..', structures='..structureCount..', removedHelpers='..helpers)
 return out,n
end
return SafeAssetImporter
