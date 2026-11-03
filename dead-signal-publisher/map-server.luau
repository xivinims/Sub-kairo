local Players=game:GetService("Players")
local Tags=game:GetService("CollectionService")
local Power=require(script.Parent.PowerService)
local Door=require(script.Parent.DoorService)
local Debug=require(script.Parent.DebugService)
local debug=Debug.new({})
local power=Power.new({Power={DefaultVoltage=100,OverloadGraceSeconds=1.5,TickRate=0.2}})
local doors=Door.new(power)
for _,node in ipairs(workspace.MapSectors:GetChildren()) do power:RegisterNode(node) end
for _,id in ipairs({"RECEPTION","WORKSHOP","POWER","STORAGE","OBSERVATION","PARK"}) do power:SetLink(id.."_SUPPLY",id.."_LIGHTS",true) end
power:Recalculate()
for _,model in ipairs(Tags:GetTagged("DeadSignalMapDoor")) do doors:Register(model) end
local prompts={}
local throttle={}
local Guard=require(script.Parent.MapInteractionGuard)
local function canUse(player,prompt)
 return Guard.CanUse(player,prompt,os.clock(),throttle,workspace)
end
local function syncSector(id)
 local on=power:IsEnergized(id.."_LIGHTS")
 workspace:SetAttribute("Sector_"..id,on)
 for _,p in ipairs(Tags:GetTagged("DeadSignalSectorSwitch")) do
  if p:GetAttribute("SectorId")==id then
   p.Color=on and Color3.fromRGB(106,137,91) or Color3.fromRGB(117,92,64)
   local prompt=p:FindFirstChildOfClass("ProximityPrompt")
   if prompt then prompt.ActionText=on and "Apagar luzes" or "Acender luzes" end
  end
 end
end
for _,id in ipairs({"RECEPTION","WORKSHOP","POWER","STORAGE","OBSERVATION","PARK"}) do syncSector(id) end
for _,control in ipairs(Tags:GetTagged("DeadSignalDoorControl")) do
 local prompt=control:FindFirstChildOfClass("ProximityPrompt")
 local id=control:GetAttribute("DoorId")
 if not doors.Doors[id] then debug:Error("MAP_DOOR_NODE","Control references absent door "..tostring(id))
 elseif prompt then
  prompts[id]=prompts[id] or {}; table.insert(prompts[id],prompt)
  prompt.Triggered:Connect(function(player)
   if not canUse(player,prompt) then return end
   local door=doors.Doors[id]
   if door.busy then return end
   local audio=door.panel:FindFirstChild("DoorLatchSound")
   if not audio then
    audio=Instance.new("Sound"); audio.Name="DoorLatchSound"; audio.SoundId="rbxasset://sounds/action_jump_land.mp3"; audio.Volume=0.14; audio.PlaybackSpeed=0.75; audio.RollOffMaxDistance=34; audio.Parent=door.panel
   end
   audio:Play()
   local target=door.state=="Waiting" or not door.open
   local ok,reason=doors:SetOpen(id,target)
   if not ok and reason~="occupied" and reason~="busy" then debug:Warn("MAP_DOOR",tostring(reason),{door=id}) end
  end)
 end
end
doors.StateChanged.Event:Connect(function(id,state)
 for _,prompt in ipairs(prompts[id] or {}) do
  prompt.Enabled=state~="Opening" and state~="Closing"
  if state=="Waiting" then prompt.ActionText="Manter aberta" end
 end
end)
doors.Changed.Event:Connect(function(id,opened)
 for _,prompt in ipairs(prompts[id] or {}) do prompt.ActionText=opened and "Fechar" or "Abrir" end
end)
for _,control in ipairs(Tags:GetTagged("DeadSignalSectorSwitch")) do
 local prompt=control:FindFirstChildOfClass("ProximityPrompt")
 if prompt then prompt.Triggered:Connect(function(player)
  if not canUse(player,prompt) then return end
  local id=control:GetAttribute("SectorId")
  local source=power.Nodes[id.."_SUPPLY"]
  if not source then debug:Error("MAP_POWER_NODE","Missing sector "..tostring(id)); return end
  power:SetEnabled(source.id,not source.enabled); power:Recalculate(); syncSector(id)
 end) end
end
Players.PlayerRemoving:Connect(function(player)
 local prefix=tostring(player.UserId)..":"
 for key in pairs(throttle) do if key:sub(1,#prefix)==prefix then throttle[key]=nil end end
end)
workspace:SetAttribute("MapRuntimeReady",true)
