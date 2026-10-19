import fs from 'node:fs';

const API='https://apis.roblox.com/';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const LOGO_URL='https://overyard-logo-temp.vercel.app/logo.jpg';
const CREATOR_ID='8344738123';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function jsonReq(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let attempt=0;attempt<12;attempt++){
    const res=await fetch(url,{
      ...options,
      headers:{...(options.headers||{}),'x-api-key':key},
      signal:AbortSignal.timeout(60000),
    });
    const text=await res.text();
    let data;try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok)return data;
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
  let task=await jsonReq(CLOUD+TARGET+'luau-execution-session-tasks',{
    method:'POST',
    headers:{'content-type':'application/json'},
    body:JSON.stringify({timeout:'180s',script}),
  });
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline)throw new Error('Luau execution timeout');
    await sleep(1500);
    task=await jsonReq(CLOUD+task.path);
  }
  if(task.state!=='COMPLETE'||task.error)throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string')return v??null;
  try{return JSON.parse(v)}catch{return v}
}

async function downloadLogo(){
  const res=await fetch(LOGO_URL,{signal:AbortSignal.timeout(60000)});
  if(!res.ok)throw new Error('Logo download failed '+res.status);
  const bytes=new Uint8Array(await res.arrayBuffer());
  if(bytes.length<1000)throw new Error('Downloaded logo is unexpectedly small');
  console.log(JSON.stringify({logoDownloaded:true,bytes:bytes.length,contentType:res.headers.get('content-type')}));
  return bytes;
}

async function uploadImage(bytes){
  const key=process.env.ROBLOX_API_KEY;
  const request={
    assetType:'Image',
    displayName:'Overyard Loading Logo',
    description:'Overyard game loading screen logo',
    creationContext:{creator:{userId:CREATOR_ID}},
  };

  async function post(){
    const form=new FormData();
    form.append('request',JSON.stringify(request));
    form.append('fileContent',new Blob([bytes],{type:'image/jpeg'}),'overyard-loading-logo.jpg');
    return fetch(API+'assets/v1/assets',{
      method:'POST',
      headers:{'x-api-key':key},
      body:form,
      signal:AbortSignal.timeout(120000),
    });
  }

  let res=await post();
  if(res.status===429){
    const waitMs=Number(res.headers.get('retry-after')||15)*1000;
    await sleep(waitMs);
    res=await post();
  }
  const text=await res.text();
  let op;try{op=JSON.parse(text)}catch{op={raw:text}}
  if(!res.ok)throw new Error('Image upload failed '+res.status+': '+JSON.stringify(op));
  if(!op.path)throw new Error('Image upload returned no operation path: '+JSON.stringify(op));

  const operationId=op.path.replace(/^operations\//,'');
  const deadline=Date.now()+360000;
  while(Date.now()<deadline){
    const status=await jsonReq(API+'assets/v1/operations/'+operationId);
    if(status.done){
      if(status.error)throw new Error('Image asset operation failed: '+JSON.stringify(status.error));
      const assetId=Number(status.response?.assetId);
      if(!assetId)throw new Error('Image operation finished without assetId: '+JSON.stringify(status));
      console.log(JSON.stringify({logoAssetUploaded:true,assetId,moderation:status.response?.moderationResult}));
      return assetId;
    }
    await sleep(2500);
  }
  throw new Error('Timed out waiting for image asset');
}

const bytes=await downloadLogo();
const assetId=await uploadImage(bytes);

const patchSource=fs.readFileSync('treeworld-loading-logo-v8/patch.luau','utf8')
  .replaceAll('__LOGO_ASSET_ID__',String(assetId));
const verifySource=fs.readFileSync('treeworld-loading-logo-v8/verify.luau','utf8');

const patch=first(await execute(patchSource));

let verify=null,last=null;
for(let i=0;i<10;i++){
  if(i)await sleep(3500);
  try{
    verify=first(await execute(verifySource));
    last=null;
    break;
  }catch(e){last=e}
}
if(last)throw last;
if(!verify?.ok)throw new Error('Verification did not return ok=true');
if(typeof patch?.sourceVersion==='number' && verify.placeVersion<=patch.sourceVersion){
  throw new Error('Place version did not advance');
}

console.log(JSON.stringify({ok:true,assetId,patch,verify}));
