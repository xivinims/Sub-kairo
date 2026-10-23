-- Exact animation playback for Jason and survivors.
-- Survivor default = Forsaken Survivor Animations (127092032896760).
-- Crouching = full-body R15 Crouch Animation set (134326820545987).
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local TweenService=game:GetService("TweenService")
local Encoding=game:GetService("EncodingService")
local net=game.ReplicatedStorage:WaitForChild("Survival")
local cache=setmetatable({},{__mode="k"})
local activeFolder=setmetatable({},{__mode="k"})
local animateState=setmetatable({},{__mode="k"})

local function decodePose(raw)
 if typeof(raw)=="table" and raw.c then
  return {cf=CFrame.new(table.unpack(raw.c)),easing=raw.e or "Linear",direction=raw.d or "InOut",weight=raw.w or 1}
 end
 return {cf=CFrame.new(table.unpack(raw)),easing="Linear",direction="InOut",weight=1}
end

local function normalized(name)
 return tostring(name or ""):lower():gsub("[%s_%-%.]","")
end

local function prepare(model,folder)
 local perModel=cache[model]
 if not perModel then perModel={} cache[model]=perModel end
 if perModel[folder] then return perModel[folder] end
 if #folder:GetChildren()~=(folder:GetAttribute("ClipCount") or math.huge) then return nil end
 local d={joints={},lookup={},clips={},time=0,state="",active=false,folder=folder}
 for _,j in ipairs(model:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part1 then
   d.joints[j]=true
   d.lookup[normalized(j.Part1.Name)]=j
   d.lookup[normalized(j.Name)]=j
  end
 end
 local aliasTargets={
  humanoidrootpart="LowerTorso",rootpart="LowerTorso",
  torso="UpperTorso",uppertorso="UpperTorso",
  head="Head",
  leftarm="LeftUpperArm",rightarm="RightUpperArm",
  leftleg="LeftUpperLeg",rightleg="RightUpperLeg",
 }
 for alias,partName in pairs(aliasTargets) do
  local joint=d.lookup[normalized(partName)]
  if joint then d.lookup[alias]=joint end
 end
 for _,v in ipairs(folder:GetChildren()) do
  if v:IsA("Folder") then
   local chunks=v:GetChildren()
   if #chunks~=(v:GetAttribute("ChunkCount") or math.huge) then return nil end
   table.sort(chunks,function(a,b) return a.Name<b.Name end)
   local values={} for _,chunk in ipairs(chunks) do table.insert(values,chunk.Value) end
   local ok,clip=pcall(function()
    local compressed=Encoding:Base64Decode(buffer.fromstring(table.concat(values)))
    return Http:JSONDecode(buffer.tostring(Encoding:DecompressBuffer(compressed,Enum.CompressionAlgorithm.Zstd)))
   end)
   if not ok then return nil end
   clip.channels={}
   for _,frame in ipairs(clip.frames) do
    for name,raw in pairs(frame.poses) do
     local channel=clip.channels[name]
     if not channel then channel={} clip.channels[name]=channel end
     local pose=decodePose(raw) pose.time=frame.time table.insert(channel,pose)
    end
   end
   clip.bound={} clip.boundCount=0
   for name,channel in pairs(clip.channels) do
    table.sort(channel,function(a,b) return a.time<b.time end)
    local joint=d.lookup[normalized(name)]
    if joint and not clip.bound[joint] then clip.bound[joint]=channel clip.boundCount+=1 end
   end
   d.clips[v.Name]=clip
  end
 end
 perModel[folder]=d
 return d
end

local function resetData(d)
 if not d or not d.active then return end
 for joint in pairs(d.joints) do if joint.Parent then joint.Transform=CFrame.identity end end
 d.active=false d.state="" d.time=0
end

local function resetModel(model)
 local perModel=cache[model]
 if perModel then for _,d in pairs(perModel) do resetData(d) end end
 activeFolder[model]=nil
end

local function easedAlpha(alpha,pose)
 local style=Enum.EasingStyle[pose.easing] or Enum.EasingStyle.Linear
 local direction=Enum.EasingDirection[pose.direction] or Enum.EasingDirection.InOut
 local ok,value=pcall(TweenService.GetValue,TweenService,alpha,style,direction)
 return ok and value or alpha
end

local function sample(channel,t)
 if not channel or #channel==0 then return CFrame.identity end
 if #channel==1 or t<=channel[1].time then return CFrame.identity:Lerp(channel[1].cf,channel[1].weight) end
 local last=channel[#channel]
 if t>=last.time then return CFrame.identity:Lerp(last.cf,last.weight) end
 local a,b=channel[1],last
 for i=1,#channel-1 do if channel[i+1].time>=t then a=channel[i] b=channel[i+1] break end end
 local alpha=b.time>a.time and math.clamp((t-a.time)/(b.time-a.time),0,1) or 0
 alpha=easedAlpha(alpha,a)
 return CFrame.identity:Lerp(a.cf,a.weight):Lerp(CFrame.identity:Lerp(b.cf,b.weight),alpha)
end

local function canDrive(d,state)
 local clip=state and d.clips[state]
 return clip and clip.length>0 and (clip.boundCount or 0)>=4
end

local function apply(d,state,dt,loop,absolute)
 if not state then return false end
 local clip=d.clips[state]
 if not clip or clip.length<=0 or (clip.boundCount or 0)<4 then return false end
 if d.state~=state then
  for joint in pairs(d.joints) do if joint.Parent then joint.Transform=CFrame.identity end end
  d.state=state d.time=0
 end
 d.time+=dt
 local t=absolute or d.time
 t=loop and t%clip.length or math.min(t,clip.length)
 for joint,channel in pairs(clip.bound) do
  if joint.Parent then joint.Transform=sample(channel,t) end
 end
 d.active=true
 return true
end

local function matchName(clips,groups)
 local names={}
 for name in pairs(clips) do table.insert(names,name) end
 table.sort(names)
 for _,tokens in ipairs(groups) do
  for _,name in ipairs(names) do
   local low=name:lower()
   local ok=true
   for _,token in ipairs(tokens) do if not low:find(token,1,true) then ok=false break end end
   if ok then return name end
  end
 end
 return nil
end

local function executionName(d)
 if d.clips["Jason_Kill"] then return "Jason_Kill" end
 if d.clips["Guest Kill Animation (jason)"] then return "Guest Kill Animation (jason)" end
 return matchName(d.clips,{{"behead"},{"gashing","wound"},{"kill"},{"execution"},{"execute"},{"finisher"},{"fatal"}}) or matchName(d.clips,{{"slash"},{"attack"}}) or "Jason Slash"
end

local function locomotionName(d,kind,crouched,injured)
 if crouched then
  if kind=="jump" then return matchName(d.clips,{{"crouch","jump"},{"jump"}}) or matchName(d.clips,{{"crouch","walk"},{"walk"},{"idle"}}) end
  if kind=="fall" then return matchName(d.clips,{{"crouch","fall"},{"fall"}}) or matchName(d.clips,{{"crouch","idle"},{"idle"}}) end
  if kind=="move" then return matchName(d.clips,{{"crouch","walk"},{"crouch","move"},{"walk"},{"move"}}) or matchName(d.clips,{{"idle"}}) end
  return matchName(d.clips,{{"crouch","idle"},{"idle"}}) or next(d.clips)
 end
 if injured then
  if kind=="run" then return matchName(d.clips,{{"injured","run"}}) or matchName(d.clips,{{"injured","walk"}}) end
  if kind=="move" then return matchName(d.clips,{{"injured","walk"}}) or matchName(d.clips,{{"injured","run"}}) end
  return matchName(d.clips,{{"injured","idle"}}) or matchName(d.clips,{{"idle"}}) or next(d.clips)
 end
 if kind=="jump" then return matchName(d.clips,{{"jump"},{"leap"}}) or matchName(d.clips,{{"idle"}}) end
 if kind=="fall" then return matchName(d.clips,{{"fall"},{"freefall"},{"air"}}) or matchName(d.clips,{{"jump"},{"idle"}}) end
 if kind=="run" then return matchName(d.clips,{{"run"},{"sprint"}}) or matchName(d.clips,{{"walk"},{"move"}}) end
 if kind=="move" then return matchName(d.clips,{{"walk"},{"move"}}) or matchName(d.clips,{{"run"},{"idle"}}) end
 return matchName(d.clips,{{"idle"},{"stand"}}) or next(d.clips)
end

local function setDefaultAnimate(model,enabled)
 local a=model:FindFirstChild("Animate")
 if a and a:IsA("LocalScript") then
  if animateState[model]==nil then animateState[model]=not a.Disabled end
  a.Disabled=not enabled
 end
 local hum=model:FindFirstChildOfClass("Humanoid")
 local animator=hum and hum:FindFirstChildOfClass("Animator")
 if animator and not enabled then
  for _,track in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() track:Stop(.08) end) end
 end
end

Run.PreSimulation:Connect(function(dt)
 for _,model in ipairs(workspace:GetChildren()) do
  if model:IsA("Model") and (model:GetAttribute("ActivePursuer") or model:GetAttribute("CinematicPursuer")) and model.PrimaryPart then
   local folder=model:FindFirstChild("MotionClips")
   if folder then
    local d=prepare(model,folder)
    if model:GetAttribute("CinematicPursuer") then
     local introAt=model:GetAttribute("IntroAt") or workspace:GetServerTimeNow()
     local runDuration=model:GetAttribute("IntroRunDuration") or 3.15
     local elapsed=workspace:GetServerTimeNow()-introAt
     local state=elapsed<runDuration and "Jason Run" or "Jason Intro"
     if d then apply(d,state,dt,state=="Jason Run",state=="Jason Intro" and math.max(0,elapsed-runDuration) or nil) end
    else
     local speed=(model.PrimaryPart.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude
     local execution=model:GetAttribute("ExecutionAt") or -100
     local attack=model:GetAttribute("AttackAt") or -100
     local execSince=workspace:GetServerTimeNow()-execution
     local since=workspace:GetServerTimeNow()-attack
     local execState=d and executionName(d) or nil
     local executing=execSince>=0 and execSince<1.65
     local state=executing and execState or since<.75 and "Jason Slash" or speed>16 and "Jason Run" or speed>1 and "Jason Walk" or "Jason Idle"
     if d then apply(d,state,dt,not executing and state~="Jason Slash",executing and execSince or (state=="Jason Slash" and since or nil)) end
    end
   end
  end
 end

 for _,p in ipairs(Players:GetPlayers()) do
  local model=p.Character
  if model and not model:GetAttribute("ActivePursuer") then
   local isJason=p:GetAttribute("IsJason")
   local inRound=p:GetAttribute("InRound")
   local downed=p:GetAttribute("Downed")
   if inRound and not isJason and not downed then
    local crouched=p:GetAttribute("MoveMode")=="slow"
    local injured=p:GetAttribute("Injured")==true
    local folder=crouched and net.CrouchClips or net.SurvivorClips
    if activeFolder[model]~=folder then
     resetModel(model) activeFolder[model]=folder
    end
    local d=prepare(model,folder)
    local hum=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    if d and hum and root then
     local speed=(root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude
     local hs=hum:GetState()
     local kind
     if hs==Enum.HumanoidStateType.Jumping then kind="jump"
     elseif hs==Enum.HumanoidStateType.Freefall or hs==Enum.HumanoidStateType.FallingDown then kind="fall"
     elseif speed>1 then kind=(not crouched and speed>16) and "run" or "move"
     else kind="idle" end
     local state=locomotionName(d,kind,crouched,injured)
     local supported=canDrive(d,state)
     if p==Players.LocalPlayer then setDefaultAnimate(model,not supported) end
     if supported then apply(d,state,dt,kind~="jump" and kind~="fall") else resetData(d) end
    elseif p==Players.LocalPlayer then
     setDefaultAnimate(model,true)
    end
   else
    resetModel(model)
    if p==Players.LocalPlayer then setDefaultAnimate(model,true) end
   end
  end
 end
end)