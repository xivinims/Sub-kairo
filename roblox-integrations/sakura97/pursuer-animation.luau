-- Faithful local playback of the authored Jason KeyframeSequences.
-- Roblox Pose.CFrame belongs on Motor6D.Transform; C0/C1 remain untouched.
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local TweenService=game:GetService("TweenService")
local Encoding=game:GetService("EncodingService")
local net=game.ReplicatedStorage:WaitForChild("Survival")
local cache=setmetatable({},{__mode="k"})

local function decodePose(raw)
 if typeof(raw)=="table" and raw.c then
  return {
   cf=CFrame.new(table.unpack(raw.c)),
   easing=raw.e or "Linear",
   direction=raw.d or "InOut",
   weight=raw.w or 1,
  }
 end
 -- Compatibility with older compact clips.
 return {cf=CFrame.new(table.unpack(raw)),easing="Linear",direction="InOut",weight=1}
end

local function prepare(model,folder)
 if #folder:GetChildren()~=(folder:GetAttribute("ClipCount") or math.huge) then return nil end
 local d={joints={},clips={},time=0,state="",active=false}
 for _,j in ipairs(model:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part1 then
   d.joints[j.Part1.Name]=j
  end
 end

 for _,v in ipairs(folder:GetChildren()) do
  if v:IsA("Folder") then
   local chunks=v:GetChildren()
   if #chunks~=(v:GetAttribute("ChunkCount") or math.huge) then return nil end
   table.sort(chunks,function(a,b) return a.Name<b.Name end)
   local values={}
   for _,chunk in ipairs(chunks) do table.insert(values,chunk.Value) end
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
     local pose=decodePose(raw)
     pose.time=frame.time
     table.insert(channel,pose)
    end
   end
   for _,channel in pairs(clip.channels) do
    table.sort(channel,function(a,b) return a.time<b.time end)
   end
   d.clips[v.Name]=clip
  end
 end
 cache[model]=d
 return d
end

local function reset(d)
 if not d.active then return end
 for _,joint in pairs(d.joints) do
  if joint.Parent then joint.Transform=CFrame.identity end
 end
 d.active=false
end

local function easedAlpha(alpha,pose)
 local style=Enum.EasingStyle[pose.easing] or Enum.EasingStyle.Linear
 local direction=Enum.EasingDirection[pose.direction] or Enum.EasingDirection.InOut
 local ok,value=pcall(TweenService.GetValue,TweenService,alpha,style,direction)
 return ok and value or alpha
end

local function sample(channel,t)
 if not channel or #channel==0 then return CFrame.identity end
 if #channel==1 or t<=channel[1].time then
  return CFrame.identity:Lerp(channel[1].cf,channel[1].weight)
 end
 local last=channel[#channel]
 if t>=last.time then return CFrame.identity:Lerp(last.cf,last.weight) end
 local a,b=channel[1],last
 for i=1,#channel-1 do
  if channel[i+1].time>=t then a=channel[i] b=channel[i+1] break end
 end
 local alpha=b.time>a.time and math.clamp((t-a.time)/(b.time-a.time),0,1) or 0
 alpha=easedAlpha(alpha,a)
 local acf=CFrame.identity:Lerp(a.cf,a.weight)
 local bcf=CFrame.identity:Lerp(b.cf,b.weight)
 return acf:Lerp(bcf,alpha)
end

local function apply(d,state,dt,loop,absolute)
 if d.state~=state then d.state=state d.time=0 end
 d.time+=dt
 local clip=d.clips[state]
 if not clip or clip.length<=0 then return end
 local t=absolute or d.time
 t=loop and t%clip.length or math.min(t,clip.length)
 for name,joint in pairs(d.joints) do
  if joint.Parent then joint.Transform=sample(clip.channels[name],t) end
 end
 d.active=true
end

Run.PreSimulation:Connect(function(dt)
 for _,model in ipairs(workspace:GetChildren()) do
  if model:IsA("Model") and model:GetAttribute("ActivePursuer") and model.PrimaryPart then
   local folder=model:FindFirstChild("MotionClips")
   if folder then
    local d=cache[model] or prepare(model,folder)
    local speed=(model.PrimaryPart.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude
    local attack=model:GetAttribute("AttackAt") or -100
    local since=workspace:GetServerTimeNow()-attack
    local state=since<.75 and "Jason Slash" or speed>16 and "Jason Run" or speed>1 and "Jason Walk" or "Jason Idle"
    if d then apply(d,state,dt,state~="Jason Slash",state=="Jason Slash" and since or nil) end
   end
  end
 end

 for _,p in ipairs(Players:GetPlayers()) do
  local model=p.Character
  if model and not model:GetAttribute("ActivePursuer") then
   if p:GetAttribute("MoveMode")=="slow" and p:GetAttribute("InRound") and not p:GetAttribute("Downed") then
    local d=cache[model] or prepare(model,net.CrouchClips)
    local root=model:FindFirstChild("HumanoidRootPart")
    local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
    if d then apply(d,speed>1 and "Crouch Walk" or "Crouch Idle",dt,true) end
   elseif cache[model] then
    reset(cache[model])
   end
  end
 end
end)