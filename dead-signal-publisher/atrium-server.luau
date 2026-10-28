local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local remote=game:GetService("ReplicatedStorage"):WaitForChild("AtriumSession")
local DoorService=require(script.Parent.DoorService)
local Guard=require(script.Parent.MapInteractionGuard)
local doors=DoorService.new(nil)
local cooldowns={}
local records={}
local store=DSS:GetDataStore("DeadSignalAtriumV1")
local markers=workspace.OvergrownAtrium.RouteMarkers
local checkpoints={"Start","Garden","Floor1","Floor2","Floor3"}
local function save(player)
 local r=records[player];if not r or not r.started then return end
 local snapshot={checkpoint=r.checkpoint,settings=r.settings}
 local ok,err=pcall(function() store:UpdateAsync(tostring(player.UserId),function() return snapshot end) end)
 if not ok then warn("[AtriumSave] "..tostring(err)) end
end
local function load(player)
 if records[player] then return end
 local r={checkpoint="Start",settings={quality="Alta",motion=true},started=false,loaded=false,busy=false,last=0};records[player]=r
 local ok,data=pcall(function() return store:GetAsync(tostring(player.UserId)) end)
 if ok and type(data)=="table" then
  if type(data.checkpoint)=="string" and markers:FindFirstChild(data.checkpoint) then r.checkpoint=data.checkpoint;r.hasSave=true end
  if type(data.settings)=="table" then r.settings={quality=data.settings.quality=="Baixa" and "Baixa" or "Alta",motion=data.settings.motion~=false} end
 elseif not ok then warn("[AtriumSave] load failed: "..tostring(data)) end
 r.loaded=true
end
local function spawnAt(player)
 local r=records[player];local char=player.Character;if not r or not char then return end
 local root=char:WaitForChild("HumanoidRootPart",10);if not root then return end
 local target=markers:FindFirstChild(r.checkpoint) or markers.Start
 char:PivotTo(CFrame.lookAt(target.Position,target.Position+Vector3.new(0,0,-1)))
 root.Anchored=not r.started
end
local function join(player)
 task.spawn(load,player)
 player.CharacterAdded:Connect(function() while not records[player] or not records[player].loaded do task.wait(.1) end;spawnAt(player) end)
 if player.Character then task.spawn(function() while not records[player] or not records[player].loaded do task.wait(.1) end;spawnAt(player) end) end
end
Players.PlayerAdded:Connect(join);for _,p in ipairs(Players:GetPlayers()) do join(p) end
Players.PlayerRemoving:Connect(function(p) save(p);records[p]=nil;cooldowns[p.UserId]=nil end)
remote.OnServerInvoke=function(player,action,payload)
 local r=records[player];if not r or not r.loaded then return {ready=false} end
 if action=="status" then return {ready=true,hasSave=r.hasSave==true,settings=r.settings} end
 if r.busy or os.clock()-r.last<.4 then return {ok=false} end
 r.last=os.clock();r.busy=true
 local result={ok=false}
 if action=="new" or action=="continue" then
  if action=="new" then r.checkpoint="Start" end
  r.started=true;r.hasSave=true;spawnAt(player);task.spawn(save,player);result={ok=true,checkpoint=r.checkpoint}
 elseif action=="settings" and type(payload)=="table" then
  r.settings={quality=payload.quality=="Baixa" and "Baixa" or "Alta",motion=payload.motion~=false};task.spawn(save,player);result={ok=true}
 end
 r.busy=false;return result
end
for _,p in ipairs(workspace.OvergrownAtrium.Doors:GetChildren()) do
 doors:Register(p)
 for _,prompt in ipairs(p:GetDescendants()) do if prompt:IsA("ProximityPrompt") then
 prompt.Triggered:Connect(function(player)
  local r=records[player]
  if r and r.started and Guard.CanUse(player,prompt,os.clock(),cooldowns,workspace) then
   local id=p:GetAttribute("DoorId");doors:SetOpen(id,not (p:GetAttribute("Open")==true))
  end
 end)
 end end
end
-- Save only at authored, reachable points. Each player's progress is independent.
task.spawn(function()
 while true do
  task.wait(1)
  for player,r in pairs(records) do
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if r.started and root then
    for _,name in ipairs(checkpoints) do
     local point=markers:FindFirstChild(name)
     if point and (root.Position-point.Position).Magnitude<8 and r.checkpoint~=name then r.checkpoint=name;task.spawn(save,player);break end
    end
    if root.Position.Y< -20 then spawnAt(player) end
   end
  end
 end
end)
game:BindToClose(function() for _,p in ipairs(Players:GetPlayers()) do task.spawn(save,p) end;task.wait(3) end)
