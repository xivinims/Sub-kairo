const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:body?'POST':'GET',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:body?JSON.stringify(body):undefined,
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  return data;
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
  const deadline=Date.now()+180000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Live verify timeout');
    await sleep(1200);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Live verify failed: '+JSON.stringify(task));
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

const luau = `
local Http=game:GetService("HttpService")
local lobby=assert(workspace:FindFirstChild("JediLibrary"),"JediLibrary missing")
local house=assert(lobby:FindFirstChild("House"),"Lobby house missing")
assert((lobby:GetAttribute("PassageRepairRevision") or 0)>=2,"Passage repair revision missing")

local openDoorParts,doorFrames,visualStairs,stairSteps=0,0,0,0
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  if p.Transparency>=.98 then
   assert(not p.CanCollide,"Invisible collidable blocker: "..p:GetFullName())
  end
  if p:GetAttribute("OpenPassage") then
   assert(not p.CanCollide,"Open passage collides: "..p:GetFullName())
   openDoorParts+=1
   if p:GetAttribute("PassageWidth") then doorFrames+=1 end
  end
  if p:GetAttribute("VisualOnlyStair") then
   assert(not p.CanCollide,"Visual stair still collides: "..p:GetFullName())
   visualStairs+=1
  end
 end
end
assert(openDoorParts>=7 and doorFrames>=3,"Persisted door repair incomplete")
assert(visualStairs>=6,"Persisted stair visuals incomplete")

local access=assert(lobby:FindFirstChild("PassageColliders"),"PassageColliders missing")
local groups={}
for _,p in ipairs(access:GetDescendants()) do
 if p:IsA("BasePart") and p:GetAttribute("WalkableStairStep") then
  assert(p.CanCollide and p.Transparency>=.98,"Walkable stair step invalid")
  stairSteps+=1
  local source=p:GetAttribute("SourceStair") or "unknown"
  groups[source]=(groups[source] or 0)+1
 end
end
local usableStairs=0
for _,count in pairs(groups) do if count>=8 then usableStairs+=1 end end
assert(stairSteps>=8 and usableStairs>=1,"Persisted walkable stair chain missing")

local npc=assert(workspace:FindFirstChild("LobbyGuide"),"Fill missing")
assert(npc:GetAttribute("ReceptionAccessMode")=="SpawnRoomDirect","Fill direct access mode missing")
assert(npc:GetAttribute("GuideStation")=="FillGuideStool","Fill guide station metadata missing")
local station=assert(lobby:FindFirstChild("FillGuideStool"),"FillGuideStool missing")
assert(station:GetAttribute("SpawnRoomGuideStation")==true and station:GetAttribute("NonBlocking")==true,"Fill station flags missing")
for _,p in ipairs(station:GetDescendants()) do
 if p:IsA("BasePart") then assert(not p.CanCollide,"Fill station blocks movement: "..p:GetFullName()) end
end
local visitor=npc:GetAttribute("VerifiedVisitorPosition")
local spawn=lobby:GetAttribute("VerifiedSpawn")
assert(typeof(visitor)=="Vector3" and typeof(spawn)=="Vector3","Fill/spawn access position missing")
local flat=(Vector2.new(visitor.X,visitor.Z)-Vector2.new(spawn.X,spawn.Z)).Magnitude
assert(flat<=1.5,"Fill visitor point is not at spawn")
assert((visitor-npc.HumanoidRootPart.Position).Magnitude<=npc.ProximityPrompt.MaxActivationDistance,"Fill outside prompt range from spawn")

local client=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SurvivalClient"),"SurvivalClient missing")
local source=client.Source
assert(source:find("CartIcon",1,true),"Shop cart icon source missing")
assert(source:find("ClockFace",1,true) and source:find("MinuteHand",1,true),"Waiting clock icon source missing")
assert(source:find('phase=="Aguardando"',1,true),"Waiting-player clock state missing")

local guideSource=assert(npc:FindFirstChild("GuideInteraction"),"Fill GuideInteraction missing").Source
assert(guideSource:find("local breath=math.sin",1,true),"Fill breathing animation missing")
assert(guideSource:find("leftShoulder",1,true) and guideSource:find("rightShoulder",1,true),"Fill shoulder idle animation missing")

return Http:JSONEncode({
 ok=true,
 version=game.PlaceVersion,
 openDoorParts=openDoorParts,
 doorFrames=doorFrames,
 visualStairs=visualStairs,
 stairSteps=stairSteps,
 usableStairs=usableStairs,
 fillDirectFromSpawn=true,
 shopCart=true,
 waitingClock=true,
 fillAnimated=true
})
`;

const result=await execute(luau);
console.log('SUVIVERS_LOBBY_LIVE_VERIFY',JSON.stringify(result));
if(!result || result.ok!==true) throw new Error('Live lobby verification did not return ok');
