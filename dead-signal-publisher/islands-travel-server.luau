local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local destinations=workspace:WaitForChild('IslandDestinations')
local remote=RS:WaitForChild('IslandTravel')
local Chunks=require(script.Parent.IslandChunks)
Chunks.Start()
local valid={city=true,forest1=true,forestCurrent=true}
local busy,last={},{}
local function arrival(id)
 local spawn=destinations:FindFirstChild(id)
 return spawn and spawn:IsA('SpawnLocation') and spawn.Enabled and spawn or nil
end
local function travel(p,id,reply)
 if workspace:GetAttribute('IslandWorldReady')~=true then if reply then remote:FireClient(p,false,'O mundo ainda está carregando.') end;return end
 if not valid[id] or busy[p] then return end
 if reply and os.clock()-(last[p] or -10)<2 then remote:FireClient(p,false,'Aguarda um instante.');return end
 local spawn=arrival(id);local char=p.Character;local hum=char and char:FindFirstChildOfClass('Humanoid')
 local root=char and char:FindFirstChild('HumanoidRootPart')
 if not spawn or not root or not hum or hum.Health<=0 then if reply then remote:FireClient(p,false,'Espera seu personagem aparecer.');end;return end
 busy[p]=true;p:SetAttribute('IslandTravelPending',true);last[p]=os.clock();p.RespawnLocation=spawn;root.Anchored=true
 local ok,err=pcall(function()
  Chunks.Warm(id,spawn.Position,128)
  if p.Character~=char or not char.Parent or hum.Health<=0 then error('Personagem mudou durante a viagem') end
  hum.Sit=false
  char:PivotTo(spawn.CFrame+Vector3.new(0,4,0))
  p:RequestStreamAroundAsync(spawn.Position,6)
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  p:SetAttribute('IslandDestination',id)
 end)
 busy[p]=nil;p:SetAttribute('IslandTravelPending',false)
 if root.Parent then root.Anchored=false end
 if reply and p.Parent==Players then remote:FireClient(p,ok,ok and id or 'Não deu para viajar agora. Tenta de novo.') end
 if not ok then warn('[IslandTravel] '..p.UserId..': '..tostring(err)) end
end
remote.OnServerEvent:Connect(function(p,id) if typeof(id)=='string' then travel(p,id,true) end end)
local function added(p)
 p:SetAttribute('IslandDestination','forestCurrent');p.RespawnLocation=assert(arrival('forestCurrent'),'Default spawn unavailable')
 local function onCharacter(char)
  local root=char:WaitForChild('HumanoidRootPart',15)
  if root then
   root.Anchored=true
   while char.Parent and workspace:GetAttribute('IslandWorldReady')~=true and not workspace:GetAttribute('IslandWorldError') do task.wait(.25) end
   if workspace:GetAttribute('IslandWorldError') and root.Parent then root.Anchored=false end
   if p.Character==char then task.defer(travel,p,p:GetAttribute('IslandDestination') or 'forestCurrent',true) end
  end
 end
 p.CharacterAdded:Connect(onCharacter)
 if p.Character then task.spawn(onCharacter,p.Character) end
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(p) busy[p]=nil;last[p]=nil end)
for _,p in ipairs(Players:GetPlayers()) do added(p) end
-- Bounded rescue if a player jumps from an island into the void.
task.spawn(function()
 while task.wait(1) do for _,p in ipairs(Players:GetPlayers()) do
  local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  local s=arrival(p:GetAttribute('IslandDestination') or 'forestCurrent')
  if r and s and r.Position.Y<s.Position.Y-220 then travel(p,s.Name,false) end
 end end
end)
