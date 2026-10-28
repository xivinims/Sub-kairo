-- Original, live 3D cinematic set. Inspired by the supplied composition, not an official Poppy character.
-- Lives far from the explorable atrium and has no collisions. No player can interact with it.
do
 local scene=Instance.new("Model");scene.Name="DeadSignalCinematicSet";scene.Parent=W
 local origin=Vector3.new(320,0,-318)
 local function setpart(name,x,y,z,sx,sy,sz,color,mat,shape,angle,transparency)
  local p=Instance.new("Part")
  p.Name=name;p.Size=Vector3.new(sx,sy,sz);p.Anchored=true
  p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true
  p.Material=mat or Enum.Material.Metal;p.Color=color
  if shape then p.Shape=shape end
  p.CFrame=CFrame.new(origin+Vector3.new(x,y,z))
  if angle then p.CFrame*=CFrame.Angles(math.rad(angle[1] or 0),math.rad(angle[2] or 0),math.rad(angle[3] or 0)) end
  p.Transparency=transparency or 0
  p.Parent=scene
  return p
 end
 local function link(name,a,b,width,color,mat)
  local d=b-a
  if d.Magnitude<.03 then return end
  local p=setpart(name,0,0,0,width,width,d.Magnitude,color,mat)
  p.CFrame=CFrame.lookAt(origin+(a+b)*.5,origin+b)
  return p
 end
 local asphalt=Color3.fromRGB(21,13,16)
 local rust=Color3.fromRGB(57,25,26)
 local steel=Color3.fromRGB(33,23,31)
 local coal=Color3.fromRGB(10,8,15)
 local scarlet=Color3.fromRGB(139,19,14)
 setpart("WetFactoryFloor",0,-1,12,118,2,112,asphalt,Enum.Material.Slate)
 for x=-52,52,13 do
  setpart("FloorSeam",x,.015,12,.08,.02,102,Color3.fromRGB(61,31,35),Enum.Material.Metal)
 end
 for z=-35,58,11 do
  setpart("FloorSeam",0,.02,z,110,.025,.075,Color3.fromRGB(55,26,33),Enum.Material.Metal)
 end
 for x=-46,46,23 do
  for z=-35,40,25 do
   local wet=setpart("WetPatch",x,.04,z,8,.012,4,Color3.fromRGB(104,37,40),Enum.Material.Glass,nil,{0,(x+z)%28,0},.5)
   wet.Reflectance=.12
  end
 end
 setpart("BackWall",0,26,-60,120,54,2,Color3.fromRGB(54,11,17),Enum.Material.Concrete)
 for x=-56,56,16 do
  setpart("FactoryPillar",x,27,-58,3.8,54,3.8,Color3.fromRGB(28,13,23))
  setpart("PillarEdge",x+2,27,-56.7,.35,54,.3,rust)
 end
 setpart("LeftWall",-54,23,3,2,47,105,Color3.fromRGB(12,10,17),Enum.Material.Concrete)
 setpart("RightWall",54,25,3,2,51,108,Color3.fromRGB(48,14,21),Enum.Material.Concrete)
 for y=9,45,9 do
  link("HangingServicePipe",Vector3.new(-54,y,-32),Vector3.new(-54,y,58),.42,Color3.fromRGB(40,38,44))
  link("RustServicePipe",Vector3.new(52,y,-38),Vector3.new(52,y,47),.36,rust)
 end
 for z=-40,44,20 do
  link("CeilingGirder",Vector3.new(-54,47,z),Vector3.new(54,47,z),1.4,steel)
  link("DiagonalGirder",Vector3.new(-54,47,z),Vector3.new(0,53,z-13),.9,Color3.fromRGB(40,22,27))
 end
 for x=-30,37,21 do
  setpart("FactoryHatch",x,18,-58,10,22,.25,Color3.fromRGB(26,11,17),Enum.Material.Metal)
  setpart("HatchHorizontal",x,18,-57.7,10,.3,.4,Color3.fromRGB(79,24,28))
 end
 -- Bright rear-red flood; masked by angular industrial clutter.
 local lit=setpart("RedLightSource",18,20,-58,26,35,.15,Color3.fromRGB(196,23,17),Enum.Material.Neon,nil,nil,.12)
 lit.CastShadow=false
 local light=Instance.new("SurfaceLight");light.Name="Backlight";light.Face=Enum.NormalId.Front
 light.Angle=160;light.Range=58;light.Brightness=3.9;light.Color=Color3.fromRGB(255,50,29);light.Shadows=true;light.Parent=lit
 for _,x in ipairs({-33,3,42}) do
  setpart("Crate",x,2,5,10,4,9,steel,Enum.Material.Metal)
  for _,dy in ipairs({.5,3.5}) do
   setpart("CrateEdge",x,dy,9.7,10,.4,.3,rust)
  end
 end
 local creature=Instance.new("Model");creature.Name="TheSignalKeeper";creature.Parent=scene
 local older=scene
 scene=creature
 local base=Vector3.new(18,0,-19)
 local ink=Color3.fromRGB(17,11,22)
 local ink2=Color3.fromRGB(25,15,25)
 local armor=Color3.fromRGB(39,26,34)
 -- Layered shoulders, long legs, torso, irregular crown and multiple jaw plates.
 setpart("LowerBody",base.X,13,base.Z,7,13,5,ink,Enum.Material.SmoothPlastic,Enum.PartType.Ball,nil)
 setpart("UpperBody",base.X,21,base.Z,11,14,7,ink2,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 setpart("ChestPlate",base.X,22,base.Z+3,7.5,9,.7,armor,Enum.Material.Metal,nil,{6,0,0})
 setpart("Collar",base.X,30,base.Z,9,4,6,ink2,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 setpart("Head",base.X,36,base.Z+1,13,10,7.5,ink,Enum.Material.SmoothPlastic,Enum.PartType.Ball,nil)
 for _,side in ipairs({-1,1}) do
  setpart("CrownFin",base.X+side*5.1,42.5,base.Z+.4,2,11,3,armor,Enum.Material.SmoothPlastic,nil,{0,0,side*23})
  setpart("Shoulder",base.X+side*6.4,27,base.Z,5.3,6,5.7,ink2,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  link("UpperArm",base+Vector3.new(side*7,25,0),base+Vector3.new(side*10,15,2),3.1,ink,Enum.Material.SmoothPlastic)
  link("LongForearm",base+Vector3.new(side*10,15,2),base+Vector3.new(side*10.6,3,3),2.3,ink2,Enum.Material.SmoothPlastic)
  for claw=1,3 do
   link("HandClaw",base+Vector3.new(side*10.6,4,3+claw*.65),base+Vector3.new(side*(10.6+(claw-2)*.6),.6,5+claw*.7),.52,coal,Enum.Material.Metal)
  end
  link("Leg",base+Vector3.new(side*2.6,12,0),base+Vector3.new(side*3.9,1.5,-1.9),3.4,ink,Enum.Material.SmoothPlastic)
  setpart("Foot",base.X+side*4,1,base.Z+1,5.3,1.9,7,ink2,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 end
 setpart("Jaw",base.X,33,base.Z+4.3,9,2.8,1.5,coal,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 for _,x in ipairs({-3.1,3.1}) do
  local eye=setpart("TinyWhiteEye",base.X+x,36,base.Z+5,1.1,1.1,.35,Color3.fromRGB(194,183,180),Enum.Material.Neon,Enum.PartType.Ball)
  eye.CastShadow=false
 end
 for i=1,8 do
  local t=i/9
  link("TornFabric",base+Vector3.new(-5+t*10,14,3),base+Vector3.new(-6+t*12,6+(i%3)*1.4,2),.65,ink,Enum.Material.SmoothPlastic)
 end
 scene=older
 -- Hand-held foreground silhouette to add actual cinematic depth.
 setpart("ForegroundCarriage",38,2,42,21,4,12,coal,Enum.Material.Metal,nil,{0,-16,0})
 for x=27,48,20 do
  setpart("Wheel",x,1.6,44,4.6,4.6,1.8,steel,Enum.Material.Metal,Enum.PartType.Cylinder,{0,90,0})
 end
 -- The view marker is never a visible part.
 local marker=Instance.new("Part")
 marker.Name="MenuSceneCamera";marker.Size=Vector3.new(1,1,1);marker.Transparency=1
 marker.Anchored=true;marker.CanCollide=false;marker.CanQuery=false
 marker.CFrame=CFrame.lookAt(Vector3.new(320,16,-258),Vector3.new(328,19,-337))
 marker.Parent=older
 older:SetAttribute("VisualIdentity","Dead Signal original Signal Keeper")
 older:SetAttribute("StageVersion",2)
end
