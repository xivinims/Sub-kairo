local Map={}
local C3=Color3
local function part(parent,name,size,cf,color,material,transparency,collide,shape)
 local p=Instance.new('Part')
 p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
 p.Color=color or C3.fromRGB(38,44,39)
 p.Material=material or Enum.Material.Metal
 p.Transparency=transparency or 0
 p.CanCollide=collide==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true
 if shape then p.Shape=shape end
 p.Parent=parent
 return p
end
local function prompt(host,name,action,object,enabled)
 local p=Instance.new('ProximityPrompt')
 p.Name=name;p.ActionText=action;p.ObjectText=object
 p.KeyboardKeyCode=Enum.KeyCode.E;p.GamepadKeyCode=Enum.KeyCode.ButtonX
 p.Style=Enum.ProximityPromptStyle.Custom
 p.HoldDuration=.75;p.MaxActivationDistance=10
 p.RequiresLineOfSight=false;p.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally
 p.Enabled=enabled~=false;p.Parent=host
 return p
end
local function window(parent,name,pos,size)
 return part(parent,name,size,CFrame.new(pos),C3.fromRGB(101,139,136),Enum.Material.Glass,.79,false)
end
local function vine(parent,name,pos,length,angle)
 local stem=part(parent,name..'_Stem',Vector3.new(.22,length,.22),
  CFrame.new(pos)*CFrame.Angles(0,0,angle),C3.fromRGB(39,68,45),Enum.Material.Wood,false,false)
 for i=1,3 do
  local leaf=part(parent,name..'_Leaf'..i,Vector3.new(.24,.8,.48),
   CFrame.new(pos+Vector3.new(math.sin(i*2)*.45,(i-2)*length*.2,math.cos(i*2)*.3))
    *CFrame.Angles(0,0,math.rad((i-2)*35)),
   C3.fromRGB(47+i*4,78+i*3,47),Enum.Material.Grass,false,false,Enum.PartType.Ball)
  leaf.CastShadow=false
 end
 stem.CastShadow=false
end
local function addLamp(parent,name,pos,lights)
 local housing=part(parent,name,Vector3.new(2,.45,1.2),CFrame.new(pos),C3.fromRGB(40,48,43),Enum.Material.Metal,false,false)
 local bulb=part(parent,name..'_Bulb',Vector3.new(1.5,.14,.8),CFrame.new(pos+Vector3.new(0,-.3,0)),C3.fromRGB(179,195,153),Enum.Material.Neon,false,false)
 bulb.CastShadow=false
 local light=Instance.new('PointLight')
 light.Name=name..'_Glow';light.Color=C3.fromRGB(169,193,145);light.Brightness=.75
 light.Range=24;light.Shadows=false;light.Parent=bulb
 table.insert(lights,light)
 return housing
end
local function buildFrame(parent)
 local dark=C3.fromRGB(24,34,32)
 local iron=C3.fromRGB(40,52,48)
 local moss=C3.fromRGB(33,61,42)
 local glass=C3.fromRGB(78,111,108)
 local lights={}
 part(parent,'ConservatoryFloor',Vector3.new(112,2,88),CFrame.new(0,-1,0),C3.fromRGB(27,32,29),Enum.Material.Slate,false,true)
 part(parent,'WestFoundation',Vector3.new(2,14,88),CFrame.new(-56,7,0),dark,Enum.Material.Concrete,false,true)
 part(parent,'EastFoundation',Vector3.new(2,14,88),CFrame.new(56,7,0),dark,Enum.Material.Concrete,false,true)
 window(parent,'WestGlassWall',Vector3.new(-54.8,7,0),Vector3.new(.35,12,82))
 window(parent,'EastGlassWall',Vector3.new(54.8,7,0),Vector3.new(.35,12,82))
 for _,x in ipairs({-54,0,54}) do
  part(parent,'RoofRib',Vector3.new(.8,1,84),CFrame.new(x,15,0),iron,Enum.Material.Metal,false,false)
  part(parent,'Pillar',Vector3.new(1.4,14,1.4),CFrame.new(x,7,0),iron,Enum.Material.Metal,false,true)
 end
 for _,z in ipairs({-42,-21,0,21,42}) do
  part(parent,'RoofCrossbeam',Vector3.new(108,.8,1),CFrame.new(0,15,z),iron,Enum.Material.Metal,false,false)
 end
 for _,x in ipairs({-27,0,27}) do
  for _,z in ipairs({-31,-10,11,32}) do
   local pane=part(parent,'BrokenRoofPane',Vector3.new(25,.25,18),
    CFrame.new(x,14.45,z)*CFrame.Angles(0,0,math.rad((x+z)%2==0 and 0 or 1.5)),
    glass,Enum.Material.Glass,.82,false)
   pane.CastShadow=false
  end
 end
 part(parent,'NorthWallLeft',Vector3.new(40,14,2),CFrame.new(-36,7,-43),dark,Enum.Material.Concrete,false,true)
 part(parent,'NorthWallRight',Vector3.new(40,14,2),CFrame.new(36,7,-43),dark,Enum.Material.Concrete,false,true)
 part(parent,'NorthWindowLeft',Vector3.new(38,10,.3),CFrame.new(-36,9,-41.9),glass,Enum.Material.Glass,.82,false)
 part(parent,'NorthWindowRight',Vector3.new(38,10,.3),CFrame.new(36,9,-41.9),glass,Enum.Material.Glass,.82,false)
 part(parent,'SouthWallLeft',Vector3.new(40,14,2),CFrame.new(-36,7,43),dark,Enum.Material.Concrete,false,true)
 part(parent,'SouthWallRight',Vector3.new(40,14,2),CFrame.new(36,7,43),dark,Enum.Material.Concrete,false,true)
 part(parent,'SouthWindowLeft',Vector3.new(38,10,.3),CFrame.new(-36,9,41.9),glass,Enum.Material.Glass,.82,false)
 part(parent,'SouthWindowRight',Vector3.new(38,10,.3),CFrame.new(36,9,41.9),glass,Enum.Material.Glass,.82,false)
 for _,z in ipairs({-43,43}) do
  for _,x in ipairs({-16,-8,8,16}) do
   part(parent,'DoorFrame',Vector3.new(.7,14,1),CFrame.new(x,7,z),iron,Enum.Material.Metal,false,false)
  end
 end
 -- Low planter beds divide the glasshouse into three readable search lanes.
 for _,x in ipairs({-39,39}) do
  part(parent,'Planter',Vector3.new(8,1.5,56),CFrame.new(x,.1,0),C3.fromRGB(42,43,34),Enum.Material.Slate,false,true)
  for _,z in ipairs({-22,-10,3,16,28}) do
   vine(parent,'Overgrowth',Vector3.new(x,.9,z),2.4,math.rad((x+z)%40))
  end
 end
 for _,x in ipairs({-48,-28,28,48}) do
  vine(parent,'HangingRoot',Vector3.new(x,12,-13),4,math.rad(x/4))
  vine(parent,'HangingRoot',Vector3.new(x,11,22),3,math.rad(-x/5))
 end
 for _,pos in ipairs({Vector3.new(-31,12,-35),Vector3.new(31,12,-35),Vector3.new(-31,12,35),Vector3.new(31,12,35),Vector3.new(0,12,7)}) do
  addLamp(parent,'FlickeringGrowLight',pos,lights)
 end
 return lights
end
function Map.Build(world)
 local prior=world:FindFirstChild('ChapterTwoWorld')
 if prior then prior:Destroy() end
 world.Terrain:Clear()
 local map=Instance.new('Model');map.Name='ChapterTwoWorld';map.Parent=world
 local lights=buildFrame(map)
 local lighting=game:GetService('Lighting')
 lighting.ClockTime=.35;lighting.Brightness=1.1
 lighting.GlobalShadows=true;lighting.ShadowSoftness=.38;lighting.ExposureCompensation=.03
 lighting.Ambient=Color3.fromRGB(30,42,38)
 lighting.OutdoorAmbient=Color3.fromRGB(17,28,25)
 lighting.FogColor=Color3.fromRGB(25,39,34)
 lighting.FogStart=10;lighting.FogEnd=125
 lighting.EnvironmentDiffuseScale=.28;lighting.EnvironmentSpecularScale=.22
 local atmosphere=lighting:FindFirstChildOfClass('Atmosphere') or Instance.new('Atmosphere')
 atmosphere.Name='ChapterTwoAtmosphere';atmosphere.Density=.28
 atmosphere.Offset=.12;atmosphere.Haze=2.1;atmosphere.Glare=0
 atmosphere.Color=Color3.fromRGB(137,162,144)
 atmosphere.Decay=Color3.fromRGB(30,43,38);atmosphere.Parent=lighting
 local grade=lighting:FindFirstChild('ChapterTwoColorGrade') or Instance.new('ColorCorrectionEffect')
 grade.Name='ChapterTwoColorGrade';grade.Saturation=-.25;grade.Contrast=.16
 grade.TintColor=Color3.fromRGB(193,213,192);grade.Brightness=-.04;grade.Parent=lighting
 local spawn=Instance.new('SpawnLocation')
 spawn.Name='SpawnLocation';spawn.Size=Vector3.new(12,1,12)
 spawn.CFrame=CFrame.new(0,.6,34);spawn.Anchored=true
 spawn.Neutral=true;spawn.Duration=0;spawn.Enabled=true
 spawn.AllowTeamChangeOnTouch=false;spawn.Parent=map
 local fragments=Instance.new('Folder');fragments.Name='MemoryFragments';fragments.Parent=map
 local function addFragment(name,pos)
  local orb=part(fragments,name,Vector3.new(1.6,1.6,1.6),CFrame.new(pos),
   C3.fromRGB(161,207,171),Enum.Material.Neon,false,false,Enum.PartType.Ball)
  orb.CanQuery=false;orb.CastShadow=false
  local glow=Instance.new('PointLight');glow.Color=orb.Color;glow.Brightness=1.15;glow.Range=12;glow.Parent=orb
  prompt(orb,'RecoverMemory','RECOLHER','Fragmento de memória',true)
  return orb
 end
 addFragment('Fragment_01',Vector3.new(-31,2,24))
 addFragment('Fragment_02',Vector3.new(31,2,13))
 addFragment('Fragment_03',Vector3.new(0,2,-28))
 local console=part(map,'GeneratorConsole',Vector3.new(5,4,3),CFrame.new(0,2,-5),
  C3.fromRGB(28,45,38),Enum.Material.Metal,false,true)
 local screen=part(map,'GeneratorScreen',Vector3.new(2.4,.18,.1),CFrame.new(0,3,-3.42),
  C3.fromRGB(143,183,130),Enum.Material.Neon,false,false)
 screen.CastShadow=false
 local generatorPrompt=prompt(console,'RestartGenerator','REINICIAR','Gerador da estufa',false)
 local door=part(map,'ExitDoor',Vector3.new(14,13,1.2),CFrame.new(0,6.5,-42),
  C3.fromRGB(27,42,37),Enum.Material.Metal,false,true)
 part(map,'ExitDoorGlass',Vector3.new(5,8,.12),CFrame.new(0,7,-41.3),
  C3.fromRGB(75,108,98),Enum.Material.Glass,.43,false)
 local exitPrompt=prompt(door,'OpenExit','ABRIR','Porta de emergência',false)
 local sign=part(map,'ExitSign',Vector3.new(6,.8,.15),CFrame.new(0,13.1,-41.1),
  C3.fromRGB(100,140,99),Enum.Material.Neon,false,false)
 sign.CastShadow=false
 map:SetAttribute('Design','The abandoned greenhouse')
 map:SetAttribute('LightCount',#lights)
 return map
end
function Map.BuildMenuBackdrop()
 local world=workspace
 local old=world:FindFirstChild('LocalChapterTwoBackdrop')
 if old then old:Destroy() end
 local folder=Instance.new('Model');folder.Name='LocalChapterTwoBackdrop';folder.Parent=world
 local lights={}
 part(folder,'Floor',Vector3.new(44,1,50),CFrame.new(0,-.5,0),C3.fromRGB(24,30,28),Enum.Material.Slate,false,true)
 part(folder,'BackWall',Vector3.new(44,15,1),CFrame.new(0,7,-22),C3.fromRGB(24,37,34),Enum.Material.Concrete,false,true)
 part(folder,'LeftWall',Vector3.new(1,15,50),CFrame.new(-22,7,2),C3.fromRGB(24,37,34),Enum.Material.Concrete,false,true)
 part(folder,'RightWall',Vector3.new(1,15,50),CFrame.new(22,7,2),C3.fromRGB(24,37,34),Enum.Material.Concrete,false,true)
 for _,x in ipairs({-15,-8,0,8,15}) do
  part(folder,'WindowFrame',Vector3.new(.5,14,.5),CFrame.new(x,7,-21),C3.fromRGB(47,61,56),Enum.Material.Metal,false,false)
 end
 for _,x in ipairs({-12,0,12}) do
  window(folder,'FoggedGlass',Vector3.new(x,7,-21.1),Vector3.new(7.2,11,.25))
 end
 for _,x in ipairs({-20,-10,0,10,20}) do
  part(folder,'RoofBeam',Vector3.new(.6,.7,46),CFrame.new(x,14,1),C3.fromRGB(43,55,51),Enum.Material.Metal,false,false)
 end
 for _,z in ipairs({-14,0,14}) do
  part(folder,'RoofCrossbeam',Vector3.new(42,.6,.7),CFrame.new(0,14,z),C3.fromRGB(43,55,51),Enum.Material.Metal,false,false)
 end
 for _,pos in ipairs({Vector3.new(-17,3,-5),Vector3.new(17,3,-11),Vector3.new(-18,2,12)}) do
  part(folder,'OvergrownPlanter',Vector3.new(4,1.6,9),CFrame.new(pos),C3.fromRGB(42,43,34),Enum.Material.Slate,false,true)
  vine(folder,'DeadVine',pos+Vector3.new(0,1,0),2.2,0)
 end
 addLamp(folder,'DeadGrowLight',Vector3.new(0,12,-7),lights)
 local cameras=world:FindFirstChild('Cameras')
 if not cameras then cameras=Instance.new('Folder');cameras.Name='Cameras';cameras.Parent=world end
 local marker=cameras:FindFirstChild('MenuCamPart')
 if marker then marker:Destroy() end
 marker=Instance.new('Part');marker.Name='MenuCamPart'
 marker.Size=Vector3.new(1,1,1);marker.Anchored=true
 marker.CFrame=CFrame.lookAt(Vector3.new(0,6,18),Vector3.new(0,4,0))
 marker.Transparency=1;marker.CanCollide=false;marker.CanTouch=false;marker.CanQuery=false
 marker.Parent=cameras
 return folder
end
return Map
