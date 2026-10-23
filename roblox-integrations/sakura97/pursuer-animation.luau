-- Exact source keyframes, evaluated locally without animation ownership substitution.
local Run=game:GetService("RunService") local Players=game:GetService("Players") local Http=game:GetService("HttpService")
local net=game.ReplicatedStorage:WaitForChild("Survival") local cache=setmetatable({},{__mode="k"}) local models={} local elapsed=0
local function prepare(model,folder)
 if #folder:GetChildren()~=(folder:GetAttribute("ClipCount") or math.huge) then return nil end
 local d={joints={},clips={},time=0,state="",active=false}
 for _,j in ipairs(model:GetDescendants()) do if j:IsA("Motor6D") and j.Part1 then d.joints[j.Part1.Name]={joint=j,base=j.C0} end end
 for _,v in ipairs(folder:GetChildren()) do if v:IsA("Folder") then
  local chunks=v:GetChildren() if #chunks~=(v:GetAttribute("ChunkCount") or math.huge) then return nil end table.sort(chunks,function(a,b) return a.Name<b.Name end)
  local values={} for _,chunk in ipairs(chunks) do table.insert(values,chunk.Value) end
  local ok,clip=pcall(function() return Http:JSONDecode(buffer.tostring(game:GetService("EncodingService"):DecompressBuffer(game:GetService("EncodingService"):Base64Decode(buffer.fromstring(table.concat(values))),Enum.CompressionAlgorithm.Zstd))) end) if not ok then return nil end
  for _,f in ipairs(clip.frames) do for n,components in pairs(f.poses) do f.poses[n]=CFrame.new(table.unpack(components)) end end
  d.clips[v.Name]=clip
 end end
 cache[model]=d return d
end
local function reset(d)
 if d.active then for _,j in pairs(d.joints) do if j.joint.Parent then j.joint.C0=j.base end end d.active=false end
end
local function apply(d,state,dt,loop,absolute)
 if d.state~=state then d.state=state d.time=0 end d.time+=dt
 local clip=d.clips[state] if not clip or clip.length<=0 then return end
 local t=absolute or d.time t=loop and t%clip.length or math.min(t,clip.length)
 local a,b=clip.frames[1],clip.frames[#clip.frames]
 for i=1,#clip.frames-1 do if clip.frames[i+1].time>=t then a=clip.frames[i] b=clip.frames[i+1] break end end
 local alpha=b.time>a.time and math.clamp((t-a.time)/(b.time-a.time),0,1) or 0
 for name,j in pairs(d.joints) do
  local pose=a.poses[name] or CFrame.identity
  if j.joint.Parent then j.joint.C0=j.base*pose:Lerp(b.poses[name] or pose,alpha) j.joint.Transform=CFrame.identity end
 end d.active=true
end
Run.PreSimulation:Connect(function(dt)
 for _,model in ipairs(workspace:GetChildren()) do
  if model:IsA("Model") and model:GetAttribute("ActivePursuer") and model.PrimaryPart then
   local folder=model:FindFirstChild("MotionClips")
   if folder then
    local d=cache[model] or prepare(model,folder) local speed=(model.PrimaryPart.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude
    local attack=model:GetAttribute("AttackAt") or -100
    local since=workspace:GetServerTimeNow()-attack
    local state=since<.75 and "Jason Slash" or speed>16 and "Jason Run" or speed>1 and "Jason Walk" or "Jason Idle"
    if d then apply(d,state,dt,state~="Jason Slash",state=="Jason Slash" and since or nil) end
   end
  end
 end
 for _,p in ipairs(Players:GetPlayers()) do local model=p.Character
  if model and not model:GetAttribute("ActivePursuer") then
   if p:GetAttribute("MoveMode")=="slow" and p:GetAttribute("InRound") and not p:GetAttribute("Downed") then
    local d=cache[model] or prepare(model,net.CrouchClips)
    local root=model:FindFirstChild("HumanoidRootPart") local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
    if d then apply(d,speed>1 and "Crouch Walk" or "Crouch Idle",dt,true) end
   elseif cache[model] then reset(cache[model]) end
  end
 end
end)
