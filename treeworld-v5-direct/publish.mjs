import fs from 'node:fs';

const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const HOUSE_ID=115962225394318;
const PORTAL_ID=113932150476095;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let attempt=0;attempt<10;attempt++){
    const res=await fetch(CLOUD+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(60000),
    });
    const text=await res.text();
    let data; try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      const retry=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(45000,5000*(attempt+1));
      console.log(JSON.stringify({retrying:true,status:res.status,attempt:attempt+1,waitMs}));
      last=new Error('Roblox '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('Roblox '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+300000;
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

let src=fs.readFileSync('treeworld-v5/rebuild.luau','utf8')
  .replaceAll('__HOUSE_ASSET_ID__',String(HOUSE_ID))
  .replaceAll('__PORTAL_ASSET_ID__',String(PORTAL_ID));
const verifySrc=fs.readFileSync('treeworld-v5/verify.luau','utf8');

const rebuild=first(await execute(src));
let verify=null,last=null;
for(let i=0;i<8;i++){
  if(i) await sleep(3500);
  try{verify=first(await execute(verifySrc));last=null;break}catch(e){last=e}
}
if(last) throw last;
if(!verify?.ok) throw new Error('Verification did not return ok=true');
if(typeof rebuild?.sourceVersion==='number' && verify.placeVersion<=rebuild.sourceVersion){
  throw new Error('Place version did not advance');
}
console.log(JSON.stringify({ok:true,rebuild,verify}));
