import fs from 'node:fs';
const API='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
async function request(path,body){
 const key=process.env.ROBLOX_API_KEY;if(!key)throw new Error('Missing ROBLOX_API_KEY');
 let last=null;
 for(let attempt=0;attempt<9;attempt++){
  const r=await fetch(API+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(30000)});
  const text=await r.text();let data;try{data=JSON.parse(text)}catch{data={raw:text}}
  if(r.ok)return data;
  if([429,500,502,503].includes(r.status)){
   const h=Number(r.headers.get('retry-after'));const waitMs=Number.isFinite(h)&&h>0?h*1000:Math.min(45000,5000*(attempt+1));
   last=new Error('Roblox '+r.status+': '+JSON.stringify(data));
   console.log(JSON.stringify({retrying:true,status:r.status,attempt:attempt+1,waitMs}));
   await new Promise(res=>setTimeout(res,waitMs));continue;
  }
  throw new Error('Roblox '+r.status+': '+JSON.stringify(data));
 }
 throw last||new Error('retry limit');
}
async function execute(script){
 let task=await request(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
 const deadline=Date.now()+240000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
  if(Date.now()>deadline)throw new Error('timeout');
  await new Promise(r=>setTimeout(r,1500));task=await request(task.path);
 }
 if(task.state!=='COMPLETE'||task.error)throw new Error('Luau failed: '+JSON.stringify(task));
 return task;
}
const task=await execute(fs.readFileSync(new URL('./verify.luau',import.meta.url),'utf8'));
const v=task.output?.results?.[0];
const result=typeof v==='string'?JSON.parse(v):v;
if(!result?.ok)throw new Error('Verification did not return ok=true');
console.log(JSON.stringify({ok:true,verify:result}));
