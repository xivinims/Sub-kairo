local Tags=game:GetService("CollectionService")
local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local Grab={}; Grab.__index=Grab
local RANGE=42
local ALLOWED={CablePickup=true,CableSocket=true,Sequence=true,PowerSwitch=true,BatteryPickup=true,BatteryDock=true,ToggleDoor=true}
local function ancestor(obj,tag)
    while obj and obj~=workspace do if Tags:HasTag(obj,tag) then return obj end; obj=obj.Parent end
end
function Grab.new(ctx)
    return setmetatable({ctx=ctx,last={},charge={},links={},pullBusy={}},Grab)
end
function Grab:_unlink(player)
    local link=self.links[player]
    self.links[player]=nil
    if not link then return end
    -- Another player may still be holding the same physical circuit closed.
    for _,other in pairs(self.links) do
        if other[1]==link[1] and other[2]==link[2] then return end
    end
    self.ctx.power:SetLink(link[1],link[2],false)
    self.ctx.power:Recalculate()
end
function Grab:Clear(player)
    self:_unlink(player)
    self.charge[player]=nil
end
function Grab:Fire(player,side,direction)
    if side~="Left" and side~="Right" then return false,"side" end
    if not player:GetAttribute("DeadSignalPlaying") or player:GetAttribute("DeadSignalPaused") then return false,"inactive" end
    if typeof(direction)~="Vector3" or direction.Magnitude~=direction.Magnitude or direction.Magnitude<0.95 or direction.Magnitude>1.05 then return false,"direction" end
    self.last[player]=self.last[player] or {}
    if os.clock()-(self.last[player][side] or 0)<0.45 then return false,"cooldown" end
    self.last[player][side]=os.clock()
    local char=player.Character; local head=char and char:FindFirstChild("Head"); local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not head or not hum or hum.Health<=0 then return false,"character" end
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
    local origin=head.Position
    local hit=workspace:Raycast(origin,direction*RANGE,params)
    local target=hit and hit.Position or origin+direction*RANGE
    local payload={side=side,origin=origin,target=target,latched=false,kind="miss"}
    if hit then
        local source=ancestor(hit.Instance,"DeadSignalGrabSource")
        local receiver=ancestor(hit.Instance,"DeadSignalGrabReceiver")
        local pullable=ancestor(hit.Instance,"DeadSignalPullable")
        local interactable=ancestor(hit.Instance,"DeadSignalGrabInteractable")
        if source and side=="Left" and self.ctx.power:IsEnergized(source:GetAttribute("PowerNodeId")) then
            self:Clear(player)
            local record={node=source:GetAttribute("PowerNodeId"),untilTime=os.clock()+8,source=source}
            self.charge[player]=record; payload.latched=true; payload.kind="charged"; payload.duration=8
            task.delay(8,function() if self.charge[player]==record then self:Clear(player); self.ctx.remote:FireClient(player,{kind="retract"}) end end)
        elseif receiver and side=="Right" and self.charge[player] and self.charge[player].untilTime>os.clock() then
            local record=self.charge[player]
            if (head.Position-record.source.Position).Magnitude>RANGE then self:Clear(player); return false,"source-range" end
            local node=receiver:GetAttribute("PowerNodeId")
            self:_unlink(player)
            self.ctx.power:SetLink(record.node,node,true); self.ctx.power:Recalculate(); self.links[player]={record.node,node}
            record.receiver=receiver
            payload.latched=true; payload.kind="power-bridge"; payload.duration=math.max(0.2,record.untilTime-os.clock())
            self.ctx.chapters:SetFlag(player,"grabBridge",true)
        elseif pullable and pullable.PrimaryPart and not self.pullBusy[pullable] then
            self.pullBusy[pullable]=true; payload.kind="pull"
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then
                local from=pullable:GetPivot(); local delta=root.Position-from.Position
                delta=Vector3.new(delta.X,0,delta.Z)
                if delta.Magnitude>5 then
                    local travel=delta.Unit*math.min(7,delta.Magnitude-5)
                    local collisionParams=RaycastParams.new(); collisionParams.FilterType=Enum.RaycastFilterType.Exclude
                    collisionParams.FilterDescendantsInstances={pullable,char}; collisionParams.RespectCanCollide=true
                    local obstruction=workspace:Blockcast(pullable.PrimaryPart.CFrame,pullable.PrimaryPart.Size*0.95,travel,collisionParams)
                    if obstruction then travel=travel.Unit*math.max(0,obstruction.Distance-0.25) end
                    local cf=Instance.new("CFrameValue"); cf.Value=from
                    local connection=cf.Changed:Connect(function(v) if pullable.Parent then pullable:PivotTo(v) end end)
                    local tween=TweenService:Create(cf,TweenInfo.new(0.55,Enum.EasingStyle.Quad),{Value=from+travel})
                    tween:Play(); task.delay(0.65,function() connection:Disconnect(); cf:Destroy(); self.pullBusy[pullable]=nil end)
                else self.pullBusy[pullable]=nil end
            else self.pullBusy[pullable]=nil end
        elseif interactable then
            local prompt=interactable:FindFirstChildOfClass("ProximityPrompt")
            local action=prompt and prompt:GetAttribute("ActionId")
            if action and ALLOWED[action] and self.ctx.interactions.Actions[action] then
                local ok,result=pcall(self.ctx.interactions.Actions[action],player,prompt)
                if not ok then self.ctx.debug:Error("GRAB_INTERACTION",tostring(result)) end
                payload.kind=ok and result~=false and "interaction" or "rejected"
            end
        end
        self.ctx.noise:Emit(target,0.35,"grabpack",hit.Instance)
    end
    self.ctx.remote:FireClient(player,payload)
    return true,payload
end
function Grab:TetherValid(player,record)
    local char=player.Character
    local head=char and char:FindFirstChild("Head")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not head or not hum or hum.Health<=0 or player:GetAttribute("DeadSignalPlaying")~=true
        or os.clock()>=record.untilTime then return false end
    for _,endpoint in pairs({source=record.source,receiver=record.receiver}) do
        if not endpoint.Parent then return false end
        local delta=endpoint.Position-head.Position
        if delta.Magnitude>RANGE then return false end
        if delta.Magnitude>0.01 then
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={char}
            local obstruction=workspace:Raycast(head.Position,delta,params)
            if obstruction and obstruction.Instance~=endpoint and not obstruction.Instance:IsDescendantOf(endpoint) then return false end
        end
    end
    return true
end
function Grab:Start()
    -- Range, death and occlusion are checked at 5 Hz, never every render frame.
    task.spawn(function()
        while true do
            task.wait(0.2)
            for player,record in pairs(self.charge) do
                local valid=self:TetherValid(player,record)
                if not valid then
                    self:Clear(player)
                    self.ctx.remote:FireClient(player,{kind="retract"})
                end
            end
        end
    end)
    self.ctx.action.OnServerEvent:Connect(function(player,side,direction)
        if side=="Retract" then self:Clear(player); self.ctx.remote:FireClient(player,{kind="retract"}); return end
        self:Fire(player,side,direction)
    end)
    Players.PlayerRemoving:Connect(function(p) self:Clear(p); self.last[p]=nil end)
end
return Grab
