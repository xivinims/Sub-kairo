local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Tags=game:GetService('CollectionService')
local Run=game:GetService('RunService')
local Data=game:GetService('DataStoreService'):GetDataStore('OveryardForestInventory_v1')
local Http=game:GetService('HttpService')
local runtime=RS:WaitForChild('LivingForest')
local Rules=require(runtime.FruitRules)
local C=require(RS.PhotoWorldConfig)
local Movement=require(script.Parent.MovementService);Movement.start()
local event=runtime.NatureEvent
local ground=Instance.new('Folder');ground.Name='CollectibleFruit';ground.Parent=workspace
local rng=Random.new()
local states={};local inventories={};local pending={};local saving={};local lastHit={};local treeCooldown={}
local buckets={}
local function key(x,z)return math.floor(x/100)..':'..math.floor(z/100)end
for _,tree in ipairs(Tags:GetTagged('LivingTree'))do local r=tree:GetAttribute('RootPosition');if r then local k=key(r.X,r.Z);buckets[k]=buckets[k]or{};table.insert(buckets[k],tree)end end
local function nearby(pos,fn)
 local x,z=math.floor(pos.X/100),math.floor(pos.Z/100)
 for dx=-1,1 do for dz=-1,1 do for _,tree in ipairs(buckets[(x+dx)..':'..(z+dz)]or{})do if tree.Parent then fn(tree)end end end end
end
local function sync(player)
 local values=player:FindFirstChild('ForestInventory');if not values then values=Instance.new('Folder');values.Name='ForestInventory';values.Parent=player end
 for _,kind in ipairs({'Apple','Orange'})do local value=values:FindFirstChild(kind)or Instance.new('IntValue');value.Name=kind;value.Value=(inventories[player]or{})[kind]or 0;value.Parent=values end
end
local function save(player)
 if saving[player]or not pending[player]or not player:GetAttribute('InventoryLoaded')then return end
 local delta=pending[player];if (delta.Apple or 0)+(delta.Orange or 0)==0 then return end
 saving[player]=true;pending[player]={Apple=0,Orange=0};local token=Http:GenerateGUID(false)
 local success=false
 for attempt=1,3 do
  local ok=pcall(function()Data:UpdateAsync(tostring(player.UserId),function(old)
   old=type(old)=='table' and old or {Apple=0,Orange=0};old.receipts=type(old.receipts)=='table'and old.receipts or{}
   if table.find(old.receipts,token)then return old end
   for _,kind in ipairs({'Apple','Orange'})do old[kind]=math.clamp((tonumber(old[kind])or 0)+(delta[kind]or 0),0,Rules.MaxStack)end
   table.insert(old.receipts,token);if #old.receipts>24 then table.remove(old.receipts,1)end;return old
  end)end)
  if ok then success=true;break end;task.wait(attempt*2)
 end
 if not success and pending[player]then for _,kind in ipairs({'Apple','Orange'})do pending[player][kind]=(pending[player][kind]or 0)+(delta[kind]or 0)end end
 saving[player]=nil
end
local function join(player)
 inventories[player]={Apple=0,Orange=0};pending[player]={Apple=0,Orange=0};sync(player)
 local ok,data=false,nil
 for attempt=1,3 do ok,data=pcall(function()return Data:GetAsync(tostring(player.UserId))end);if ok then break end;task.wait(attempt*2)end
 if not player.Parent then return end
 if ok then
  for _,kind in ipairs({'Apple','Orange'})do inventories[player][kind]=math.clamp((type(data)=='table'and tonumber(data[kind]))or 0,0,Rules.MaxStack)end
  player:SetAttribute('InventoryLoaded',true);sync(player)
 else player:SetAttribute('InventoryLoaded',false);task.delay(20,function()if player.Parent then join(player)end end)end
end
Players.PlayerAdded:Connect(join);for _,p in ipairs(Players:GetPlayers())do task.spawn(join,p)end
local function flush(p)
 local deadline=os.clock()+24
 while saving[p]and os.clock()<deadline do task.wait(.1)end
 while pending[p]and((pending[p].Apple or 0)+(pending[p].Orange or 0)>0)and os.clock()<deadline do save(p);task.wait(.1)end
end
Players.PlayerRemoving:Connect(function(p)flush(p);inventories[p]=nil;pending[p]=nil;lastHit[p]=nil end)
game:BindToClose(function()
 local left=0
 for p in pairs(pending)do left+=1;task.spawn(function()flush(p);left-=1 end)end
 local deadline=os.clock()+26;while left>0 and os.clock()<deadline do task.wait(.1)end
end)
local function remove(part)states[part]=nil;part:Destroy()end
local function drop(tree)
 if #ground:GetChildren()>=Rules.MaxGroundFruit then return end
 local kind=tree:GetAttribute('FruitKind');if not kind then return end
 local now=os.clock();if now-(treeCooldown[tree]or -100)<Rules.TreeCooldown then return end;treeCooldown[tree]=now
 local root=tree:GetAttribute('RootPosition');local a=rng:NextNumber(0,math.pi*2);local r=rng:NextNumber(2,5)
 local pos=root+Vector3.new(math.cos(a)*r,math.min(20,tree:GetAttribute('CanopyHeight')*.7),math.sin(a)*r)
 local part=runtime.Meshes[kind]:Clone();part.Name=kind;part.CFrame=CFrame.new(pos);part.CanCollide=false;part.Anchored=true;part.Parent=ground
 local born=os.clock();states[part]={born=born,claimed=false,kind=kind,start=pos,landed=false}
 part:SetAttribute('FruitKind',kind);part:SetAttribute('ExpiresAt',workspace:GetServerTimeNow()+Rules.Lifetime)
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Pegar';prompt.ObjectText=kind=='Apple'and'Maçã'or'Laranja';prompt.HoldDuration=.15;prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=false;prompt.Enabled=false;prompt.Parent=part
 prompt.Triggered:Connect(function(player)
  local state=states[part];local rootPart=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if not rootPart or not player:GetAttribute('InventoryLoaded')or not Rules.pickup(state,os.clock(),(rootPart.Position-part.Position).Magnitude)then return end
  local bag=inventories[player];if not bag or bag[kind]>=Rules.MaxStack then return end
  -- Claim before any yielding operation; two players cannot collect the same item.
  state.claimed=true;bag[kind]=Rules.increment(bag[kind]);pending[player][kind]+=1;sync(player);remove(part)
 end)
end
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={workspace.Terrain}
local clock=0;local autoDrop=0;local autosave=0;local streamClock=0;local previous={}
Run.Heartbeat:Connect(function(dt)
 clock+=dt;autoDrop+=dt;autosave+=dt;streamClock+=dt;if clock<.12 then return end;clock=0
 local now=os.clock()
 for part,state in pairs(states)do
  if not part.Parent or Rules.expired(state.born,now)then remove(part)
  elseif not state.landed then
   local t=now-state.born;local nextPos=state.start-Vector3.yAxis*(28*t*t)
   local hit=workspace:Raycast(part.Position+Vector3.yAxis*.2,nextPos-part.Position-Vector3.yAxis*.7,ray)
   if hit then
    if hit.Material==Enum.Material.Water then remove(part)else
     part.CFrame=CFrame.new(hit.Position+Vector3.yAxis*.43)*CFrame.Angles(.15,t*1.7,.12);state.landed=true;part.ProximityPrompt.Enabled=true
    end
   else part.CFrame=CFrame.new(nextPos)*CFrame.Angles(t*1.2,t*.7,t*.9)end
  end
 end
 for _,player in ipairs(Players:GetPlayers())do
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  if root and hum and hum.Health>0 then
   local velocity=root.AssemblyLinearVelocity;local speed=Vector2.new(velocity.X,velocity.Z).Magnitude;local before=previous[player]or speed;previous[player]=speed
   nearby(root.Position,function(tree)
    local trunk=tree.PrimaryPart;local r=tree:GetAttribute('RootPosition')
    if trunk and math.abs(root.Position.Y-r.Y)<8 and Vector2.new(root.Position.X-r.X,root.Position.Z-r.Z).Magnitude<trunk.Size.X/2+1.65 and hum.MoveDirection.Magnitude>.2 and now-(lastHit[player]or -100)>8 then
     lastHit[player]=now;Movement.authorize(player,3);event:FireAllClients('tree',tree,player,math.max(speed,before)>6);drop(tree)
    end
   end)
   if autoDrop>Rules.DropInterval then
    local candidates={};nearby(root.Position,function(tree)if tree:GetAttribute('FruitKind')and(tree:GetAttribute('RootPosition')-root.Position).Magnitude<95 then table.insert(candidates,tree)end end)
    if #candidates>0 then drop(candidates[rng:NextInteger(1,#candidates)])end
   end
   if streamClock>2 and speed>1 then
    local target=root.Position+hum.MoveDirection*86
    task.spawn(function()pcall(function()player:RequestStreamAroundAsync(target,1.8)end)end)
   end
  end
 end
 if autoDrop>Rules.DropInterval then autoDrop=0 end
 if streamClock>2 then streamClock=0 end
 if autosave>30 then autosave=0;for _,p in ipairs(Players:GetPlayers())do task.spawn(save,p)end end
 local wind=3.2+math.sin(now*.13)*.9+math.sin(now*.037)*.5;workspace.GlobalWind=Vector3.new(wind,0,wind*.32)
end)
