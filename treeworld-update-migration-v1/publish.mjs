import fs from 'node:fs';

const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const UNIVERSE_ID='9421311218';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function jsonReq(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let attempt=0;attempt<12;attempt++){
    const res=await fetch(url,{...options,headers:{...(options.headers||{}),'x-api-key':key},signal:AbortSignal.timeout(60000)});
    const text=await res.text();
    let data; try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok) return {data,status:res.status,raw:text};
    if([429,500,502,503].includes(res.status)){
      const h=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(h)&&h>0?h*1000:Math.min(60000,5000*(attempt+1));
      console.log(JSON.stringify({retrying:true,status:res.status,attempt:attempt+1,waitMs,url}));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Request retries exhausted');
}

async function execute(script){
  const created=await jsonReq(CLOUD+TARGET+'luau-execution-session-tasks',{
    method:'POST',
    headers:{'content-type':'application/json'},
    body:JSON.stringify({timeout:'180s',script}),
  });
  let task=created.data;
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau execution timeout');
    await sleep(1500);
    task=(await jsonReq(CLOUD+task.path)).data;
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

async function probeMessaging(){
  const payload={topic:'Overyard_Update_Probe_v1',message:JSON.stringify({probe:true,source:'github-actions'})};
  try{
    const r=await jsonReq(CLOUD+'universes/'+UNIVERSE_ID+':publishMessage',{
      method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload),
    });
    console.log(JSON.stringify({messagingProbe:true,mode:'open-cloud',status:r.status}));
    return 'open-cloud';
  }catch(openErr){
    console.log(JSON.stringify({messagingOpenCloudProbe:false,error:String(openErr)}));
    const probeScript='local MessagingService=game:GetService("MessagingService")\nlocal HttpService=game:GetService("HttpService")\nlocal ok,err=pcall(function()\n  MessagingService:PublishAsync("Overyard_Update_Probe_v1",HttpService:JSONEncode({probe=true,source="luau-execution"}))\nend)\nreturn {ok=ok,error=ok and nil or tostring(err)}';
    const result=first(await execute(probeScript));
    if(!result?.ok) throw new Error('Both messaging publish methods failed: '+JSON.stringify(result));
    console.log(JSON.stringify({messagingProbe:true,mode:'luau'}));
    return 'luau';
  }
}

const installSource=fs.readFileSync('treeworld-update-migration-v1/install.luau','utf8');
const verifySource=fs.readFileSync('treeworld-update-migration-v1/verify.luau','utf8');
const install=first(await execute(installSource));

let verify=null,last=null;
for(let i=0;i<10;i++){
  if(i) await sleep(3500);
  try{verify=first(await execute(verifySource));last=null;break}catch(e){last=e}
}
if(last) throw last;
if(!verify?.ok) throw new Error('Verification did not return ok=true');
if(typeof install?.sourceVersion==='number' && verify.placeVersion<=install.sourceVersion) throw new Error('Place version did not advance');

const messagingMode=await probeMessaging();
console.log(JSON.stringify({ok:true,install,verify,messagingMode}));
