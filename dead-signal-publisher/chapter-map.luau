-- Signalworks: original geometry. No third-party executable content or unreviewed audio.
local map = Instance.new("Model")
map.Name = "SignalworksChapter01"
map:SetAttribute("BuildId", BUILD_ID)
map.Parent = Workspace
local V = Vector3.new
local C = Color3.fromRGB
local palette = {C(66,89,87), C(126,102,69), C(78,91,103), C(109,76,65)}
local function model(name, parent)
    local m = Instance.new("Model"); m.Name = name; m.Parent = parent or map
    return m
end
local function box(parent, name, x,y,z, sx,sy,sz, color, material, collide)
    return part(parent,name,V(sx,sy,sz),CFrame.new(x,y,z),color or C(67,70,69),material or Enum.Material.Metal,collide)
end
local function tag(p,t,attrs)
    for k,v in pairs(attrs or {}) do p:SetAttribute(k,v) end
    CollectionService:AddTag(p,t); return p
end
local function prompt(p, action, text, attrs)
    local q=Instance.new("ProximityPrompt"); q.ActionText=text; q.ObjectText=p.Name
    q.KeyboardKeyCode=Enum.KeyCode.F; q.HoldDuration=0.15; q.MaxActivationDistance=9
    q.RequiresLineOfSight=true; q.Parent=p
    tag(q,"DeadSignalInteraction",attrs); q:SetAttribute("ActionId",action)
    return q
end
local function sign(parent,text,x,y,z,sx,sy)
    local p=box(parent,"Wayfinding",x,y,z,sx or 12,sy or 3,0.15,C(26,35,37),Enum.Material.SmoothPlastic,false)
    -- Text on both sides so direction is readable on the return journey.
    addText(p,text,Enum.NormalId.Front,C(231,218,185))
    addText(p,text,Enum.NormalId.Back,C(231,218,185))
    return p
end
local function lamp(parent,x,y,z,col,node)
    box(parent,"LuminaireHousing",x,y+0.2,z,7,0.5,2,C(25,31,32))
    local p=box(parent,"Luminaire",x,y,z,6,0.12,1.2,col,Enum.Material.Neon,false)
    CollectionService:AddTag(p,"DeadSignalLocalLight")
    local l=Instance.new("PointLight"); l.Range=28; l.Brightness=1.3; l.Color=col; l.Shadows=false; l.Parent=p
    if node then p:SetAttribute("LightPowerNode",node); l.Enabled=false; p.Material=Enum.Material.Glass end
    return p
end
local function boundary(parent,z,width,height)
    for _,side in ipairs({-1,1}) do
        box(parent,"WallPier",side*(width/4+3.5),height/2,z,width/2-7,height,1.2,C(75,79,76),Enum.Material.Concrete)
    end
    box(parent,"PortalLintel",0,13+(height-13)/2,z,14,height-13,1.2,C(56,64,62))
    box(parent,"PortalTrimL",-7.5,6.5,z,1,13,2,C(39,47,47))
    box(parent,"PortalTrimR",7.5,6.5,z,1,13,2,C(39,47,47))
end
local roomDefs={
    {"01_Reception",0,48,44,18,"SIGNALWORKS / RECEPÇÃO",1},
    {"02_Atrium",48,120,76,32,"NÚCLEO CENTRAL / 1978",2},
    {"03_Induction",120,158,40,18,"01 / INDUÇÃO ELÉTRICA",3},
    {"04_Maintenance",158,218,32,16,"MANUTENÇÃO / ACESSO TÉCNICO",1},
    {"05_Accumulators",218,266,52,22,"02 / ACUMULADORES",2},
    {"06_Assembly",266,366,88,34,"MONTAGEM / LINHA DE ECOS",1},
    {"07_Distribution",366,418,62,25,"03 / DISTRIBUIÇÃO — LIMITE 100 U",3},
    {"08_Archive",418,458,46,21,"ARQUIVO / CANAL 04",2},
    {"09_Blackout",458,518,38,20,"RETORNO / REFRIGERAÇÃO",3},
    {"10_Escape",518,608,46,22,"LOGÍSTICA / SAÍDA DE EMERGÊNCIA",4},
    {"11_Relay",608,648,38,20,"DESCARGA / NÃO PARE",4},
    {"12_Sanctuary",648,694,48,24,"ESTAÇÃO DE DESCIDA",1},
}
local rooms={}
for i,d in ipairs(roomDefs) do
    local name,a,b,w,h,title,pi=table.unpack(d)
    local r=model(name); rooms[i]=r; r:SetAttribute("SectorIndex",i)
    box(r,"Slab",0,-1,(a+b)/2,w,2,b-a,C(62,65,62),Enum.Material.Concrete)
    box(r,"Roof",0,h+0.5,(a+b)/2,w,1,b-a,C(35,41,42))
    for _,side in ipairs({-1,1}) do
        box(r,"StructuralWall",side*w/2,h/2,(a+b)/2,1.5,h,b-a,C(100,104,96),Enum.Material.Concrete)
        box(r,"PaintedDado",side*(w/2-0.85),3,(a+b)/2,0.25,6,b-a,palette[pi])
        box(r,"PipeMain",side*(w/2-2),h-4,(a+b)/2,0.8,0.8,b-a-3,C(92,78,57))
        for z=a+6,b-3,14 do
            box(r,"WallRib",side*(w/2-1.1),h/2,z,0.6,h,0.8,C(45,52,51))
            box(r,"PipeBracket",side*(w/2-1.7),h-4,z,1.5,1.5,0.2,C(31,38,38),nil,false)
            box(r,"Conduit",side*(w/2-1.3),7,z,0.3,0.3,12,C(38,45,46),nil,false)
        end
    end
    boundary(r,a,w,h)
    sign(r,title,0,h-3,a+2,math.min(w-6,30),3)
    for z=a+10,b-4,18 do
        lamp(r,-w/4,h-1.5,z,i==9 and C(186,102,66) or C(204,215,195),i==9 and "DIST_LIGHTS" or nil)
        if w>50 then lamp(r,w/4,h-1.5,z,C(214,185,137)) end
        for _,x in ipairs({-5.5,5.5}) do box(r,"FloorGuide",x,0.025,z,0.16,0.05,12,palette[pi],Enum.Material.SmoothPlastic,false) end
        box(r,"FloorJoint",0,0.015,z,w-3,0.03,0.08,C(28,32,32),nil,false)
    end
    -- Deliberate wall furniture, outside the clear 14-stud progression lane.
    for z=a+12,b-4,23 do
        local x=w/2-5
        box(r,"ServiceCabinet",x,3,z,5,6,2,C(49,62,62))
        for yy=1.2,4.8,0.9 do box(r,"VentSlot",x,yy,z-1.02,3.8,0.12,0.05,C(22,28,28),nil,false) end
        box(r,"InspectionLamp",x+1.5,5.2,z-1.1,0.3,0.3,0.12,C(164,132,64),Enum.Material.Neon,false)
        sign(r,"LOTE "..tostring(i*100+z).."\nINSPEÇÃO SUSPENSA",-w/2+4,8,z,5,3)
    end
end
boundary(rooms[12],694,48,24)
local function checkpoint(id,z)
    local p=box(map,id,0,0.1,z,7,0.2,5,C(86,131,118),Enum.Material.SmoothPlastic,false)
    p.Transparency=0.5; tag(p,"DeadSignalCheckpoint",{CheckpointId=id})
    tag(p,"DeadSignalChapterZone",{ZoneId=id}); return p
end
checkpoint("CH01_START",12); checkpoint("CH01_BATTERY",225)
checkpoint("CH01_PRODUCTION",278); checkpoint("CH01_DISTRIBUTION",380)
checkpoint("CH01_DARK",470); checkpoint("CH01_CHASE",512); checkpoint("CH01_SAFE",665)
local spawn=Instance.new("SpawnLocation"); spawn.Name="SignalworksSpawn"; spawn.Size=V(6,1,6)
spawn.CFrame=CFrame.new(0,2,12); spawn.Anchored=true; spawn.Transparency=1
spawn.CanCollide=false; spawn.Neutral=true; spawn.Duration=0; spawn.Parent=map
local function zone(id,z,sx,sz)
    local p=box(map,id,0,4,z,sx or 12,8,sz or 5,C(255,255,255),nil,false)
    p.Transparency=1; tag(p,"DeadSignalChapterZone",{ZoneId=id}); return p
end
zone("INTRO",25); zone("OBSERVATION",345); zone("RADIO",438); zone("CHASE",535); zone("END",680)
local function node(id,typ,x,z,amount,enabled)
    local p=box(map,id,x,4,z,3,3,1,C(149,122,62))
    tag(p,"DeadSignalPowerNode",{PowerNodeId=id,PowerNodeType=typ,Output=typ=="Source" and amount or 0,Demand=typ=="Consumer" and amount or 0,Enabled=enabled~=false})
    tag(p,"DeadSignalWireEndpoint",{WireEndpointId=id.."_SOCKET",PowerNodeId=id,Accepts="Any"})
    prompt(p,"CableSocket","Conectar / retirar cabo",{EndpointId=id.."_SOCKET"})
    sign(map,id.."\n"..amount.." U",x,7,z,8,2)
    return p
end
local function cable(id,x,z,length,a,b)
    local m=model(id); tag(m,"DeadSignalWire",{WireId=id,MaxLength=length,WireColor="Universal",SolutionA=a.."_SOCKET",SolutionB=b.."_SOCKET"})
    local p=box(m,"CableReel",x,0.65,z,3.4,1.3,3.4,C(43,47,43)); m.PrimaryPart=p
    for i=1,4 do box(m,"Coil",x,0.7+i*0.12,z,3.1-i*0.3,0.14,3.1-i*0.3,C(174,125,49),nil,false) end
    prompt(p,"CablePickup","Pegar cabo — "..length.." m",{WireId=id})
end
local function door(id,z,power)
    local m=model(id); tag(m,"DeadSignalDoor",{DoorId=id,PowerNodeId=power,Locked=false,OpenOffset=V(0,13,0),OpenDuration=0.65,AutoOpenWhenPowered=true})
    local p=box(m,"DoorPanel",0,6,z,14,12,1.2,C(77,91,89))
    addText(p,"SIGNALWORKS\n"..id,Enum.NormalId.Front,C(218,207,171))
    return m
end
node("IND_SOURCE","Source",-10,133,40); node("IND_DOOR","Consumer",10,145,20)
cable("IND_CABLE",-3,134,28,"IND_SOURCE","IND_DOOR"); door("INDUCTION_GATE",158,"IND_DOOR")
node("BAT_SOURCE","Source",-15,239,60,false); node("BAT_DOOR","Consumer",14,253,40)
cable("BAT_CABLE",-3,240,36,"BAT_SOURCE","BAT_DOOR"); door("ACCUMULATOR_GATE",266,"BAT_DOOR")
node("PROD_SOURCE","Source",-24,337,80,false); node("PROD_DOOR","Consumer",0,353,60)
cable("PROD_CABLE",-14,339,32,"PROD_SOURCE","PROD_DOOR"); door("ASSEMBLY_GATE",366,"PROD_DOOR")
node("DIST_SOURCE","Source",-20,386,100); node("DIST_BUS","Junction",0,397,0)
cable("DIST_CABLE",-9,385,26,"DIST_SOURCE","DIST_BUS")
node("DIST_DOOR","Consumer",19,400,50,false)
node("DIST_LIFT","Consumer",19,407,70,false)
node("DIST_LIGHTS","Consumer",-20,407,20,true)
node("DIST_RELAY","Consumer",-20,414,30,false)
door("ARCHIVE_GATE",418,"DIST_DOOR"); door("RETURN_GATE",458,"DIST_LIFT")
for i,id in ipairs({"DIST_DOOR","DIST_LIFT","DIST_LIGHTS","DIST_RELAY"}) do
    local x=({-18,-6,6,18})[i]
    local p=box(map,"Switch_"..id,x,3.5,392,3,2,2,C(47,66,62))
    prompt(p,"PowerSwitch","Alternar circuito",{NodeId=id})
    sign(map,({"PORTA / 50","ELEVADOR / 70","LUZES / 20","RELÉ / 30"})[i],x,6,392,10,2)
end
-- Batteries remain individually reachable; no giant remote kit containers.
for i,x in ipairs({-16,16}) do
    local b=model("Battery"..i)
    tag(b,"DeadSignalBattery",{BatteryId="CELL_"..i})
    local p=box(b,"CellHandle",x,1.5,230,2,3,2,C(133,105,52)); b.PrimaryPart=p
    box(b,"Positive",x,3.15,230,0.8,0.3,0.8,C(191,186,154),nil,false)
    prompt(p,"BatteryPickup","Levar bateria",{BatteryId="CELL_"..i})
end
for i,d in ipairs({{"BAT_SOURCE",-15,236},{"BAT_LAMP",15,244}}) do
    local p=box(map,"BatteryDock_"..d[1],d[2],1.5,d[3],3.5,3,3.5,C(39,58,55))
    prompt(p,"BatteryDock","Inserir / retirar bateria",{DockId=d[1]})
end
lamp(map,15,14,244,C(238,198,132),"BAT_SOURCE")
-- Reception: desk, glazed booths, turnstiles and abandoned paperwork.
box(rooms[1],"ReceptionDesk",-13,2.2,30,13,4.4,5,C(101,79,56),Enum.Material.Wood)
box(rooms[1],"DeskTop",-13,4.5,30,14,0.3,6,C(28,43,43))
for i=1,5 do box(rooms[1],"VisitorForm",-18+i*1.8,4.7,29,1.3,0.05,1.7,C(181,175,144),nil,false) end
for _,x in ipairs({-6,6}) do
    box(rooms[1],"Turnstile",x,2,40,2,4,3,C(53,65,65))
    box(rooms[1],"RetractedArm",x,3,40,0.2,0.2,3,C(167,158,125),nil,false)
end
for z=10,34,12 do
    local g=box(rooms[1],"SecurityGlass",20,8,z,0.2,7,9,C(124,157,150),Enum.Material.Glass)
    g.Transparency=0.55
end
sign(rooms[1],"A GENTE ENSINA AS MÁQUINAS A ESCUTAR.\nPor favor, não responda aos corredores.",-12,11,6,16,5)
-- Atrium: original listening-bell mascot, mezzanine, exhibits and sectors sealed by shutters.
box(rooms[2],"MascotPlinth",-19,1,83,9,2,9,C(108,100,78),Enum.Material.Concrete)
local bell=box(rooms[2],"EchoBell",-19,6,83,5,8,4,C(130,116,69)); bell.Shape=Enum.PartType.Ball
for _,x in ipairs({-20,-18}) do box(rooms[2],"MascotEye",x,7.5,80.9,0.4,0.7,0.2,C(31,46,43),nil,false) end
sign(rooms[2],"ECO / UNIDADE DE ESCUTA\nSeu silêncio é parte do trabalho.",-19,3,77,12,3)
for _,x in ipairs({-32,32}) do
    box(rooms[2],"Mezzanine",x,14,87,11,1,62,C(49,60,58))
    for z=60,112,8 do box(rooms[2],"BalconyPost",x>0 and 26.5 or -26.5,16,z,0.3,4,0.3,C(49,57,53)) end
    box(rooms[2],"BalconyRail",x>0 and 26.5 or -26.5,18,87,0.3,0.3,62,C(138,132,105))
    for z=68,108,20 do box(rooms[2],"SealedSector",x,6,z,8,12,1,C(46,55,54)); sign(rooms[2],"SETOR ISOLADO",x,11,z-0.6,8,2) end
end
local function stairs(parent,x,startZ,height,count)
    for i=1,count do box(parent,"StairTread",x,height/count*i/2,startZ+i*1.2,9,height/count*i,1.22,C(77,80,68)) end
end
stairs(rooms[2],-31,52,13.5,20)
sign(rooms[2],"PLANTA DO COMPLEXO\nRECEPÇÃO → INDUÇÃO → ACUMULADORES\nMONTAGEM → DISTRIBUIÇÃO → DESCIDA",17,9,75,20,8)
-- Maintenance alcoves: shelving, tools, fallen maintenance cart; middle lane remains unobstructed.
for z=172,208,18 do
    for y=1.5,7.5,3 do box(rooms[4],"Shelf",-11,y,z,6,0.25,5,C(55,68,65)); box(rooms[4],"ToolCase",-11,y+0.8,z,3,1.4,2,C(132,104,57)) end
    box(rooms[4],"Locker",12,4,z,4,8,5,C(69,88,83))
end
-- Production: paired assembly lines, an overhead walk and access stairs.
for _,x in ipairs({-24,24}) do
    box(rooms[6],"ConveyorBase",x,2.5,310,9,3,52,C(36,46,46))
    for z=286,334,4 do
        local roller=box(rooms[6],"Roller",x,4.2,z,8,0.7,1.3,C(98,108,102)); roller.Shape=Enum.PartType.Cylinder
        box(rooms[6],"EchoProduct",x+math.sin(z)*2,5.3,z,2,2,2,palette[(z%4)+1],Enum.Material.SmoothPlastic,false)
    end
    for z=291,327,18 do
        box(rooms[6],"RobotPedestal",x>0 and 34 or -34,3,z,4,6,4,C(98,80,48))
        local arm=box(rooms[6],"RobotArm",x>0 and 31 or -31,8,z,7,1.2,1.2,C(144,119,64)); arm.CFrame*=CFrame.Angles(0,0,math.rad(x>0 and 28 or -28))
    end
end
box(rooms[6],"OverheadWalk",0,14,347,80,1,9,C(49,60,59))
for _,z in ipairs({342.5,351.5}) do
    box(rooms[6],"GuardRail",0,18,z,80,0.25,0.25,C(151,141,111))
    for x=-39,39,8 do box(rooms[6],"GuardPost",x,16,z,0.25,4,0.25,C(63,76,71)) end
end
stairs(rooms[6],-37,316,13.5,25)
for i=1,3 do
    local p=box(rooms[6],"Sequencer"..i,({-12,0,12})[i],3.5,326,3,3,2,C(112,96,53))
    prompt(p,"Sequence","Armar relé "..i,{SequenceIndex=i})
end
sign(rooms[6],"PARTIDA A FRIO\nVENTILAÇÃO (2) → PRENSA (1) → SINAL (3)",0,10,322,25,5)
-- Narrative radio has a physical CRT face, indicator and selectable interaction.
local crt=box(rooms[8],"MARA_CRT",-12,5,437,7,5,4,C(25,37,37))
local face=sign(rooms[8],"M A R A\nCANAL 04 / ESCUTANDO",-12,5.3,434.9,6,3)
tag(face,"DeadSignalRadio",{})
prompt(crt,"Mara","Falar com MARA")
for i=1,7 do box(rooms[8],"ArchiveDrawer",15,2+i*1.5,443,7,1.4,5,C(84+i*3,90,76)) end
sign(rooms[8],"NÃO APAGUE A LUZ PARA ECONOMIZAR.\nEle escuta melhor sem os ventiladores.",0,11,448,23,4)
-- Selective emergency lighting. Not a fully black map.
for z=465,640,18 do lamp(map,8,5,z,C(186,89,55)) end
-- Escape has alternating islands and two routes around each, all > 7 studs wide.
for i,z in ipairs({550,576,596,625}) do
    box(map,"FreightIsland",i%2==0 and -5 or 5,2.5,z,12,5,7,C(86,77,58),Enum.Material.WoodPlanks)
    sign(map,"SAÍDA ↑",i%2==0 and 13 or -13,7,z,8,2)
end
local blast=door("BLAST_GATE",648,nil)
blast:SetAttribute("AutoOpenWhenPowered",false)
local escape=box(map,"EmergencyDischarge",10,4,639,3,3,2,C(150,110,52))
prompt(escape,"Discharge","Descarregar / abrir refúgio")
box(rooms[12],"TerminalDesk",-13,2,679,9,4,5,C(64,80,73))
local terminal=box(rooms[12],"DescentTerminal",-13,5,679,5,3,2,C(29,43,41))
prompt(terminal,"Mara","Consultar terminal")
sign(rooms[12],"DESCIDA / NÍVEL -2\nFIM DA BUILD DE TESTE",0,11,690,27,6)
box(rooms[12],"FutureElevator",0,5,693,13,10,1,C(36,52,49))
-- Audio routing markers: no borrowed copyrighted IDs. Client synthesizes mechanical foley.
for i,r in ipairs(rooms) do
    local a=Instance.new("Attachment"); a.Name="AmbientEmitter"; a.Parent=r:FindFirstChild("Slab")
    a:SetAttribute("AudioProfile",i==6 and "machinery" or i==9 and "ventilation" or "transformer")
end
-- Original jointed Threadbare. Server owns movement, client animates only visible nearby rigs.
local monster=model("Threadbare")
tag(monster,"DeadSignalStalker",{})
local root=box(monster,"HumanoidRootPart",0,6,710,2,4,2,C(38,40,35)); root.Transparency=1; root.Anchored=false
monster.PrimaryPart=root
local hum=Instance.new("Humanoid"); hum.HipHeight=4; hum.MaxHealth=1000; hum.Health=1000; hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; hum.Parent=monster
local function limb(name,offset,size,col)
    local p=part(monster,name,size,root.CFrame*CFrame.new(offset),col,Enum.Material.Fabric,false)
    p.Anchored=false; p.Massless=true
    local j=Instance.new("Motor6D"); j.Name=name.."Joint"; j.Part0=root; j.Part1=p; j.C0=CFrame.new(offset); j.Parent=root
    return p
end
limb("Torso",V(0,0.9,0),V(2.2,5,1.4),C(91,83,58))
limb("Head",V(0,4,0),V(1.4,1.7,1.3),C(117,108,80))
for _,s in ipairs({-1,1}) do
    limb(s<0 and "LeftArm" or "RightArm",V(s*2,0,0),V(0.7,7,0.8),C(78,74,54))
    limb(s<0 and "LeftLeg" or "RightLeg",V(s*0.75,-3,0),V(0.7,6,0.8),C(52,58,51))
    limb("Cable"..s,V(s*0.65,1,-0.8),V(0.12,4,0.12),C(28,33,30))
    limb("Eye"..s,V(s*0.32,4.2,-0.7),V(0.15,0.25,0.1),C(183,160,89))
end
for _,z in ipairs({480,503,541,575,614}) do
    local p=box(map,"Patrol"..z,0,1,z,1,1,1,C(255,255,255),nil,false); p.Transparency=1
    tag(p,"DeadSignalPatrolPoint",{})
end
local observation=box(map,"ObservationAnchor",0,20,347,1,1,1,C(255,255,255),nil,false); observation.Transparency=1
local offstage=box(map,"StalkerOffstage",0,0,710,14,1,16,C(22,25,25))
box(map,"OffstageOccluder",0,12,702,60,26,2,C(22,25,25))
local cam=box(map,"MenuCamera",12,8,66,1,1,1,C(255,255,255),nil,false); cam.Transparency=1
cam.CFrame=CFrame.lookAt(V(12,8,66),V(-19,7,83))
Workspace:SetAttribute("ChapterRoomCount",#roomDefs)

box(rooms[1],"EntrySecurityShutter",0,6,0,14,12,1,C(44,57,53))

-- A real powered freight lift inside the archive, with an upper inspection deck.
local lift=box(rooms[8],"FreightLift",12,0.4,433,10,0.8,10,C(99,103,81))
lift:SetAttribute("LiftLowY",0.4); lift:SetAttribute("LiftHighY",10.4)
prompt(lift,"LiftRide","Acionar elevador / 70 U + relé")
for _,x in ipairs({6,18}) do box(rooms[8],"LiftGuide",x,9,433,0.5,18,0.5,C(47,60,55)) end
box(rooms[8],"InspectionDeck",12,10,445,11,0.7,12,C(61,77,68))
sign(rooms[8],"INSPEÇÃO SUPERIOR / DESCER PELO ELEVADOR",12,14,450,15,3)
