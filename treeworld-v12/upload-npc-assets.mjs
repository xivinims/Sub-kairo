import fs from 'node:fs';

const API='https://apis.roblox.com/';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function jsonRequest(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let attempt=0;attempt<9;attempt++){
    const res=await fetch(url,{
      ...options,
      headers:{...(options.headers||{}),'x-api-key':key},
      signal:AbortSignal.timeout(60000),
    });
    const text=await res.text();
    let data;
    try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      const h=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(h)&&h>0?h*1000:Math.min(45000,5000*(attempt+1));
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
  let task=await jsonRequest(CLOUD+TARGET+'luau-execution-session-tasks',{
    method:'POST',
    headers:{'content-type':'application/json'},
    body:JSON.stringify({timeout:'180s',script}),
  });
  const deadline=Date.now()+300000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline || !task.path?.startsWith(TARGET)) throw new Error('Luau task timeout/wrong target');
    await sleep(1600);
    task=await jsonRequest(CLOUD+task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

async function getCreator(){
  const src='return {creatorId=game.CreatorId, creatorType=tostring(game.CreatorType), placeVersion=game.PlaceVersion, gameId=game.GameId, placeId=game.PlaceId}';
  const info=first(await execute(src));
  if(!info?.creatorId) throw new Error('Could not resolve creator');
  return info;
}

async function createAsset(filePath,mime,displayName,creator,assetType){
  const key=process.env.ROBLOX_API_KEY;
  const bytes=fs.readFileSync(filePath);
  if(bytes.length>20*1024*1024) throw new Error(displayName+' exceeds 20MB asset upload limit: '+bytes.length);

  const request={
    assetType,
    displayName,
    description:'User provided exact adventurer texture or original NPC narration for Overyard',
    creationContext:{
      creator: creator.creatorType?.includes('Group')
        ? {groupId:String(creator.creatorId)}
        : {userId:String(creator.creatorId)}
    }
  };

  async function postForm(){
    const form=new FormData();
    form.append('request',JSON.stringify(request));
    form.append('fileContent',new Blob([bytes],{type:mime}),filePath.split('/').pop());
    return fetch(API+'assets/v1/assets',{
      method:'POST',
      headers:{'x-api-key':key},
      body:form,
      signal:AbortSignal.timeout(120000),
    });
  }

  let res=await postForm();
  if(res.status===429){
    const wait=Number(res.headers.get('retry-after')||15)*1000;
    await sleep(wait);
    res=await postForm();
  }

  const text=await res.text();
  let op;
  try{op=JSON.parse(text)}catch{op={raw:text}}
  if(!res.ok) throw new Error('Asset upload '+displayName+' failed '+res.status+': '+JSON.stringify(op));
  if(!op.path) throw new Error('Asset upload did not return operation path: '+JSON.stringify(op));

  const operationId=op.path.replace(/^operations\//,'');
  const deadline=Date.now()+360000;
  while(Date.now()<deadline){
    const status=await jsonRequest(API+'assets/v1/operations/'+operationId);
    if(status.done){
      if(status.error) throw new Error('Asset operation error: '+JSON.stringify(status.error));
      const assetId=Number(status.response?.assetId);
      if(!assetId) throw new Error('Asset operation finished without assetId: '+JSON.stringify(status));
      console.log(JSON.stringify({assetUploaded:displayName,assetId,moderation:status.response?.moderationResult}));
      return assetId;
    }
    await sleep(3000);
  }
  throw new Error('Timed out waiting for asset operation '+displayName);
}



const creator=await getCreator();
fs.mkdirSync('treeworld-v12/assets/clothes',{recursive:true});
const jobs=[
 ['Shirt','Image','image/png','https://sb-73bkts3rmufh.vercel.run/e34d2e7a-02a4-4b3b-9ce4-2b8353aa6577-top.png'],
 ['Pants','Image','image/png','https://sb-73bkts3rmufh.vercel.run/e34d2e7a-02a4-4b3b-9ce4-2b8353aa6577-bottom.png'],
 ['report','Audio','audio/mpeg',"https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/7c1bd31f-7778-4ff5-b49c-cc0da8329553.mp3"]
];
const result={};
for(const [name,type,mime,url]of jobs){
 const r=await fetch(url);if(!r.ok)throw Error('Asset download failed '+r.status);
 const bytes=Buffer.from(await r.arrayBuffer()),file='treeworld-v12/assets/clothes/'+name+(type==='Image'?'.png':'.mp3');
 fs.writeFileSync(file,bytes);
 result[name]=await createAsset(file,mime,'Caio Overyard '+name,creator,type);
}
console.log(JSON.stringify({stage:'npc-assets',assets:result}));
