import fs from 'node:fs';
const API='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
async function req(path,body){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const r=await fetch(API+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(30000)});
 const text=await r.text(); let data; try{data=JSON.parse(text)}catch{data={raw:text}}
 if(!r.ok) throw new Error('Roblox '+r.status+': '+JSON.stringify(data));
 return data;
}
async function execute(script){
 let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
 const deadline=Date.now()+240000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
  if(Date.now()>deadline) throw new Error('timeout');
  await new Promise(r=>setTimeout(r,1400));
  task=await req(task.path);
 }
 if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task));
 return task;
}
const task=await execute(fs.readFileSync(new URL('./probe.luau',import.meta.url),'utf8'));
const v=task.output?.results?.[0];
const data=typeof v==='string'?JSON.parse(v):v;
console.log(JSON.stringify(data));
