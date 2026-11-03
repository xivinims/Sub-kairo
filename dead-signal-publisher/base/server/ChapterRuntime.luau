local Players=game:GetService("Players")
local Tags=game:GetService("CollectionService")
local Run={}; Run.__index=Run
local milestones={IND_DOOR="induction",BAT_DOOR="battery",PROD_DOOR="production"}
local objectives={"Feche o circuito na sala de indução.","Encontre uma bateria e alimente a montagem.","Arme a partida a frio: 2 → 1 → 3.","Distribua os 100 U e encontre MARA.","Desligue porta e luzes. Ligue elevador e relé.","Siga a sinalização até a descarga de emergência.","FIM DA BUILD DE TESTE — consulte o terminal."}
local ranks={CH01_START=1,CH01_BATTERY=2,CH01_PRODUCTION=3,CH01_DISTRIBUTION=4,CH01_DARK=5,CH01_CHASE=6,CH01_SAFE=7}
local function position(p) return p:IsA("Attachment") and p.WorldPosition or p.Position end
function Run.new(ctx)
    local self=setmetatable(ctx,Run)
    self.cells={}; self.docks={}; self.carried={}; self.sequence=0; self.stage=1
    self.connections={}; self.chaseAt=nil; self.observed=false; self.latch=false; self.lastSwitch={}
    self.home={}; self.beams={}; self.dropAt={}; self.alive=true
    return self
end
function Run:Feedback(player,text,kind)
    self.remotes[self.protocol.Events.ChapterFeedback]:FireClient(player,text,kind or "info")
end
function Run:Active()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("DeadSignalPlaying") and not p:GetAttribute("DeadSignalPaused") then table.insert(list,p) end end
    return list
end
function Run:Flag(flag,value)
    for _,p in ipairs(self:Active()) do self.chapters:SetFlag(p,flag,value) end
end
function Run:Objective(stage)
    self.stage=math.max(self.stage,stage)
    for _,p in ipairs(self:Active()) do
        for id,state in pairs(self.save:Get(p).objectives) do
            if state=="active" then self.chapters:SetObjectiveState(p,id,"complete") end
        end
        self.chapters:SetObjectiveState(p,objectives[self.stage],"active")
    end
end
function Run:Say(player,id)
    if self.dialogue:CanStart(player) then self.dialogue:Start(player,id) end
end
function Run:SetCell(id,dock)
    local cell=self.cells[id]; if not cell then return end
    if cell.dock then self.docks[cell.dock]=nil end
    cell.dock=dock
    local part=cell.model.PrimaryPart
    if dock then
        self.docks[dock]=id
        local holder=workspace.SignalworksChapter01:FindFirstChild("BatteryDock_"..dock,true)
        cell.model:PivotTo(holder.CFrame*CFrame.new(0,2.2,0))
        part.Transparency=0
    else cell.model:PivotTo(self.home[id]) end
    self.power:SetEnabled("BAT_SOURCE",self.docks.BAT_SOURCE~=nil)
    self.power:Recalculate()
end
function Run:Restore(player)
    local data=self.save:Get(player)
    if not ranks[data.checkpoint] then data.checkpoint="CH01_START" end
    local rank=ranks[data.checkpoint]
    if not player:GetAttribute("DeadSignalPlaying") then return end
    self.stage=math.max(self.stage,rank)
    -- Persistent milestones restore solved circuits; source placement is deterministic.
    local specs={{"induction","IND_CABLE","IND_SOURCE","IND_DOOR",2},{"battery","BAT_CABLE","BAT_SOURCE","BAT_DOOR",3},{"production","PROD_CABLE","PROD_SOURCE","PROD_DOOR",4}}
    for _,s in ipairs(specs) do
        if data.flags[s[1]] or rank>=s[5] then
            if s[1]=="battery" then self:SetCell("CELL_1","BAT_SOURCE") end
            if s[1]=="production" then self.power:SetEnabled("PROD_SOURCE",true) end
            local w=self.wires.Wires[s[2]]
            if not w.endpointA and not w.endpointB then
                self.wires:Connect(s[2],s[3].."_SOCKET"); self.wires:Connect(s[2],s[4].."_SOCKET")
            end
        end
    end
    if rank>=5 or data.flags.archive then
        self.latch=true
        local d=self.doors.Doors.ARCHIVE_GATE; d.powerNodeId=nil
        self.doors:SetOpen("ARCHIVE_GATE",true,true)
        local w=self.wires.Wires.DIST_CABLE
        if not w.endpointA and not w.endpointB then
            self.wires:Connect("DIST_CABLE","DIST_SOURCE_SOCKET"); self.wires:Connect("DIST_CABLE","DIST_BUS_SOCKET")
        end
        for _,id in ipairs({"DIST_DOOR","DIST_LIGHTS"}) do self.power:SetEnabled(id,false) end
        for _,id in ipairs({"DIST_LIFT","DIST_RELAY"}) do self.power:SetEnabled(id,true) end
        self.power:Recalculate()
    end
    if rank>=7 then self.doors:SetOpen("BLAST_GATE",true,true) end
    self.chapters:SetObjectiveState(player,objectives[self.stage],"active")
end
function Run:Start()
    self.dialogue:RegisterSpeaker("MARA",{displayName="MARA · Canal 04",color=Color3.fromRGB(159,203,177)})
    local lines={
        maintenanceRecording={"Registro de manutenção: a alimentação de contato dura oito segundos. Uma mão segura a fonte; a outra fecha o circuito.","A linha antiga nunca devia ter sido ligada ao arquivo. Alguém refez a conexão depois do fechamento."},
        intro={"Você voltou pelo sinal? A recepção ainda não sabe que fechamos.","Sou MARA. Estou no arquivo. Primeiro, ligue os dois terminais da indução. O cabo tem limite."},
        battery={"O acumulador está respondendo. Existem duas células. Pode retirar uma do encaixe quando precisar.","As máquinas não dividem a energia por educação. Você vai ter que escolher."},
        production={"Essa linha montava aparelhos que aprendiam vozes. Um deles começou a repetir vozes que nunca gravamos.","Se alguma coisa estiver olhando da passarela... não chame por ela."},
        archive={"Você chegou. O rosto no monitor é só uma interface. Eu ainda estou aqui embaixo.","Abra a porta com 50 U. Depois, volte ao distribuidor: corte porta e iluminação, ligue elevador e relé. 70 mais 30. A porta do arquivo ficará travada aberta.","Aquela coisa não procura luz. Procura mudança."},
        dark={"Ventiladores desligados. Agora seus passos chegam mais longe.","Siga as luzes âmbar. Se ele vier, chegue à descarga. Eu seguro o contato."},
        safe={"A descarga rompeu o sinal dele. Só por enquanto.","O terminal guardou sua rota. A descida ao nível menos dois será a próxima etapa.","FIM DA BUILD DE TESTE. Você atravessou a primeira linha."},
        hint={"O quadro admite 100 U. A porta usa 50, o elevador 70, as luzes 20 e o relé 30.","Sobrecarga desliga o circuito. Desligue cargas até voltar ao limite."},
    }
    for id,texts in pairs(lines) do
        local def={}; for _,text in ipairs(texts) do table.insert(def,{speaker="MARA",text=text,radio=true}) end
        self.dialogue:RegisterDialogue(id,def)
    end
    for _,m in ipairs(Tags:GetTagged("DeadSignalBattery")) do
        local id=m:GetAttribute("BatteryId"); self.cells[id]={model=m}; self.home[id]=m:GetPivot()
    end
    for id,w in pairs(self.wires.Wires) do
        self.home[id]=w.model:GetPivot()
        local a=Instance.new("Attachment"); a.Name="CableA"; a.Parent=w.model.PrimaryPart
        local b=Instance.new("Attachment"); b.Name="CableB"; b.Parent=w.model.PrimaryPart
        local beam=Instance.new("Beam"); beam.Attachment0=a; beam.Attachment1=b
        beam.Width0=0.17; beam.Width1=0.17; beam.Segments=12; beam.FaceCamera=true
        beam.CurveSize0=2; beam.CurveSize1=-2; beam.Color=ColorSequence.new(Color3.fromRGB(183,135,54)); beam.Parent=w.model.PrimaryPart
        self.beams[id]={a=a,b=b,beam=beam}
    end
    for _,id in ipairs({"DIST_DOOR","DIST_LIFT","DIST_LIGHTS","DIST_RELAY"}) do self.power:SetLink("DIST_BUS",id,true) end
    self.power:Recalculate()
    local function register(id,fn)
        self.interactions:RegisterAction(id,function(p,q)
            if not p:GetAttribute("DeadSignalPlaying") then return false end
            return fn(p,q)
        end)
    end
    register("CablePickup",function(p,q)
        local id=q:GetAttribute("WireId"); local w=self.wires.Wires[id]
        if w.endpointA and w.endpointB then self:Feedback(p,"Retire uma ponta no terminal antes de levar o cabo."); return false end
        local ok=self.wires:BeginCarry(p,id)
        if ok then
            self.remotes[self.protocol.Events.WireState]:FireClient(p,"carry-start",self.wires:GetState(id))
            self:Feedback(p,"Cabo na mão. Conecte uma ponta em cada terminal. Q / SOLTAR para largar.","cable")
        end
        return ok
    end)
    register("CableSocket",function(p,q)
        local id=q:GetAttribute("EndpointId"); local e=self.wires.Endpoints[id]
        local carried=self.wires.PlayerCarry[p]
        if e.occupiedBy then
            local w=self.wires.Wires[e.occupiedBy]
            if w.carriedBy and w.carriedBy~=p then return false end
            local wid=w.id; self.wires:Disconnect(wid,id)
            if not carried then self.wires:BeginCarry(p,wid) end
            self.remotes[self.protocol.Events.WireState]:FireClient(p,"carry-start",self.wires:GetState(wid))
            return true
        end
        if not carried then self:Feedback(p,"Pegue um cabo primeiro."); return false end
        local ok,why=self.wires:Connect(carried,id)
        if not ok then self:Feedback(p,why=="too-long" and "O cabo não alcança. Procure uma rota mais curta." or "Terminal ocupado ou incompatível."); return false end
        local state=self.wires:GetState(carried)
        self.remotes[self.protocol.Events.WireState]:FireAllClients("connected",{wire=state})
        self.noise:Emit(position(q.Parent),0.5,"cable")
        if state.endpointA and state.endpointB then
            self.wires:EndCarry(p); self.remotes[self.protocol.Events.WireState]:FireClient(p,"carry-end",state)
        end
        self:Feedback(p,"Contato fechado.","connect"); return true
    end)
    register("BatteryPickup",function(p,q)
        local id=q:GetAttribute("BatteryId"); local cell=self.cells[id]
        if self.carried[p] or cell.carrier then return false end
        if cell.dock then self:SetCell(id,nil) end
        cell.carrier=p; self.carried[p]=id
        cell.model:PivotTo(CFrame.new(0,-100,0))
        self.save:Mutate(p,function(d) d.inventory.battery=id end)
        self:Feedback(p,"Bateria equipada. Use um encaixe para instalar.","battery"); return true
    end)
    register("BatteryDock",function(p,q)
        local dock=q:GetAttribute("DockId"); local id=self.carried[p]
        if self.docks[dock] then
            if id then self:Feedback(p,"Você já carrega uma bateria."); return false end
            id=self.docks[dock]; self:SetCell(id,nil); self.cells[id].carrier=p; self.carried[p]=id
            self.cells[id].model:PivotTo(CFrame.new(0,-100,0))
        elseif id then
            self.cells[id].carrier=nil; self.carried[p]=nil; self:SetCell(id,dock)
        else self:Feedback(p,"Encontre uma bateria nas bancadas."); return false end
        self.save:Mutate(p,function(d) d.inventory.battery=self.carried[p]; d.flags.batteryDock=dock end)
        self:Feedback(p,"Encaixe atualizado.","battery"); return true
    end)
    register("Sequence",function(p,q)
        if not self.power:IsEnergized("BAT_DOOR") then return false end
        local expected=({2,1,3})[self.sequence+1]
        if q:GetAttribute("SequenceIndex")==expected then
            self.sequence+=1; self:Feedback(p,"Relé confirmado: "..self.sequence.." / 3","connect")
            if self.sequence==3 then self.power:SetEnabled("PROD_SOURCE",true); self.power:Recalculate(); self:Flag("sequence",true) end
        else
            self.sequence=0; self.power:SetEnabled("PROD_SOURCE",false); self.power:Recalculate()
            self.noise:Emit(q.Parent.Position,1,"relay-fault"); self:Feedback(p,"Falha de sequência. Observe o padrão das três luzes dos relés.","fault")
        end
        return true
    end)
    register("PowerSwitch",function(p,q)
        local id=q:GetAttribute("NodeId")
        local now=os.clock(); if now-(self.lastSwitch[p] or 0)<0.4 then return false end; self.lastSwitch[p]=now
        self.power:SetEnabled(id,not self.power.Nodes[id].enabled)
        local state=self.power:Recalculate()
        q.Parent.Color=self.power.Nodes[id].enabled and Color3.fromRGB(133,153,104) or Color3.fromRGB(47,66,62)
        self.noise:Emit(q.Parent.Position,state.overloaded and 1.5 or 0.6,"switch")
        self:Feedback(p,state.overloaded and "SOBRECARGA. Desligue uma das cargas." or "Circuito atualizado — "..id,state.overloaded and "fault" or "connect")
        if self.power:IsEnergized("DIST_LIFT") and self.power:IsEnergized("DIST_RELAY") then self:Objective(5) end
        return true
    end)
    register("LiftRide",function(p,q)
        if not self.power:IsEnergized("DIST_LIFT") or not self.power:IsEnergized("DIST_RELAY") then
            self:Feedback(p,"Elevador: ligue o motor de 70 U e o relé de 30 U."); return false
        end
        if self.liftBusy then return false end
        self.liftBusy=true
        local platform=q.Parent
        local start=platform.CFrame
        local targetY=platform.Position.Y>5 and 0.4 or 10.4
        task.spawn(function()
            local previous=platform.Position
            for i=1,60 do
                if not platform.Parent then break end
                local alpha=i/60; local eased=alpha*alpha*(3-2*alpha)
                local nextCF=start:Lerp(CFrame.new(start.X,targetY,start.Z),eased)
                platform.CFrame=nextCF
                local delta=platform.Position-previous; previous=platform.Position
                for _,rider in ipairs(self:Active()) do
                    local char=rider.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local rel=platform.CFrame:PointToObjectSpace(root.Position)
                        if math.abs(rel.X)<5.2 and math.abs(rel.Z)<5.2 and rel.Y>0 and rel.Y<5.5 then char:PivotTo(char:GetPivot()+delta) end
                    end
                end
                task.wait(0.05)
            end
            self.liftBusy=false
        end)
        self.noise:Emit(platform.Position,1,"elevator")
        self:Feedback(p,"Elevador em movimento.","elevator"); return true
    end)
    register("Mara",function(p)
        self:Say(p,self.stage>=7 and "safe" or self.latch and "hint" or "archive"); return true
    end)
    register("Discharge",function(p)
        if not self.chaseAt then self:Feedback(p,"O relé de emergência aguarda uma falha de sinal."); return false end
        self.stalker:SetState("Cooldown"); self.stalker.Enabled=false; self.chaseAt=nil
        self.doors:SetOpen("BLAST_GATE",true)
        self:Flag("escaped",true); self:Objective(7)
        self:Feedback(p,"Descarga concluída. Entre no refúgio!","fault")
        return true
    end)
    self.power.NodeChanged.Event:Connect(function(id,on)
        for _,p in ipairs(workspace.SignalworksChapter01:GetDescendants()) do
            if p:IsA("BasePart") and p:GetAttribute("LightPowerNode")==id then
                local l=p:FindFirstChildOfClass("PointLight"); if l then l.Enabled=on end
                p.Material=on and Enum.Material.Neon or Enum.Material.Glass
            end
        end
        if on and id=="IND_DOOR" and not self.observed then
            local cf=CFrame.new(0,20,347)
            if self:HiddenAt(cf) and self:HiddenAt(self.stalker.Root.CFrame) then
                self.observed=true; self.stalker.Model:PivotTo(cf); self.stalker:Activate("Observe")
            end
        end
        if on and milestones[id] then
            self:Flag(milestones[id],true)
            self:Objective(id=="IND_DOOR" and 2 or id=="BAT_DOOR" and 3 or 4)
        end
        if id=="DIST_LIFT" or id=="DIST_RELAY" then
            -- Elevator interlock requires both the motor and safety relay, not just one live terminal.
            local open=self.power:IsEnergized("DIST_LIFT") and self.power:IsEnergized("DIST_RELAY")
            task.defer(function() self.doors:SetOpen("RETURN_GATE",open) end)
        end
    end)
    -- Disable generic auto-open for the interlocked return gate.
    self.doors.Doors.RETURN_GATE.model:SetAttribute("AutoOpenWhenPowered",false)
    self.remotes[self.protocol.Events.ChapterAction].OnServerEvent:Connect(function(p,action,settings)
        if action=="leave" then p:Kick("Você saiu de Dead Signal."); return end
        if action=="settings" and type(settings)=="table" then
            self.save:Mutate(p,function(d)
                local bounds={masterVolume={0,1},sfxVolume={0,1},dialogueVolume={0,1},fov={60,100},sensitivity={0.25,2},brightness={-0.1,0.25}}
                for k,range in pairs(bounds) do
                    local v=settings[k]
                    if type(v)=="number" and v==v then d.settings[k]=math.clamp(v,range[1],range[2]) end
                end
                for _,k in ipairs({"reducedMotion","shadows","subtitles"}) do if type(settings[k])=="boolean" then d.settings[k]=settings[k] end end
                if settings.graphics=="Baixo" or settings.graphics=="Médio" or settings.graphics=="Alto" then d.settings.graphics=settings.graphics end
            end)
            return
        end
        if action=="pause" and type(settings)=="boolean" then
            p:SetAttribute("DeadSignalPaused",settings)
            local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=settings and 0 or 16 end
            return
        end
        if action=="movement" and p:GetAttribute("DeadSignalPlaying") and not p:GetAttribute("DeadSignalPaused") then
            local mode=settings
            if mode~="walk" and mode~="sprint" and mode~="crouch" then return end
            local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=self.wires.PlayerCarry[p] and 13 or mode=="crouch" and 8 or mode=="sprint" and 22 or 16 end
            return
        end
        if action~="continue" and action~="new" and action~="drop" then return end
        if action=="drop" then
            self.wires:EndCarry(p)
            self.remotes[self.protocol.Events.WireState]:FireClient(p,"carry-end",{})
            local id=self.carried[p]
            if id then self.cells[id].carrier=nil; self.carried[p]=nil; self:SetCell(id,nil) end
            return
        end
        if p:GetAttribute("DeadSignalPlaying") then return end
        if action=="new" then
            local hasSession=false
            for _,other in ipairs(Players:GetPlayers()) do if other:GetAttribute("DeadSignalPlaying") then hasSession=true end end
            if hasSession then self:Feedback(p,"Há uma sessão em andamento. Use Continuar."); return end
            self.save:Mutate(p,function(d)
                local defaults=self.save:DefaultData()
                d.checkpoint=defaults.checkpoint; d.flags={}; d.objectives={}; d.inventory={}
            end)
            self:ResetWorld()
        end
        p:SetAttribute("DeadSignalPlaying",true)
        p:SetAttribute("DeadSignalPaused",false)
        self:Restore(p); self.checkpoints:RespawnCharacter(p,p.Character)
        self:Feedback(p,"Sinal recebido.","started")
    end)
    Players.PlayerRemoving:Connect(function(p)
        local id=self.carried[p]; if id then self.cells[id].carrier=nil; self:SetCell(id,nil) end
        self.carried[p]=nil; self.lastSwitch[p]=nil
    end)
    task.spawn(function()
        while self.alive do
            local ok,err=pcall(function() self:Step() end)
            if not ok then self.debug:Error("CHAPTER_STEP",tostring(err)); self.alive=false end
            task.wait(0.2)
        end
    end)
end
function Run:ResetWorld()
    self.stage=1; self.latch=false; self.observed=false; self.observationSeen=nil; self.sequence=0; self.chaseAt=nil
    self.stalker:Deactivate(); self.stalker.Model:PivotTo(CFrame.new(0,6,710))
    for id,w in pairs(self.wires.Wires) do
        if w.endpointA then self.wires:Disconnect(id,w.endpointA) end
        if w.endpointB then self.wires:Disconnect(id,w.endpointB) end
    end
    for _,id in ipairs({"BAT_SOURCE","PROD_SOURCE","DIST_DOOR","DIST_LIFT","DIST_RELAY"}) do self.power:SetEnabled(id,false) end
    self.power:SetEnabled("DIST_LIGHTS",true)
    for id in pairs(self.cells) do self:SetCell(id,nil) end
    self.doors.Doors.ARCHIVE_GATE.powerNodeId="DIST_DOOR"
    for id in pairs(self.doors.Doors) do self.doors:SetOpen(id,false,true) end
    self.power:Recalculate()
end
function Run:HiddenAt(cf)
    -- Conservative server occlusion test: never relocate a rig in a player's unobstructed view.
    for _,p in ipairs(Players:GetPlayers()) do
        local head=p.Character and p.Character:FindFirstChild("Head")
        if head then
            local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={p.Character,self.stalker.Model}
            for _,offset in ipairs({Vector3.new(0,0,0),Vector3.new(0,4,0),Vector3.new(2,0,0),Vector3.new(-2,0,0)}) do
                if not workspace:Raycast(head.Position,cf.Position+offset-head.Position,params) then return false end
            end
        end
    end
    return true
end
function Run:Zone(p,id)
    if ranks[id] then
        if id=="CH01_CHASE" and self.stage>=7 then return end
        local current=self.save:Get(p).checkpoint
        if ranks[id]>(ranks[current] or 1) then
            self.checkpoints:Set(p,id); task.spawn(function() self.save:Save(p,true) end)
            if id=="CH01_DARK" then self:Say(p,"dark") end
            if id=="CH01_SAFE" then self:Say(p,"safe"); self:Objective(7) end
        end
    elseif id=="INTRO" and not self.chapters:GetFlag(p,"intro") then self.chapters:SetFlag(p,"intro",true); self:Say(p,"intro")
    elseif id=="OBSERVATION" and self.power:IsEnergized("PROD_DOOR") and not self.observed then
        local cf=CFrame.new(0,20,347)
        if self:HiddenAt(cf) and self:HiddenAt(self.stalker.Root.CFrame) then
            self.observed=true; self.stalker.Model:PivotTo(cf); self.stalker:Activate("Observe")
        end
        self:Say(p,"production")
    elseif id=="RADIO" and not self.latch then
        self.latch=true; self:Flag("archive",true)
        self.doors.Doors.ARCHIVE_GATE.powerNodeId=nil
        self:Say(p,"archive")
    elseif id=="CHASE" and not self.chaseAt and self.stage<7 then
        local cf=CFrame.new(14,6,514)
        if self:HiddenAt(cf) and self:HiddenAt(self.stalker.Root.CFrame) then
            self.stalker.Model:PivotTo(cf); self.stalker:Activate("Patrol"); self.stalker.Target=p
            self.stalker.LastSeenPosition=p.Character:GetPivot().Position; self.stalker.LastSeenAt=os.clock()
            self.stalker:SetState("Chase"); self.chaseAt=os.clock(); self:Objective(6)
            self:Feedback(p,"CORRA ATÉ A DESCARGA.","chase")
        end
    elseif id=="END" and not self.chapters:GetFlag(p,"chapterTestComplete") then
        self:Flag("chapterTestComplete",true)
        self:Feedback(p,"FIM DA BUILD DE TESTE", "info")
    end
end
function Run:Step()
    local now=os.clock()
    local pattern=math.floor(now/0.75)%6+1
    for _,lamp in ipairs(Tags:GetTagged("DeadSignalSequenceLamp")) do
        local on=self.stage==3 and pattern==lamp:GetAttribute("SequenceOrder")
        lamp.Color=on and Color3.fromRGB(223,186,91) or Color3.fromRGB(57,60,49)
        lamp.Material=on and Enum.Material.Neon or Enum.Material.Metal
    end
    for _,p in ipairs(self:Active()) do
        local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health>0 then
            for _,zone in ipairs(Tags:GetTagged("DeadSignalChapterZone")) do
                local localPos=zone.CFrame:PointToObjectSpace(root.Position)
                if math.abs(localPos.X)<=zone.Size.X/2+1 and math.abs(localPos.Z)<=zone.Size.Z/2+1 and math.abs(localPos.Y)<=8 then self:Zone(p,zone:GetAttribute("ZoneId")) end
            end
            if self.chaseAt and self.stalker.State=="Chase" and (root.Position-self.stalker.Root.Position).Magnitude<4 then
                hum.Health=0; self.stalker:Deactivate(); self.chaseAt=nil
                self.stalker.Model:PivotTo(CFrame.new(0,6,710))
                self.save:Mutate(p,function(d) d.stats.deaths+=1 end)
            end
        elseif self.carried[p] then
            local id=self.carried[p]; self.carried[p]=nil; self.cells[id].carrier=nil; self:SetCell(id,nil)
        end
    end
    for id,w in pairs(self.wires.Wires) do
        local a=w.endpointA and position(self.wires.Endpoints[w.endpointA].instance) or self.home[id].Position
        local b=w.endpointB and position(self.wires.Endpoints[w.endpointB].instance) or a+Vector3.new(2,0,0)
        local carrier=w.carriedBy
        if carrier then
            local root=carrier.Character and carrier.Character:FindFirstChild("HumanoidRootPart")
            if not root or not carrier.Character:FindFirstChildOfClass("Humanoid") or carrier.Character:FindFirstChildOfClass("Humanoid").Health<=0 then
                self.wires:EndCarry(carrier)
            elseif (root.Position-a).Magnitude>w.maxLength then
                self.wires:EndCarry(carrier); self:Feedback(carrier,"Limite do cabo. A ponta foi solta.","fault")
                self.remotes[self.protocol.Events.WireState]:FireClient(carrier,"carry-end",{})
            else b=root.Position+root.CFrame.LookVector*2 end
        end
        local visual=self.beams[id]
        visual.a.WorldPosition=a; visual.b.WorldPosition=b
        visual.beam.Enabled=w.endpointA~=nil or carrier~=nil
    end
    -- Remove observation only when the whole silhouette is occluded.
    if self.stalker.State=="Observe" and not self:HiddenAt(self.stalker.Root.CFrame) then self.observationSeen=now end
    if self.stalker.State=="Observe" and self.observationSeen and now-self.observationSeen>1 and self:HiddenAt(self.stalker.Root.CFrame) then
        self.stalker:Deactivate(); self.stalker.Model:PivotTo(CFrame.new(0,6,710))
    end
end
return Run
