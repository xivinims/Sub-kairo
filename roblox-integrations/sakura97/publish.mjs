import fs from 'node:fs';

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



const result=first(await execute(`
local out={}
for _,id in ipairs({87377915371959,4617134997,84828163072141}) do
 local a=game:GetService("AssetService"):LoadAssetAsync(id)
 local item={id=id,details={}}
 for _,d in ipairs(a:GetDescendants()) do
  if d:IsA("MeshPart") and id==87377915371959 then
   local mn=Vector3.new(math.huge,math.huge,math.huge) local mx=-mn local n=0
   for _,b in ipairs(d:GetDescendants()) do if b:IsA("Bone") then
    local v=d.CFrame:PointToObjectSpace(b.WorldPosition) mn=mn:Min(v) mx=mx:Max(v) n+=1
   end end
   table.insert(item.details,{name=d:GetFullName(),mesh=d.MeshId,size=tostring(d.Size),rotation=tostring(d.CFrame.Rotation),bones=n,min=tostring(mn),max=tostring(mx),color=tostring(d.Color),material=d.Material.Name})
  elseif d:IsA("GuiObject") then
   local e={name=d:GetFullName(),class=d.ClassName,position=tostring(d.Position),size=tostring(d.Size),visible=d.Visible}
   if d:IsA("TextLabel") or d:IsA("TextButton") then e.text=d.Text end
   table.insert(item.details,e)
  end
 end
 if id==4617134997 then local cf,sz=a:GetBoundingBox() item.size=tostring(sz) item.parts=#a:GetDescendants() end
 table.insert(out,item) a:Destroy()
end
return out
`));console.log(JSON.stringify(result));
