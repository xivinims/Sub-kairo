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
local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local house=assert(lobby:FindFirstChild("House"))
local npc=workspace:FindFirstChild("LobbyGuide")
local spawn=lobby:GetAttribute("VerifiedSpawn")
local lobbyCF,lobbySize=lobby:GetBoundingBox()
local minv=Vector3.new(math.huge,math.huge,math.huge)
local maxv=Vector3.new(-math.huge,-math.huge,-math.huge)
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  local half=p.Size/2
  minv=Vector3.new(math.min(minv.X,p.Position.X-half.X),math.min(minv.Y,p.Position.Y-half.Y),math.min(minv.Z,p.Position.Z-half.Z))
  maxv=Vector3.new(math.max(maxv.X,p.Position.X+half.X),math.max(maxv.Y,p.Position.Y+half.Y),math.max(maxv.Z,p.Position.Z+half.Z))
 end
end
local houseSize=maxv-minv
local houseCF=CFrame.new((minv+maxv)/2)
local out={
 version=game.PlaceVersion,
 spawn=tostring(spawn),
 lobby={cf=tostring(lobbyCF),size=tostring(lobbySize)},
 house={cf=tostring(houseCF),size=tostring(houseSize)},
 npc=npc and {root=tostring(npc.HumanoidRootPart.Position),surface=npc:GetAttribute("ReceptionSurface")} or nil,
 furniture={},stairs={},outside={}
}

local function ancestry(obj)
 local names={obj.Name}
 local p=obj.Parent
 for _=1,5 do
  if not p or p==lobby then break end
  table.insert(names,1,p.Name)
  p=p.Parent
 end
 return table.concat(names,"/")
end

for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  local text=string.lower(ancestry(p))
  if string.find(text,"table",1,true) or string.find(text,"desk",1,true) or string.find(text,"counter",1,true) or string.find(text,"dining",1,true) or string.find(text,"hutch",1,true) then
   table.insert(out.furniture,{
    path=ancestry(p),name=p.Name,pos=tostring(p.Position),size=tostring(p.Size),
    top=p.Position.Y+p.Size.Y/2,collide=p.CanCollide,trans=p.Transparency,
    spawnDist=typeof(spawn)=="Vector3" and (p.Position-spawn).Magnitude or -1,
    npcDist=npc and (p.Position-npc.HumanoidRootPart.Position).Magnitude or -1
   })
  end
  local n=string.lower(p.Name)
  if string.find(n,"stair",1,true) or string.find(n,"step",1,true) or string.find(n,"rail",1,true) then
   table.insert(out.stairs,{path=ancestry(p),pos=tostring(p.Position),size=tostring(p.Size),collide=p.CanCollide,visual=p:GetAttribute("VisualOnlyStair"),walkable=p:GetAttribute("WalkableReplacement")})
  end
 end
end

table.sort(out.furniture,function(a,b)return a.npcDist<b.npcDist end)
while #out.furniture>30 do table.remove(out.furniture) end

local access=lobby:FindFirstChild("PassageColliders")
if access then
 for _,p in ipairs(access:GetChildren()) do
  if p:IsA("BasePart") and p:GetAttribute("WalkableStairStep") then
   table.insert(out.stairs,{path="PassageColliders/"..p.Name,pos=tostring(p.Position),size=tostring(p.Size),collide=p.CanCollide,source=p:GetAttribute("SourceStair")})
  end
 end
end
while #out.stairs>80 do table.remove(out.stairs) end

local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={lobby}
params.RespectCanCollide=true
local yTop=math.max(houseCF.Position.Y+houseSize.Y/2+30,lobbyCF.Position.Y+lobbySize.Y/2+10)
for xi=-3,3 do
 for zi=-3,3 do
  local x=houseCF.Position.X+xi*(houseSize.X/2+12)/3
  local z=houseCF.Position.Z+zi*(houseSize.Z/2+12)/3
  local inHouse=math.abs(x-houseCF.Position.X)<houseSize.X/2-2 and math.abs(z-houseCF.Position.Z)<houseSize.Z/2-2
  if not inHouse then
   local hit=workspace:Raycast(Vector3.new(x,yTop,z),Vector3.new(0,-220,0),params)
   table.insert(out.outside,{x=x,z=z,hit=hit and ancestry(hit.Instance) or nil,y=hit and hit.Position.Y or nil,normal=hit and tostring(hit.Normal) or nil,collide=hit and hit.Instance.CanCollide or nil})
  end
 end
end
return Http:JSONEncode(out)
`;

const result=await execute(luau);
console.log('SUVIVERS_LOBBY_DIAGNOSTIC',JSON.stringify(result));
