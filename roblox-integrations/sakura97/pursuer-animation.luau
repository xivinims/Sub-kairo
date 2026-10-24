-- Exact animation playback for Jason and survivors.
-- Survivor default = Forsaken Survivor Animations (127092032896760).
-- Survivors are R6. Crouching retargets the supplied R15 crouch set (134326820545987) onto the six R6 motors.
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local TweenService=game:GetService("TweenService")
local Encoding=game:GetService("EncodingService")
local net=game.ReplicatedStorage:WaitForChild("Survival")
local cache=setmetatable({},{__mode="k"})
local activeFolder=setmetatable({},{__mode="k"})
local animateState=setmetatable({},{__mode="k"})
local watchedRigs=setmetatable({},{__mode="k"})
local downedPoses=setmetatable({},{__mode="k"})
local function jointParts(joint)
 if joint:IsA("Motor6D") then return joint.Part0,joint.Part1 end
 if joint:IsA("AnimationConstraint") then return joint.Attachment0 and joint.Attachment0.Parent,joint.Attachment1 and joint.Attachment1.Parent end
 return nil,nil
end
local function rootJoint(model)
 local root=model:FindFirstChild("HumanoidRootPart")
 for _,joint in ipairs(model:GetDescendants()) do local part0,part1=jointParts(joint) if part0==root and part1 then return joint end end
end

local function decodePose(raw)
 if typeof(raw)=="table" and raw.c then
  return {cf=CFrame.new(table.unpack(raw.c)),easing=raw.e or "Linear",direction=raw.d or "InOut",weight=raw.w or 1}
 end
 return {cf=CFrame.new(table.unpack(raw)),easing="Linear",direction="InOut",weight=1}
end

local function normalized(name)
 return tostring(name or ""):lower():gsub("[%s_%-%.]","")
end

local sharedClips=setmetatable({},{__mode="k"})
local function decodeClips(folder)
 if sharedClips[folder] then return sharedClips[folder] end
 if #folder:GetChildren()~=(folder:GetAttribute("ClipCount") or math.huge) then return nil end
 local clips={}
 for _,v in ipairs(folder:GetChildren()) do
  if v:IsA("Folder") then
   local chunks=v:GetChildren()
   if #chunks~=(v:GetAttribute("ChunkCount") or math.huge) then return nil end
   table.sort(chunks,function(a,b) return a.Name<b.Name end)
   local values={} for _,chunk in ipairs(chunks) do table.insert(values,chunk.Value) end
   local ok,data=pcall(function()
    local compressed=Encoding:Base64Decode(buffer.fromstring(table.concat(values)))
    return Http:JSONDecode(buffer.tostring(Encoding:DecompressBuffer(compressed,Enum.CompressionAlgorithm.Zstd)))
   end)
   if not ok then return nil end
   local clip={length=data.length,frameCount=#data.frames,channels={}}
   for _,frame in ipairs(data.frames) do
    for name,raw in pairs(frame.poses) do
     local channel=clip.channels[name]
     if not channel then channel={} clip.channels[name]=channel end
     local pose=decodePose(raw) pose.time=frame.time table.insert(channel,pose)
    end
   end
   for _,channel in pairs(clip.channels) do table.sort(channel,function(a,b) return a.time<b.time end) end
   clips[v.Name]=clip
  end
 end
 sharedClips[folder]=clips return clips
end

local function motionFolder(model)
 local localFolder=model:FindFirstChild("MotionClips")
 if localFolder then return localFolder end
 local name=model:GetAttribute("MotionLibrary")
 local libraries=net:FindFirstChild("KillerMotionLibraries")
 return name and libraries and libraries:FindFirstChild(name) or nil
end

local function prepare(model,folder)
 if not watchedRigs[model] then
  watchedRigs[model]=true
  local function changed(j) if j:IsA("Motor6D") or j:IsA("AnimationConstraint") then cache[model]=nil end end
  model.DescendantAdded:Connect(changed) model.DescendantRemoving:Connect(changed)
 end
 local perModel=cache[model]
 if not perModel then perModel={} cache[model]=perModel end
 if perModel[folder] then return perModel[folder] end
 if #folder:GetChildren()~=(folder:GetAttribute("ClipCount") or math.huge) then return nil end
 local d={joints={},lookup={},clips={},time=0,state="",active=false,folder=folder}
 local jointCount=0
 for _,j in ipairs(model:GetDescendants()) do
  local _,part1=jointParts(j)
  if part1 and part1:IsA("BasePart") then
   jointCount+=1 d.joints[j]=true
   d.lookup[normalized(part1.Name)]=j
   d.lookup[normalized(j.Name)]=j
  end
 end
 local hum=model:FindFirstChildOfClass("Humanoid")
 local rigType=hum and hum.RigType or Enum.HumanoidRigType.R6
 local motors={}
 for joint in pairs(d.joints) do motors[normalized(joint.Name)]=joint end
 local aliasTargets
 if rigType==Enum.HumanoidRigType.R6 then
  aliasTargets={
   humanoidrootpart="root",rootpart="root",lowertorso="root",uppertorso="root",torso="root",
   head="neck",
   leftarm="leftshoulder",leftupperarm="leftshoulder",leftlowerarm="leftshoulder",lefthand="leftshoulder",
   rightarm="rightshoulder",rightupperarm="rightshoulder",rightlowerarm="rightshoulder",righthand="rightshoulder",
   leftleg="lefthip",leftupperleg="lefthip",leftlowerleg="lefthip",leftfoot="lefthip",
   rightleg="righthip",rightupperleg="righthip",rightlowerleg="righthip",rightfoot="righthip",
  }
 else
  aliasTargets={
   humanoidrootpart="root",rootpart="root",torso="root",uppertorso="waist",head="neck",
   leftarm="leftshoulder",rightarm="rightshoulder",leftleg="lefthip",rightleg="righthip",
  }
 end
 for alias,motorName in pairs(aliasTargets) do
  local joint=motors[normalized(motorName)]
  if joint then d.lookup[alias]=joint end
 end
 local clips=decodeClips(folder)
 if not clips then return nil end
 local r6Priority={
  torso=100,head=100,leftarm=100,rightarm=100,leftleg=100,rightleg=100,
  lowertorso=90,uppertorso=80,leftupperarm=90,rightupperarm=90,leftupperleg=90,rightupperleg=90,
  leftlowerarm=60,rightlowerarm=60,leftlowerleg=60,rightlowerleg=60,lefthand=40,righthand=40,leftfoot=40,rightfoot=40,
  humanoidrootpart=30,rootpart=30,
 }
 for name,source in pairs(clips) do
  local clip={length=source.length,frameCount=source.frameCount,bound={},boundScore={},boundCount=0}
  for pose,channel in pairs(source.channels) do
   local key=normalized(pose)
   local joint=d.lookup[key]
   local score=rigType==Enum.HumanoidRigType.R6 and (r6Priority[key] or 50) or 50
   if joint and (not clip.bound[joint] or score>(clip.boundScore[joint] or -1)) then
    if not clip.bound[joint] then clip.boundCount+=1 end
    clip.bound[joint]=channel clip.boundScore[joint]=score
   end
  end
  d.clips[name]=clip
 end
 local expected=rigType==Enum.HumanoidRigType.R15 and 15 or 6
 if jointCount>=expected then perModel[folder]=d end
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
 local lo,hi=1,#channel
 while hi-lo>1 do local mid=math.floor((lo+hi)/2) if channel[mid].time<=t then lo=mid else hi=mid end end
 local a,b=channel[lo],channel[hi]
 local alpha=b.time>a.time and math.clamp((t-a.time)/(b.time-a.time),0,1) or 0
 alpha=easedAlpha(alpha,a)
 return CFrame.identity:Lerp(a.cf,a.weight):Lerp(CFrame.identity:Lerp(b.cf,b.weight),alpha)
end

local function canDrive(d,state)
 local clip=state and d.clips[state]
 return clip and clip.frameCount>0 and (clip.boundCount or 0)>=4
end

local function apply(d,state,dt,loop,absolute)
 if not state then return false end
 local clip=d.clips[state]
 if not clip or clip.frameCount==0 or (clip.boundCount or 0)<4 then return false end
 if d.state~=state then
  for joint in pairs(d.joints) do
   if joint.Parent then joint.Transform=CFrame.identity end
  end
  d.state=state
  d.time=0
 end
 d.time+=dt
 local t=absolute or d.time
 t=clip.length>0 and (loop and t%clip.length or math.min(t,clip.length)) or 0
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

local function resolveLocomotion(d,kind,crouched,injured)
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

local function locomotionName(d,kind,crouched,injured)
 d.locomotion=d.locomotion or {}
 local key=kind..tostring(crouched)..tostring(injured)
 if d.locomotion[key]==nil then d.locomotion[key]=resolveLocomotion(d,kind,crouched,injured) or false end
 return d.locomotion[key] or nil
end
local driven=setmetatable({},{__mode="k"})
local function setDefaultAnimate(model,enabled)
 local a=model:FindFirstChild("Animate")
 if driven[model]==enabled and (not a or animateState[model]~=nil) then return end
 driven[model]=enabled
 if a and a:IsA("BaseScript") then
  if animateState[model]==nil then animateState[model]=not a.Disabled end
  a.Disabled=not (enabled and animateState[model])
 end
 local hum=model:FindFirstChildOfClass("Humanoid")
 local animator=hum and hum:FindFirstChildOfClass("Animator")
 if animator and not enabled then
  for _,track in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() track:Stop(.08) end) end
 end
end

local presentationModels=setmetatable({},{__mode="k"})
local pg=Players.LocalPlayer:WaitForChild("PlayerGui")
local function presentation(instance)
 if instance:IsA("Model") and instance:GetAttribute("PresentationPursuer") then presentationModels[instance]=true end
end
pg.DescendantAdded:Connect(presentation)
for _,d in ipairs(pg:GetDescendants()) do presentation(d) end
Run.PreSimulation:Connect(function(dt)
 for model in pairs(presentationModels) do
  if not model.Parent then presentationModels[model]=nil
  else
   local folder=motionFolder(model) local d=folder and prepare(model,folder)
   local visible=true local ancestor=model.Parent
   while ancestor and ancestor~=pg do
    if ancestor:IsA("GuiObject") and not ancestor.Visible then visible=false break end
    ancestor=ancestor.Parent
   end
   if d and visible then apply(d,"Winning Screen",dt,false) end
  end
 end
 for _,model in ipairs(workspace:GetChildren()) do
  if model:IsA("Model") and (model:GetAttribute("ActivePursuer") or model:GetAttribute("CinematicPursuer")) and model.PrimaryPart then
   local folder=motionFolder(model)
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
   if downedPoses[model] and not downed then
    local j=downedPoses[model] if j.Parent then j.Transform=CFrame.identity end downedPoses[model]=nil
   end
   if inRound and not isJason and downed then
    if not downedPoses[model] then resetModel(model) downedPoses[model]=rootJoint(model) end
    if p==Players.LocalPlayer then setDefaultAnimate(model,false) end
    local joint=downedPoses[model]
    if joint and joint.Parent then joint.Transform=CFrame.new(0,-.7+math.sin(os.clock()*2)*.025,0)*CFrame.Angles(math.rad(75),0,math.sin(os.clock()*1.4)*.012) end
   elseif inRound and not isJason then
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
     elseif speed>1 then kind=(not crouched and speed>(injured and 13 or 16)) and "run" or "move"
     else kind="idle" end
     local state=locomotionName(d,kind,crouched,injured)
     local supported=canDrive(d,state)
     if p==Players.LocalPlayer and supported then setDefaultAnimate(model,false) end
     if supported then
      apply(d,state,dt,kind~="jump" and kind~="fall")
     else
      resetData(d)
      if p==Players.LocalPlayer then setDefaultAnimate(model,true) end
     end
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
