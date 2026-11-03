import fs from 'node:fs';

const API='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';

async function request(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let lastError=null;
  for(let attempt=0;attempt<8;attempt++){
    const response=await fetch(API+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(30000),
    });
    const text=await response.text();
    let data;
    try{data=JSON.parse(text)}catch{data={raw:text}}
    if(response.ok) return data;
    if(response.status===429 || response.status===500 || response.status===502 || response.status===503){
      const retryHeader=Number(response.headers.get('retry-after'));
      const waitMs=Number.isFinite(retryHeader) && retryHeader>0
        ? retryHeader*1000
        : Math.min(45000,5000*(attempt+1));
      lastError=new Error('Roblox '+response.status+': '+JSON.stringify(data));
      console.log(JSON.stringify({retrying:true,status:response.status,attempt:attempt+1,waitMs}));
      await new Promise(r=>setTimeout(r,waitMs));
      continue;
    }
    throw new Error('Roblox '+response.status+': '+JSON.stringify(data));
  }
  throw lastError || new Error('Roblox request exhausted retries');
}

async function execute(script){
  let task=await request(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+240000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline || !task.path.startsWith(TARGET)) throw new Error('Task timeout or wrong target');
    await new Promise(r=>setTimeout(r,1500));
    task=await request(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau task failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const value=task?.output?.results?.[0];
  if(typeof value!=='string') return value??null;
  try{return JSON.parse(value)}catch{return value}
}

async function main(){
  const rebuildSource=fs.readFileSync(new URL('./rebuild.luau',import.meta.url),'utf8');
  const verifySource=fs.readFileSync(new URL('./verify.luau',import.meta.url),'utf8');

  const rebuildTask=await execute(rebuildSource);
  const rebuild=first(rebuildTask);

  let verifyTask=null,verify=null,lastError=null;
  for(let attempt=1;attempt<=6;attempt++){
    if(attempt>1) await new Promise(r=>setTimeout(r,3000));
    try{
      verifyTask=await execute(verifySource);
      verify=first(verifyTask);
      lastError=null;
      break;
    }catch(error){
      lastError=error;
    }
  }
  if(lastError) throw lastError;
  if(!verify?.ok) throw new Error('Fresh verification did not return ok=true');
  if(typeof rebuild?.sourceVersion==='number' && verify.placeVersion<=rebuild.sourceVersion){
    throw new Error('Place version did not advance');
  }

  const report={ok:true,target:{universeId:9421311218,placeId:118064584465155},rebuild,verify};
  fs.mkdirSync('out',{recursive:true});
  fs.writeFileSync('out/treeworld-v3-result.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report));
}

main().catch(error=>{
  const key=process.env.ROBLOX_API_KEY;
  console.error(key?String(error?.stack||error).split(key).join('[REDACTED]'):String(error?.stack||error));
  process.exit(1);
});
