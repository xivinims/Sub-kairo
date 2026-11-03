import fs from 'node:fs';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  let last=null;
  for(let i=0;i<12;i++){
    const res=await fetch(CLOUD+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(60000),
    });
    const text=await res.text();let data;try{data=JSON.parse(text)}catch{data={raw:text}}
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
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    await sleep(1500);task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error)throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}
const source=fs.readFileSync('treeworld-clean-v6-check/verify.luau','utf8');
const task=await execute(source);
const v=task.output?.results?.[0];
const result=typeof v==='string'?JSON.parse(v):v;
if(!result?.ok)throw new Error('Verification did not return ok=true');
console.log(JSON.stringify({ok:true,verify:result}));
