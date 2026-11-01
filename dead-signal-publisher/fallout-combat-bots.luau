-- Lightweight Roblox combat practice bots. All shots are virtual server-authoritative
-- gameplay effects; no external models, remote code or real-world weapon mechanics.
local Players=game:GetService('Players')
local ServerStorage=game:GetService('ServerStorage')
local PathfindingService=game:GetService('PathfindingService')
local Debris=game:GetService('Debris')
local TweenService=game:GetService('TweenService')
local Bots={}
Bots.__index=Bots
local maximum=4
local respawnSeconds=5
local rng=Random.new()
local function alive(player)
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass('Humanoid')
 local root=char and char:FindFirstChild('HumanoidRootPart')
 if hum and root and hum.Health>0 then return char,hum,root end
end
local function botAppearance(team)
 local desc=Instance.new('HumanoidDescription')
 local primary=team==1 and Color3.fromRGB(115,178,197) or Color3.fromRGB(201,132,122)
 local neutral=Color3.fromRGB(64,72,76)
 desc.HeadColor=primary
 desc.LeftArmColor=primary;desc.RightArmColor=primary
 desc.LeftLegColor=neutral;desc.RightLegColor=neutral
 desc.TorsoColor=Color3.fromRGB(52,59,62)
 return desc
end
local function createTrack(animator,id,priority)
 local anim=Instance.new('Animation')
 anim.AnimationId='rbxassetid://'..id
 local ok,track=pcall(function()return animator:LoadAnimation(anim) end)
 anim:Destroy()
 if not ok or not track then return nil end
 track.Priority=priority
 track.Looped=true
 return track
end
local function animate(bot)
 local hum=bot.hum
 local animator=hum:FindFirstChildOfClass('Animator') or Instance.new('Animator',hum)
 local idle=createTrack(animator,180435571,Enum.AnimationPriority.Idle)
 local walk=createTrack(animator,180426354,Enum.AnimationPriority.Movement)
 bot.idle=idle;bot.walk=walk
 if idle then idle:Play(.2) end
 hum.Running:Connect(function(speed)
  if bot.dead then return end
  if speed>1.8 then
   if idle and idle.IsPlaying then idle:Stop(.15) end
   if walk and not walk.IsPlaying then walk:Play(.18) end
  else
   if walk and walk.IsPlaying then walk:Stop(.18) end
   if idle and not idle.IsPlaying then idle:Play(.18) end
  end
 end)
 -- Add the same simple weapon-raising and recoil feedback as the player view.
 local torso=bot.model:FindFirstChild('Torso')
 local right=torso and torso:FindFirstChild('Right Shoulder')
 if right then
  local base=right.C0
  bot.raise=function()
   if bot.dead or not right.Parent then return end
   if bot.poseTween then bot.poseTween:Cancel() end
   bot.poseTween=TweenService:Create(right,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
    C0=base*CFrame.Angles(math.rad(-23),0,math.rad(7))
   })
   bot.poseTween:Play()
  end
  bot.firePose=function()
   if bot.dead or not right.Parent then return end
   if bot.poseTween then bot.poseTween:Cancel() end
   bot.poseTween=TweenService:Create(right,TweenInfo.new(.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
    C0=base*CFrame.Angles(math.rad(-16),0,math.rad(7))
   })
   bot.poseTween:Play()
   task.delay(.12,function()if not bot.dead and right.Parent then bot.raise() end end)
  end
  bot.reloadPose=function()
   if bot.dead or not right.Parent then return end
   if bot.poseTween then bot.poseTween:Cancel() end
   bot.poseTween=TweenService:Create(right,TweenInfo.new(.18),{C0=base*CFrame.Angles(math.rad(8),0,0)})
   bot.poseTween:Play()
  end
  bot.raise()
 end
 -- Some experiences cannot load built-in animation assets. Procedural R6
 -- leg movement keeps mobile NPCs animated even when a track is unavailable.
 if not walk then
  local leftHip=torso and torso:FindFirstChild('Left Hip')
  local rightHip=torso and torso:FindFirstChild('Right Hip')
  if leftHip and rightHip then
   local leftBase,rightBase=leftHip.C0,rightHip.C0
   bot.fallbackWalk=function()
    if bot.dead then return end
    local speed=bot.root.AssemblyLinearVelocity.Magnitude
    local angle=speed>1.5 and math.sin(os.clock()*8)*.34 or 0
    leftHip.C0=leftBase*CFrame.Angles(angle,0,0)
    rightHip.C0=rightBase*CFrame.Angles(-angle,0,0)
   end
  end
 end
end
local function chooseSpawn(team,id)
 local locations=workspace:FindFirstChild('FalloutSpawns')
 local group=locations and locations:FindFirstChild('Team'..team)
 if not group then return nil end
 local list=group:GetChildren()
 if #list==0 then return nil end
 table.sort(list,function(a,b)return a.Name<b.Name end)
 return list[(id-1)%#list+1]
end
local function makeNameplate(model,team,index)
 local head=model:FindFirstChild('Head')
 if not head then return end
 local plate=Instance.new('BillboardGui')
 plate.Name='CombatBotNametag'
 plate.Adornee=head;plate.AlwaysOnTop=false
 plate.Size=UDim2.fromOffset(110,26)
 plate.StudsOffsetWorldSpace=Vector3.new(0,2.4,0)
 plate.MaxDistance=120
 plate.Parent=head
 local title=Instance.new('TextLabel')
 title.Name='BotName';title.BackgroundTransparency=1
 title.Size=UDim2.fromScale(1,1);title.Text='BOT '..string.format('%02d',index)
 title.TextScaled=false;title.TextSize=12
 title.Font=Enum.Font.GothamBold
 title.TextColor3=team==1 and Color3.fromRGB(110,202,236) or Color3.fromRGB(250,147,140)
 title.TextStrokeTransparency=.5
 title.Parent=plate
end
function Bots.new(config)
 local folder=workspace:FindFirstChild('FalloutCombatBots')
 if not folder then folder=Instance.new('Folder');folder.Name='FalloutCombatBots';folder.Parent=workspace end
 local self=setmetatable({
  config=config,folder=folder,active=false,generation=0,
  desired=1,slots={},models={},nextId=1
 },Bots)
 folder:SetAttribute('BotCount',self.desired)
 return self
end
function Bots:Count() return self.desired end
function Bots:SetCount(value)
 if type(value)~='number' or value~=value then return false,'Quantidade inválida' end
 value=math.clamp(math.floor(value),0,maximum)
 self.desired=value
 self.folder:SetAttribute('BotCount',value)
 return true,value
end
function Bots:TeamCounts()
 local result={0,0}
 if not self.active then return result end
 for _,slot in ipairs(self.slots) do result[slot.team]+=1 end
 return result
end
function Bots:Roster()
 local rows={}
 if not self.active then return rows end
 for _,slot in ipairs(self.slots) do
  table.insert(rows,{
   userId=-10000-slot.id,name='BOT '..string.format('%02d',slot.id),
   team=slot.team,alive=slot.bot~=nil and not slot.bot.dead,
   downed=false,bot=true
  })
 end
 return rows
end
function Bots:Ranking()
 local rows={}
 for _,slot in ipairs(self.slots) do
  table.insert(rows,{userId=-10000-slot.id,name='BOT '..string.format('%02d',slot.id),
   team=slot.team,kills=slot.kills,deaths=slot.deaths,downs=0,heals=0,headshots=0})
 end
 return rows
end
function Bots:Resolve(part)
 local current=part
 while current and current~=workspace do
  if current:IsA('Model') and current:GetAttribute('FalloutBot') then
   return self.models[current]
  end
  current=current.Parent
 end
 return nil
end
function Bots:Hit(player,part,amount,headshot)
 if not self.active or not player or player.Parent~=Players then return false end
 local bot=self:Resolve(part)
 if not bot or bot.dead or bot.hum.Health<=0 then return false end
 if player.Team and self.config.teamIndex(player)==bot.slot.team then return false end
 if player:GetAttribute('Downed') or not player:GetAttribute('InMatch') then return false end
 local value=math.clamp(tonumber(amount) or 0,0,100)
 if value<=0 then return false end
 bot.lastAttacker=player
 bot.lastHeadshot=headshot==true
 bot.hum:TakeDamage(value)
 self.config.onPlayerHit(player,bot,value,headshot==true)
 return true
end
function Bots:_removeBot(slot)
 local bot=slot.bot
 if not bot then return end
 bot.dead=true
 self.models[bot.model]=nil
 if bot.poseTween then bot.poseTween:Cancel() end
 if bot.idle then bot.idle:Stop(0) end
 if bot.walk then bot.walk:Stop(0) end
 if bot.model then bot.model:Destroy() end
 slot.bot=nil
end
function Bots:_spawn(slot,generation)
 if not self.active or generation~=self.generation then return end
 local spawn=chooseSpawn(slot.team,slot.id)
 if not spawn then return end
 local description=botAppearance(slot.team)
 local ok,model=pcall(function()
  return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
 end)
 description:Destroy()
 if not ok or not model then
  warn('Combat bot R6 creation failed:',model)
  return
 end
 if generation~=self.generation or not self.active then model:Destroy();return end
 model.Name='CombatBot_'..slot.id
 model:SetAttribute('FalloutBot',true)
 model:SetAttribute('FalloutTeam',slot.team)
 model:SetAttribute('FalloutBotId',slot.id)
 model.Parent=self.folder
 local hum=model:FindFirstChildOfClass('Humanoid')
 local root=model:FindFirstChild('HumanoidRootPart')
 if not hum or not root then model:Destroy();return end
 hum.MaxHealth=100;hum.Health=100
 hum.WalkSpeed=12
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.AutoRotate=true
 root.Anchored=false
 model.PrimaryPart=root
 model:PivotTo(spawn.CFrame*CFrame.new(0,2,0))
 pcall(function()root:SetNetworkOwner(nil)end)
 local gunIds={'compact','service','subcompact','longslide'}
 local id=gunIds[(slot.id-1)%#gunIds+1]
 local weapon=ServerStorage:WaitForChild('FalloutWeaponTemplates'):FindFirstChild(id)
 local tool=weapon and weapon:Clone()
 if tool then
  tool.CanBeDropped=false
  tool.Parent=model
  hum:EquipTool(tool)
 end
 local bot={model=model,hum=hum,root=root,slot=slot,tool=tool,def=self.config.catalog[id],
  ammo=self.config.catalog[id] and self.config.catalog[id].mag or 12,
  reserve=self.config.catalog[id] and self.config.catalog[id].reserve or 60,
  reloadingUntil=0,
  dead=false,nextShot=0,nextThink=0,nextPath=0,moveIndex=1,lastAttacker=nil,lastHeadshot=false}
 slot.bot=bot;self.models[model]=bot
 if tool then tool:SetAttribute('Ammo',bot.ammo);tool:SetAttribute('Reserve',bot.reserve) end
 makeNameplate(model,slot.team,slot.id)
 animate(bot)
 hum.Died:Connect(function()
  if bot.dead then return end
  bot.dead=true;slot.deaths+=1
  self.models[model]=nil
  if bot.lastAttacker and bot.lastAttacker.Parent==Players then
   self.config.onBotEliminated(bot,bot.lastAttacker,bot.lastHeadshot)
  end
  self.config.onChanged()
  task.delay(respawnSeconds,function()
   if generation~=self.generation or not self.active or slot.bot~=bot then return end
   self:_removeBot(slot)
   task.spawn(function()self:_spawn(slot,generation)end)
  end)
 end)
 task.spawn(function()self:_loop(bot,generation)end)
 self.config.onChanged()
end
function Bots:_target(bot)
 local best,closest=nil,300
 for _,p in ipairs(Players:GetPlayers()) do
  if self.config.teamIndex(p)~=bot.slot.team and not p:GetAttribute('Downed') then
   local _,h,root=alive(p)
   if root then
    local distance=(bot.root.Position-root.Position).Magnitude
    if distance<closest then closest=distance;best=p end
   end
  end
 end
 return best,closest
end
function Bots:_loop(bot,generation)
 local rayParams=RaycastParams.new()
 rayParams.FilterType=Enum.RaycastFilterType.Exclude
 rayParams.FilterDescendantsInstances={bot.model,workspace:FindFirstChild('FalloutEffects')}
 while self.active and generation==self.generation and not bot.dead and bot.model.Parent do
  local target,distance=self:_target(bot)
  if target then
   local char,hum,targetRoot=alive(target)
   if char and targetRoot then
    local origin=bot.model:FindFirstChild('Head')
    origin=origin and origin.Position or bot.root.Position+Vector3.new(0,2,0)
    local aimPoint=targetRoot.Position+Vector3.new(0,1.2,0)
    local direction=aimPoint-origin
    if direction.Magnitude>.1 then
     local hit=workspace:Raycast(origin,direction,rayParams)
     local visible=not hit or hit.Instance:IsDescendantOf(char)
     if distance>30 or not visible then
      if os.clock()>=bot.nextThink then
       bot.nextThink=os.clock()+1.25+rng:NextNumber(0,.5)
       local destination=targetRoot.Position
       if not visible and os.clock()>=bot.nextPath then
        bot.nextPath=os.clock()+3.25
        local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=8})
        local worked=pcall(function()path:ComputeAsync(bot.root.Position,destination)end)
        if worked and path.Status==Enum.PathStatus.Success then
         local waypoints=path:GetWaypoints()
         if #waypoints>0 then destination=waypoints[math.min(#waypoints,3)].Position end
        end
       end
       bot.hum:MoveTo(destination)
      end
     elseif os.clock()>=bot.nextThink then
      bot.nextThink=os.clock()+1.8
      local angle=rng:NextNumber(0,math.pi*2)
      bot.hum:MoveTo(bot.root.Position+Vector3.new(math.cos(angle)*7,0,math.sin(angle)*7))
     end
     if visible and distance<110 and os.clock()>=bot.nextShot and
      self.config.getPhase()=='Match' and not target:GetAttribute('Downed') then
      local def=bot.def
      if bot.ammo<=0 then
       bot.reloadingUntil=os.clock()+(def and def.reload or 1.8)
       bot.nextShot=bot.reloadingUntil
       if bot.tool then bot.tool:SetAttribute('Reloading',true) end
       if bot.reloadPose then bot.reloadPose() end
       task.delay(def and def.reload or 1.8,function()
        if bot.dead or generation~=self.generation then return end
        local loading=math.min(def and def.mag or 12,bot.reserve)
        bot.reserve-=loading;bot.ammo=loading
        if bot.reserve<=0 then bot.reserve=def and def.reserve or 60 end
        if bot.tool then
         bot.tool:SetAttribute('Ammo',bot.ammo)
         bot.tool:SetAttribute('Reserve',bot.reserve)
         bot.tool:SetAttribute('Reloading',false)
        end
        if bot.raise then bot.raise() end
       end)
      else
      bot.ammo-=1
      if bot.tool then bot.tool:SetAttribute('Ammo',bot.ammo) end
      bot.nextShot=os.clock()+math.max(1.1,def and def.rate*3 or 1.25)+rng:NextNumber(0,.45)
      if bot.firePose then bot.firePose() end
      local muzzle=bot.tool and bot.tool:FindFirstChild('Handle')
      muzzle=muzzle and muzzle:FindFirstChild('Muzzle')
      local from=muzzle and muzzle.WorldPosition or origin
      -- A bounded amount of random miss is deliberate: practice bots are not perfect.
      local miss=rng:NextNumber()<.42
      local endpoint=aimPoint+(miss and Vector3.new(rng:NextNumber(-13,13),rng:NextNumber(-6,6),rng:NextNumber(-13,13)) or Vector3.zero)
      self.config.onBotShot(bot,from,endpoint)
      if not miss and bot.hum.Health>0 then
       local verify=workspace:Raycast(origin,aimPoint-origin,rayParams)
       if not verify or verify.Instance:IsDescendantOf(char) then
        self.config.onBotDamage(bot,target,11)
       end
      end
      end
     end
    end
   end
  elseif os.clock()>=bot.nextThink then
   bot.nextThink=os.clock()+3
   local spot=chooseSpawn(bot.slot.team,rng:NextInteger(1,5))
   if spot then bot.hum:MoveTo(spot.Position) end
  end
  if bot.fallbackWalk then bot.fallbackWalk() end
  task.wait(.22+rng:NextNumber(0,.09))
 end
end
function Bots:Stop()
 self.active=false;self.generation+=1
 for _,slot in ipairs(self.slots) do self:_removeBot(slot) end
 table.clear(self.slots)
 self.folder:SetAttribute('InMatch',false)
end
function Bots:Start()
 self:Stop()
 if self.desired<=0 then return end
 self.active=true
 self.folder:SetAttribute('InMatch',true)
 local generation=self.generation
 local counts={0,0}
 for _,p in ipairs(Players:GetPlayers()) do
  local team=self.config.teamIndex(p)
  if team==1 or team==2 then counts[team]+=1 end
 end
 for n=1,self.desired do
  local team=(counts[1]<=counts[2] and counts[1]<self.config.teamSize) and 1 or
   (counts[2]<self.config.teamSize and 2 or nil)
  if not team then break end
  counts[team]+=1
  local slot={id=n,team=team,kills=0,deaths=0,bot=nil}
  table.insert(self.slots,slot)
  task.spawn(function()self:_spawn(slot,generation)end)
 end
 self.config.onChanged()
end
return Bots
