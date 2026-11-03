-- Runs after trusted modules are installed and before any runtime script starts.
local Importer=require(services.SafeAssetImporter)
local dressing=Instance.new("Model"); dressing.Name="AuditedVisualDressing"; dressing.Parent=map
local function fit(m, size, cf)
    m:PivotTo(CFrame.new())
    local _,old=m:GetBoundingBox()
    local ratio=Vector3.new(size.X/math.max(old.X,0.001),size.Y/math.max(old.Y,0.001),size.Z/math.max(old.Z,0.001))
    for _,p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            local pos=p.Position
            p.Size=Vector3.new(p.Size.X*ratio.X,p.Size.Y*ratio.Y,p.Size.Z*ratio.Z)
            p.CFrame=CFrame.new(pos.X*ratio.X,pos.Y*ratio.Y,pos.Z*ratio.Z)*p.CFrame.Rotation
        end
    end
    m.WorldPivot=CFrame.new(); m:PivotTo(cf)
    return m
end
local templates={}
local function visual(id,selection,name,size,cf,parent)
    local key=tostring(id)..selection
    if not templates[key] then templates[key]=Importer.Select(id,selection) end
    local m=templates[key]:Clone(); m.Name=name
    fit(m,size,cf); m.Parent=parent or dressing
    return m
end
-- The supplied textured industrial floor replaces the visible concrete slabs.
for i,d in ipairs(roomDefs) do
    local a,b,w,h=d[2],d[3],d[4],d[5]
    local cols=math.ceil((w-2)/16); local rows=math.ceil((b-a)/16)
    local tw=(w-2)/cols; local td=(b-a)/rows
    for x=1,cols do for z=1,rows do
        visual(11961684378,"__ALL_STATIC__","IndustrialFloor_"..i.."_"..x.."_"..z,
            V(tw-0.035,0.16,td-0.035),CFrame.new(-(w-2)/2+(x-0.5)*tw,-0.06,a+(z-0.5)*td))
    end end
    -- Porcelain/service-panel wall skins, baseboards, horizontal reveal and concrete upper ribs.
    for _,side in ipairs({-1,1}) do
        local x=side*(w/2-0.92)
        box(dressing,"Skirting",x,0.35,(a+b)/2,0.18,0.7,b-a,C(32,39,38))
        box(dressing,"DadoCap",x,6.1,(a+b)/2,0.25,0.2,b-a,C(168,155,123))
        local panelCount=math.ceil((b-a)/16)
        local panelDepth=(b-a)/panelCount
        for panelIndex=1,panelCount do
            local z=a+(panelIndex-0.5)*panelDepth
            local skin=box(dressing,"PorcelainWallPanel",x,3.2,z,0.12,5.4,panelDepth-0.12,
                (i==1 or i==2) and C(75,116,116) or C(75,92,85),Enum.Material.SmoothPlastic,false)
            -- Slight warm upper plaster breaks the original grey box appearance.
            box(dressing,"UpperMasonry",side*(w/2-0.83),10,z,0.1,7.4,panelDepth-0.16,C(164,155,128),Enum.Material.Brick,false)
            if z+panelDepth/2<b then box(dressing,"WallExpansionJoint",side*(w/2-1.02),3.2,z+panelDepth/2-0.03,0.04,5.4,0.055,C(24,33,32),nil,false) end
        end
    end
end
-- Five-piece supplied passage geometry, rotated from its original X-facing axis.
for _,i in ipairs({2,3,5,6,7,8,9,12}) do
    local z=roomDefs[i][2]
    local m=visual(96103787859080,"__ALL_STATIC__","ImportedPortal_"..i,V(3.4,17,17),CFrame.new(0,8.5,z)*CFrame.Angles(0,math.pi/2,0))
    m:SetAttribute("PortalZ",z)
end
-- Real supplied station mesh behind each electrical training station.
for _,spec in ipairs({{-10,133},{-15,239},{-24,337},{-20,386}}) do
    visual(9609111841,"__ALL_STATIC__","ElectricalStation",V(6.4,8,0.65),CFrame.new(spec[1],4.7,spec[2]+1.15))
end
for _,spec in ipairs({{"ElectricalPanel_A",-12,142},{"ElectricalPanel_B",16,250},{"PowerReceiver",10,145},{"PowerSource",-10,133},
    {"ElectricalPanel_A",20,384},{"ElectricalPanel_B",22,405}}) do
    local height=spec[1]:find("Panel") and 5.5 or 2.8
    visual(16592756903,spec[1],"Selected_"..spec[1],V(height*0.8,height,0.55),CFrame.new(spec[2],height/2+1,spec[3]+0.75))
end
-- Replace the primitive battery appearance but retain original prompts and IDs.
for _,cell in ipairs(CollectionService:GetTagged("DeadSignalBattery")) do
    local grip=cell.PrimaryPart
    for _,p in ipairs(cell:GetChildren()) do if p:IsA("BasePart") then p.Transparency=1 end end
    visual(16551049618,"SM_Battery.mo","AuditedBatteryBody",V(1.65,3.5,1.65),grip.CFrame,cell)
end
for _,spec in ipairs({{"BAT_SOURCE",-15,236},{"BAT_LAMP",15,244}}) do
    visual(16551049618,"SM_BatteryFrame.mo","AuditedBatterySocket",V(3.2,4.5,2.9),CFrame.new(spec[2],2.25,spec[3]))
end
-- Two supplied leaves per powered door, driven only by our moving collision panel.
for _,doorModel in ipairs(CollectionService:GetTagged("DeadSignalDoor")) do
    local panel=doorModel:FindFirstChild("DoorPanel")
    panel.Transparency=1
    for _,g in ipairs(panel:GetChildren()) do if g:IsA("SurfaceGui") then g:Destroy() end end
    for _,side in ipairs({-1,1}) do
        local leaf=visual(8593730677,"__ALL_STATIC__","ImportedDoorLeaf",V(6.9,11.7,0.7),panel.CFrame*CFrame.new(side*3.45,0,0),doorModel)
        for _,p in ipairs(leaf:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Anchored=false; p.Massless=true
                local weld=Instance.new("WeldConstraint"); weld.Part0=panel; weld.Part1=p; weld.Parent=p
            end
        end
    end
end
-- The authored treads remain simplified colliders beneath selected stair meshes.
for _,r in ipairs({rooms[2],rooms[6]}) do for _,p in ipairs(r:GetChildren()) do if p.Name=="StairTread" then p.Transparency=1 end end end
for _,spec in ipairs({{-31,52,13.5,24},{-37,316,13.5,30}}) do
    for flight=1,2 do
        visual(120661626985584,"SM_TrainStationKit_BigStairsMain_A.mo","ImportedStairFlight",
            V(9,spec[3]/2,spec[4]/2),CFrame.new(spec[1],spec[3]/4+(flight-1)*spec[3]/2,spec[2]+spec[4]/4+(flight-1)*spec[4]/2))
    end
end
-- Selected kit props with intentional room purposes. Never clone the entire kit.
visual(16390129962,"Block Castle","ReceptionChildrenExhibit",V(8,5.6,9),CFrame.new(12,2.8,20))
visual(136978268470872,"Block Castle","AssemblyProductDisplay",V(9,6.3,10),CFrame.new(32,3.15,350))
for i,spec in ipairs({{-25,74},{-29,105},{25,93},{-9,227},{32,287},{-32,304},{29,331},{-13,676}}) do
    local letter=({"SM_BoxLetters_A_MI_Box_Letters_A_0","SM_BoxLetters_B_MI_Box_Letters_B_0","SM_BoxLetters_C_MI_Box_Letters_C_0"})[(i-1)%3+1]
    visual(i%2==0 and 136978268470872 or 16390129962,letter,"AlphabetProductionBlock",V(2.5,2.5,2.5),CFrame.new(spec[1],1.25,spec[2])*CFrame.Angles(0,i*0.37,0))
end
visual(136978268470872,"SM_BedMerged_A_MI_BedroomKit_0","SanctuaryRestCot",V(9,6,5.2),CFrame.new(16,3,674))
visual(16390129962,"SM_Jail_Frame_MI_JailDoor_0","MaintenanceGrilleFrame",V(5,10,0.6),CFrame.new(-12,5,201))
-- Explicitly selected neutral structural pieces from the large Chapter 4 library.
for _,spec in ipairs({{-23,59},{23,59},{-23,112},{23,112}}) do
    visual(72028919182927,"SM_HSH_Column_Lg.mo.001_Material.188_0","AtriumAuthoredColumn",V(2.6,24,2.6),CFrame.new(spec[1],12,spec[2]))
end
-- Room-specific supporting props, positioned away from the 14-stud main route.
local function crate(parent,x,y,z,s)
    box(parent,"ShippingCrate",x,y+s/2,z,s,s,s,C(107,82,52),Enum.Material.WoodPlanks)
    for _,side in ipairs({-1,1}) do box(parent,"CrateBand",x+side*s*0.3,y+s/2,z,s*0.08,s+0.03,s+0.04,C(49,57,50),nil,false) end
end
for _,spec in ipairs({{4,-9,181},{4,9,194},{5,-19,255},{6,34,277},{6,-33,282},{6,34,320},{7,-26,375},{9,-12,487},{10,16,560},{11,-12,615}}) do
    local r,x,z=rooms[spec[1]],spec[2],spec[3]
    crate(r,x,0,z,3.8); crate(r,x+1,3.8,z+0.4,2.6)
end
-- Drainage channels, loading edge paint, overhead cable trays, ventilation grilles.
for _,i in ipairs({3,4,5,6,7,9,10,11}) do
    local d=roomDefs[i]; local a,b,w,h=d[2],d[3],d[4],d[5]
    box(dressing,"CableTray",-w/4,h-3,(a+b)/2,2.2,0.25,b-a-4,C(36,46,45),Enum.Material.DiamondPlate,false)
    for z=a+6,b-4,24 do
        box(dressing,"DrainageGrille",w/2-6,0.025,z,2.6,0.05,5.5,C(35,43,42),Enum.Material.DiamondPlate,false)
        for _,side in ipairs({-1,1}) do
            local v=box(dressing,"VentilationFrame",side*(w/2-1.3),11,z,0.3,3,4.5,C(37,47,46),nil,false)
            for yy=10,12,0.5 do box(dressing,"VentFin",v.Position.X-side*0.2,yy,z,0.15,0.08,4,C(106,110,91),nil,false) end
        end
    end
end
-- Focused narrative stations: inspection paperwork, trolley, worker break table, noticeboards.
for _,spec in ipairs({{4,10,175},{5,-18,223},{6,32,342},{7,25,412},{8,-15,449}}) do
    local r,x,z=rooms[spec[1]],spec[2],spec[3]
    box(r,"WorkBench",x,2.8,z,6,0.35,3,C(106,90,64),Enum.Material.Wood)
    for _,side in ipairs({-1,1}) do box(r,"BenchLeg",x+side*2.5,1.35,z,0.3,2.7,2.5,C(49,62,57)) end
    box(r,"TechnicianClipboard",x-1,3.02,z,1.4,0.08,1.8,C(183,170,129),nil,false)
    box(r,"Toolbox",x+1.5,3.5,z,2,1,1.3,C(117,62,46))
end
for _,template in pairs(templates) do template:Destroy() end
Importer.ClearSelectionCache()
map:SetAttribute("VisualRevision","audited-assets-v4")
Workspace:SetAttribute("ImportedVisuals",#dressing:GetChildren())
