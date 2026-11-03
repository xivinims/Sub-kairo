-- Photo-specific scene pass. Preserve the v8 house/bridge collision repairs.
local W=game:GetService("Workspace")
local T=W.Terrain
local L=game:GetService("Lighting")
local world=assert(W:FindFirstChild("ReferenceWorld"),"ReferenceWorld missing")
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(W:GetAttribute("WorldCorrectionVersion")=="2026-10-19-house-grounding-forest-v8","House repairs required")
local VERSION="2026-10-20-reference-scenes-v9"
local rng=Random.new(2010202609)
local V=Vector3.new
local C=CFrame.new
local rgb=Color3.fromRGB
local function folder(parent,name)
 local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
local function model(parent,name)
 local m=Instance.new("Model");m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=parent;return m
end
local function part(parent,name,size,cf,mat,color,collide,trans)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
 p.Material=mat;p.Color=color;p.CanCollide=collide or false;p.CanTouch=false;p.CanQuery=collide or false
 p.Transparency=trans or 0;p.CastShadow=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function rod(parent,name,a,b,width,mat,color,collide)
 local p=part(parent,name,V(width,(b-a).Magnitude,width),C((a+b)/2)*CFrame.fromMatrix(V(0,0,0),(b-a).Unit:Cross(V(0,0,1)).Unit,(b-a).Unit),mat,color,collide)
 return p
end
local tp=RaycastParams.new();tp.FilterType=Enum.RaycastFilterType.Include;tp.FilterDescendantsInstances={T}
local function ground(x,z)
 local h=W:Raycast(V(x,230,z),V(0,-500,0),tp)
 if h and h.Material~=Enum.Material.Water then return h.Position end
 return nil
end
local function onGround(x,z) return assert(ground(x,z),"No dry soil at "..x..","..z)end
local old=world:FindFirstChild("ReferenceDetailPass");if old then old:Destroy()end
local detail=folder(world,"ReferenceDetailPass")

-- Reuse actual foliage meshes. Nothing in this package is allowed to execute.
local pack=game:GetService("InsertService"):LoadAsset(6432306802)
for _,d in ipairs(pack:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()end end
local function template(name)
 local m=pack:FindFirstChild(name,true);assert(m and m:IsA("Model"),"Missing foliage template "..name);return m
end
local meshCount=0
local function placeMesh(parent,name,source,x,z,height,y,yaw)
 local m=template(source):Clone();m.Name=name
 local _,s=m:GetBoundingBox();m:ScaleTo(m:GetScale()*height/s.Y)
 local g=y and V(x,y,z) or onGround(x,z)
 m:PivotTo(C(x,0,z)*CFrame.Angles(0,yaw or rng:NextNumber(-math.pi,math.pi),0))
 local cf,sz=m:GetBoundingBox();m:PivotTo(m:GetPivot()+V(0,g.Y-(cf.Position.Y-sz.Y/2),0))
 for _,p in ipairs(m:GetDescendants())do
  if p:IsA("BasePart")then
   p.Anchored=true;p.CanTouch=false;p.CanQuery=false;p.CanCollide=false
   p.CastShadow=height>7
   if p:IsA("MeshPart")then p.RenderFidelity=Enum.RenderFidelity.Automatic end
  elseif p:IsA("ParticleEmitter")or p:IsA("Beam")then p:Destroy()end
 end
 m:SetAttribute("SourceAssetId",6432306802);m:SetAttribute("GroundPosition",g)
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=parent;meshCount+=1;return m
end

-- Temple photo: gray stone, curved ends, framed tablet and a real twisted rope.
local torii=world.Torii.MainTorii
local previous=torii:FindFirstChild("ReferenceDetails");if previous then previous:Destroy()end
local td=folder(torii,"ReferenceDetails")
for _,p in ipairs(torii:GetDescendants())do
 if p:IsA("BasePart")and p.Name~="RopeA"and p.Name~="RopeB"then
  if not string.find(p.Name,"Tassel")then p.Color=rgb(91,98,94);p.Material=Enum.Material.Slate end
 end
 if p:IsA("Beam")or p.Name=="Tassel"then p:Destroy()end
end
local g=onGround(0,620)
-- Existing feet used the old assumed y=20; re-seat at the measured grade.
local foot=torii:FindFirstChild("Foot");local footBottom=foot.Position.Y-foot.Size.Y/2
torii:PivotTo(torii:GetPivot()+V(0,g.Y-footBottom,0))
local frame=C(0,g.Y,620)
local stone=rgb(92,98,94)
for _,p in ipairs(torii:GetChildren())do
 if p.Name=="TopLeft"then p.CFrame=C(p.Position)*CFrame.Angles(0,0,-math.rad(8))end
 if p.Name=="TopRight"then p.CFrame=C(p.Position)*CFrame.Angles(0,0,math.rad(8))end
end
part(td,"TabletRim",V(5.1,7.2,1.2),frame*C(0,30.4,3),Enum.Material.Slate,rgb(115,122,113))
part(td,"TabletFace",V(4.1,6.1,1.3),frame*C(0,30.4,3.1),Enum.Material.Slate,rgb(66,76,76))
local ropeColor={rgb(139,123,83),rgb(163,146,99)}
for strand=1,2 do
 for i=0,39 do
  local function point(t)
   local angle=t*math.pi*18+(strand-1)*math.pi
   return frame:PointToWorldSpace(V(-12+24*t,23.2-5.4*math.sin(t*math.pi)+math.sin(angle)*.24,2.7+math.cos(angle)*.24))
  end
  rod(td,"TwistedStraw",point(i/40),point((i+1)/40),.46,Enum.Material.Wood,ropeColor[strand],false)
 end
end
for _,x in ipairs({-7,0,7})do
 local y=23.2-5.4*math.sin((x+12)/24*math.pi)
 for j=-1,1 do
  rod(td,"StrawTassel",frame:PointToWorldSpace(V(x,y,2.7)),frame:PointToWorldSpace(V(x+j*.23,y-2.7,2.7)),.19,Enum.Material.Wood,ropeColor[1],false)
 end
end
-- Bring the reduced user-supplied house into the torii's background view.
-- Its scale and authored entrance colliders remain unchanged.
local house=world.House.JapaneseHouse
local houseMesh=assert(house:FindFirstChildWhichIsA("MeshPart",true))
assert(math.abs(math.max(houseMesh.Size.X,houseMesh.Size.Y,houseMesh.Size.Z)-42)<.05,"Unexpected house scale")
local oldPivot=house:GetPivot()
local hg=onGround(0,500)
house:PivotTo(oldPivot+V(-oldPivot.Position.X,hg.Y-(houseMesh.Position.Y-houseMesh.Size.Y/2),500-oldPivot.Position.Z))
local pathPositions={{0,730},{2,690},{-3,652},{2,605},{-2,565},{1,540},{-50,500},{-51,450},{-51,400},{-53,350},{-58,300},{-72,250}}
local pathIndex=0
for _,p in ipairs(world.Path:GetChildren())do
 if p.Name=="PathStone"then
  pathIndex+=1;local v=pathPositions[pathIndex];local pground=onGround(v[1],v[2])
  p.CFrame=C(v[1],pground.Y+.18,v[2])*p.CFrame.Rotation
 end
end
-- Shallow joints on the twelve existing sparse stones; no new paved highway.
for _,p in ipairs(world.Path:GetChildren())do
 if p.Name=="PathStone"then
  local f=folder(td,"StoneJoints")
  for j=1,3 do
   part(f,"Joint",V(.035,.012,p.Size.Z*.86),p.CFrame*C((j/4-.5)*p.Size.X,p.Size.Y/2+.01,0),Enum.Material.Slate,rgb(49,59,58))
  end
 end
end

-- Dense natural pond, set beside the main route rather than on either bridge.
local pond=folder(detail,"ForestPond")
local removedTrees=0
for _,m in ipairs(world.Forest:GetDescendants())do
 if m:IsA("Model")then
  local p=m:GetAttribute("GroundPosition")
  if not p and string.match(m.Name,"^Understory_")then p=m:GetPivot().Position end
  if p and p.X>228 and p.X<480 and p.Z>80 and p.Z<340 then
   if string.match(m.Name,"^ForestTree_")then removedTrees+=1 end
   m:Destroy()
  end
 end
end
local region=Region3.new(V(264,-4,148),V(440,28,292)):ExpandToGrid(4)
local materials,occupancies=T:ReadVoxels(region,4)
local origin=region.CFrame.Position-region.Size/2
for ix=1,#materials do
 for iz=1,#materials[ix][1]do
  local x=origin.X+(ix-.5)*4;local z=origin.Z+(iz-.5)*4
  local dx,dz=(x-350)/84,(z-220)/64
  local rho=math.sqrt(dx*dx+dz*dz)*(1+.045*math.sin(x*.07+z*.08))
  if rho<1 then
   local shore=math.clamp((rho-.62)/.38,0,1)
   local bed=5+17*(shore*shore*(3-2*shore))
   for iy=1,#materials[ix]do
    local bottom=origin.Y+(iy-1)*4
    if bottom<bed then
     materials[ix][iy][iz]=Enum.Material.Ground;occupancies[ix][iy][iz]=math.clamp((bed-bottom)/4,0,1)
    elseif bottom<16 then
     materials[ix][iy][iz]=Enum.Material.Water;occupancies[ix][iy][iz]=math.clamp((16-bottom)/4,0,1)
    else materials[ix][iy][iz]=Enum.Material.Air;occupancies[ix][iy][iz]=0 end
   end
  end
 end
end
T:WriteVoxels(region,4,materials,occupancies)
T.WaterColor=rgb(63,126,139);T.WaterTransparency=.24;T.WaterReflectance=.22;T.WaterWaveSize=.045;T.WaterWaveSpeed=6
-- Fixed silhouettes place the waterfall left of center, broadleaf thickets
-- right of the water and tall conifers behind, as in the pond photograph.
for i,s in ipairs({{280,142,48},{299,134,60},{321,141,39},{267,159,30},{307,163,31},{327,158,25}})do
 placeMesh(pond,"WaterfallRock_"..i,"LargeBoulder_Var01",s[1],s[2],s[3],22)
end
local treeSources={"BeechwoodTree_Var01","BroadLeafTree_Var01","RedwoodTree-Var01","MapleLeafTreeVar01","DogwoodTree_Var01"}
for i=1,64 do
 local a=i/64*math.pi*2
 local x=350+math.cos(a)*rng:NextNumber(94,128)
 local z=216+math.sin(a)*rng:NextNumber(77,101)
 -- Keep the near foreground open so the pond/waterfall actually read.
 if not(z>274 and x>315 and x<393)then
  local src=treeSources[(i%#treeSources)+1]
  local h=(src=="RedwoodTree-Var01")and rng:NextNumber(38,57)or rng:NextNumber(22,39)
  placeMesh(pond,"PondTree_"..i,src,x,z,h,22)
 end
end
local plants={"Fern_Var01","FernTallVar01","MountainLaurelBush_Var01","CloverPatch","WildFlower01","Wildflower02","RhododendronVar02"}
local pondPlants=0
for i=1,190 do
 local a=rng:NextNumber(0,2*math.pi);local r=rng:NextNumber(1.02,1.52)
 local x,z=350+math.cos(a)*85*r,220+math.sin(a)*65*r
 local src=plants[(i%#plants)+1]
 local h=src=="CloverPatch"and .45 or(src=="FernTallVar01"and 4.8 or rng:NextNumber(1.3,3.2))
 placeMesh(pond,"ShorePlant_"..i,src,x,z,h,22)
 pondPlants+=1
end
for i=1,20 do
 local a=i/20*math.pi*2
 local x,z=350+math.cos(a)*75,220+math.sin(a)*55
 placeMesh(pond,"MossyShoreRock_"..i,"MediumMossBoulder01",x,z,rng:NextNumber(3.5,8),14)
end
local fall=folder(pond,"Waterfall")
for i=1,5 do
 local top=part(fall,"WaterfallSource",V(.1,.1,.1),C(296+(i-3)*.95,63,158),Enum.Material.SmoothPlastic,rgb(255,255,255),false,1)
 local bottom=part(fall,"WaterfallImpact",V(.1,.1,.1),C(300+(i-3)*.9,16.2,181),Enum.Material.SmoothPlastic,rgb(255,255,255),false,1)
 local a=Instance.new("Attachment");a.Parent=top
 local b=Instance.new("Attachment");b.Parent=bottom
 local beam=Instance.new("Beam");beam.Name="WaterfallRibbon";beam.Attachment0=a;beam.Attachment1=b
 beam.Width0=1.8;beam.Width1=2.4;beam.FaceCamera=true;beam.Segments=12
 beam.Texture="rbxasset://textures/particles/smoke_main.dds";beam.TextureLength=7;beam.TextureSpeed=1.6
 beam.Color=ColorSequence.new(rgb(204,239,238));beam.Transparency=NumberSequence.new(.22);beam.LightEmission=.2;beam.Parent=fall
 if i==3 then
  local splash=Instance.new("ParticleEmitter");splash.Name="ImpactMist";splash.Texture="rbxasset://textures/particles/smoke_main.dds"
  splash.Rate=5;splash.Lifetime=NumberRange.new(.5,1);splash.Speed=NumberRange.new(1,2.5);splash.SpreadAngle=Vector2.new(35,35)
  splash.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,5)})
  splash.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.78),NumberSequenceKeypoint.new(1,1)})
  splash.Color=ColorSequence.new(rgb(225,248,244));splash.Parent=bottom
 end
end
for i=1,18 do
 local a=rng:NextNumber(0,math.pi*2);local x,z=350+math.cos(a)*rng:NextNumber(43,57),220+math.sin(a)*rng:NextNumber(32,42)
 local leaf=part(pond,"LilyLeaf",V(.08,rng:NextNumber(1.5,2.5),rng:NextNumber(1.5,2.5)),C(x,16.12,z)*CFrame.Angles(0,0,math.pi/2),Enum.Material.Grass,rgb(95+rng:NextInteger(0,25),130,46))
 leaf.Shape=Enum.PartType.Cylinder;leaf.CastShadow=false
end

-- More real ground vegetation throughout the full map, while keeping the
-- geometric vegetation of the temple corridor consistent with that image.
local groundCover=folder(detail,"MapGroundCover")
local replacements={}
for _,m in ipairs(world.Forest:GetDescendants())do
 if m:IsA("Model")and string.match(m.Name,"^Understory_")then
  local p=m:GetPivot().Position
  if math.abs(p.X)>180 or p.Z<220 or p.Z>800 then table.insert(replacements,m)end
 end
end
for i,m in ipairs(replacements)do
 local p=m:GetPivot().Position;local g=ground(p.X,p.Z)
 if g then
  m:ClearAllChildren()
  placeMesh(m,"Fern","Fern_Var01",g.X,g.Z,rng:NextNumber(1.8,3.5),g.Y)
  placeMesh(m,"Clover","CloverPatch",g.X+3,g.Z+2,.4,g.Y)
  if i%3==0 then placeMesh(m,"Flowers","WildFlower01",g.X-2,g.Z+3,1.4,g.Y)end
 end
end

-- White ruins photograph: tall irregular enclosing walls and arch, open
-- courtyard, round columns, narrow cypresses, bright moss and trailing ivy.
world.Ruins:ClearAllChildren()
local ruins=model(world.Ruins,"AncientWhiteRuins")
ruins.ModelStreamingMode=Enum.ModelStreamingMode.Default
local white=rgb(218,214,202);local pale=rgb(232,225,211);local moss=rgb(104,143,52)
local baseY=onGround(0,-360).Y
local function rp(name,size,x,y,z,color,collide,rot)
 return part(ruins,name,size,C(x,baseY+y,-360+z)*(rot or CFrame.identity),Enum.Material.Limestone,color or white,collide)
end
-- Broken pale paving is slightly above measured soil, unlike the buried v7 tiles.
for ix=-6,6 do for iz=-5,5 do
 if rng:NextNumber()>.27 then
  local x,z=ix*15+rng:NextNumber(-1.8,1.8),iz*15+rng:NextNumber(-1.8,1.8)
  rp("BrokenPaving",V(rng:NextNumber(10,14.7),.22,rng:NextNumber(9,14)),x,.06,z,pale,true,CFrame.Angles(0,rng:NextNumber(-.09,.09),0))
 end
end end
for _,side in ipairs({-1,1})do
 for i=0,7 do
  local h=({84,98,76,90,72,68,86,64})[i+1]+(side==1 and 8 or 0)
  local z=-83+i*25
  rp("PaleCliffWall",V(20,h,26),side*(117+(i%3)*3),h/2,z,i%2==0 and pale or white,true)
  rp("OvergrownLedge",V(28,1.5,27),side*116,h*.61,z,pale,true)
  local grass=rp("LedgeMoss",V(25,.65,25),side*115,h*.61+1.1,z,moss,false);grass.Material=Enum.Material.Grass
  -- Sparse recessed black slit windows and angled weathered ribs.
  for k=1,2 do
   rp("AncientWindow",V(.12,3.2,1.3),side*106,h*.68+k*6,z+5*k,rgb(78,81,69),false)
  end
  rp("CliffRib",V(5,h*.5,8),side*105,h*.32,z-5,rgb(197,196,183),false,CFrame.Angles(0,0,side*.12))
 end
end
local function arch(cx,z,width,spring,depth)
 local r=width/2
 for _,side in ipairs({-1,1})do rp("ArchPier",V(9,spring,depth),cx+side*(r+4.5),spring/2,z,white,true)end
 for i=0,17 do
  local a=(i+.5)/18*math.pi
  rp("ArchVoussoir",V(math.pi*(r+4)/18+.2,8,depth),cx+math.cos(a)*(r+4),spring+math.sin(a)*(r+4),z,pale,true,CFrame.Angles(0,0,a-math.pi/2))
 end
end
arch(0,-107,54,43,18)
for _,side in ipairs({-1,1})do
 rp("RearCliff",V(74,96,22),side*84,48,-110,white,true)
 rp("RearTerrace",V(79,3,27),side*81,61,-108,pale,true)
 local p=rp("RearTerraceMoss",V(77,.8,25),side*81,63,-107,moss);p.Material=Enum.Material.Grass
end
local columns={{-77,59,72,6.8},{-48,18,47,5},{-81,-27,57,5.4},{-41,-62,26,4.8},{71,58,70,6.8},{46,8,41,5.1},{78,-35,53,5.8},{38,-57,19,5.2},{-13,-76,13,3.7},{16,-80,16,3.6}}
for i,c in ipairs(columns)do
 local x,z,h,r=table.unpack(c)
 local p=rp("RoundColumn",V(h,r*2,r*2),x,h/2,z,pale,true,CFrame.Angles(0,0,math.pi/2));p.Shape=Enum.PartType.Cylinder
 local cap=rp("ColumnMoss",V(.65,r*2.05,r*2.05),x,h+.2,z,moss,false,CFrame.Angles(0,0,math.pi/2));cap.Shape=Enum.PartType.Cylinder;cap.Material=Enum.Material.Grass
 if i<=2 or i==5 then rp("ColumnLintel",V(26,3,18),x,h+2.1,z,white,true)end
end
-- Thin tapering evergreen silhouettes from the image, rooted in the court.
for i,v in ipairs({{-94,-63,63},{-62,-73,49},{88,4,69},{91,-51,65},{64,-64,58},{48,-79,45}})do
 local x,z,h=table.unpack(v)
 rp("CypressTrunk",V(1.2,h*.3,1.2),x,h*.15,z,rgb(80,91,59),true)
 for j=1,3 do
  local p=rp("CypressCrown",V(6-j*.9,h*(.8-j*.1),6-j*.9),x,h*(.35+j*.12),z,rgb(85+j*7,124+j*6,39),false)
  p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Grass
 end
end
for side=-1,1,2 do
 for i=0,11 do
  local z=-93+i*17;local length=rng:NextNumber(14,40);local top=rng:NextNumber(56,75)
  for j=1,3 do
   local p=rp("HangingIvy",V(1.3,length*(1-j*.11),rng:NextNumber(4,7)),side*(104-j*.12),top-length*.5-j*2,z+j*1.2,rgb(93+j*6,133+j*5,46),false)
   p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Grass;p.CastShadow=false
  end
 end
end
for i=1,62 do
 local x,z=rng:NextNumber(-96,96),rng:NextNumber(-82,77)
 if math.abs(x)>15 then
  placeMesh(ruins,"RuinGrass_"..i,i%3==0 and "WildFlower01"or "CloverPatch",x,-360+z,i%3==0 and 1.6 or .45,baseY+.15)
 end
end
for i=1,20 do
 local side=i%2==0 and -1 or 1
 rp("BrokenStoneFragment",V(rng:NextNumber(3,6),rng:NextNumber(1.2,3),rng:NextNumber(3,6)),side*rng:NextNumber(60,98),.6,rng:NextNumber(-75,75),pale,true,CFrame.Angles(.05,rng:NextNumber(-1,1),.12))
end

-- Dark bridge: fine spike rails, massive masonry beneath the existing level
-- deck, warm caged lanterns, and HOLLOW interlocking chain links.
local dark=world.DarkZone.AbyssBridgeZone
local darkY=dark:GetAttribute("DeckY")
local oldDetail=dark:FindFirstChild("ReferenceDetails");if oldDetail then oldDetail:Destroy()end
local dd=folder(dark,"ReferenceDetails")
local oldChain=world.DarkZone:FindFirstChild("Chain");if oldChain then oldChain:Destroy()end
local chain=folder(world.DarkZone,"Chain")
local metal=rgb(43,42,34);local masonry=rgb(60,57,43)
for _,p in ipairs(dark:GetChildren())do
 if p.Name=="LampPost"or p.Name=="Lantern"or p.Name=="RailPost"then p:Destroy()end
end
for _,side in ipairs({-1,1})do
 for x=-104,104,4 do
  part(dd,"IronSpike",V(.18,4.6,.18),C(x,darkY+2.15,-850+side*7.5),Enum.Material.Metal,metal,true)
  part(dd,"SpikeCollar",V(.4,.23,.4),C(x,darkY+3.3,-850+side*7.5),Enum.Material.Metal,metal,false)
 end
 for x=-100,100,20 do
  part(dd,"EdgeStone",V(19.8,2,2.4),C(x,darkY-1.1,-850+side*9.1),Enum.Material.Slate,masonry,true)
  part(dd,"LowerCornice",V(20,1.5,3.2),C(x,darkY-3.1,-850+side*8.7),Enum.Material.Slate,metal,true)
 end
end
for _,x in ipairs({-72,0,72})do
 for j=1,4 do
  part(dd,"ButtressTier",V(20-j*2,3,24-j*2),C(x,darkY-5-j*2.4,-850),Enum.Material.Slate,masonry,true)
 end
end
for i,x in ipairs({-96,-48,0,48,96})do
 local z=-850+((i%2==1)and 10.3 or -10.3)
 local lamp=model(dd,"CagedLantern_"..i)
 for j=0,2 do part(lamp,"PedestalTier",V(3.4-j*.6,.8,3.4-j*.6),C(x,darkY+j*.8,z),Enum.Material.Slate,masonry,true)end
 part(lamp,"LanternStem",V(1.05,4.3,1.05),C(x,darkY+4.4,z),Enum.Material.Metal,metal,true)
 part(lamp,"CageBase",V(2.4,.55,2.4),C(x,darkY+6.5,z),Enum.Material.Metal,metal,true)
 local flame=part(lamp,"WarmGlass",V(1.55,2.6,1.55),C(x,darkY+8,z),Enum.Material.Neon,rgb(246,174,76),false,.3)
 for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
  part(lamp,"CageBar",V(.17,3,.17),C(x+sx*.94,darkY+8.05,z+sz*.94),Enum.Material.Metal,metal,false)
 end end
 part(lamp,"CageRoof",V(2.65,.55,2.65),C(x,darkY+9.65,z),Enum.Material.Metal,metal,false)
 part(lamp,"RoofFinial",V(.32,1.3,.32),C(x,darkY+10.45,z),Enum.Material.Metal,metal,false)
 local light=Instance.new("PointLight");light.Color=rgb(255,173,82);light.Range=24;light.Brightness=1.15;light.Shadows=false;light.Parent=flame
end
for i=0,22 do
 local t=i/22;local pos=V(-47-35*(1-t)^2,darkY+7+155*(1-t)^1.55,-863)
 local nextT=math.min(1,t+.015);local nextPos=V(-47-35*(1-nextT)^2,darkY+7+155*(1-nextT)^1.55,-863)
 local frame=C(pos)*CFrame.Angles(0,(i%2)*math.pi/2,math.atan2(-(nextPos.X-pos.X),nextPos.Y-pos.Y))
 local link=model(chain,"HollowLink_"..i)
 for _,s in ipairs({-1,1})do
  part(link,"LinkSide",V(1,8,1),frame*C(s*2.3,0,0),Enum.Material.Metal,metal,false)
  part(link,"LinkEnd",V(4.6,1,1),frame*C(0,s*3.5,0),Enum.Material.Metal,metal,false)
 end
end

-- Store art-direction anchors for repeatable in-engine comparison.
detail:SetAttribute("PondCamera",CFrame.lookAt(V(365,27,312),V(318,42,167)))
detail:SetAttribute("RuinsCamera",CFrame.lookAt(V(9,28,-264),V(0,58,-430)))
detail:SetAttribute("TempleCamera",CFrame.lookAt(V(-14,28,675),V(8,44,585)))
detail:SetAttribute("DarkBridgeCamera",CFrame.lookAt(V(-155,69,-760),V(-5,27,-850)))
local blockTrees,shrubs=0,0
for _,m in ipairs(world.Forest:GetDescendants())do
 if m:IsA("Model")and string.match(m.Name,"^ForestTree_")then blockTrees+=1 end
 if m:IsA("Model")and string.match(m.Name,"^Understory_")then shrubs+=1 end
end
W:SetAttribute("TreeCount",blockTrees);W:SetAttribute("ShrubCount",shrubs)
W:SetAttribute("ReferenceSceneVersion",VERSION)
W:SetAttribute("NaturalMeshGroups",meshCount)
pack:Destroy()
return {version=VERSION,sourceVersion=game.PlaceVersion,blockTrees=blockTrees,removedTrees=removedTrees,shrubs=shrubs,naturalMeshGroups=meshCount,pondPlants=pondPlants}
