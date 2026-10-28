local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Maze=require(RS.Shared.Maze)
local World={Targets={},Origins={},Spawns={},EnemySpawns={}}
local palettes={Color3.fromRGB(38,62,51),Color3.fromRGB(72,53,38),Color3.fromRGB(43,57,65),Color3.fromRGB(36,58,29),Color3.fromRGB(42,49,66),Color3.fromRGB(63,37,27),Color3.fromRGB(42,58,68)}
function World.part(parent,name,size,cf,color,material,collide)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or Color3.fromRGB(51,57,54);p.Material=material or Enum.Material.Concrete;p.Anchored=true;p.CanCollide=collide~=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
function World.label(p,text,size)
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(700,180);gui.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=Color3.fromRGB(222,229,212);t.Font=Enum.Font.Code;t.TextScaled=true;t.TextWrapped=true;t.Parent=gui
 local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize=size or 48;limit.Parent=t
 return t
end
local function block(parent,name,pos,size,color,material,collide) return World.part(parent,name,size,CFrame.new(pos),color,material,collide) end
function World.target(folder,sector,id,pos,title,color)
 local old=World.Targets[sector..":"..id];if old then old:Destroy();if World.Index and World.Index:FindFirstChild(sector..":"..id) then World.Index[sector..":"..id]:Destroy() end end
 local p=block(folder,id,pos,Vector3.new(2.6,3,0.8),Color3.fromRGB(33,40,40),Enum.Material.Metal,true)
 p:SetAttribute("TargetId",sector..":"..id);p:SetAttribute("Sector",sector);p:SetAttribute("Action",id);p:SetAttribute("Title",title)
 local lamp=block(p,"Indicator",pos+Vector3.new(0,-0.6,0.5),Vector3.new(1,0.45,0.12),color or Color3.fromRGB(63,174,189),Enum.Material.Neon,false)
 lamp.CastShadow=false
 local display=World.label(p,title,28);display.Name="Readout"
 local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Mão azul / E";prompt.ObjectText=title;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=true;prompt.HoldDuration=0.3;prompt.Parent=p
 World.Targets[sector..":"..id]=p
 if World.Index then local ref=Instance.new("ObjectValue");ref.Name=sector..":"..id;ref.Value=p;ref.Parent=World.Index end
 return p
end
function World.light(folder,pos,color)
 local fixture=block(folder,"Luminária",pos,Vector3.new(8,.2,1),color or Color3.fromRGB(192,217,205),Enum.Material.Neon,false)
 local l=Instance.new("PointLight");l.Brightness=1.3;l.Range=38;l.Color=fixture.Color;l.Shadows=false;l.Parent=fixture
 return fixture
end
function World.createEnemy(parent,at)
 local template=game:GetService("ServerStorage"):FindFirstChild("BrambleTemplate")
 if template and template:IsA("Model") and template.PrimaryPart then
  local imported=template:Clone();imported.Name="Bramble_Imported"
  for _,item in ipairs(imported:GetDescendants()) do
   if item:IsA("LuaSourceContainer") then item:Destroy()
   elseif item:IsA("BasePart") then item.Anchored=true;item.CanCollide=false;item.CanTouch=false end
  end
  local size=imported:GetExtentsSize();if size.Y>0 then imported:ScaleTo(imported:GetScale()*11/size.Y) end
  imported.Parent=parent;imported:PivotTo(CFrame.new(at));return imported
 end
 -- Original procedural placeholder. No Creator Store scripts execute at runtime.
 local m=Instance.new("Model");m.Name="Bramble_Placeholder";m.Parent=parent
 local core=block(m,"Root",at,Vector3.new(3,4,2),Color3.fromRGB(41,47,24),Enum.Material.Wood,false);m.PrimaryPart=core
 local head=block(m,"Head",at+Vector3.new(0,3,0),Vector3.new(4,3.6,3),Color3.fromRGB(48,61,31),Enum.Material.Wood,false);head.Shape=Enum.PartType.Ball
 for _,x in ipairs({-1.1,1.1}) do local eye=block(m,"Eye",at+Vector3.new(x,3.5,-1.45),Vector3.new(.55,.55,.2),Color3.fromRGB(237,214,135),Enum.Material.Neon,false);eye.Shape=Enum.PartType.Ball end
 for _,x in ipairs({-1.7,1.7}) do
  block(m,"Arm",at+Vector3.new(x,0,-.4),Vector3.new(.6,6,.7),Color3.fromRGB(54,62,31),Enum.Material.Wood,false)
  block(m,"Leg",at+Vector3.new(x*.6,-3,0),Vector3.new(.8,4,.8),Color3.fromRGB(31,37,18),Enum.Material.Wood,false)
 end
 for i=1,7 do local spike=block(m,"Thorn",at+Vector3.new((i-4)*.7,5,0),Vector3.new(.25,2+(i%3),.25),Color3.fromRGB(64,74,36),Enum.Material.Wood,false);spike.CFrame*=CFrame.Angles(0,0,(i-4)*.12) end
 return m
end
function World.build()
 local previous=workspace:FindFirstChild("BrambleWorld")
 if previous and previous:GetAttribute("Prebuilt") then
  for sector=1,7 do local o=Vector3.new((sector-1)*650,0,-100);World.Origins[sector]=o;World.Spawns[sector]=o+Vector3.new(0,4,0);World.EnemySpawns[sector]=o+Vector3.new(0,5,-210) end
  World.Spawns[4]=World.Origins[4]+Vector3.new(-63,4,-15);World.EnemySpawns[4]=World.Origins[4]+Vector3.new(-63,5,-15)
  World.Index=previous:FindFirstChild("TargetIndex")
  for _,item in ipairs(previous:GetDescendants()) do local id=item:GetAttribute("TargetId");if id then World.Targets[id]=item end end
  workspace:SetAttribute("BrambleWorldReady",true);return World
 end
 if previous then previous:Destroy() end
 local root=Instance.new("Folder");root.Name="BrambleWorld";root.Parent=workspace
 World.Index=Instance.new("Folder");World.Index.Name="TargetIndex";World.Index.Parent=root
 local lobby=Instance.new("Folder");lobby.Name="MenuSet";lobby.Parent=root
 block(lobby,"Stage",Vector3.new(0,-1,80),Vector3.new(110,2,90),Color3.fromRGB(22,24,24),Enum.Material.Concrete)
 block(lobby,"BackWall",Vector3.new(0,15,50),Vector3.new(110,30,2),Color3.fromRGB(25,29,27))
 World.light(lobby,Vector3.new(10,14,65),Color3.fromRGB(183,45,20));World.light(lobby,Vector3.new(-10,10,80),Color3.fromRGB(43,99,110))
 World.createEnemy(lobby,Vector3.new(6,6,67))
 local spawn=Instance.new("SpawnLocation");spawn.Name="SafeSpawn";spawn.Size=Vector3.new(8,1,8);spawn.CFrame=CFrame.new(0,1,100);spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Parent=lobby
 for sector,info in ipairs(Config.Sectors) do
  local o=Vector3.new((sector-1)*650,0,-100);World.Origins[sector]=o;World.Spawns[sector]=o+Vector3.new(0,4,0);World.EnemySpawns[sector]=o+Vector3.new(0,5,-210)
  local f=Instance.new("Folder");f.Name=string.format("%02d_%s",sector,info.Name);f.Parent=root;local color=palettes[sector]
  for z=0,8 do
   local tile=block(f,"Floor",o+Vector3.new(0,-1,-z*30),Vector3.new(160,2,30),Color3.fromRGB(78,82,75),Enum.Material.Concrete)
   block(f,"Stripe",tile.CFrame.Position+Vector3.new(0,1.02,0),Vector3.new(1,.04,30),Color3.fromRGB(151,115,43),Enum.Material.Metal,false)
   block(f,"Beam",o+Vector3.new(0,17,-z*30),Vector3.new(160,1,1),Color3.fromRGB(34,40,39),Enum.Material.Metal,false)
   World.light(f,o+Vector3.new(0,16,-z*30))
   for _,side in ipairs({-1,1}) do
    block(f,"Pipe",o+Vector3.new(side*77,12,-z*30),Vector3.new(.7,.7,30),Color3.fromRGB(78,88,86),Enum.Material.Metal,false)
    block(f,"Skirting",o+Vector3.new(side*79,3,-z*30),Vector3.new(.2,.5,30),Color3.fromRGB(116,54,29),Enum.Material.Metal,false)
   end
  end
  block(f,"Ceiling",o+Vector3.new(0,19,-120),Vector3.new(160,1,270),Color3.fromRGB(17,23,23))
  for _,side in ipairs({-1,1}) do block(f,"Wall",o+Vector3.new(side*80,9,-120),Vector3.new(2,20,270),color) end
  block(f,"EndWall",o+Vector3.new(0,9,-255),Vector3.new(160,20,2),color)
  block(f,"EntryWall",o+Vector3.new(0,9,15),Vector3.new(160,20,2),color)
  local sign=block(f,"SectorSign",o+Vector3.new(0,12,-25),Vector3.new(30,4,.2),color,Enum.Material.Metal,false);World.label(sign,info.Name,40)
  World.target(f,sector,"protocol",o+Vector3.new(5,4,-8),"LER PROTOCOLO",Color3.fromRGB(213,183,118))
  World.target(f,sector,"exit",o+Vector3.new(0,4,-244),if sector==7 then "ENTRAR NO ELEVADOR" else "PRÓXIMO SETOR",Color3.fromRGB(198,125,47))
  local function target(id,x,z,title,c) return World.target(f,sector,id,o+Vector3.new(x,4,z),title,c) end
  if sector==1 then
   for _,side in ipairs({-1,1}) do
    for z=45,195,50 do
     block(f,"Partition",o+Vector3.new(side*35,6,-z),Vector3.new(2,12,28),color)
     block(f,"Desk",o+Vector3.new(side*55,2,-z+4),Vector3.new(20,4,5),Color3.fromRGB(65,48,31),Enum.Material.Wood)
    end
   end
   target("card",-55,-30,"CRACHÁ");target("fuse",48,-38,"FUSÍVEL");target("power",40,-70,"QUADRO PRINCIPAL")
   target("socket1",-44,-105,"TERMINAL 1 / AZUL",Color3.fromRGB(35,100,230));target("socket2",45,-135,"TERMINAL 2 / VERMELHA",Color3.fromRGB(220,40,25))
   for i=1,3 do target("bloom"..i,-50+(i-1)*50,-175,"PODAR FLOR "..i,Color3.fromRGB(143,91,47)) end
   target("socket3",40,-207,"TERMINAL 3 / AZUL");target("release",-30,-225,"LIBERAÇÃO / VERMELHA")
  elseif sector==2 then
   for _,x in ipairs({-65,-40,40,65}) do for z=55,210,25 do block(f,"Bookcase",o+Vector3.new(x,5,-z),Vector3.new(9,10,3),Color3.fromRGB(52,36,23),Enum.Material.Wood)
    for shelf=1,3 do for book=1,5 do block(f,"Book",o+Vector3.new(x-3+book, shelf*2.5,-z-2),Vector3.new(.6,2,1),Color3.fromHSV((book+shelf)*.04,.4,.35),Enum.Material.Fabric,false) end end
   end end
   target("page1",-65,-42,"PÁGINA 1");target("page2",65,-142,"PÁGINA 2");target("page3",-36,-212,"PÁGINA 3")
   for i=1,4 do target("digit"..i,-15+(i-1)*10,-224,"DÍGITO "..i) end;target("safe",0,-235,"ABRIR COFRE")
  elseif sector==3 then
   for _,side in ipairs({-1,1}) do for z=50,220,35 do block(f,"Generator",o+Vector3.new(side*58,4,-z),Vector3.new(12,8,12),Color3.fromRGB(34,42,45),Enum.Material.Metal)
    local motor=block(f,"Motor",o+Vector3.new(side*58,10,-z),Vector3.new(5,8,5),Color3.fromRGB(85,72,43),Enum.Material.Metal,false);motor.Shape=Enum.PartType.Cylinder
   end end
   local names={"ENTRADA","DESVIO","RETORNO","RESERVA"};for i=1,4 do target("valve"..i,-45+(i-1)*30,-92,names[i]) end
   target("pressure",0,-150,"PRESSÃO");for i=1,3 do target("cell"..i,if i%2==1 then -70 else 70,-35-i*45,"CÉLULA "..i) end;target("start",0,-225,"PARTIDA / VERMELHA")
  elseif sector==4 then
   local cells,leaves=Maze.generate(10,16,58817);local spacing=14
   for y=1,16 do for x=1,10 do
    local c=o+Vector3.new(-63+(x-1)*spacing,4,-15-(y-1)*spacing)
    if cells[y][x][1] then block(f,"Hedge",c+Vector3.new(0,0,7),Vector3.new(14,8,1),color,Enum.Material.Grass) end
    if cells[y][x][4] then block(f,"Hedge",c+Vector3.new(-7,0,0),Vector3.new(1,8,14),color,Enum.Material.Grass) end
    if y==16 then block(f,"Hedge",c+Vector3.new(0,0,-7),Vector3.new(14,8,1),color,Enum.Material.Grass) end
    if x==10 then block(f,"Hedge",c+Vector3.new(7,0,0),Vector3.new(1,8,14),color,Enum.Material.Grass) end
   end end
   for i=1,6 do local cell=leaves[math.floor((i-1)*#leaves/6)+1];target("seed"..i,-63+(cell[1]-1)*14,-15-(cell[2]-1)*14,"SEMENTE "..i,Color3.fromRGB(223,151,55)) end
   World.Spawns[sector]=o+Vector3.new(-63,4,-15);World.EnemySpawns[sector]=o+Vector3.new(-63,5,-15)
   local exit=World.Targets[sector..":exit"];local delta=o+Vector3.new(63,4,-225)-exit.CFrame.Position;exit.CFrame+=delta;for _,part in ipairs(exit:GetChildren()) do if part:IsA("BasePart") then part.CFrame+=delta end end
   target("protocol",-60,-11,"LER PROTOCOLO")
  elseif sector==5 then
   for i=1,4 do target("tone"..i,-30+(i-1)*20,-95,"TOM "..i) end
   for i=1,9 do local p=target("lamp"..i,-12+((i-1)%3)*12,-205,"MATRIZ "..i);local shift=Vector3.new(0,math.floor((i-1)/3)*5,0);p.CFrame+=shift;for _,part in ipairs(p:GetChildren()) do if part:IsA("BasePart") then part.CFrame+=shift end end end
   for _,x in ipairs({-60,60}) do for z=60,210,25 do block(f,"TapeRack",o+Vector3.new(x,5,-z),Vector3.new(10,10,5),Color3.fromRGB(25,30,34),Enum.Material.Metal) end end
  elseif sector==6 then
   local rootBall=block(f,"RootCore",o+Vector3.new(0,4,-135),Vector3.new(24,8,24),Color3.fromRGB(49,29,18),Enum.Material.Wood);rootBall.Shape=Enum.PartType.Ball
   for i=1,12 do local a=i*math.pi/6;local vine=block(f,"Root",o+Vector3.new(math.cos(a)*25,1,-135+math.sin(a)*25),Vector3.new(55,1.5,2),Color3.fromRGB(56,36,23),Enum.Material.Wood,false);vine.CFrame*=CFrame.Angles(0,-a,0) end
   for i=1,4 do local x=if i%2==1 then -55 else 55;local z=-25-i*45;target("isolate"..i,x,z,"ISOLAR "..i.." / AZUL");target("cut"..i,x,z-10,"CORTAR "..i.." / VERMELHA",Color3.fromRGB(225,35,26)) end
  else
   for i=1,4 do target("fuse"..i,if i%2==1 then -65 else 65,-25-i*42,"FUSÍVEL "..i) end
   for i=1,3 do local x=-25+(i-1)*25;target("angle"..i,x,-210,"ANTENA "..i)
    block(f,"Mast",o+Vector3.new(x,7,-220),Vector3.new(.7,14,.7),Color3.fromRGB(91,102,108),Enum.Material.Metal,false)
    local dish=block(f,"Antenna"..i,o+Vector3.new(x,13,-220),Vector3.new(12,12,2),Color3.fromRGB(116,126,128),Enum.Material.Metal,false);dish.Shape=Enum.PartType.Cylinder;dish.CFrame*=CFrame.Angles(0,0,math.pi/2);dish:SetAttribute("Antenna",i);dish:SetAttribute("Sector",sector)
   end;target("master",0,-233,"CHAVE MESTRE / VERMELHA",Color3.fromRGB(225,35,26))
  end
 end
 workspace:SetAttribute("BrambleWorldReady",true)
 return World
end
return World
