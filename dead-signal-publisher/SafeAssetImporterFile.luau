-- Offline companion to base/server/SafeAssetImporter: never executes imported code.
local R=require('@lune/roblox')
local SafeAssetImporter={}
local approved={['76722373571113']=true,['186677844']=true,['5326950832']=true}
local visual={Decal=true,Texture=true,SurfaceAppearance=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true}
function SafeAssetImporter.Parts(root,id,limit)
 assert(approved[id],'Unapproved source')
 local out=R.Instance.new('Model');out.Name=root.Name
 local list=root:IsA('BasePart') and {root} or root:GetDescendants()
 local n=0
 for _,p in ipairs(list) do
  if p:IsA('BasePart') and not p:IsA('SpawnLocation') and p.Transparency<1 then
   local c=p:Clone()
   for _,d in ipairs(c:GetDescendants()) do if not visual[d.ClassName] then d:Destroy() end end
   c.Anchored=true;c.CanTouch=false
   c.Parent=out;n+=1
  end
 end
 assert(n>0 and n<=limit,'Geometry budget exceeded: '..n)
 out:SetAttribute('DeadSignalSourceAssetId',id);out:SetAttribute('DeadSignalGeometryOnly',true)
 for _,d in ipairs(out:GetDescendants()) do assert(not d:IsA('LuaSourceContainer'),'Unsafe geometry') end
 return out,n
end
return SafeAssetImporter
