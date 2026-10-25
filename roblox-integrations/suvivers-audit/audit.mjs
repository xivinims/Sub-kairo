const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<12;i++){
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
      const retry=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(60000,5000*(i+1));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function patchCloud(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:'PATCH',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:JSON.stringify(body),
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('PATCH '+path+' HTTP '+res.status+': '+JSON.stringify(data));
  return data;
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau timeout');
    await sleep(1500);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}



const script=`
local Players=game:GetService("Players")
local id=Players:GetUserIdFromNameAsync("ch_ckz2n")
local description=Players:GetHumanoidDescriptionFromUserIdAsync(id)
local report={userId=id,shirt=description.Shirt,pants=description.Pants,accessories=description:GetAccessories(true),tables={}}
local npc=game:GetService("AssetService"):LoadAssetAsync(92697245643515)
report.joints={}
for _,v in ipairs(npc:GetDescendants()) do if v:IsA("Motor6D") then table.insert(report.joints,{name=v.Name,part0=v.Part0 and v.Part0.Name,part1=v.Part1 and v.Part1.Name,c0={v.C0:GetComponents()},transform={v.Transform:GetComponents()}}) end end
local ok,seq=pcall(function() return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync("rbxassetid://10353447633") end)
report.pose={ok=ok}
if ok then
 local frames=seq:GetKeyframes() table.sort(frames,function(a,b) return a.Time<b.Time end)
 report.pose.frames=#frames report.pose.length=frames[#frames].Time report.pose.first={}
 for _,p in ipairs(frames[1]:GetDescendants()) do if p:IsA("Pose") then table.insert(report.pose.first,{name=p.Name,weight=p.Weight,cf={p.CFrame:GetComponents()}}) end end
else report.pose.error=tostring(seq) end
local lobby=workspace:FindFirstChild("JediLibrary")
local spawn=lobby and lobby:GetAttribute("VerifiedSpawn")
report.spawn=tostring(spawn)
local origin=typeof(spawn)=="CFrame" and spawn.Position or typeof(spawn)=="Vector3" and spawn or Vector3.zero
for _,v in ipairs(lobby:GetDescendants()) do
 if v:IsA("BasePart") and v.Anchored and v.CanCollide and v.Size.X>=4 and v.Size.Z>=3 and v.Size.Y<=2 and v.CFrame.UpVector.Y>.98 then
 table.insert(report.tables,{path=v:GetFullName(),pos=tostring(v.Position),size=tostring(v.Size),distance=(v.Position-origin).Magnitude,name=v.Name,parent=v.Parent.Name})
 end
end
table.sort(report.tables,function(a,b) return a.distance<b.distance end)
while #report.tables>35 do table.remove(report.tables) end
return report
`;
console.log('NPC_AVATAR_AUDIT',JSON.stringify(first(await execute(script))));
