local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
for _,id in ipairs({'7902470429','13037825880'}) do
 local file='/tmp/asset-'..id..'.rbxl';if not fs.isFile(file) then continue end
 local dm=R.deserializePlace(fs.readFile(file));local list={};local scripts={}
 for _,d in ipairs(dm:GetDescendants()) do
  if d:IsA('Model') or d:IsA('Folder') then
   local name=d.Name:lower();local path=d:GetFullName()
   if (d.Parent and d.Parent.ClassName=='Workspace') or name:find('forest') or name:find('tree') or name:find('mansion') or name:find('house') or name:find('exterior') or name:find('interior') then
    local count=0;local min=R.Vector3.new(math.huge,math.huge,math.huge);local max=-min
    for _,p in ipairs(d:GetDescendants()) do if p:IsA('BasePart') and not p:IsA('Terrain') then
     count+=1;local v=p.CFrame.Position;local s=p.Size*.5;min=R.Vector3.new(math.min(min.X,v.X-s.X),math.min(min.Y,v.Y-s.Y),math.min(min.Z,v.Z-s.Z));max=R.Vector3.new(math.max(max.X,v.X+s.X),math.max(max.Y,v.Y+s.Y),math.max(max.Z,v.Z+s.Z))
    end end
    if count>0 then table.insert(list,{path=path,class=d.ClassName,parts=count,lo={min.X,min.Y,min.Z},hi={max.X,max.Y,max.Z},children=#d:GetChildren()}) end
   end
  end
  if d:IsA('LuaSourceContainer') then table.insert(scripts,{path=d:GetFullName(),length=#d.Source,suspicious=d.Source:find('loadstring',1,true)~=nil or d.Source:find('HttpGet',1,true)~=nil}) end
 end
 print('MANSION FOREST AUDIT '..J.encode('json',{id=id,models=list,scripts=scripts}))
end
