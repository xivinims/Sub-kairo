local BUILD_ID="dead-signal-overgrown-atrium-v2"
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local W=workspace
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SP=game:GetService("StarterPlayer")
local L=game:GetService("Lighting")
local Http=game:GetService("HttpService")
for _,c in ipairs(W:GetChildren()) do if not c:IsA("Camera") and c~=W.Terrain then c:Destroy() end end
W.Terrain:Clear()
for _,s in ipairs({SSS,RS,SP.StarterPlayerScripts,SP.StarterCharacterScripts,game:GetService("StarterGui"),game:GetService("ReplicatedFirst"),L,game:GetService("SoundService")}) do for _,c in ipairs(s:GetChildren()) do c:Destroy() end end
for k in pairs(W:GetAttributes()) do W:SetAttribute(k,nil) end
W.StreamingEnabled=true
local map=Instance.new("Model");map.Name="OvergrownAtrium";map.Parent=W
local architecture=Instance.new("Folder");architecture.Name="Architecture";architecture.Parent=map
local foliage=Instance.new("Folder");foliage.Name="BotanicalReclamation";foliage.Parent=map
local details=Instance.new("Folder");details.Name="WeatheringAndFixtures";details.Parent=map
local routes=Instance.new("Folder");routes.Name="RouteMarkers";routes.Parent=map
local rng=Random.new(82143)
local stone=Color3.fromRGB(100,111,126)
local dark=Color3.fromRGB(29,40,51)
local metal=Color3.fromRGB(47,57,65)
local green=Color3.fromRGB(36,63,47)
local function part(parent,name,size,cf,color,mat,solid)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or stone;p.Material=mat or Enum.Material.Concrete;p.Anchored=true;p.CanCollide=solid~=false;p.CanQuery=p.CanCollide;p.CanTouch=false;p.CastShadow=solid~=false;p.Parent=parent;return p
end
local function box(name,x,y,z,sx,sy,sz,color,mat,solid,parent)
 return part(parent or architecture,name,Vector3.new(sx,sy,sz),CFrame.new(x,y,z),color,mat,solid)
end
local function rod(parent,name,a,b,width,color,material,solid)
 return part(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material,solid)
end
local function marker(name,pos)
 local p=box(name,pos.X,pos.Y,pos.Z,1,1,1,nil,nil,false,routes);p.Transparency=1;return p
end
local function rail(a,b)
 rod(architecture,"GalleryHandrail",a+Vector3.new(0,3.5,0),b+Vector3.new(0,3.5,0),.22,metal,Enum.Material.Metal,true)
 rod(architecture,"LowerRail",a+Vector3.new(0,1.4,0),b+Vector3.new(0,1.4,0),.14,metal,Enum.Material.Metal,true)
 for i=0,math.floor((b-a).Magnitude/5) do local v=a:Lerp(b,i/math.max(1,math.floor((b-a).Magnitude/5)));rod(architecture,"Baluster",v,v+Vector3.new(0,3.5,0),.17,metal,Enum.Material.Metal,true) end
end
box("ContinuousFoundation",0,-1,0,116,2,196)
-- Flush mosaic joints, bounded worn colour variation, no trip hazards.
for x=-48,48,6 do for z=-90,90,6 do
 local c=rng:NextInteger(96,127)
 local t=box("LimestoneTile",x,.035,z,5.91,.07,5.91,Color3.fromRGB(c,c+6,c+13),Enum.Material.Slate,true)
 if rng:NextNumber()<.10 then t.Color=Color3.fromRGB(59,72,77) end
end end
for _,x in ipairs({-57,57}) do
 box("ExteriorShell",x,43,0,2,86,196,dark)
 for z=-88,88,22 do
  box("FlutedPier",x*.88,40,z,3.4,80,3.2,stone)
  box("PierFoot",x*.88,2,z,4.1,4,4.1,Color3.fromRGB(63,74,81))
  for y=22,66,22 do box("PierCapital",x*.88,y-.6,z,4.4,1.4,4.4,stone) end
 end
 for level=0,3 do
  local y=level*22
  box("SideGallery",x*.84,y-.55,0,18,1.1,192,stone)
  box("GalleryFascia",x*.67,y-1.4,0,.6,2,192,Color3.fromRGB(71,83,96))
  if level>0 then rail(Vector3.new(x*.67,y,-94),Vector3.new(x*.67,y,94)) end
  for z=-77,77,22 do
   box("RecessedBayLintel",x*.96,y+13,z,1,2,19,Color3.fromRGB(63,73,86))
   box("BlindBay",x*.98,y+6,z,.25,11,18,Color3.fromRGB(19,29,41))
   for off=-7,7,7 do box("BayMullion",x*.975,y+6,z+off,.35,11,.18,metal,Enum.Material.Metal) end
  end
 end
end
for _,x in ipairs({-33,33}) do box("EntranceUpperWall",x,44,97,50,68,2,stone) end
-- Towering glazed opening from the additional reverse-angle reference.
for row=0,9 do for col=-1,1 do
 local pane=box("ClerestoryPane",col*5.2,14+row*6.4,97,4.9,6.05,.22,Color3.fromRGB(146,171,192),Enum.Material.Glass,false)
 pane.Transparency=.35;pane.CastShadow=false
end end
for x=-8,8,5.33 do box("ClerestoryMullion",x,44,96.6,.22,68,.35,metal,Enum.Material.Metal) end
for y=10,78,6.4 do box("ClerestoryTransom",0,y,96.6,16,.2,.35,metal,Enum.Material.Metal) end
for _,v in ipairs({{-42,32},{0,36},{42,32}}) do box("EntranceWallPier",v[1],5,97,v[2],10,2,stone) end
for _,x in ipairs({-22,22}) do
 box("VestibuleFloor",x,-.5,106,14,1,18,stone)
 box("VestibuleRear",x,5,115,14,10,1,stone)
 box("VestibuleCeiling",x,10,106,14,1,18,stone)
 for _,dx in ipairs({-7,7}) do box("VestibuleSide",x+dx,5,106,1,10,18,stone) end
end
box("RearWall",0,39,-97,116,78,2,stone)
for y=0,66,22 do
 box("RearLanding",0,y-.55,-86,100,1.1,20,stone)
 -- Front return links both side galleries, making every floor a loop.
 box("FrontReturn",0,y-.55,88,100,1.1,16,stone)
 if y>0 then rail(Vector3.new(-38,y,80),Vector3.new(38,y,80)) end
end
-- Three real flights cross the rear of the atrium, like the reference.
for level=0,2 do
 local y=level*22
 local sign=level%2==0 and 1 or -1
 local flightZ=level%2==0 and -65 or -51
 local a=Vector3.new(-30*sign,y,flightZ)
 local b=Vector3.new(30*sign,y+22,flightZ)
 local count=44
 for i=1,count do
  local v=a:Lerp(b,(i-.5)/count)
  box("StairTread",v.X,y+i*.5-.25,v.Z,60/count+.02,.5,10,Color3.fromRGB(101,111,121),Enum.Material.Concrete)
  box("TreadNosing",v.X,y+i*.5+.015,v.Z,60/count,.03,9.8,Color3.fromRGB(135,147,155),Enum.Material.Metal,false)
 end
 for _,z in ipairs({flightZ-5.3,flightZ+5.3}) do
  rail(Vector3.new(a.X,y,z),Vector3.new(b.X,y+22,z))
  rod(architecture,"StairStringer",Vector3.new(a.X,y-1,z),Vector3.new(b.X,y+21,z),.8,metal,Enum.Material.Metal,true)
 end
 -- Side landings connect to galleries; no jump at either end.
 for _,v in ipairs({a,b}) do
  box("FlightLanding",v.X<0 and -35 or 35,v.Y-.5,-64,10,1,36,stone)
 end
 marker("Floor"..(level+1),Vector3.new(b.X,y+25,-79))
end
-- Roof trusses cast the diagonal grid in the photo. Missing panels let moonlight in.
for z=-96,96,16 do
 rod(architecture,"RoofTie",Vector3.new(-56,81,z),Vector3.new(56,81,z),.65,metal,Enum.Material.Metal,true)
 rod(architecture,"RafterLeft",Vector3.new(-56,81,z),Vector3.new(0,90,z),.7,metal,Enum.Material.Metal,true)
 rod(architecture,"RafterRight",Vector3.new(0,90,z),Vector3.new(56,81,z),.7,metal,Enum.Material.Metal,true)
 for x=-48,48,16 do
  local yy=90-math.abs(x)/56*9
  if rng:NextNumber()>.37 then
   local pane=box("SurvivingSkylight",x,yy+.3,z,15.2,.15,15.2,Color3.fromRGB(114,151,173),Enum.Material.Glass,false)
   pane.Transparency=.72;pane.CFrame*=CFrame.Angles(0,0,math.rad(x<0 and 9 or -9));pane.CastShadow=false
  end
 end
end
for x=-56,56,14 do rod(architecture,"RoofPurlin",Vector3.new(x,90-math.abs(x)/56*9,-96),Vector3.new(x,90-math.abs(x)/56*9,96),.3,metal,Enum.Material.Metal,true) end
-- Trees: tapered branching trunks and irregular small lobes, never spherical giant bushes.
local function branch(a,b,r1,r2)
 local p=rod(foliage,"WeatheredTrunk",a,b,r1,Color3.fromRGB(62,57,47),Enum.Material.Wood,true)
 local mesh=Instance.new("CylinderMesh");mesh.Parent=p
 -- CylinderMesh points along Y: use matching local vertical transform.
 p.Size=Vector3.new(r1,(b-a).Magnitude,r2);p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0)
end
local function crown(v,scale)
 for k=1,9 do
  local q=v+Vector3.new(rng:NextNumber(-scale,scale),rng:NextNumber(-scale*.35,scale*.5),rng:NextNumber(-scale,scale))
  local leaf=box("LeafCrown",q.X,q.Y,q.Z,scale*1.35,scale*.7,scale*1.2,Color3.fromRGB(rng:NextInteger(26,43),rng:NextInteger(52,75),rng:NextInteger(39,53)),Enum.Material.Grass,false,foliage)
  leaf.Shape=Enum.PartType.Ball;leaf.CFrame*=CFrame.Angles(rng:NextNumber(),rng:NextNumber(),rng:NextNumber());leaf.CastShadow=true
 end
end
for _,t in ipairs({{-29,29,45},{-30,-30,54},{30,-12,41},{-33,63,30}}) do
 local base=Vector3.new(t[1],0,t[2]);local top=base+Vector3.new(3,t[3],-4)
 branch(base,top,3.7,3)
 for j=1,7 do
  local start=base:Lerp(top,.35+j*.065)
  local tip=start+Vector3.new(rng:NextNumber(-13,13),rng:NextNumber(5,12),rng:NextNumber(-12,12))
  branch(start,tip,1.1,.8);crown(tip,5.3)
 end
 for j=1,6 do local angle=j*math.pi/3;branch(base+Vector3.new(0,1,0),base+Vector3.new(math.cos(angle)*8,.15,math.sin(angle)*8),.7,.5) end
end
-- Ivy hangs from cornices, sparse on the traversable galleries.
for _,side in ipairs({-1,1}) do for level=1,3 do for z=-82,82,13 do
 if rng:NextNumber()<.72 then
  local length=rng:NextInteger(4,12)
  for j=0,length,2 do
   local v=Vector3.new(side*38.8,level*22-j,z+math.sin(j)*.7)
   local p=box("HangingIvy",v.X,v.Y,v.Z,.18,2.8,2.4,green,Enum.Material.Grass,false,foliage)
   p.CFrame*=CFrame.Angles(0,rng:NextNumber(-.3,.3),rng:NextNumber(-.2,.2))
  end
 end
end end end
-- Low moss beds leave a broad central walkway and safe stair approach.
for i=1,125 do
 local x=rng:NextNumber(-35,35);local z=rng:NextNumber(-51,72)
 if math.abs(x)>8 then
  local p=box("MossIsland",x,.09,z,rng:NextNumber(2,7),.08,rng:NextNumber(2,6),green,Enum.Material.Grass,false,foliage)
  p.CFrame*=CFrame.Angles(0,rng:NextNumber(0,6.28),0)
 end
end
-- White four-petal ground flowers. No per-flower light or emitter.
for i=1,290 do
 local x=rng:NextNumber(-35,35);local z=rng:NextNumber(-52,75)
 if math.abs(x)>6 or rng:NextNumber()<.16 then
  local height=rng:NextNumber(.25,.65)
  for petal=1,4 do
   local a=petal*math.pi/2+rng:NextNumber(-.12,.12)
   local p=part(foliage,"Moonflower",Vector3.new(.16,.12,.85),CFrame.new(x,height,z)*CFrame.Angles(0,a,0)*CFrame.new(0,.12,.3)*CFrame.Angles(-.45,0,0),Color3.fromRGB(192,207,244),Enum.Material.Neon,false)
  end
 end
end
-- Irregular exposed brick scars and water streaks, all flat and nonblocking.
for _,side in ipairs({-1,1}) do for i=1,68 do
 local z=rng:NextNumber(-90,90);local y=rng:NextNumber(4,76)
 local p=box("DampScar",side*55.85,y,z,.03,rng:NextNumber(1,6),rng:NextNumber(.2,1.5),Color3.fromRGB(48,59,62),Enum.Material.Concrete,false,details)
end end
for i=1,32 do
 local x=rng:NextNumber(-32,32);local z=rng:NextNumber(-50,70)
 if math.abs(x)>9 then
  local p=box("MasonryFragment",x,.15,z,rng:NextNumber(.3,1.2),.3,rng:NextNumber(.3,.9),stone,Enum.Material.Concrete,false,details);p.CFrame*=CFrame.Angles(0,rng:NextNumber()*6,0)
 end
end
-- Flaking pale plaster exposes dark substrate on the structural piers.
for _,side in ipairs({-1,1}) do for z=-88,88,22 do
 for i=1,9 do
  local y=rng:NextNumber(5,77)
  local p=box("ExposedPierSubstrate",side*48.43,y,z+rng:NextNumber(-1.1,1.1),.025,rng:NextNumber(.7,3.8),rng:NextNumber(.3,1.3),Color3.fromRGB(45,55,68),Enum.Material.Slate,false,details)
  p.CFrame*=CFrame.Angles(rng:NextNumber(-.2,.2),0,0)
 end
end end
-- Teal remnants of the original floor pattern, flush with the surviving stone.
for x=-24,24,12 do for z=-84,72,12 do
 if rng:NextNumber()<.45 then
  box("FadedTealInlay",x,.078,z,5.87,.012,5.87,Color3.fromRGB(66,108,105),Enum.Material.Slate,false,details)
 end
end end
-- Cable catenaries below the broken roof.
for _,z in ipairs({-48,25,61}) do
 local last=Vector3.new(-45,78,z)
 for i=1,16 do local t=i/16;local nextP=Vector3.new(-45+90*t,78-13*math.sin(t*math.pi),z);rod(details,"HangingCable",last,nextP,.10,dark,Enum.Material.Metal,false);last=nextP end
end
local doors=Instance.new("Folder");doors.Name="Doors";doors.Parent=map
for i,x in ipairs({-22,22}) do
 local z=97
 local model=Instance.new("Model");model.Name="ServiceDoor"..i;model.Parent=doors
 local p=box("DoorPanel",x,4,z,7.8,8,.45,Color3.fromRGB(52,67,76),Enum.Material.Metal,true,model)
 model:SetAttribute("DoorId","ATRIUM_"..i);model:SetAttribute("OpenOffset",Vector3.new(0,8.5,0));model:SetAttribute("OpenDuration",1.1)
 for _,offset in ipairs({-1.2,1.2}) do
  local control=box("DoorControl",x+5,4,z+offset,.6,1,.2,Color3.fromRGB(131,162,176),Enum.Material.Metal,false,model)
  local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Abrir / fechar";prompt.ObjectText="Porta de serviço";prompt.MaxActivationDistance=8;prompt.HoldDuration=.15;prompt.RequiresLineOfSight=true;prompt.Parent=control
 end
 for _,off in ipairs({-4.1,4.1}) do box("DoorJamb",x+off,4,z,.3,8.8,.8,stone) end
 box("DoorLintel",x,8.5,z,9,.7,.8,stone)
end
local spawn=Instance.new("SpawnLocation");spawn.Name="AtriumSpawn";spawn.Size=Vector3.new(8,.2,8);spawn.CFrame=CFrame.lookAt(Vector3.new(0,.17,66),Vector3.new(0,.17,-40));spawn.Transparency=1;spawn.Anchored=true;spawn.CanCollide=false;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=map
marker("Start",Vector3.new(0,3.5,66))
marker("Garden",Vector3.new(0,3.5,-40))
local camera=marker("MenuCamera",Vector3.new(24,8,65));camera.CFrame=CFrame.lookAt(camera.Position,Vector3.new(-8,30,-54))
-- Cool skylight with readable ambient bounce. Native post processing, not an external shader.
L.ClockTime=9.2;L.GeographicLatitude=35;L.Brightness=2.1;L.GlobalShadows=true;L.Ambient=Color3.fromRGB(45,55,78);L.OutdoorAmbient=Color3.fromRGB(90,111,145);L.ExposureCompensation=-.15;L.EnvironmentDiffuseScale=.65;L.EnvironmentSpecularScale=.7
pcall(function() L.Technology=Enum.Technology.Future end)
local grade=Instance.new("ColorCorrectionEffect");grade.Name="AtriumGrade";grade.TintColor=Color3.fromRGB(200,218,255);grade.Contrast=.14;grade.Saturation=-.24;grade.Parent=L
local bloom=Instance.new("BloomEffect");bloom.Name="MoonflowerBloom";bloom.Intensity=.22;bloom.Size=24;bloom.Threshold=1.3;bloom.Parent=L
local rays=Instance.new("SunRaysEffect");rays.Intensity=.045;rays.Spread=.7;rays.Parent=L
local fog=Instance.new("Atmosphere");fog.Density=.26;fog.Offset=.1;fog.Color=Color3.fromRGB(131,154,187);fog.Decay=Color3.fromRGB(66,79,107);fog.Haze=1.9;fog.Glare=.1;fog.Parent=L
for _,z in ipairs({-44,26,65}) do
 local p=box("SkylightBounce",0,48,z,1,1,1,nil,nil,false,details);p.Transparency=1
 local light=Instance.new("PointLight");light.Color=Color3.fromRGB(152,181,235);light.Range=60;light.Brightness=.65;light.Shadows=false;light.Parent=p
end
local dust=box("DriftingDust",0,28,10,60,30,120,nil,nil,false,details);dust.Transparency=1
local emitter=Instance.new("ParticleEmitter");emitter.Name="AtriumDust";emitter.Texture="rbxasset://textures/particles/sparkles_main.dds";emitter.Rate=4;emitter.Lifetime=NumberRange.new(9,14);emitter.Speed=NumberRange.new(.1,.35);emitter.Size=NumberSequence.new(.045);emitter.Transparency=NumberSequence.new(.75);emitter.LightEmission=.35;emitter.SpreadAngle=Vector2.new(180,180);emitter.Parent=dust
local root=Instance.new("Folder");root.Name="AtriumRuntime";root.Parent=SSS
local function module(name,source) local m=Instance.new("ModuleScript");m.Name=name;m.Source=source;m.Parent=root end
module("DoorService",__DOOR_SERVICE__);module("MapInteractionGuard",__INTERACTION_GUARD__)
local remote=Instance.new("RemoteFunction");remote.Name="AtriumSession";remote.Parent=RS
local s=Instance.new("Script");s.Name="AtriumServer";s.Source=__SERVER__;s.Enabled=false;s.Parent=root
local client=Instance.new("LocalScript");client.Name="AtriumClient";client.Source=__CLIENT__;client.Parent=SP.StarterPlayerScripts
local loading=Instance.new("LocalScript");loading.Name="AurivaneLoading";loading.Source=__LOADING__;loading.Parent=game:GetService("ReplicatedFirst")
RS:SetAttribute("AurivaneLogo",__LOGO_ID__)
local okLogo,logoModel=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(RS:GetAttribute("AurivaneLogo")) end)
if okLogo and logoModel then
 local decal=logoModel:FindFirstChildWhichIsA("Decal",true)
 if decal then RS:SetAttribute("AurivaneLogoTexture",decal.Texture) end
 logoModel:Destroy()
end
SP.CameraMode=Enum.CameraMode.LockFirstPerson;SP.CameraMinZoomDistance=.5;SP.CameraMaxZoomDistance=.5;SP.CharacterWalkSpeed=16
W:SetAttribute("DeadSignalBuildId",BUILD_ID);W:SetAttribute("MapSource","Original geometry from user photo");W:SetAttribute("StalkerPaused",true)
__PREPUBLISH_VALIDATE__
s.Enabled=true
local prior=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return Http:JSONEncode({ok=true,published=true,build=BUILD_ID,sourceVersion=prior})
