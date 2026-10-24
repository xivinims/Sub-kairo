import fs from 'node:fs';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
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
    const text=await res.text();
    let data;try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok)return data;
    if([429,500,502,503].includes(res.status)){
      const h=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(h)&&h>0?h*1000:Math.min(60000,5000*(i+1));
      console.log(JSON.stringify({retrying:true,status:res.status,attempt:i+1,waitMs}));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}
async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline)throw new Error('Luau timeout');
    await sleep(1500);task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error)throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}
function first(task){const v=task?.output?.results?.[0];if(typeof v!=='string')return v??null;try{return JSON.parse(v)}catch{return v}}
const rebuild=first(await execute(fs.readFileSync('treeworld-v7/rebuild.luau','utf8')));
let verify=null,last=null;
for(let i=0;i<10;i++){
  if(i)await sleep(3500);
  try{verify=first(await execute(fs.readFileSync('treeworld-v7/verify.luau','utf8')));last=null;break}catch(e){last=e}
}
if(last)throw last;
if(!verify?.ok)throw new Error('Verification did not return ok=true');
if(typeof rebuild?.sourceVersion==='number' && verify.placeVersion<=rebuild.sourceVersion)throw new Error('Place version did not advance');
console.log(JSON.stringify({ok:true,rebuild,verify}));
