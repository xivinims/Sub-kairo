local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local Terrain=Workspace.Terrain
local M=Enum.Material
local V=Vector3.new
local CF=CFrame.new
local C=require(RS:WaitForChild("PhotoWorldConfig"))

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
local sourceVersion=game.PlaceVersion
local world=assert(Workspace:FindFirstChild("OveryardPhotoWorld"),"OveryardPhotoWorld missing")
local caio=assert(world:FindFirstChild("Caio"),"Caio missing")
local caioDescBefore=#caio:GetDescendants()
local starterGui=game:GetService("StarterGui")
local replicatedFirst=game:GetService("ReplicatedFirst")
local starterPlayer=game:GetService("StarterPlayer")
local uiBefore=#starterGui:GetChildren()
local rfBefore=#replicatedFirst:GetChildren()
local spsBefore=#starterPlayer.StarterPlayerScripts:GetChildren()

local old=world:FindFirstChild("WholeMapPhotoDetailV14")
if old then old:Destroy() end
local root=Instance.new("Folder")
root.Name="WholeMapPhotoDetailV14"
root.Parent=world

local rng=Random.new(2156)
local QUALITY=.72
local counts={grass=0,flowers=0,rocks=0,trees=0,lanterns=0,torii=0,leafPlates=0,waterDetails=0}
local function N(x)return math.max(1,math.floor(x*QUALITY+.5))end
local function R(a,b)return rng:NextNumber(a,b)end
local function pick(t)return t[rng:NextInteger(1,#t)]end
local function col(r,g,b)return Color3.fromRGB(r,g,b)end
local function jit(c,a)
 local d=rng:NextNumber(-a,a)/255
 return Color3.new(math.clamp(c.R+d,0,1),math.clamp(c.G+d,0,1),math.clamp(c.B+d,0,1))
end

-- Apply the supplied map palette globally. No NPC/UI object is touched.
Terrain:SetMaterialColor(M.Grass,col(88,162,52))
Terrain:SetMaterialColor(M.LeafyGrass,col(214,172,40))
Terrain:SetMaterialColor(M.Ground,col(110,78,56))
Terrain:SetMaterialColor(M.Rock,col(96,102,112))
Terrain:SetMaterialColor(M.Sand,col(225,205,155))
Terrain:SetMaterialColor(M.Snow,col(245,248,255))
Terrain.WaterColor=col(40,140,190)
Terrain.WaterTransparency=.70
Terrain.WaterReflectance=.62
Terrain.WaterWaveSize=.09
Terrain.WaterWaveSpeed=7

local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances={Terrain}

local function ground(x,z)
 local h=Workspace:Raycast(V(x,300,z),V(0,-500,0),ray)
 if not h or h.Material==M.Water then return nil,nil end
 return h.Position.Y,h.Material
end
local function waterSurface(x,z)
 local h=Workspace:Raycast(V(x,300,z),V(0,-500,0),ray)
 if h and h.Material==M.Water then return h.Position.Y end
 return nil
end
local function safe(x,z,margin)
 margin=margin or 5
 if Vector2.new(x-C.NPC.X,z-C.NPC.Z).Magnitude<75 then return false end
 if Vector2.new(x+130,z-95).Magnitude<85 then return false end
 if Vector2.new(x,z+320).Magnitude<70 then return false end -- existing stone bridge
 local ok=C.open(x,z,margin)
 return ok==true
end

local function part(parent,name,size,frame,color,material,collide,trans,class)
 local p=Instance.new(class or "Part")
 p.Name=name
 p.Size=size
 p.CFrame=frame
 p.Anchored=true
 p.CanCollide=collide==true
 p.CanTouch=false
 p.CanQuery=collide==true
 p.CastShadow=true
 p.TopSurface=Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth
 p.Material=material or M.SmoothPlastic
 p.Color=color
 p.Transparency=trans or 0
 p.Parent=parent
 return p
end
local function model(parent,name)
 local m=Instance.new("Model");m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=parent;return m
end
local function seg(parent,a,b,r,color,material)
 local len=(b-a).Magnitude
 if len<.05 then return nil end
 local p=part(parent,"Branch",V(len,r*2,r*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.rad(90),0),color,material or M.Wood,false,0)
 p.Shape=Enum.PartType.Cylinder
 return p
end
local function emitter(parent,pos,size,props)
 local anchor=part(parent,"ParticleAnchor",size,CF(pos),col(255,255,255),M.SmoothPlastic,false,1)
 anchor.CanQuery=false
 local e=Instance.new("ParticleEmitter")
 for k,v in pairs(props)do e[k]=v end
 e.Parent=anchor
 return e
end

local function grassBlade(parent,p,h,colors)
 local hh=h*R(.65,1.35)
 local blade=part(parent,"GrassBlade",V(.08,hh,R(.35,.72)),CF(p+V(0,hh/2-.04,0))*CFrame.Angles(R(-.18,.18),R(0,6.28),R(-.18,.18)),jit(pick(colors),9),M.SmoothPlastic,false,0,"WedgePart")
 blade.CanQuery=false;blade.CastShadow=false;counts.grass+=1
end
local function flower(parent,p,colors)
 local h=R(1.3,2.4)
 local stem=part(parent,"FlowerStem",V(.09,h,.09),CF(p+V(0,h/2,0)),col(68,125,52),M.SmoothPlastic,false,0)
 stem.CanQuery=false;stem.CastShadow=false
 local bloom=part(parent,"Flower",V(.7,.32,.7)*R(.8,1.25),CF(p+V(0,h,0)),pick(colors),M.SmoothPlastic,false,0)
 bloom.Shape=Enum.PartType.Ball;bloom.CanQuery=false;bloom.CastShadow=false;counts.flowers+=1
end
local function rock(parent,p,s,color)
 local sz=V(s*R(1,1.45),s*R(.55,.9),s*R(1,1.35))
 local r=part(parent,"WeatheredRock",sz,CF(p+V(0,sz.Y*.25,0))*CFrame.Angles(R(-.08,.08),R(0,6.28),R(-.08,.08)),jit(color,9),M.Slate,true,0)
 r.Shape=Enum.PartType.Ball;counts.rocks+=1
end

local function roundTree(parent,b,h,leaf,bark)
 local m=model(parent,"RoundTree")
 seg(m,b-V(0,.7,0),b+V(0,h*.72,0),h*.038,bark,M.Wood)
 local cc=b+V(0,h*.82,0)
 for i=1,7 do
  local off=V(R(-1,1),R(-.45,.65),R(-1,1))*h*.22
  local d=h*R(.24,.37)
  local p=part(m,"Canopy",V(d,d,d),CF(cc+off),jit(leaf,12),M.Grass,false,0)
  p.Shape=Enum.PartType.Ball
 end
 counts.trees+=1
 return m
end
local function pine(parent,b,h,color)
 local m=model(parent,"LayerPineAccent")
 seg(m,b-V(0,.5,0),b+V(0,h*.45,0),h*.027,col(76,55,43),M.Wood)
 for i=1,6 do
  local t=(i-1)/5
  local d=h*.39*(1-t*.82)
  local p=part(m,"PineLayer",V(h*.1,d,d),CF(b+V(0,h*(.20+.115*i),0))*CFrame.Angles(0,0,math.rad(90)),jit(color,9),M.Grass,false,0)
  p.Shape=Enum.PartType.Cylinder
 end
 counts.trees+=1
 return m
end
local function cypress(parent,b,h,color)
 local m=model(parent,"CypressAccent")
 seg(m,b-V(0,.5,0),b+V(0,h*.28,0),h*.025,col(65,48,38),M.Wood)
 local a=part(m,"CypressCrown",V(h*.24,h*.82,h*.24),CF(b+V(0,h*.55,0)),jit(color,8),M.Grass,false,0);a.Shape=Enum.PartType.Ball
 local b2=part(m,"CypressCrown",V(h*.18,h*.56,h*.18),CF(b+V(h*.045,h*.48,h*.03)),jit(color,8),M.Grass,false,0);b2.Shape=Enum.PartType.Ball
 counts.trees+=1
 return m
end
local function blockTree(parent,b,h,leaf,bark,vines)
 local m=model(parent,"BlockJungleTree")
 part(m,"Trunk",V(h*.13,h,h*.13),CF(b+V(0,h/2,0)),bark,M.Wood,true,0)
 for i=1,rng:NextInteger(3,5)do
  local sw=h*R(.38,.65)
  local sz=V(sw,h*R(.11,.17),sw*R(.72,1.05))
  local pos=b+V(R(-1,1)*h*.14,h*(.5+.075*i),R(-1,1)*h*.14)
  part(m,"BlockCanopy",sz,CF(pos),jit(leaf,11),M.SmoothPlastic,false,0)
  if vines then
   for j=1,2 do
    local vl=R(h*.12,h*.28)
    part(m,"Vine",V(.42,vl,.42),CF(pos+V(R(-.42,.42)*sz.X,-sz.Y/2-vl/2,R(-.42,.42)*sz.Z)),col(35,95,80),M.SmoothPlastic,false,0)
   end
  end
 end
 counts.trees+=1
 return m
end
local function cherry(parent,b,h)
 local m=model(parent,"CherryAccent")
 local bark=col(122,84,88)
 local p1=b+V(0,h*.34,h*.04);local p2=p1+V(h*.08,h*.3,0);local p3=p2+V(h*.04,h*.28,-h*.04)
 seg(m,b-V(0,.5,0),p1,h*.04,bark,M.Wood);seg(m,p1,p2,h*.03,bark,M.Wood);seg(m,p2,p3,h*.025,bark,M.Wood)
 local pinks={col(244,168,196),col(232,140,178),col(250,190,210),col(238,155,185)}
 local cc=p3+V(0,h*.05,0)
 for i=1,18 do
  local off=V(R(-1,1)*h*.38,R(-.25,.5)*h*.36,R(-1,1)*h*.36)
  local d=h*R(.11,.20)
  local p=part(m,"Blossom",V(d,d,d),CF(cc+off),jit(pick(pinks),7),M.Fabric,false,0);p.Shape=Enum.PartType.Ball
 end
 emitter(m,cc,V(h*.65,1,h*.65),{Rate=3,Lifetime=NumberRange.new(5,8),Speed=NumberRange.new(.3,1),Acceleration=V(.25,-1,0),Size=NumberSequence.new(.22),Color=ColorSequence.new(col(250,190,215)),EmissionDirection=Enum.NormalId.Bottom,SpreadAngle=Vector2.new(55,55),RotSpeed=NumberRange.new(-50,50)})
 counts.trees+=1
 return m
end
local function maple(parent,b,h)
 local m=model(parent,"CrimsonMapleAccent")
 local bark=col(62,42,44)
 local p1=b+V(h*.04,h*.36,0);local p2=p1+V(-h*.035,h*.30,h*.025)
 seg(m,b-V(0,.5,0),p1,h*.045,bark,M.Wood);seg(m,p1,p2,h*.035,bark,M.Wood)
 local cc=p2+V(0,h*.15,0)
 local reds={col(185,35,50),col(150,28,48),col(210,60,60),col(170,30,70)}
 for i=1,95 do
  local off=V(R(-1,1)*h*.43,R(-.30,.48)*h*.43,R(-1,1)*h*.39)
  part(m,"MapleLeaf",V(R(1.1,2.5),.10,R(1.1,2.5)),CF(cc+off)*CFrame.Angles(R(-.7,.7),R(0,6.28),R(-.7,.7)),jit(pick(reds),13),M.SmoothPlastic,false,0)
  counts.leafPlates+=1
 end
 counts.trees+=1
 return m
end

local function lantern(parent,p)
 local m=model(parent,"StoneLantern")
 part(m,"Foot",V(2.4,.7,2.4),CF(p+V(0,.35,0)),col(125,128,132),M.Slate,true,0)
 part(m,"Stem",V(.8,3.1,.8),CF(p+V(0,2.15,0)),col(125,128,132),M.Slate,true,0)
 local glow=part(m,"Glow",V(1.8,1.6,1.8),CF(p+V(0,4.4,0)),col(235,215,150),M.Glass,false,.25)
 local l=Instance.new("PointLight");l.Color=col(255,200,120);l.Brightness=.8;l.Range=14;l.Parent=glow
 part(m,"Roof",V(3.4,.7,3.4),CF(p+V(0,5.6,0)),col(112,115,120),M.Slate,true,0)
 counts.lanterns+=1
end
local function torii(parent,p,s)
 local m=model(parent,"SanctuaryTorii")
 local stone=col(128,130,134)
 for _,sx in ipairs({-1,1})do
  local post=part(m,"Post",V(25*s,3.2*s,3.2*s),CF(p+V(sx*10*s,12.5*s,0))*CFrame.Angles(0,0,math.rad(90)),stone,M.Slate,true,0)
  post.Shape=Enum.PartType.Cylinder
 end
 part(m,"TopBeam",V(34*s,2.6*s,3.2*s),CF(p+V(0,24*s,0)),stone,M.Slate,true,0)
 part(m,"LowerBeam",V(28*s,1.7*s,2.3*s),CF(p+V(0,19*s,0)),stone,M.Slate,true,0)
 counts.torii+=1
end
local function deer(parent,p,yaw)
 local m=model(parent,"WhiteForestDeer")
 local base=CF(p)*CFrame.Angles(0,yaw,0);local white=col(245,245,252)
 local function wp(x,y,z)return base:PointToWorldSpace(V(x,y,z))end
 local body=part(m,"Body",V(7,3.6,3),base*CF(0,5.2,0),white,M.SmoothPlastic,false,0);body.Shape=Enum.PartType.Ball
 local head=part(m,"Head",V(2,1.4,1.2),base*CF(4.7,8.2,0),white,M.SmoothPlastic,false,0);head.Shape=Enum.PartType.Ball
 part(m,"Neck",V(3.4,1.1,1.1),base*CF(3.5,6.8,0)*CFrame.Angles(0,0,math.rad(55)),white,M.SmoothPlastic,false,0).Shape=Enum.PartType.Cylinder
 for _,lx in ipairs({-2.4,2.4})do for _,lz in ipairs({-.9,.9})do
  part(m,"Leg",V(4.4,.5,.5),base*CF(lx,2.2,lz)*CFrame.Angles(0,0,math.rad(90)),white,M.SmoothPlastic,false,0).Shape=Enum.PartType.Cylinder
 end end
 for _,side in ipairs({-1,1})do
  seg(m,wp(4.4,8.6,side*.4),wp(4,11.2,side*2.2),.13,white,M.SmoothPlastic)
  seg(m,wp(4,11.2,side*2.2),wp(4.9,12.7,side*2.7),.09,white,M.SmoothPlastic)
 end
 local l=Instance.new("PointLight");l.Color=col(150,200,255);l.Brightness=.6;l.Range=14;l.Parent=body
end

local centers={
 Cliff=V(C.Cliff.x+45,0,C.Cliff.z+30),
 Jungle=V(0,0,-400),
 Sunset=V(400,0,400),
 Falls=V(400,0,-400),
 Blue=V(-400,0,400),
 Shrine=V(680,0,800),
 Golden=V(0,0,400),
 StoneTrail=V(-1090,0,1040),
 Emerald=V(1460,0,410),
 WhitePath=V(300,0,1300),
}

local zones={}
for name,c0 in pairs(centers)do
 local f=Instance.new("Folder");f.Name=name;f:SetAttribute("Center",c0);f.Parent=root;zones[name]=f
end

-- 1. Ocean cliff: one dramatic crimson tree and weathered coastal rocks.
do
 local c0=centers.Cliff;local y=ground(c0.X,c0.Z)
 if y then maple(zones.Cliff,V(c0.X,y,c0.Z),38)end
 for i=1,N(14)do local x,z=c0.X+R(-55,55),c0.Z+R(-42,42);local gy=ground(x,z);if gy then rock(zones.Cliff,V(x,gy,z),R(2,5),col(90,110,70))end end
end

-- 2. Square jungle: block trees/vines and a tiny low-impact camp.
do
 local c0=centers.Jungle
 for i=1,N(22)do
  local a=R(0,math.pi*2);local rr=R(65,155);local x,z=c0.X+math.cos(a)*rr,c0.Z+math.sin(a)*rr
  if safe(x,z,8)then local y=ground(x,z);if y then blockTree(zones.Jungle,V(x,y,z),R(32,50),pick({col(48,125,80),col(40,110,90),col(60,135,85)}),col(98,70,86),true)end end
 end
 local cx,cz=90,-475;local cy=ground(cx,cz)
 if cy then
  local a=part(zones.Jungle,"CampfireAnchor",V(1,1,1),CF(cx,cy+.4,cz),col(255,255,255),M.SmoothPlastic,false,1)
  local fire=Instance.new("Fire");fire.Size=4.5;fire.Heat=4;fire.Color=col(255,140,40);fire.SecondaryColor=col(255,70,25);fire.Parent=a
  local l=Instance.new("PointLight");l.Color=col(255,150,70);l.Brightness=1;l.Range=18;l.Parent=a
 end
end

-- 3. Sakura/sunset: blossoming trees and sparse stepping stones.
do
 local c0=centers.Sunset
 for i=1,5 do
  local a=(i-1)/5*math.pi*2;local x,z=c0.X+math.cos(a)*R(55,95),c0.Z+math.sin(a)*R(55,95)
  if safe(x,z,8)then local y=ground(x,z);if y then cherry(zones.Sunset,V(x,y,z),R(30,42))end end
 end
 for i=1,11 do
  local t=(i-1)/10;local x=c0.X-55+35*t+math.sin(t*3)*6;local z=c0.Z+110-115*t;local y=ground(x,z)
  if y then part(zones.Sunset,"SteppingStone",V(R(3.5,6),.45,R(3,5.5)),CF(x,y+.1,z)*CFrame.Angles(0,R(-.45,.45),0),jit(col(140,125,150),10),M.Slate,true,0)end
 end
end

-- 4. Spring lake: visible waterfall sheet + mist, using the existing lake.
do
 local c0=centers.Falls
 local sheet=part(zones.Falls,"WaterfallSheet",V(7,38,1.1),CF(c0.X-72,43,c0.Z-74)*CFrame.Angles(math.rad(-17),0,0),col(205,232,255),M.Glass,false,.35)
 local l=Instance.new("PointLight");l.Color=col(150,205,255);l.Brightness=.35;l.Range=18;l.Parent=sheet
 emitter(zones.Falls,V(c0.X-72,23,c0.Z-68),V(9,2,5),{Rate=15,Lifetime=NumberRange.new(1.5,2.6),Speed=NumberRange.new(1,2.5),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,3),NumberSequenceKeypoint.new(1,7)}),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.65),NumberSequenceKeypoint.new(1,1)}),Color=ColorSequence.new(col(255,255,255)),EmissionDirection=Enum.NormalId.Top})
 counts.waterDetails+=1
end

-- 5. Blue autumn: tall pines, golden leaf plates and the white deer.
do
 local c0=centers.Blue
 for i=1,N(18)do
  local a=R(0,6.28);local rr=R(70,170);local x,z=c0.X+math.cos(a)*rr,c0.Z+math.sin(a)*rr
  if safe(x,z,9)then local y=ground(x,z);if y then pine(zones.Blue,V(x,y,z),R(45,72),col(45,82,105))end end
 end
 for i=1,N(180)do
  local x,z=c0.X+R(-135,135),c0.Z+R(-135,135);local y=ground(x,z)
  if y then part(zones.Blue,"AutumnLeaf",V(.1,R(2,4),R(2,4)),CF(x,y+.08,z)*CFrame.Angles(R(-.25,.25),R(0,6.28),R(-.25,.25))*CFrame.Angles(0,0,math.rad(90)),pick({col(250,185,40),col(240,150,30),col(255,205,70)}),M.SmoothPlastic,false,0).CanQuery=false;counts.leafPlates+=1 end
 end
 local dx,dz=c0.X+42,c0.Z-38;local dy=ground(dx,dz);if dy then deer(zones.Blue,V(dx,dy,dz),2.4)end
end

-- 6. Sanctuary: exactly ONE torii, a small pagoda and paired stone lanterns.
do
 local c0=centers.Shrine;local y=ground(c0.X,c0.Z)
 if not y then
  for r=20,160,20 do
   for a=0,math.pi*2,math.pi/4 do
    local x,z=c0.X+math.cos(a)*r,c0.Z+math.sin(a)*r
    if safe(x,z,14)then y=ground(x,z);if y then c0=V(x,0,z);break end end
   end
   if y then break end
  end
 end
 if y then
  torii(zones.Shrine,V(c0.X,y,c0.Z),.82)
  local pg=model(zones.Shrine,"SmallStonePagoda")
  for i=0,3 do
   local w=17-i*2.4
   part(pg,"PagodaBody",V(w*.68,4,w*.68),CF(c0.X,y+i*5.5+2,c0.Z-48),col(200,191,177),M.Slate,true,0)
   part(pg,"PagodaRoof",V(w+4,.8,w+4),CF(c0.X,y+i*5.5+4.4,c0.Z-48),col(78,84,89),M.Slate,true,0)
  end
  for zoff=-24,36,20 do
   lantern(zones.Shrine,V(c0.X-10,y,c0.Z+zoff))
   lantern(zones.Shrine,V(c0.X+10,y,c0.Z+zoff))
  end
 end
end

-- 7. Golden meadow: grass, flowers and floating warm motes.
do
 local c0=centers.Golden
 emitter(zones.Golden,V(c0.X,38,c0.Z),V(250,24,250),{Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Rate=9,Lifetime=NumberRange.new(6,10),Speed=NumberRange.new(.2,.55),Size=NumberSequence.new(.18),LightEmission=1,Color=ColorSequence.new(col(255,230,140)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.35),NumberSequenceKeypoint.new(.8,.35),NumberSequenceKeypoint.new(1,1)})})
end

-- 8. Stone trail: low wall beside the current route, never across it.
do
 local c0=centers.StoneTrail
 for row=0,2 do
  for i=1,N(10)do
   local x=c0.X-55+row*2;local z=c0.Z-105+(i-1)*20;local y=ground(x,z)
   if y then
    part(zones.StoneTrail,"TrailWallBlock",V(R(10,16),R(6,8),R(13,18)),CF(x,y+3.5+row*6.5,z),jit(col(205,152,112),11),M.Sandstone,true,0)
   end
  end
 end
end

-- 9. Emerald lake: shore rocks, flowers and water pads around existing EastLake.
do
 local c0=centers.Emerald
 for i=1,N(26)do
  local a=R(0,6.28);local rr=R(145,195);local x,z=c0.X+math.cos(a)*rr,c0.Z+math.sin(a)*rr;local y=ground(x,z)
  if y then rock(zones.Emerald,V(x,y,z),R(3.5,7),col(105,135,100))end
 end
 for i=1,N(34)do
  local a=R(0,6.28);local rr=R(25,105);local x,z=c0.X+math.cos(a)*rr,c0.Z+math.sin(a)*rr;local wy=waterSurface(x,z)
  if wy then
   local pad=part(zones.Emerald,"WaterPad",V(.12,R(2.2,3.5),R(2.2,3.5)),CF(x,wy+.06,z)*CFrame.Angles(0,0,math.rad(90)),jit(col(115,180,75),10),M.SmoothPlastic,false,0)
   pad.Shape=Enum.PartType.Cylinder;pad.CanQuery=false;counts.waterDetails+=1
  end
 end
end

-- 10. White path: pale stepping ribbon + cypress around SouthLake.
do
 local c0=centers.WhitePath
 for i=0,20 do
  local t=i/20;local x=c0.X-85+t*160+math.sin(t*5)*12;local z=c0.Z+120-t*200;local y=ground(x,z)
  if y then part(zones.WhitePath,"WhitePathStone",V(8,.35,10),CF(x,y+.08,z)*CFrame.Angles(0,R(-.15,.15),0),col(240,236,222),M.Sand,true,0)end
 end
 for i=1,N(18)do
  local a=R(0,6.28);local rr=R(150,215);local x,z=c0.X+math.cos(a)*rr,c0.Z+math.sin(a)*rr
  if safe(x,z,8)then local y=ground(x,z);if y then cypress(zones.WhitePath,V(x,y,z),R(20,31),col(35,108,84))end end
 end
end

-- Spread the supplied grass/flowers/rocks/tree language across the WHOLE current map.
local themeOrder={"Cliff","Jungle","Sunset","Falls","Blue","Shrine","Golden","StoneTrail","Emerald","WhitePath"}
local grassColors={col(80,150,55),col(95,170,60),col(70,135,50),col(120,150,45),col(70,150,80)}
local flowerColors={col(255,255,245),col(245,210,60),col(238,155,185),col(190,170,220)}
for _,name in ipairs(themeOrder)do
 local c0=centers[name]
 local zoneFolder=zones[name]
 for i=1,N(115)do
  local x,z=c0.X+R(-145,145),c0.Z+R(-145,145)
  if safe(x,z,3)then local y=ground(x,z);if y then grassBlade(zoneFolder,V(x,y,z),R(2.3,4.6),grassColors)end end
 end
 for i=1,N(24)do
  local x,z=c0.X+R(-138,138),c0.Z+R(-138,138)
  if safe(x,z,3)then local y=ground(x,z);if y then flower(zoneFolder,V(x,y,z),flowerColors)end end
 end
 for i=1,N(7)do
  local x,z=c0.X+R(-140,140),c0.Z+R(-140,140)
  if safe(x,z,5)then local y=ground(x,z);if y then rock(zoneFolder,V(x,y,z),R(1.8,4.2),col(105,113,108))end end
 end
end

-- A little more tree volume everywhere, but keep paths/structures/NPC clear.
for i=1,N(95)do
 local x,z=R(-1850,1850),R(-1850,1850)
 if safe(x,z,10)then
  local y=ground(x,z)
  if y then
   local zone=C.zone(x,z)
   if zone.id=="Sakura" and rng:NextNumber()<.35 then cherry(root,V(x,y,z),R(26,38))
   elseif zone.id=="BlueAutumn" and rng:NextNumber()<.7 then pine(root,V(x,y,z),R(32,55),col(47,88,74))
   elseif rng:NextNumber()<.28 then cypress(root,V(x,y,z),R(20,33),col(42,112,74))
   else roundTree(root,V(x,y,z),R(24,40),pick({col(72,150,66),col(85,165,72),col(55,128,70)}),col(92,68,52))end
  end
 end
end

-- Map-only lighting touch. Existing client biome controller remains the authority.
local bloom=Lighting:FindFirstChild("PhotoBloom")
if bloom and bloom:IsA("BloomEffect")then bloom.Intensity=math.max(bloom.Intensity,.18);bloom.Size=math.max(bloom.Size,24)end
local rays=Lighting:FindFirstChild("PhotoSun")
if rays and rays:IsA("SunRaysEffect")then rays.Intensity=math.max(rays.Intensity,.06)end
Workspace.GlobalWind=V(3.6,0,1.15)

root:SetAttribute("Version","whole-map-photo-detail-v14")
root:SetAttribute("SourcePlaceVersion",sourceVersion)
root:SetAttribute("GrassCount",counts.grass)
root:SetAttribute("FlowerCount",counts.flowers)
root:SetAttribute("RockCount",counts.rocks)
root:SetAttribute("AccentTreeCount",counts.trees)
root:SetAttribute("LanternCount",counts.lanterns)
root:SetAttribute("ToriiCount",counts.torii)
root:SetAttribute("LeafPlateCount",counts.leafPlates)
root:SetAttribute("WaterDetailCount",counts.waterDetails)
root:SetAttribute("CaioDescendantsBefore",caioDescBefore)
root:SetAttribute("StarterGuiChildrenBefore",uiBefore)
root:SetAttribute("ReplicatedFirstChildrenBefore",rfBefore)
root:SetAttribute("StarterPlayerScriptsBefore",spsBefore)

assert(#caio:GetDescendants()==caioDescBefore,"Map pass changed Caio")
assert(#starterGui:GetChildren()==uiBefore,"Map pass changed StarterGui")
assert(#replicatedFirst:GetChildren()==rfBefore,"Map pass changed ReplicatedFirst")
assert(#starterPlayer.StarterPlayerScripts:GetChildren()==spsBefore,"Map pass changed StarterPlayerScripts")

game:GetService("AssetService"):SavePlaceAsync()
return {ok=true,sourceVersion=sourceVersion,counts=counts,caioUntouched=true,uiUntouched=true}
