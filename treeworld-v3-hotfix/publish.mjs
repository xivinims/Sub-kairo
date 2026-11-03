import fs from 'node:fs';
const API='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';

async function request(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let attempt=0;attempt<9;attempt++){
    const response=await fetch(API+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(30000),
    });
    const text=await response.text();
    let data; try{data=JSON.parse(text)}catch{data={raw:text}}
    if(response.ok) return data;
    if([429,500,502,503].includes(response.status)){
      const retry=Number(response.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(45000,5000*(attempt+1));
      last=new Error('Roblox '+response.status+': '+JSON.stringify(data));
      console.log(JSON.stringify({retrying:true,status:response.status,attempt:attempt+1,waitMs}));
      await new Promise(r=>setTimeout(r,waitMs));
      continue;
    }
    throw new Error('Roblox '+response.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Roblox retry limit exhausted');
}

async function execute(script){
  let task=await request(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+240000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline||!task.path.startsWith(TARGET)) throw new Error('Task timeout or wrong target');
    await new Promise(r=>setTimeout(r,1500));
    task=await request(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}
function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}
const patch=first(await execute(fs.readFileSync(new URL('./rocks-hotfix.luau',import.meta.url),'utf8')));
let verify,last;
for(let i=0;i<6;i++){
  if(i) await new Promise(r=>setTimeout(r,3000));
  try{
    verify=first(await execute(fs.readFileSync(new URL('../treeworld-rebuild-v3/verify.luau',import.meta.url),'utf8')));
    last=null;break;
  }catch(e){last=e}
}
if(last) throw last;
if(!verify?.ok) throw new Error('Verification did not return ok=true');
console.log(JSON.stringify({ok:true,patch,verify}));
