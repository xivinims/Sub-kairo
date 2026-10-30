-- Approved data-only extraction of Roblox's Beyond the Dark sky effect.
local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau')
return function(dm)
 local original=R.deserializePlace(fs.readFile('/tmp/asset-7208091524.rbxl'))
 local W=original:GetService('Workspace');local sky=assert(W:FindFirstChild('Skybox'),'Skybox missing'):Clone()
 local other={}
 for _,c in ipairs(sky:GetChildren()) do
  table.insert(other,c.Name..'/'..c.ClassName..'/'..#c:GetDescendants())
 end
 print('SOURCE SKYBOX CONTENTS: '..table.concat(other,', '))
 -- Preserve the original source skybox textures if they exist. Without this,
 -- the menu inherits the unrelated mansion's cloudy horizon.
 local originalSky=original:GetService('Lighting'):FindFirstChildWhichIsA('Sky')
 if originalSky then
  local skyCopy=originalSky:Clone()
  skyCopy.Name='OriginalBlackHoleSky'
  local rs=dm:GetService('ReplicatedStorage')
  local oldSky=rs:FindFirstChild(skyCopy.Name)
  if oldSky then oldSky:Destroy() end
  skyCopy.Parent=rs
  print('ORIGINAL SOURCE SPACE SKY COPIED: '..skyCopy.Name)
 else
  print('SOURCE SKY: no authored Lighting.Sky; using mansion sky temporarily')
 end
 for _,c in ipairs(sky:GetChildren()) do if c.Name~='BlackHole' and c.Name~='DebrisField' then c:Destroy() end end
 local allowed={Bone=true,Model=true,Folder=true,MeshPart=true,Part=true,WedgePart=true,UnionOperation=true,Attachment=true,Beam=true,Trail=true,ParticleEmitter=true,PointLight=true,SpotLight=true,SurfaceLight=true,SurfaceAppearance=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,Texture=true,Decal=true,SurfaceGui=true,BillboardGui=true,ImageLabel=true,Frame=true,UIGradient=true,UICorner=true,UIStroke=true,UIPadding=true,UIScale=true,UIAspectRatioConstraint=true}
 local list=sky:GetDescendants()
 for i=#list,1,-1 do local d=list[i];if not allowed[d.ClassName] then d:Destroy() end end
 local template=R.Instance.new('Model');template.Name='SkyBlackHoleTemplate'
 for _,c in ipairs(sky:GetChildren()) do c.Parent=template end
 sky:Destroy()
 local halo=assert(template.BlackHole.Model.Singularity:FindFirstChild('Halo'),'Original halo missing')
 local spawn=W:FindFirstChildWhichIsA('SpawnLocation',true)
 local distance=spawn and (spawn.CFrame.Position-halo.CFrame.Position).Magnitude or 1028
 if distance<400 or distance>10000 then distance=1028 end
 local n,beams,gui=0,0,0
 for _,d in ipairs(template:GetDescendants()) do
  assert(not d:IsA('Terrain') and not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'Unsafe sky content')
  if d:IsA('BasePart') then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.CastShadow=false;n+=1 end
  if d:IsA('Beam') then beams+=1 end
  if d:IsA('BillboardGui') or d:IsA('SurfaceGui') then gui+=1 end
 end
 assert(n>50 and beams>10,'Incomplete original sky effect')
 template:SetAttribute('SourceAsset','7208091524');template:SetAttribute('SourcePaths','Workspace.Skybox.BlackHole + Workspace.Skybox.DebrisField')
 template:SetAttribute('SourceOrigin',halo.CFrame.Position);template:SetAttribute('ReferenceDistance',distance)
 -- The scene was authored for observation from the source spawn toward -X,
 -- NOT with Halo.LookVector (-Z) facing the player. Preserve that view.
 local observer=spawn and spawn.CFrame.Position or (halo.CFrame.Position+Vector3.new(1200,-110,0))
 local direction=(observer-halo.CFrame.Position).Unit
 template:SetAttribute('SourceViewDirection',direction)
 template:SetAttribute('SourceHaloDiameter',math.max(halo.Size.X,halo.Size.Y,halo.Size.Z))
 print('SOURCE VIEW DIRECTION '..tostring(direction)..' / original halo diameter '..tostring(math.max(halo.Size.X,halo.Size.Y,halo.Size.Z)))
 template:SetAttribute('GeometryOnly',true);template:SetAttribute('OriginalPartCount',n)
 local RS=dm:GetService('ReplicatedStorage');local old=RS:FindFirstChild(template.Name);if old then old:Destroy() end
 template.Parent=RS
 local source=fs.readFile('blackhole-client.luau');luau.load(source,{debugName='blackhole-client'})
 local SP=dm:GetService('StarterPlayer').StarterPlayerScripts
 local previous=SP:FindFirstChild('SkyBlackHoleClient');if previous then previous:Destroy() end
 local client=R.Instance.new('LocalScript');client.Name='SkyBlackHoleClient';client.Source=source;client.Disabled=false;client.Parent=SP
 dm:GetService('Workspace'):SetAttribute('BlackHoleAsset','7208091524')
 dm:GetService('Workspace'):SetAttribute('CelestialBuildId','beyond-dark-blackhole-v1')
 print('ORIGINAL BLACK HOLE EXTRACTED: parts='..n..'; beams='..beams..'; world GUI='..gui..'; observer distance='..distance)
end
