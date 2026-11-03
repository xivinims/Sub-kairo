local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local DoorService={}; DoorService.__index=DoorService
function DoorService.new(powerService,options)
 return setmetatable({PowerService=powerService,Doors={},Changed=Instance.new("BindableEvent"),StateChanged=Instance.new("BindableEvent"),Options=options or {}},DoorService)
end
function DoorService:_state(door,value)
 door.state=value; door.model:SetAttribute("DoorState",value); self.StateChanged:Fire(door.id,value)
end
function DoorService:Register(model)
 local id=model:GetAttribute("DoorId") or model.Name
 assert(not self.Doors[id],"Duplicate door id: "..tostring(id))
 local panel=assert(model:FindFirstChild("DoorPanel",true),"DoorPanel missing for "..id)
 assert(panel:IsA("BasePart"),"DoorPanel must be BasePart")
 local offset=model:GetAttribute("OpenOffset")
 if typeof(offset)~="Vector3" then offset=Vector3.new(0,panel.Size.Y+0.5,0) end
 assert(offset.Magnitude>0.05,"Door open offset cannot be zero: "..id)
 local door={id=id,model=model,panel=panel,closedCFrame=panel.CFrame,openCFrame=panel.CFrame+offset,duration=math.clamp(tonumber(model:GetAttribute("OpenDuration")) or 0.7,0.1,3),powerNodeId=model:GetAttribute("PowerNodeId"),locked=model:GetAttribute("Locked")==true,open=false,desiredOpen=false,busy=false,retryGeneration=0}
 self.Doors[id]=door; model:SetAttribute("Open",false); self:_state(door,"Closed"); return door
end
function DoorService:CanOpen(id)
 local door=self.Doors[id]
 if not door then return false,"unknown" end
 if door.locked then return false,"locked" end
 if door.powerNodeId and not self.PowerService:IsEnergized(door.powerNodeId) then return false,"no-power" end
 return true
end
function DoorService:SetLocked(id,locked)
 local door=assert(self.Doors[id],"Unknown door");door.locked=locked==true;door.model:SetAttribute("Locked",door.locked)
end
function DoorService:_occupied(door)
 if self.Options.IsOccupied then return self.Options.IsOccupied(door) end
 for _,player in ipairs(Players:GetPlayers()) do
  local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
  if root and hum and hum.Health>0 then
   local p=door.closedCFrame:PointToObjectSpace(root.Position)
   if math.abs(p.X)<door.panel.Size.X/2+1.1 and math.abs(p.Y)<door.panel.Size.Y/2+1.5 and math.abs(p.Z)<door.panel.Size.Z/2+2 then return true end
  end
 end
 return false
end
function DoorService:_retry(door)
 door.retryGeneration+=1;local generation=door.retryGeneration
 task.delay(0.4,function()
  if door.model.Parent and generation==door.retryGeneration and door.desiredOpen==false and not door.busy then self:SetOpen(door.id,false) end
 end)
end
function DoorService:_tween(door,target,guard)
 local tween=TweenService:Create(door.panel,TweenInfo.new(door.duration,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{CFrame=target})
 local blocked=false;local finished=false
 local connection=tween.Completed:Connect(function() finished=true end)
 tween:Play()
 if guard then task.spawn(function()
  while not finished and tween.PlaybackState==Enum.PlaybackState.Playing do
   if self:_occupied(door) then blocked=true;tween:Cancel();break end
   task.wait(0.04)
  end
 end) end
 while not finished do task.wait(0.02) end
 connection:Disconnect()
 return not blocked
end
function DoorService:SetOpen(id,shouldOpen,instant)
 local door=assert(self.Doors[id],"Unknown door")
 shouldOpen=shouldOpen==true
 if shouldOpen then local ok,reason=self:CanOpen(id);if not ok then return false,reason end end
 door.desiredOpen=shouldOpen
 if shouldOpen then door.retryGeneration+=1 end
 if door.busy then return false,"busy" end
 if not shouldOpen and not instant and self:_occupied(door) then self:_state(door,"Waiting");self:_retry(door);return false,"occupied" end
 if door.open==shouldOpen then self:_state(door,shouldOpen and "Open" or "Closed");return true end
 door.busy=true;self:_state(door,shouldOpen and "Opening" or "Closing")
 local target=shouldOpen and door.openCFrame or door.closedCFrame
 if instant then door.panel.CFrame=target
 elseif not self:_tween(door,target,not shouldOpen) then
  -- A player can enter after the close starts: stop immediately and move back to the safe open position.
  self:_state(door,"Opening");self:_tween(door,door.openCFrame,false)
  door.open=true;door.busy=false;door.model:SetAttribute("Open",true);self.Changed:Fire(id,true)
  if door.desiredOpen then self:_state(door,"Open") else self:_state(door,"Waiting");self:_retry(door) end
  return false,"occupied"
 end
 door.open=shouldOpen;door.busy=false;door.model:SetAttribute("Open",shouldOpen)
 self:_state(door,shouldOpen and "Open" or "Closed");self.Changed:Fire(id,shouldOpen)
 if door.desiredOpen~=shouldOpen then task.defer(function() if door.model.Parent then self:SetOpen(id,door.desiredOpen) end end) end
 return true
end
return DoorService
