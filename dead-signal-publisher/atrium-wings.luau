-- Dead Signal: three new ORIGINAL Gothic rooms after the right service vestibule.
-- Coordinates: right vestibule (22,0,115) -> vaulted hall -> halo hall -> stained-glass chapel.
-- Intentionally low-complexity structural geometry; all primary routes use solid flooring.
do
 local wing=Instance.new("Folder");wing.Name="CathedralWing";wing.Parent=map
 local function group(name)
  local f=Instance.new("Folder");f.Name=name;f.Parent=wing;return f
 end
 local hall=group("01_FloodedVault")
 local shrine=group("02_HaloChamber")
 local chapel=group("03_GlassChapel")
 local ivory=Color3.fromRGB(169,177,183)
 local limestone=Color3.fromRGB(132,145,160)
 local charcoal=Color3.fromRGB(54,64,79)
 local tile=Color3.fromRGB(115,132,147)
 local pale=Color3.fromRGB(210,220,222)
 local gold=Color3.fromRGB(151,143,119)
 local function block(parent,name,x,y,z,sx,sy,sz,color,material,solid)
  return box(name,x,y,z,sx,sy,sz,color or limestone,material or Enum.Material.Slate,solid,parent)
 end
 local function beam(parent,name,a,b,thickness,color)
  return rod(parent,name,a,b,thickness,color or ivory,Enum.Material.Concrete,false)
 end
 local function arch(parent,name,cx,cz,width,yBase,height,color)
  -- Pointed Gothic arch with legible angular ribs; opening below remains unobstructed.
  local left=Vector3.new(cx-width*.5,yBase,cz)
  local right=Vector3.new(cx+width*.5,yBase,cz)
  local peak=Vector3.new(cx,yBase+height,cz)
  beam(parent,name.."L",left,peak,.75,color)
  beam(parent,name.."R",right,peak,.75,color)
  local cap=block(parent,name.."Keystone",cx,yBase+height-.4,cz,1.2,1.5,1.3,color)
  cap.CanCollide=false;cap.CanQuery=false
 end
 local function light(parent,x,y,z,color,power,range)
  local source=block(parent,"LightMount",x,y,z,.6,.6,.6,color,Enum.Material.Glass,false)
  source.Transparency=1
  local l=Instance.new("PointLight");l.Name="GothicWingLight";l.Color=color;l.Brightness=power;l.Range=range;l.Shadows=false;l.Parent=source
 end
 -- Open only the right vestibule's rear wall. Left vestibule remains unchanged.
 for _,p in ipairs(architecture:GetChildren()) do
  if p.Name=="VestibuleRear" and math.abs(p.Position.X-22)<1 and math.abs(p.Position.Z-115)<1 then p:Destroy() end
 end
 -- Short framed, covered connector to avoid a missing floor at z=115..124.
 block(hall,"WingConnectorFloor",22,-.52,119,12,1.1,12,limestone)
 for _,x in ipairs({15,29}) do block(hall,"ConnectorWall",x,6,118,.9,13,14,charcoal) end
 block(hall,"ConnectorLintel",22,13,118,14,2,14,limestone)
 -- ROOM 1: flooded Gothic arcade, evocative of the white stone reference.
 block(hall,"VaultFloor",22,-.58,169,70,1.1,94,limestone)
 for _,x in ipairs({-13,57}) do
  block(hall,"VaultOuterWall",x,29,169,2,59,94,Color3.fromRGB(116,128,145))
  for z=136,202,16 do
   block(hall,"VaultPillar",x-(x<22 and -3 or 3),16,z,3.4,32,3.4,ivory,Enum.Material.Marble)
   block(hall,"VaultPillarBase",x-(x<22 and -3 or 3),1.5,z,5.8,3,5.8,limestone)
   block(hall,"VaultCapital",x-(x<22 and -3 or 3),31.5,z,6.2,2.4,6.2,pale,Enum.Material.Marble,false)
  end
 end
 -- Entrance and exit are framed above/around a 12-stud-wide centre opening.
 for _,z in ipairs({123,215}) do
  for _,x in ipairs({-1,45}) do block(hall,"VaultPorticoWall",x,22,z,44,44,2,limestone) end
  block(hall,"VaultPortalHeader",22,37,z,12,17,2,limestone)
  arch(hall,"VaultPortal",22,z-1,13,13,10,pale)
 end
 -- Repeating overhead pointed rib arches, supported by cross-vaulted ceilings.
 for z=135,205,14 do
  arch(hall,"NaveRib",22,z,61,34,19,pale)
  for _,dx in ipairs({-17,17}) do
   block(hall,"CeilingNiche",22+dx,56,z,25,1.5,11,charcoal)
  end
  beam(hall,"VaultLongitudinalRib",Vector3.new(22,53,z-6),Vector3.new(22,53,z+6),.6,pale)
 end
 -- Shallow real Terrain water only in side channels, not over the central walkway.
 local terra=W.Terrain
 terra.WaterColor=Color3.fromRGB(83,111,129)
 terra.WaterTransparency=.52;terra.WaterReflectance=.25
 terra.WaterWaveSize=.05;terra.WaterWaveSpeed=1.5
 for _,x in ipairs({1,43}) do
  block(hall,"WaterChannelBed",x,-1,170,13,.5,70,charcoal)
  block(hall,"ChannelInsideCurb",x<22 and 9 or 35,.43,170,.55,.9,70,pale)
  block(hall,"ChannelOutsideCurb",x<22 and -7 or 51,.43,170,.55,.9,70,pale)
  terra:FillBlock(CFrame.new(x,-.33,170),Vector3.new(11,2,68),Enum.Material.Water)
 end
 -- Wide dry central footpath and subtly wet weathered tiles.
 block(hall,"CentralMarbleWalk",22,.05,170,21,.22,90,Color3.fromRGB(128,140,150),Enum.Material.Marble)
 for z=130,206,7 do
  block(hall,"WalkJoint",22,.171,z,20,.018,.07,charcoal,Enum.Material.Slate,false)
 end
 for _,z in ipairs({144,179,202}) do light(hall,22,49,z,Color3.fromRGB(171,199,231),.9,35) end
 marker("VaultedHall",Vector3.new(22,3.5,166))
 -- ROOM 2: round ceremonial hall. The statue is loaded from the REAL Roblox avatar.
 block(shrine,"ShrineFloor",22,-.57,262,80,1.1,82,Color3.fromRGB(175,181,188),Enum.Material.Marble)
 for _,x in ipairs({-18,62}) do
  block(shrine,"ShrineWall",x,31,262,2,63,82,limestone)
 end
 for _,z in ipairs({221,303}) do
  for _,x in ipairs({-4,48}) do block(shrine,"ShrineEntranceWall",x,31,z,42,63,1.8,limestone) end
  block(shrine,"ShrineGateUpper",22,42,z,14,41,1.8,limestone)
  arch(shrine,"ShrineDoorRib",22,z,14,16,13,pale)
 end
 -- Twelve-sided arcade impression from eight tall tapered columns.
 for i=0,7 do
  local a=i*math.pi/4
  local x=22+math.cos(a)*30
  local z=263+math.sin(a)*29
  block(shrine,"CircularPillar",x,20,z,3.5,40,3.5,pale,Enum.Material.Marble)
  block(shrine,"PillarFoot",x,1.5,z,6,3,6,limestone)
  block(shrine,"PillarCrown",x,41,z,6,3,6,pale,Enum.Material.Marble,false)
  local nextA=(i+1)*math.pi/4
  beam(shrine,"CircularCrownArch",Vector3.new(x,43,z),Vector3.new(22+math.cos(nextA)*30,43,263+math.sin(nextA)*29),.65,ivory)
 end
 -- Inlaid stone radial lines in floor remain nonblocking.
 for i=0,15 do
  local a=i*math.pi/8
  beam(shrine,"RadialFloorInlay",Vector3.new(22,.035,263),Vector3.new(22+math.cos(a)*25,.035,263+math.sin(a)*24),.09,gold)
 end
 -- Avatar pedestal: no generic humanoid is substituted for ch_ckz2n.
 local plinth=block(shrine,"AvatarPedestal",22,2.3,264,11,4.6,10,Color3.fromRGB(158,168,178),Enum.Material.Marble)
 block(shrine,"PedestalCap",22,4.76,264,13,.35,12,pale,Enum.Material.Marble)
 local socket=Instance.new("Folder");socket.Name="AvatarStatueAnchor";socket.Parent=shrine
 socket:SetAttribute("Username","ch_ckz2n")
 socket:SetAttribute("PedestalTopY",4.94)
 socket:SetAttribute("CenterX",22);socket:SetAttribute("CenterZ",264)
 socket:SetAttribute("Status","Pending")
 -- Decorative carved stone rays behind the avatar, never a replacement figure.
 for i=0,11 do
  local a=(i/11)*math.pi
  beam(shrine,"HaloStoneRay",Vector3.new(22,21.8,278),Vector3.new(22+math.cos(a)*12,21.8+math.sin(a)*9,278),.4,pale)
 end
 light(shrine,22,36,278,Color3.fromRGB(194,209,233),1.4,45)
 for _,x in ipairs({-8,52}) do light(shrine,x,24,263,Color3.fromRGB(145,169,207),.6,32) end
 marker("HaloChamber",Vector3.new(22,3.5,245))
 -- Connection to chapel remains on the same floor, wide and readable.
 block(chapel,"ChapelConnectorFloor",22,-.55,313,15,1,18,ivory,Enum.Material.Marble)
 for _,x in ipairs({14,30}) do block(chapel,"ChapelConnectorRail",x,4,313,1,8,18,limestone) end
 block(chapel,"ChapelConnectorRoof",22,28,313,17,1,18,limestone)
 -- ROOM 3: grand curved stair, sanctuary, rose windows and falling blue light.
 block(chapel,"ChapelFloor",22,-.55,368,83,1.1,106,Color3.fromRGB(166,177,191),Enum.Material.Marble)
 for _,x in ipairs({-20,64}) do block(chapel,"ChapelNaveWall",x,35,368,2,71,108,limestone) end
 for _,x in ipairs({-5,49}) do block(chapel,"ChapelGateWall",x,32,316,31,64,2,limestone) end
 block(chapel,"ChapelEntranceUpper",22,49,316,25,30,2,pale)
 arch(chapel,"ChapelEntryArch",22,315,18,19,14,pale)
 -- Loft cornice, repeated window columns and arched ceiling ribs.
 for _,x in ipairs({-16,60}) do
  for z=330,411,18 do
   block(chapel,"ChapelFlutedColumn",x,30,z,3,60,3,pale,Enum.Material.Marble)
   block(chapel,"ColumnFoot",x,1.3,z,5,2.6,5,limestone)
   block(chapel,"ColumnCrown",x,61,z,5,2,5,pale,Enum.Material.Marble,false)
  end
  block(chapel,"UpperBalcony",x<22 and -10 or 54,17,371,9,1.1,95,ivory)
 end
 for z=328,408,16 do arch(chapel,"ChapelRib",22,z,72,51,16,pale) end
 -- Sweeping ascending stair; 24 even steps, no invisible teleport.
 for i=1,24 do
  local z=341+(i-.5)*1.35
  local y=i*.49-.245
  local half=12+(i/24)*2
  block(chapel,"GrandStairTread",22,y,z,half*2,.49,1.37,ivory,Enum.Material.Marble)
  local trim=block(chapel,"GrandStairNosing",22,y+.249,z-.56,half*2,.04,.18,pale,Enum.Material.Marble,false)
 end
 local landingHeight=11.76
 block(chapel,"UpperSanctuaryPlatform",22,landingHeight-.5,393,31,1,53,ivory,Enum.Material.Marble)
 for _,side in ipairs({-1,1}) do
  local previous=nil
  for i=0,12 do
   local t=i/12
   local pos=Vector3.new(22+side*(12+t*2),1+t*11.76,341+t*32)
   if previous then beam(chapel,"CurvedStairHandrail",previous+Vector3.new(0,3,0),pos+Vector3.new(0,3,0),.32,pale) end
   beam(chapel,"StairBaluster",pos,pos+Vector3.new(0,3,0),.24,ivory)
   previous=pos
  end
 end
 -- Three tall luminous tracery windows, built as original transparent geometry.
 for _,wx in ipairs({-3,22,47}) do
  block(chapel,"WindowFrameSide",wx-7,38,420,.7,47,.8,pale,Enum.Material.Marble)
  block(chapel,"WindowFrameSide",wx+7,38,420,.7,47,.8,pale,Enum.Material.Marble)
  block(chapel,"WindowHead",wx,62,420,14,1,.8,pale,Enum.Material.Marble)
  for band=0,2 do
   local pane=block(chapel,"FrostedBlueStainedGlass",wx,23+band*13,421,13,12,.3,Color3.fromRGB(170+band*7,209,236),Enum.Material.Glass,false)
   pane.Transparency=.35;pane.CastShadow=false
   block(chapel,"TraceryHorizontal",wx,16+band*13,420,14,.45,.8,pale,Enum.Material.Marble,false)
  end
  for _,offset in ipairs({-4,0,4}) do
   block(chapel,"WindowMullion",wx+offset,38,419.5,.4,45,.5,pale,Enum.Material.Marble,false)
  end
  arch(chapel,"WindowGothicPeak",wx,420,14,62,8,pale)
 end
 block(chapel,"WindowRearMasonry",22,7,420,83,14,2,limestone)
 block(chapel,"RearTopMasonry",22,69,420,83,8,2,limestone)
 -- Slate and blue runner carpet; side flowerbeds preserve the staircase route.
 block(chapel,"BlueStairRunner",22,.13,335,7,.06,13,Color3.fromRGB(50,83,138),Enum.Material.Fabric,false)
 for i=1,24 do
  local z=341+(i-.5)*1.35
  local y=i*.49+.025
  block(chapel,"StairRunnerStep",22,y,z,7,.02,1.26,Color3.fromRGB(51,84,138),Enum.Material.Fabric,false)
 end
 for i=1,24 do
  local side=i%2==0 and 1 or -1
  local x=22+side*rng:NextNumber(22,33)
  local z=rng:NextNumber(329,393)
  local bouquet=block(chapel,"PaleBloomBouquet",x,1.1,z,2.3,2,2.5,Color3.fromRGB(191,198,220),Enum.Material.Grass,false)
  bouquet.Shape=Enum.PartType.Ball;bouquet.Transparency=.15
 end
 for _,x in ipairs({-8,52}) do light(chapel,x,45,384,Color3.fromRGB(191,210,245),1.1,54) end
 marker("GlassChapel",Vector3.new(22,15.2,397))
 wing:SetAttribute("Expansion","gothic-rooms-v1")
 wing:SetAttribute("StatueUsername","ch_ckz2n")
 wing:SetAttribute("WaterChannelCount",2)
end
