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
check(parts<2200,"Mobile part budget exceeded: "..parts)
check(#Tags:GetTagged("DeadSignalRadio")==1,"Missing MARA screen")
local monsters=Tags:GetTagged("DeadSignalStalker")
check(#monsters==1,"Expected exactly one stalker")
if monsters[1] then check(monsters[1]:FindFirstChild("HumanoidRootPart")~=nil and monsters[1]:FindFirstChildOfClass("Humanoid")~=nil,"Invalid stalker rig") end
check(workspace.StreamingEnabled,"Streaming is disabled")
check(workspace:GetAttribute("ChapterRoomCount")==12,"Missing sectors")
local root=SS:FindFirstChild("DeadSignalFoundation")
check(root~=nil,"Missing server root")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DeadSignalFoundationClient")~=nil,"Missing client bootstrap")
local tests={}
if root then
    local sf=root:FindFirstChild("Services")
    for _,name in ipairs({"PowerService","WireService","DoorService","SaveService","ChapterService","CheckpointService","DialogueService","StalkerService","ChapterRuntime"}) do
        local m=sf and sf:FindFirstChild(name)
        check(m~=nil,"Missing module: "..name)
        if m then local ok,result=pcall(require,m); check(ok,"Module require failed "..name..": "..tostring(result)) end
    end
    local shared=RS:FindFirstChild("DeadSignalFoundation")
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
local function count(t) local n=0; for _ in pairs(t) do n+=1 end; return n end
return {ok=#errors==0,errors=errors,build=workspace:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,
    rooms=workspace:GetAttribute("ChapterRoomCount"),parts=parts,powerNodes=count(nodes),endpoints=count(ends),wires=count(wires),
    doors=count(doors),checkpoints=count(cps),npc=#Tags:GetTagged("DeadSignalRadio"),stalkers=#monsters,serviceTests=tests,
    serverBootstrap=root and root:FindFirstChild("ServerBootstrap")~=nil,
    clientBootstrap=game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DeadSignalFoundationClient")~=nil}
