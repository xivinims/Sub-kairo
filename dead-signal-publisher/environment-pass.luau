-- Scenic direction from the supplied inline references: painted play spaces versus damaged service spaces.
-- Remove floating editorial signs. Keep text only on the physical radio / machine controls.
for _,p in ipairs(map:GetDescendants()) do
    if p:IsA("BasePart") and p.Name=="Wayfinding" then
        if CollectionService:HasTag(p,"DeadSignalRadio") then
            p.Name="MaraCRTGlass"; p.CFrame=CFrame.new(-12,5.3,434.93)
        else p:Destroy() end
    elseif p:IsA("BasePart") and (p.Name=="FloorGuide" or p.Name=="FloorJoint") then p:Destroy() end
end
for _,p in ipairs(CollectionService:GetTagged("DeadSignalCheckpoint")) do p.Transparency=1 end
local scenic=model("ScenicEnvironmentPass")
local colors={C(151,52,43),C(37,89,126),C(191,161,61),C(62,108,92)}
-- Imported floor remains the visible base. Correct its tint and repeat its authored textures at human scale.
for _,m in ipairs(dressing:GetChildren()) do
    if m.Name:find("IndustrialFloor_") then
        for _,p in ipairs(m:GetDescendants()) do
            if p:IsA("BasePart") then p.Color=C(163,159,139); p.Reflectance=0.04 end
            if p:IsA("Texture") then p.StudsPerTileU=4.4; p.StudsPerTileV=4.4 end
        end
    end
end
-- Small cream tiles with sparse primary-colour inserts, grounded at floor level.
for _,idx in ipairs({1,2,3,5,8,12}) do
    local d=roomDefs[idx]; local a,b,w=d[2],d[3],d[4]
    for x=-w/2+3,w/2-3,4.4 do
        for z=a+2.2,b-2.2,4.4 do
            local hash=math.floor((x+w)*7+z*3+idx*17)
            if hash%5==0 then
                box(scenic,"ColourTileInset",x,0.035,z,4.32,0.025,4.32,colors[hash%4+1],Enum.Material.SmoothPlastic,false)
            end
        end
    end
    for x=-w/2+1,w/2-1,4.4 do box(scenic,"TileGrout",x,0.032,(a+b)/2,0.035,0.02,b-a,C(55,58,51),nil,false) end
    for z=a,b,4.4 do box(scenic,"TileGrout",0,0.032,z,w-2,0.02,0.035,C(55,58,51),nil,false) end
end
-- Public areas use aged plaster with blue mural bands; no industrial cabinets in every reception bay.
for _,idx in ipairs({1,2,3}) do
    local r,d=rooms[idx],roomDefs[idx]
    for _,p in ipairs(r:GetChildren()) do
        if p:IsA("BasePart") and (p.Name=="ServiceCabinet" or p.Name=="InspectionLamp" or p.Name=="VentSlot" or p.Name=="SealedSector") then p:Destroy() end
    end
    for _,side in ipairs({-1,1}) do
        local x=side*(d[4]/2-1.15)
        box(scenic,"AgedMuralPlaster",x,10,(d[2]+d[3])/2,0.09,13,d[3]-d[2]-2,C(167,163,140),Enum.Material.Plaster,false)
        box(scenic,"MuralBlueBand",x-side*0.08,6.3,(d[2]+d[3])/2,0.06,3,d[3]-d[2]-2,C(49,90,121),Enum.Material.SmoothPlastic,false)
        for z=d[2]+6,d[3]-5,12 do
            local arc=box(scenic,"PaintedCloudContour",x-side*0.12,7.5+math.sin(z)*1.1,z,0.06,4,12,C(49,90,121),Enum.Material.SmoothPlastic,false)
            arc.Shape=Enum.PartType.Ball
        end
    end
end
-- Reception's focal point is a curved welcome desk and a wall mural, not a board in the walkway.
for _,name in ipairs({"ReceptionDesk","DeskTop","VisitorForm"}) do
    for _,p in ipairs(rooms[1]:GetChildren()) do if p.Name==name then p:Destroy() end end
end
for i=0,6 do
    local angle=math.rad(-65+i*21.7)
    local x=-11+math.sin(angle)*6
    local z=31+math.cos(angle)*4
    local desk=box(scenic,"ReceptionCurvedCounter",x,1.9,z,2.6,3.8,2.3,C(80,61,43),Enum.Material.Wood)
    desk.CFrame*=CFrame.Angles(0,angle,0)
    local top=box(scenic,"CounterStoneTop",x,3.95,z,2.8,0.3,2.5,C(42,57,55),Enum.Material.Slate)
    top.CFrame*=CFrame.Angles(0,angle,0)
end
local monitor=box(scenic,"ReceptionCRT",-11,5,35,3,2,2,C(29,40,38))
box(scenic,"DarkCRTGlass",-11,5,33.97,2.5,1.45,0.06,C(21,30,28),Enum.Material.Glass,false)
-- Children's corridor: red lower paint, cream upper plaster, yellow segmented arches.
for _,side in ipairs({-1,1}) do
    box(scenic,"NurseryLowerPaint",side*18.7,2.7,139,0.1,5.4,36,C(123,52,46),Enum.Material.Plaster,false)
    box(scenic,"NurseryUpperPaint",side*18.65,9.5,139,0.1,8,36,C(146,153,116),Enum.Material.Plaster,false)
end
for _,z in ipairs({123,151}) do
    for segment=0,10 do
        local angle=math.pi*segment/10
        local p=box(scenic,"YellowArchSegment",math.cos(angle)*7.8,9+math.sin(angle)*3.6,z,2.5,1.1,1.3,C(181,147,49),Enum.Material.Plaster,false)
        p.CFrame*=CFrame.Angles(0,0,angle-math.pi/2)
    end
    for _,side in ipairs({-1,1}) do box(scenic,"ArchColumn",side*8.2,4.5,z,1.2,9,1.3,C(35,100,105),Enum.Material.Plaster,false) end
end
-- Atrium: a fabricated indoor garden, scenic sky walls, suspended clouds and small playhouse facades.
for _,p in ipairs(rooms[2]:GetChildren()) do
    if p:IsA("BasePart") and (p.Name=="MascotPlinth" or (p.Name=="Mezzanine" or p.Name=="BalconyPost" or p.Name=="BalconyRail") and p.Position.X>0) then p:Destroy() end
end
local garden=box(scenic,"RaisedCircularGarden",-19,0.4,84,0.8,21,21,C(83,91,63),Enum.Material.Grass)
garden.Shape=Enum.PartType.Cylinder; garden.CFrame=CFrame.new(-19,0.4,84)*CFrame.Angles(0,0,math.pi/2)
local rim=box(scenic,"CircularPlanterRim",-19,0.1,84,0.25,23,23,C(113,107,85),Enum.Material.Concrete)
rim.Shape=Enum.PartType.Cylinder; rim.CFrame=CFrame.new(-19,0.1,84)*CFrame.Angles(0,0,math.pi/2)
for i=0,13 do
    local angle=i*math.pi*2/14
    local p=box(scenic,"ClippedHedge",-19+math.cos(angle)*8.8,1.8,84+math.sin(angle)*8.8,3.5,2.8,3.5,C(46,68+i%3*7,43),Enum.Material.Grass,false)
    p.Shape=Enum.PartType.Ball
end
for _,pos in ipairs({V(-22,28,65),V(9,29,77),V(-7,28,106),V(26,27,100)}) do
    box(scenic,"CloudSuspension",pos.X,30,pos.Z,0.04,4,0.04,C(88,96,93),nil,false)
    for j=-1,1 do
        local cloud=box(scenic,"SuspendedScenicCloud",pos.X+j*2.4,pos.Y+(j==0 and 0.6 or 0),pos.Z,5.2,3.2,3.8,C(194,194,174),Enum.Material.Plaster,false)
        cloud.Shape=Enum.PartType.Ball
    end
end
local function cottage(x,z,col)
    local group=model("PlayhouseFacade",scenic)
    box(group,"FacadeLeft",x-4,5,z,4,10,1.2,col,Enum.Material.WoodPlanks)
    box(group,"FacadeRight",x+4,5,z,4,10,1.2,col,Enum.Material.WoodPlanks)
    box(group,"DoorLintel",x,9,z,4,2,1.2,col,Enum.Material.WoodPlanks)
    box(group,"DoorRecess",x,4,z+1.2,4,8,0.2,C(27,36,34))
    for _,side in ipairs({-1,1}) do
        local roof=box(group,"PitchedRoof",x+side*3.5,12,z+2,8,0.6,7,C(91,62,42),Enum.Material.WoodPlanks,false)
        roof.CFrame*=CFrame.Angles(0,0,-side*math.rad(25))
        box(group,"WindowFrame",x+side*4,6,z-0.75,2.4,3,0.3,C(165,151,112),nil,false)
        box(group,"DarkWindow",x+side*4,6,z-0.94,1.8,2.4,0.1,C(21,43,46),Enum.Material.Glass,false)
        box(group,"WindowMullion",x+side*4,6,z-1.02,0.1,2.4,0.1,C(129,122,95),nil,false)
    end
end
cottage(22,66,C(108,108,74)); cottage(22,108,C(97,121,113))
-- Service corridors: chalky walls, a worn red stripe, fallen fixture and small debris at the edges.
for _,idx in ipairs({4,9,10,11}) do
    local d=roomDefs[idx]
    for _,side in ipairs({-1,1}) do
        local x=side*(d[4]/2-1.28)
        box(scenic,"ServiceWallFinish",x,8,(d[2]+d[3])/2,0.08,15,d[3]-d[2]-2,C(129,136,125),Enum.Material.Plaster,false)
        box(scenic,"FadedRedStripe",x-side*0.06,7.2,(d[2]+d[3])/2,0.05,0.75,d[3]-d[2]-2,C(105,47,43),nil,false)
        for z=d[2]+9,d[3]-6,17 do
            local chip=box(scenic,"SpalledPlaster",x-side*0.12,2.2,z,0.04,2.8,1.1,C(62,69,64),Enum.Material.Concrete,false)
            chip.CFrame*=CFrame.Angles(math.rad(12),0,0)
            box(scenic,"FallenPlaster",side*(d[4]/2-3),0.14,z,1.1,0.2,0.6,C(125,128,112),Enum.Material.Concrete,false)
        end
    end
end
local fallen=box(scenic,"HangingFluorescent",-5,12,193,6,0.35,1.1,C(130,144,132),Enum.Material.Neon,false)
fallen.CFrame*=CFrame.Angles(0,0,math.rad(18))
box(scenic,"FixtureSafetyWire",-7.5,13.8,193,0.04,4,0.04,C(34,43,42),nil,false)
-- No captions over puzzles: discreet engraved digits sit directly on their housings.
for i=1,3 do
    local control=rooms[6]:FindFirstChild("Sequencer"..i)
    if control then
        addText(control,tostring(i),Enum.NormalId.Front,C(211,205,166))
        local indicator=box(scenic,"RelayOrderLamp",control.Position.X,5.4,control.Position.Z,0.35,0.35,0.2,C(167,134,62),Enum.Material.Neon,false)
        indicator:SetAttribute("SequenceOrder",({2,1,3})[i])
        CollectionService:AddTag(indicator,"DeadSignalSequenceLamp")
    end
end
for _,p in ipairs(CollectionService:GetTagged("DeadSignalPowerNode")) do
    local amount=p:GetAttribute("PowerNodeType")=="Source" and p:GetAttribute("Output") or p:GetAttribute("Demand")
    if amount and amount>0 then addText(p,tostring(amount).." U",Enum.NormalId.Front,C(215,209,179)) end
end
for _,p in ipairs(scenic:GetDescendants()) do if p:IsA("BasePart") then p.CastShadow=p.CanCollide end end
map:SetAttribute("ScenicRevision","play-space-and-service-v5")
map:SetAttribute("FloatingSigns",0)
