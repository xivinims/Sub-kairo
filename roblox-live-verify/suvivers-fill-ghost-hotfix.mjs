const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9419478735/places/79738710219521/';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last;
  for(let i=0;i<8;i++){
    const res=await fetch(CLOUD+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(60000)
    });
    const raw=await res.text();
    let data; try{data=JSON.parse(raw)}catch{data={raw}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(Math.min(30000,3000*(i+1)));
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
  const deadline=Date.now()+180000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Fill ghost hotfix timeout');
    await sleep(1200);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Fill ghost hotfix failed: '+JSON.stringify(task));
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

const luau=`
local Http=game:GetService("HttpService")
local PhysicsService=game:GetService("PhysicsService")
local npc=assert(workspace:FindFirstChild("LobbyGuide"),"Fill missing")
local root=assert(npc:FindFirstChild("HumanoidRootPart"),"Fill root missing")
local GROUP="LobbyGuideGhost"

pcall(function() PhysicsService:RegisterCollisionGroup(GROUP) end)
local function refreshGroups()
 for _,group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
  pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP,group.name,false) end)
 end
 pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP,GROUP,false) end)
end
refreshGroups()

local count=0
for _,part in ipairs(npc:GetDescendants()) do
 if part:IsA("BasePart") then
  pcall(function() part.CollisionGroup=GROUP end)
  part.CanCollide=false
  part.CanTouch=false
  part.CanQuery=false
  part.AssemblyLinearVelocity=Vector3.zero
  part.AssemblyAngularVelocity=Vector3.zero
  if part~=root then part.Massless=true end
  count+=1
 end
end
root.Anchored=true
npc:SetAttribute("NonBlockingGuide",true)
npc:SetAttribute("NonBlockingPartCount",count)
npc:SetAttribute("CollisionGroup",GROUP)

local old=npc:FindFirstChild("NonBlockingGuard")
if old then old:Destroy() end
local guard=Instance.new("Script")
guard.Name="NonBlockingGuard"
guard.RunContext=Enum.RunContext.Server
guard.Source=[=[
local PhysicsService=game:GetService("PhysicsService")
local npc=script.Parent
local GROUP="LobbyGuideGhost"
pcall(function() PhysicsService:RegisterCollisionGroup(GROUP) end)

local locked=setmetatable({},{__mode="k"})
local function refreshGroups()
 for _,group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
  pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP,group.name,false) end)
 end
 pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP,GROUP,false) end)
end

local function lockPart(part)
 if not part:IsA("BasePart") then return end
 pcall(function() part.CollisionGroup=GROUP end)
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
 if part.Name~="HumanoidRootPart" then part.Massless=true end
 if locked[part] then return end
 locked[part]=true
 part:GetPropertyChangedSignal("CanCollide"):Connect(function()
  if part.Parent and part.CanCollide then part.CanCollide=false end
 end)
 part:GetPropertyChangedSignal("CanTouch"):Connect(function()
  if part.Parent and part.CanTouch then part.CanTouch=false end
 end)
 part:GetPropertyChangedSignal("CanQuery"):Connect(function()
  if part.Parent and part.CanQuery then part.CanQuery=false end
 end)
 part:GetPropertyChangedSignal("CollisionGroup"):Connect(function()
  if part.Parent and part.CollisionGroup~=GROUP then pcall(function() part.CollisionGroup=GROUP end) end
 end)
end

refreshGroups()
for _,obj in ipairs(npc:GetDescendants()) do lockPart(obj) end
npc.DescendantAdded:Connect(function(obj) task.defer(lockPart,obj) end)

while npc.Parent do
 task.wait(5)
 refreshGroups()
 for _,obj in ipairs(npc:GetDescendants()) do lockPart(obj) end
end
]=]
guard.Parent=npc

assert(not PhysicsService:CollisionGroupsAreCollidable(GROUP,"Default"),"Fill ghost group still collides with Default")
for _,part in ipairs(npc:GetDescendants()) do
 if part:IsA("BasePart") then
  assert(part.CollisionGroup==GROUP,"Fill part outside ghost group: "..part:GetFullName())
  assert(not part.CanCollide and not part.CanTouch and not part.CanQuery,"Fill part not normalized: "..part:GetFullName())
 end
end
assert(guard.Parent==npc,"Fill nonblocking guard missing")

local ok,err=pcall(function()
 game:GetService("AssetService"):SavePlaceAsync({PlaceId=79738710219521,SaveWithoutPublish=false})
end)
assert(ok,"Could not publish Fill ghost hotfix: "..tostring(err))

return Http:JSONEncode({
 ok=true,
 version=game.PlaceVersion,
 parts=count,
 group=GROUP,
 defaultCollision=PhysicsService:CollisionGroupsAreCollidable(GROUP,"Default"),
 guard=true
})
`;

const result=await execute(luau);
console.log('SUVIVERS_FILL_GHOST_HOTFIX',JSON.stringify(result));
if(!result?.ok) throw new Error('Fill ghost hotfix did not return ok');
