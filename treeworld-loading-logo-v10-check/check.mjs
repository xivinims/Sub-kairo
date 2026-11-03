import fs from 'node:fs';
const API='https://apis.roblox.com/';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const ASSET_ID=77442764802726;
const TOPIC='Overyard_Update_v1';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<12;i++){
    const res=await fetch(url,{...options,headers:{...(options.headers||{}),'x-api-key':key},signal:AbortSignal.timeout(60000)});
    const text=await res.text();let data;try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok)return data;
    if([429,500,502,503].includes(res.status)){const waitMs=Math.min(60000,5000*(i+1));last=new Error('HTTP '+res.status+': '+JSON.stringify(data));await sleep(waitMs);continue;}
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function execute(script){
  let task=await req(CLOUD+TARGET+'luau-execution-session-tasks',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({timeout:'180s',script})});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){if(Date.now()>deadline)throw new Error('Luau timeout');await sleep(1500);task=await req(CLOUD+task.path);}
  if(task.state!=='COMPLETE'||task.error)throw new Error('Luau failed: '+JSON.stringify(task));
  const v=task?.output?.results?.[0];if(typeof v!=='string')return v??null;try{return JSON.parse(v)}catch{return v}
}

async function waitApproved(){
  const deadline=Date.now()+360000;
  let last=null;
  while(Date.now()<deadline){
    try{
      const meta=await req(API+'assets/v1/assets/'+ASSET_ID+'?readMask=moderationResult,displayName,assetType');
      const state=String(meta?.moderationResult?.moderationState||meta?.moderationResult?.state||'').toUpperCase();
      console.log(JSON.stringify({assetId:ASSET_ID,moderationState:state||'UNKNOWN'}));
      if(state.includes('APPROVED'))return meta;
      if(state.includes('REJECTED'))throw new Error('Transparent logo was rejected: '+JSON.stringify(meta));
      last=meta;
    }catch(e){
      console.log(JSON.stringify({metadataCheckWarning:String(e)}));
      last=e;
    }
    await sleep(10000);
  }
  throw new Error('Transparent logo did not reach APPROVED state in time: '+String(last));
}

await waitApproved();
const verify=await execute(fs.readFileSync('treeworld-loading-logo-v10-check/verify.luau','utf8'));
if(!verify?.ok)throw new Error('Verification did not return ok=true');

const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:Number(verify.placeVersion),releaseId:'transparent-greeting-v'+verify.placeVersion,kind:'game-update'});
const broadcast='local MessagingService=game:GetService("MessagingService")\nlocal ok,err=pcall(function() MessagingService:PublishAsync("'+TOPIC+'",'+JSON.stringify(payload)+') end)\nreturn {ok=ok,error=ok and nil or tostring(err)}';
const sent=await execute(broadcast);
if(!sent?.ok)throw new Error('Update broadcast failed: '+JSON.stringify(sent));

console.log(JSON.stringify({ok:true,verify,assetApproved:true,broadcast:true}));