-- Runs before SavePlaceAsync AND in a separate task reopening the published place.
local Tags=game:GetService("CollectionService")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local errors={}
local function check(ok,msg) if not ok then table.insert(errors,msg) end end
local function index(tag,attr,cls)
    local out={}
    for _,obj in ipairs(Tags:GetTagged(tag)) do
        local id=obj:GetAttribute(attr)
        check(obj:IsA(cls),tag..": wrong class "..obj:GetFullName())
        check(type(id)=="string" and id~="",tag..": missing id")
        check(not out[id],tag..": duplicate "..tostring(id))
        if id then out[id]=obj end
    end
    return out
end
local nodes=index("DeadSignalPowerNode","PowerNodeId","BasePart")
local ends=index("DeadSignalWireEndpoint","WireEndpointId","BasePart")
local wires=index("DeadSignalWire","WireId","Model")
local doors=index("DeadSignalDoor","DoorId","Model")
local cps=index("DeadSignalCheckpoint","CheckpointId","BasePart")
for id,p in pairs(ends) do check(nodes[p:GetAttribute("PowerNodeId")]~=nil,"Endpoint without node: "..id) end
for id,m in pairs(doors) do
    local node=m:GetAttribute("PowerNodeId")
    check(not node or nodes[node]~=nil,"Door without node: "..id)
    check(m:FindFirstChild("DoorPanel",true)~=nil,"Door without panel: "..id)
end
for id,m in pairs(wires) do
    local a,b=ends[m:GetAttribute("SolutionA")],ends[m:GetAttribute("SolutionB")]
    check(a~=nil and b~=nil,"Cable missing solution endpoint: "..id)
    if a and b then check((a.Position-b.Position).Magnitude<=m:GetAttribute("MaxLength"),"Impossible cable: "..id) end
end
for _,id in ipairs({"CH01_START","CH01_BATTERY","CH01_PRODUCTION","CH01_DISTRIBUTION","CH01_DARK","CH01_CHASE","CH01_SAFE"}) do check(cps[id]~=nil,"Missing checkpoint: "..id) end
local map=workspace:FindFirstChild("SignalworksChapter01")
check(map~=nil,"Missing chapter map")
if map then
    check(map:GetAttribute("ScenicRevision")=="play-space-and-service-v5","Missing scenic pass")
    for _,d in ipairs(map:GetDescendants()) do check(d.Name~="Wayfinding","Floating editorial sign remains") end
end
local parts,externalScripts=0,0
if map then
    for _,p in ipairs(map:GetDescendants()) do
        if p:IsA("BasePart") then parts+=1 end
        if p:IsA("LuaSourceContainer") then externalScripts+=1 end
        if p:IsA("ProximityPrompt") then
            check(Tags:HasTag(p,"DeadSignalInteraction"),"Untagged prompt")
            check(p:GetAttribute("ActionId")~=nil,"Prompt without action")
        end
    end
end
check(externalScripts==0,"Map contains executable content")
check(parts<3100,"Mobile part budget exceeded: "..parts)
check(#Tags:GetTagged("DeadSignalRadio")==1,"Missing MARA screen")
local monsters=Tags:GetTagged("DeadSignalStalker")
check(#monsters==1,"Expected exactly one stalker")
if monsters[1] then check(monsters[1]:FindFirstChild("HumanoidRootPart")~=nil and monsters[1]:FindFirstChildOfClass("Humanoid")~=nil,"Invalid stalker rig") end
check(game:GetService("StarterPlayer").CameraMode==Enum.CameraMode.LockFirstPerson,"First-person default not configured")
check(map and map:GetAttribute("VisualRevision")=="audited-assets-v4","Missing visual revision")
local imported,assetIds=0,{}
if map then
    for _,m in ipairs(map:GetDescendants()) do
        local id=m:GetAttribute("DeadSignalSourceAssetId")
        if id and m:IsA("Model") then imported+=1; assetIds[tostring(id)]=true end
    end
end
for _,id in ipairs({11961684378,96103787859080,9609111841,8593730677,16551049618,16592756903,120661626985584,16390129962,136978268470872,72028919182927}) do
    check(assetIds[tostring(id)],"Requested visual asset absent: "..id)
end
check(workspace.StreamingEnabled,"Streaming is disabled")
check(workspace:GetAttribute("ChapterRoomCount")==12,"Missing sectors")
local root=SS:FindFirstChild("DeadSignalFoundation")
check(root~=nil,"Missing server root")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DeadSignalFoundationClient")~=nil,"Missing client bootstrap")
local tests={}
if root then
    local sf=root:FindFirstChild("Services")
    for _,name in ipairs({"PowerService","WireService","DoorService","SaveService","ChapterService","CheckpointService","DialogueService","StalkerService","ChapterRuntime","GrabPackService"}) do
        local m=sf and sf:FindFirstChild(name)
        check(m~=nil,"Missing module: "..name)
        if m then local ok,result=pcall(require,m); check(ok,"Module require failed "..name..": "..tostring(result)) end
    end
    local shared=RS:FindFirstChild("DeadSignalFoundation")
    check(shared and shared.Client:FindFirstChild("SettingsController"),"Missing settings controller")
    local config=shared and require(shared.Shared.GameConfig)
    if config and sf then
        -- Exercise actual services against an isolated temporary graph, not the live chapter graph.
        local Power=require(sf.PowerService); local Wire=require(sf.WireService)
        local power=Power.new(config); local wire=Wire.new(config,power)
        local folder=Instance.new("Folder")
        local function n(id,typ,out,demand,x)
            local p=Instance.new("Part"); p.Name=id; p.Position=Vector3.new(x,0,0); p.Parent=folder
            p:SetAttribute("PowerNodeId",id); p:SetAttribute("PowerNodeType",typ)
            p:SetAttribute("Output",out); p:SetAttribute("Demand",demand)
            p:SetAttribute("WireEndpointId",id); power:RegisterNode(p); wire:RegisterEndpoint(p)
            return p
        end
        n("source","Source",100,0,0); n("door","Consumer",0,50,10)
        n("lift","Consumer",0,70,20); n("isolated","Source",1000,0,100)
        power:SetLink("source","door",true); power:Recalculate()
        check(power:IsEnergized("door"),"Service test: valid circuit rejected")
        power:SetLink("source","lift",true); power:Recalculate()
        check(not power:IsEnergized("door"),"Service test: overload not isolated")
        power:SetEnabled("door",false); power:Recalculate()
        check(power:IsEnergized("lift"),"Service test: redistribution failed")
        local m=Instance.new("Model"); m.Name="testCable"; m:SetAttribute("WireId","test"); m:SetAttribute("MaxLength",15); m.Parent=folder
        wire:RegisterWire(m); wire:Connect("test","source")
        local ok,why=wire:Connect("test","lift")
        check(not ok and why=="too-long","Service test: cable limit ignored")
        check(wire:Connect("test","door"),"Service test: reachable endpoint failed")
        check(wire:Disconnect("test","door"),"Service test: disconnect failed")
        folder:Destroy(); tests.power=true; tests.wire=true
        -- Traverse all actual chapter electrical dependencies using cloned map data.
        local chapterPower=Power.new(config); local chapterWires=Wire.new(config,chapterPower)
        local testFolder=Instance.new("Folder")
        for _,p in pairs(nodes) do local c=p:Clone(); c.Parent=testFolder; chapterPower:RegisterNode(c) end
        for _,p in pairs(ends) do local c=p:Clone(); c.Parent=testFolder; chapterWires:RegisterEndpoint(c) end
        for _,m0 in pairs(wires) do local c=m0:Clone(); c.Parent=testFolder; chapterWires:RegisterWire(c) end
        for _,id in ipairs({"DIST_DOOR","DIST_LIFT","DIST_LIGHTS","DIST_RELAY"}) do chapterPower:SetLink("DIST_BUS",id,true) end
        for _,spec in ipairs({{"IND_CABLE","IND_SOURCE","IND_DOOR"},{"BAT_CABLE","BAT_SOURCE","BAT_DOOR"},{"PROD_CABLE","PROD_SOURCE","PROD_DOOR"},{"DIST_CABLE","DIST_SOURCE","DIST_BUS"}}) do
            chapterPower:SetEnabled(spec[2],true)
            check(chapterWires:Connect(spec[1],spec[2].."_SOCKET"),"Progression source connection: "..spec[1])
            check(chapterWires:Connect(spec[1],spec[3].."_SOCKET"),"Progression destination connection: "..spec[1])
            check(chapterPower:IsEnergized(spec[3]),"Progression gate not energized: "..spec[3])
        end
        chapterPower:SetEnabled("DIST_DOOR",true); chapterPower:Recalculate()
        check(chapterPower:IsEnergized("DIST_DOOR"),"Archive cannot open at 70 U total")
        chapterPower:SetEnabled("DIST_LIFT",true); chapterPower:Recalculate()
        check(not chapterPower:IsEnergized("DIST_LIFT"),"Distribution overload not enforced")
        chapterPower:SetEnabled("DIST_DOOR",false); chapterPower:SetEnabled("DIST_LIGHTS",false)
        chapterPower:SetEnabled("DIST_RELAY",true); chapterPower:Recalculate()
        check(chapterPower:IsEnergized("DIST_LIFT") and chapterPower:IsEnergized("DIST_RELAY"),"Return interlock impossible")
        testFolder:Destroy(); tests.chapterCircuits=true
    end
end
if root and root:FindFirstChild("Services") then
    local Debug=require(root.Services.DebugService)
    local logger=Debug.new({Debug={Enabled=true}})
    for _,message in ipairs(errors) do logger:Error("CHAPTER_VALIDATION",message) end
end
-- Sweep an avatar-sized volume along the complete traversable route, ignoring only powered door panels.
local excludes={}
for _,m in pairs(doors) do table.insert(excludes,m) end
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances=excludes; params.RespectCanCollide=true
local route={{0,12},{0,120},{0,153},{0,218},{0,266},{0,316},{7,320},{7,333},{0,340},{0,366},{0,380},{0,387},
    {4,395},{4,404},{0,411},{0,458},{0,518},{-12,540},{-12,558},{12,566},{12,582},{-12,587},{-12,603},{8,613},{8,631},{0,637},{0,680}}
for i=1,#route-1 do
    local a=Vector3.new(route[i][1],3.6,route[i][2]); local b=Vector3.new(route[i+1][1],3.6,route[i+1][2])
    local result=workspace:Blockcast(CFrame.new(a),Vector3.new(2.6,5.4,2.6),b-a,params)
    check(not result,"Avatar route blocked at segment "..i..": "..(result and result.Instance.Name or ""))
end
local solidImported=0
if map then
    for _,m in ipairs(map:GetDescendants()) do
        if m:IsA("Model") and m:GetAttribute("CollisionRole")=="SolidGeometry" then
            local solid=false
            for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide and p.CanQuery then solid=true; solidImported+=1 end end
            check(solid,"Imported solid has no collision: "..m:GetFullName())
        end
    end
end
local geometry=RS.DeadSignalFoundation:FindFirstChild("GrabPackGeometry")
check(geometry~=nil,"GrabPack geometry missing")
if geometry then
    for _,name in ipairs({"BlueHand","RedHand","LeftLauncher","RightLauncher"}) do check(geometry:FindFirstChild(name)~=nil,"GrabPack part absent: "..name) end
    for _,d in ipairs(geometry:GetDescendants()) do check(not d:IsA("LuaSourceContainer"),"Third-party code found in GrabPack geometry") end
end
check(workspace:FindFirstChild("MenuStage")~=nil,"Missing rendered menu stage")
check(workspace:GetAttribute("GrabPackEnabled")==true,"GrabPack disabled")
check(solidImported>200,"Solid geometry pass not applied")
check(root.Services:FindFirstChild("GrabPackService")~=nil,"GrabPack service missing")
tests.avatarRoute=#errors==0
tests.collisionRoles=solidImported>200
-- Exercise the real GrabPack service with an isolated power graph and a temporary avatar.
if root and geometry then
    local config=require(RS.DeadSignalFoundation.Shared.GameConfig)
    local Power=require(root.Services.PowerService)
    local Grab=require(root.Services.GrabPackService)
    local gp=Power.new(config); local temp=Instance.new("Folder")
    for _,id in ipairs({"GRAB_SOURCE","GRAB_RECEIVER"}) do local n=nodes[id]:Clone(); n.Parent=temp; gp:RegisterNode(n) end
    gp:Recalculate()
    local avatar=Instance.new("Model"); avatar.Name="GrabValidationAvatar"
    local head=Instance.new("Part"); head.Name="Head"; head.Size=Vector3.new(1,1,1); head.Anchored=true; head.Position=Vector3.new(-18,4,5); head.Parent=avatar
    local hrp=head:Clone(); hrp.Name="HumanoidRootPart"; hrp.Parent=avatar
    local hum=Instance.new("Humanoid"); hum.RequiresNeck=false; hum.Parent=avatar
    avatar.Parent=workspace
    local fake={Character=avatar,UserId=-600}
    function fake:GetAttribute(key) return key=="DeadSignalPlaying" end
    local flags={}; local feedback={}
    local grab=Grab.new({power=gp,chapters={SetFlag=function(_,_,key,value) flags[key]=value end},
        interactions={Actions={}},noise={Emit=function() end},debug={Error=function(_,_,err) table.insert(errors,tostring(err)) end},
        remote={FireClient=function(_,_,payload) table.insert(feedback,payload) end}})
    local ok,payload=grab:Fire(fake,"Left",Vector3.new(0,0,1))
    check(ok and payload.kind=="charged","GrabPack blue hand failed to latch onto source")
    head.Position=Vector3.new(17,4,15); hrp.Position=head.Position
    local connected,out=grab:Fire(fake,"Right",Vector3.new(0,0,1))
    check(connected and out.kind=="power-bridge" and gp:IsEnergized("GRAB_RECEIVER"),"GrabPack two-hand power bridge failed")
    check(flags.grabBridge==true,"GrabPack progression flag missing")
    check(not grab:Fire(fake,"Wrong",Vector3.new(0,0,1)),"GrabPack accepted invalid hand")
    check(not grab:Fire(fake,"Right",Vector3.new(0,0,100)),"GrabPack accepted forged ray magnitude")
    grab:Clear(fake)
    check(not gp:IsEnergized("GRAB_RECEIVER"),"GrabPack did not release temporary power link")
    avatar:Destroy(); temp:Destroy()
    tests.grabPack=true
end
local function count(t) local n=0; for _ in pairs(t) do n+=1 end; return n end
return {ok=#errors==0,errors=errors,build=workspace:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,
    solidImportedParts=solidImported,grabPack=geometry~=nil,menuRevision=workspace:GetAttribute("MenuRevision"),rooms=workspace:GetAttribute("ChapterRoomCount"),parts=parts,importedModels=imported,assetIds=assetIds,firstPerson=game:GetService("StarterPlayer").CameraMode.Name,powerNodes=count(nodes),endpoints=count(ends),wires=count(wires),
    doors=count(doors),checkpoints=count(cps),npc=#Tags:GetTagged("DeadSignalRadio"),stalkers=#monsters,serviceTests=tests,
    serverBootstrap=root and root:FindFirstChild("ServerBootstrap")~=nil,
    clientBootstrap=game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DeadSignalFoundationClient")~=nil}
