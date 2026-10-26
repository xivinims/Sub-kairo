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
local npc=assert(workspace:FindFirstChild("LobbyGuide"))
local spawn=lobby:GetAttribute("VerifiedSpawn")
local out={version=game.PlaceVersion,nearby={},outside={},topFloor={}}

local function ancestry(obj)
 local names={obj.Name}
 local p=obj.Parent
 for _=1,6 do
  if not p or p==lobby then break end
  table.insert(names,1,p.Name) p=p.Parent
 end
 return table.concat(names,"/")
end

for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") and p.Transparency<.98 then
  local d=(p.Position-npc.HumanoidRootPart.Position).Magnitude
  local horizontal=math.abs(p.CFrame.UpVector.Y)>.88
  if d<=32 and horizontal and p.Size.X>=1.5 and p.Size.Z>=1.5 and p.Size.Y<=6 then
   table.insert(out.nearby,{
    path=ancestry(p),pos=tostring(p.Position),size=tostring(p.Size),
    top=p.Position.Y+p.Size.Y/2,d=d,collide=p.CanCollide
   })
  end
  if p.Position.Y>642 and p.Position.Y<650 and p.CanCollide and p.Size.X>=3 and p.Size.Z>=3 then
   table.insert(out.topFloor,{path=ancestry(p),pos=tostring(p.Position),size=tostring(p.Size),top=p.Position.Y+p.Size.Y/2})
  end
 end
end
table.sort(out.nearby,function(a,b)return a.d<b.d end)
while #out.nearby>50 do table.remove(out.nearby) end
while #out.topFloor>30 do table.remove(out.topFloor) end

local excludes={}
for _,name in ipairs({"Barriers","InvisibleBounds","PassageColliders","FillGuideStool","FillReceptionCounter"}) do
 local o=lobby:FindFirstChild(name)
 if o then table.insert(excludes,o) end
end
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances=excludes
params.RespectCanCollide=true
for x=-180,180,45 do
 for z=-160,160,40 do
  local wx=306.9+x local wz=6.59+z
  local outside=not (wx>174.8 and wx<438.9 and wz>-111.9 and wz<125.1)
  if outside then
   local hit=workspace:Raycast(Vector3.new(wx,720,wz),Vector3.new(0,-220,0),params)
   table.insert(out.outside,{x=wx,z=wz,hit=hit and ancestry(hit.Instance) or nil,y=hit and hit.Position.Y or nil,class=hit and hit.Instance.ClassName or nil})
  end
 end
end
return Http:JSONEncode(out)
`;
const result=await execute(luau);
console.log('SUVIVERS_LOBBY_DIAGNOSTIC2',JSON.stringify(result));
