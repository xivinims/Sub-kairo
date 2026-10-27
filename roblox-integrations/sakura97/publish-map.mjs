import fs from 'node:fs';
import { inflateSync, deflateSync, gunzipSync } from 'node:zlib';
import { createHash } from 'node:crypto';

function crc32(buf){
  let crc=0xffffffff;
  for(const byte of buf){
    crc^=byte;
    for(let k=0;k<8;k++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);
  }
  return (crc^0xffffffff)>>>0;
}
function pngChunk(type,data=Buffer.alloc(0)){
  const t=Buffer.from(type,'ascii');
  const len=Buffer.alloc(4); len.writeUInt32BE(data.length);
  const sum=Buffer.alloc(4); sum.writeUInt32BE(crc32(Buffer.concat([t,data])));
  return Buffer.concat([len,t,data,sum]);
}
function paeth(a,b,c){
  const p=a+b-c, pa=Math.abs(p-a), pb=Math.abs(p-b), pc=Math.abs(p-c);
  return pa<=pb&&pa<=pc?a:pb<=pc?b:c;
}
function normalizeLogoPng(input){
  const sig=Buffer.from([137,80,78,71,13,10,26,10]);
  if(input.length<33 || !input.subarray(0,8).equals(sig)) throw new Error('Logo is not PNG');
  let off=8, ihdr=null, palette=null, alpha=null;
  const idats=[];
  while(off+12<=input.length){
    const n=input.readUInt32BE(off); const type=input.subarray(off+4,off+8).toString('ascii');
    const data=input.subarray(off+8,off+8+n); off+=12+n;
    if(type==='IHDR') ihdr=Buffer.from(data);
    else if(type==='PLTE') palette=Buffer.from(data);
    else if(type==='tRNS') alpha=Buffer.from(data);
    else if(type==='IDAT') idats.push(Buffer.from(data));
    else if(type==='IEND') break;
  }
  if(!ihdr) throw new Error('Logo PNG has no IHDR');
  const w=ihdr.readUInt32BE(0), h=ihdr.readUInt32BE(4), depth=ihdr[8], color=ihdr[9], interlace=ihdr[12];
  if(depth===8 && color===6) return input;
  if(depth!==8 || color!==3 || interlace!==0 || !palette || !idats.length){
    throw new Error(`Unsupported logo PNG format depth=${depth} color=${color} interlace=${interlace}`);
  }
  const packed=inflateSync(Buffer.concat(idats));
  const stride=w, rows=Buffer.alloc(stride*h);
  let src=0;
  for(let y=0;y<h;y++){
    const filter=packed[src++], row=rows.subarray(y*stride,(y+1)*stride), prev=y?rows.subarray((y-1)*stride,y*stride):null;
    for(let x=0;x<stride;x++){
      const raw=packed[src++], left=x?row[x-1]:0, up=prev?prev[x]:0, ul=prev&&x?prev[x-1]:0;
      let val;
      if(filter===0) val=raw;
      else if(filter===1) val=(raw+left)&255;
      else if(filter===2) val=(raw+up)&255;
      else if(filter===3) val=(raw+Math.floor((left+up)/2))&255;
      else if(filter===4) val=(raw+paeth(left,up,ul))&255;
      else throw new Error('Unsupported PNG filter '+filter);
      row[x]=val;
    }
  }
  const rgba=Buffer.alloc((w*4+1)*h);
  for(let y=0;y<h;y++){
    let out=y*(w*4+1); rgba[out++]=0;
    for(let x=0;x<w;x++){
      const idx=rows[y*w+x], pi=idx*3;
      rgba[out++]=palette[pi]??0; rgba[out++]=palette[pi+1]??0; rgba[out++]=palette[pi+2]??0;
      rgba[out++]=alpha&&idx<alpha.length?alpha[idx]:255;
    }
  }
  const next=Buffer.alloc(13); ihdr.copy(next); next[8]=8; next[9]=6; next[10]=0; next[11]=0; next[12]=0;
  return Buffer.concat([sig,pngChunk('IHDR',next),pngChunk('IDAT',deflateSync(rgba,{level:9})),pngChunk('IEND')]);
}

const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
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
    const raw=await res.text();
    let data; try{data=JSON.parse(raw)}catch{data={raw}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      const retry=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(60000,5000*(i+1));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function patchCloud(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:'PATCH',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:JSON.stringify(body),
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('PATCH '+path+' HTTP '+res.status+': '+JSON.stringify(data));
  return data;
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'300s',script});
  const deadline=Date.now()+480000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau timeout');
    await sleep(1500);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}


const FILL_VOICE_REVISION='2026-10-25-v3-exact-mp3';
const FILL_VOICE_SPECS=[
 {index:1,files:['voice1.part00.b64','voice1.part01.b64'],bytes:179104,sha256:'f266844a662d530fadb4e1c46ba495621dbb3edee58330cbafedee5250021821'},
 {index:2,files:['voice2.part00.b64','voice2.part01.b64','voice2.part02.b64'],bytes:304491,sha256:'fbb4e78da0a6c79a629407807d6e092f9043f92ce1eb59dd2a17f2c55f17e4e7'},
 {index:3,files:['voice3.part00.b64','voice3.part01.b64','voice3.part02.b64'],bytes:270219,sha256:'7d19bf9c429959aac67680f9045e912ede6903d38bdfcffd7d5dc8f8c8227605'},
 {index:4,files:['voice4.part00.b64','voice4.part01.b64','voice4.part02.b64'],bytes:222571,sha256:'8093407c37c4869f89ae57d0171b788ffdec78501105f71f9d8a9189ff0fb1c3'},
 {index:5,files:['voice5.part00.b64','voice5.part01.b64','voice5.part02.b64'],bytes:225497,sha256:'77251274508e7943bfd6be336d9e0d872c21f7e9e7a5b55017f81f86653380ac'},
 {index:6,files:['voice6.part00.b64'],bytes:99691,sha256:'aef4863727523fd6022d2fbb739ff48478933d06b0636634384ace6c0c1d5cda'},
];
function readFillVoice(spec){
 const dir='roblox-integrations/sakura97/fill-voices-v3';
 const pieces=spec.files.map(name=>fs.readFileSync(`${dir}/${name}`,'utf8').replace(/[^A-Za-z0-9+/=]/g,''));
 const bytes=Buffer.from(pieces.join(''),'base64');
 const sha=createHash('sha256').update(bytes).digest('hex');
 if(bytes.length!==spec.bytes) throw new Error(`Fill voice ${spec.index} size mismatch: ${bytes.length} != ${spec.bytes}`);
 if(sha!==spec.sha256) throw new Error(`Fill voice ${spec.index} SHA-256 mismatch: ${sha}`);
 return bytes;
}
async function createActionAtlas(bytes){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const request={
  assetType:'Decal',
  displayName:'Suvivers reference action controls',
  description:'Action controls artwork supplied by the game owner.',
  creationContext:{creator:{userId:'8344738123'}}
 };
 const form=new FormData();
 form.append('request',JSON.stringify(request));
 form.append('fileContent',new Blob([bytes],{type:'image/jpeg'}),'action-controls.jpg');
 const response=await fetch('https://apis.roblox.com/assets/v1/assets',{
  method:'POST',
  headers:{'x-api-key':key},
  body:form,
  signal:AbortSignal.timeout(60000)
 });
 const raw=await response.text();
 let operation; try{operation=JSON.parse(raw)}catch{operation={raw}}
 if(!response.ok) throw new Error(`Fill audio atlas upload HTTP ${response.status}: ${JSON.stringify(operation)}`);
 if(!operation.path) throw new Error(`Fill audio atlas upload returned no operation path: ${JSON.stringify(operation)}`);
 const deadline=Date.now()+240000;
 while(!operation.done){
  if(Date.now()>deadline) throw new Error(`Fill audio atlas moderation/upload operation timed out`);
  await sleep(1500);
  const opResponse=await fetch('https://apis.roblox.com/assets/v1/'+operation.path,{
   headers:{'x-api-key':key},
   signal:AbortSignal.timeout(60000)
  });
  const opRaw=await opResponse.text();
  try{operation=JSON.parse(opRaw)}catch{operation={raw:opRaw}}
  if(!opResponse.ok) throw new Error(`Fill audio atlas operation HTTP ${opResponse.status}: ${JSON.stringify(operation)}`);
 }
 if(operation.error) throw new Error(`Fill audio atlas operation failed: ${JSON.stringify(operation.error)}`);
 const id=Number(operation?.response?.assetId);
 if(!Number.isFinite(id)||id<=0) throw new Error(`Fill audio atlas operation returned no assetId: ${JSON.stringify(operation)}`);
 return id;
}

async function createSettingsBookAsset(bytes){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const request={
  assetType:'Decal',
  displayName:'Suvivers settings book',
  description:'Exact settings book artwork supplied by the game owner.',
  creationContext:{creator:{userId:'8344738123'}}
 };
 const form=new FormData();
 form.append('request',JSON.stringify(request));
 form.append('fileContent',new Blob([bytes],{type:'image/jpeg'}),'settings-book.jpg');
 const response=await fetch('https://apis.roblox.com/assets/v1/assets',{
  method:'POST',
  headers:{'x-api-key':key},
  body:form,
  signal:AbortSignal.timeout(60000)
 });
 const raw=await response.text();
 let operation; try{operation=JSON.parse(raw)}catch{operation={raw}}
 if(!response.ok) throw new Error(`Settings book upload HTTP ${response.status}: ${JSON.stringify(operation)}`);
 if(!operation.path) throw new Error(`Settings book upload returned no operation path: ${JSON.stringify(operation)}`);
 const deadline=Date.now()+240000;
 while(!operation.done){
  if(Date.now()>deadline) throw new Error(`Settings book moderation/upload operation timed out`);
  await sleep(1500);
  const opResponse=await fetch('https://apis.roblox.com/assets/v1/'+operation.path,{
   headers:{'x-api-key':key},
   signal:AbortSignal.timeout(60000)
  });
  const opRaw=await opResponse.text();
  try{operation=JSON.parse(opRaw)}catch{operation={raw:opRaw}}
  if(!opResponse.ok) throw new Error(`Settings book operation HTTP ${opResponse.status}: ${JSON.stringify(operation)}`);
 }
 if(operation.error) throw new Error(`Settings book operation failed: ${JSON.stringify(operation.error)}`);
 const id=Number(operation?.response?.assetId);
 if(!Number.isFinite(id)||id<=0) throw new Error(`Settings book operation returned no assetId: ${JSON.stringify(operation)}`);
 return id;
}
async function createFillAudioAsset(spec,bytes){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const request={
  assetType:'Audio',
  displayName:`Suvivers Fill English Voice ${spec.index}`,
  description:'Original English dialogue recording supplied for the Fill lobby guide in Suvivers.',
  creationContext:{creator:{userId:'8344738123'}}
 };
 const form=new FormData();
 form.append('request',JSON.stringify(request));
 form.append('fileContent',new Blob([bytes],{type:'audio/mpeg'}),`fill-voice-${spec.index}.mp3`);
 const response=await fetch('https://apis.roblox.com/assets/v1/assets',{
  method:'POST',
  headers:{'x-api-key':key},
  body:form,
  signal:AbortSignal.timeout(60000)
 });
 const raw=await response.text();
 let operation; try{operation=JSON.parse(raw)}catch{operation={raw}}
 if(!response.ok) throw new Error(`Fill audio ${spec.index} upload HTTP ${response.status}: ${JSON.stringify(operation)}`);
 if(!operation.path) throw new Error(`Fill audio ${spec.index} upload returned no operation path: ${JSON.stringify(operation)}`);
 const deadline=Date.now()+240000;
 while(!operation.done){
  if(Date.now()>deadline) throw new Error(`Fill audio ${spec.index} moderation/upload operation timed out`);
  await sleep(1500);
  const opResponse=await fetch('https://apis.roblox.com/assets/v1/'+operation.path,{
   headers:{'x-api-key':key},
   signal:AbortSignal.timeout(60000)
  });
  const opRaw=await opResponse.text();
  try{operation=JSON.parse(opRaw)}catch{operation={raw:opRaw}}
  if(!opResponse.ok) throw new Error(`Fill audio ${spec.index} operation HTTP ${opResponse.status}: ${JSON.stringify(operation)}`);
 }
 if(operation.error) throw new Error(`Fill audio ${spec.index} operation failed: ${JSON.stringify(operation.error)}`);
 const id=Number(operation?.response?.assetId);
 if(!Number.isFinite(id)||id<=0) throw new Error(`Fill audio ${spec.index} operation returned no assetId: ${JSON.stringify(operation)}`);
 return id;
}
async function readPersistedFillVoiceState(){
 const result=first(await execute(`
  local net=game:GetService("ReplicatedStorage"):FindFirstChild("Survival")
  local ids={}
  for i=1,6 do ids[i]=net and (net:GetAttribute("FillVoice"..i) or 0) or 0 end
  return {ids=ids,revision=net and (net:GetAttribute("FillVoiceRevision") or "") or ""}
 `));
 return {ids:Array.isArray(result?.ids)?result.ids.map(Number):[],revision:String(result?.revision||"")};
}
async function grantFillVoiceUniversePermission(ids){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const response=await fetch('https://apis.roblox.com/asset-permissions-api/v1/assets/permissions',{
  method:'PATCH',
  headers:{'x-api-key':key,'content-type':'application/json'},
  body:JSON.stringify({
   subjectType:'Universe',
   subjectId:'9419478735',
   action:'Use',
   requests:ids.map(assetId=>({assetId:Number(assetId),grantToDependencies:false}))
  }),
  signal:AbortSignal.timeout(60000)
 });
 const raw=await response.text();
 let payload; try{payload=JSON.parse(raw)}catch{payload={raw}}
 if(!response.ok) throw new Error(`Fill audio permission grant HTTP ${response.status}: ${JSON.stringify(payload)}`);
 const success=new Set((payload.successAssetIds||[]).map(Number));
 const failed=(payload.errors||[]).filter(Boolean);
 if(failed.length) throw new Error('Fill audio permission grant errors: '+JSON.stringify(failed));
 for(const id of ids) if(!success.has(Number(id))) throw new Error('Fill audio permission grant missing asset '+id);
 console.log('FILL_VOICE_PERMISSION_GRANTED',JSON.stringify({universeId:9419478735,assetIds:ids}));
 return payload;
}
const FIXED_LOBBY_REVISION='violence-district-lobby-v1';
const FIXED_LOBBY_GZIP_SHA256='c2fa2bcccc7830b19a319db73b87736439284c1968f70101b1d831dc357e0687';
const FIXED_LOBBY_RBXMX_SHA256='ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2';
const FIXED_LOBBY_RBXMX_BYTES=5944482;

function readFixedLobbyRbxmx(){
 const encoded=fs.readFileSync('roblox-integrations/sakura97/lobby-fixed/Violence_District_Lobby.rbxmx.gz.b64','utf8').replace(/[^A-Za-z0-9+/=]/g,'');
 const gz=Buffer.from(encoded,'base64');
 const gzSha=createHash('sha256').update(gz).digest('hex');
 if(gzSha!==FIXED_LOBBY_GZIP_SHA256) throw new Error('Fixed lobby gzip SHA-256 mismatch: '+gzSha);
 const bytes=gunzipSync(gz);
 const sha=createHash('sha256').update(bytes).digest('hex');
 if(bytes.length!==FIXED_LOBBY_RBXMX_BYTES) throw new Error('Fixed lobby size mismatch: '+bytes.length+' != '+FIXED_LOBBY_RBXMX_BYTES);
 if(sha!==FIXED_LOBBY_RBXMX_SHA256) throw new Error('Fixed lobby RBXMX SHA-256 mismatch: '+sha);
 return bytes;
}

async function createFixedLobbyAsset(bytes){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const request={
  assetType:'Model',
  displayName:'Suvivers Fixed Violence District Lobby',
  description:'Fixed lobby snapshot imported from the supplied Violence_District.rbxlx. Embedded scripts removed.',
  creationContext:{creator:{userId:'8344738123'}}
 };
 const form=new FormData();
 form.append('request',JSON.stringify(request));
 form.append('fileContent',new Blob([bytes],{type:'model/x-rbxm'}),'Violence_District_Lobby.rbxmx');
 const response=await fetch('https://apis.roblox.com/assets/v1/assets',{
  method:'POST',
  headers:{'x-api-key':key},
  body:form,
  signal:AbortSignal.timeout(60000)
 });
 const raw=await response.text();
 let operation; try{operation=JSON.parse(raw)}catch{operation={raw}}
 if(!response.ok) throw new Error('Fixed lobby upload HTTP '+response.status+': '+JSON.stringify(operation));
 if(!operation.path) throw new Error('Fixed lobby upload returned no operation path: '+JSON.stringify(operation));
 const deadline=Date.now()+300000;
 while(!operation.done){
  if(Date.now()>deadline) throw new Error('Fixed lobby upload operation timed out');
  await sleep(1800);
  const opResponse=await fetch('https://apis.roblox.com/assets/v1/'+operation.path,{
   headers:{'x-api-key':key},
   signal:AbortSignal.timeout(60000)
  });
  const opRaw=await opResponse.text();
  try{operation=JSON.parse(opRaw)}catch{operation={raw:opRaw}}
  if(!opResponse.ok) throw new Error('Fixed lobby operation HTTP '+opResponse.status+': '+JSON.stringify(operation));
 }
 if(operation.error) throw new Error('Fixed lobby operation failed: '+JSON.stringify(operation.error));
 const id=Number(operation?.response?.assetId);
 if(!Number.isFinite(id)||id<=0) throw new Error('Fixed lobby operation returned no assetId: '+JSON.stringify(operation));
 return id;
}

async function readPersistedFixedLobbyState(){
 const luau=[
  'local net=game:GetService("ReplicatedStorage"):FindFirstChild("Survival")',
  'return {',
  ' id=net and (net:GetAttribute("FixedLobbyAssetId") or 0) or 0,',
  ' revision=net and (net:GetAttribute("FixedLobbyRevision") or "") or ""',
  '}'
 ].join('\n');
 const result=first(await execute(luau));
 return {id:Number(result?.id)||0,revision:String(result?.revision||'')};
}

async function grantFixedLobbyUniversePermission(id){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const response=await fetch('https://apis.roblox.com/asset-permissions-api/v1/assets/permissions',{
  method:'PATCH',
  headers:{'x-api-key':key,'content-type':'application/json'},
  body:JSON.stringify({
   subjectType:'Universe',
   subjectId:UNIVERSE_ID,
   action:'Use',
   requests:[{assetId:Number(id),grantToDependencies:true}]
  }),
  signal:AbortSignal.timeout(60000)
 });
 const raw=await response.text();
 let payload; try{payload=JSON.parse(raw)}catch{payload={raw}}
 if(!response.ok) throw new Error('Fixed lobby permission grant HTTP '+response.status+': '+JSON.stringify(payload));
 const success=new Set((payload.successAssetIds||[]).map(Number));
 const failed=(payload.errors||[]).filter(Boolean);
 if(failed.length) throw new Error('Fixed lobby permission grant errors: '+JSON.stringify(failed));
 if(!success.has(Number(id))) throw new Error('Fixed lobby permission grant missing asset '+id);
 console.log('FIXED_LOBBY_PERMISSION_GRANTED',JSON.stringify({universeId:Number(UNIVERSE_ID),assetId:id}));
}

async function ensureFixedLobbyAsset(){
 const state=await readPersistedFixedLobbyState();
 let id=state.revision===FIXED_LOBBY_REVISION?state.id:0;
 let created=false;
 if(!(id>0)){
  const bytes=readFixedLobbyRbxmx();
  id=await createFixedLobbyAsset(bytes);
  created=true;
  console.log('FIXED_LOBBY_UPLOADED',JSON.stringify({assetId:id,bytes:bytes.length,sha256:FIXED_LOBBY_RBXMX_SHA256}));
 }
 await grantFixedLobbyUniversePermission(id);
 if(created){
  const luau=[
   'local net=assert(game:GetService("ReplicatedStorage"):FindFirstChild("Survival"),"Survival runtime missing")',
   'net:SetAttribute("FixedLobbyAssetId",'+id+')',
   'net:SetAttribute("FixedLobbyRevision","violence-district-lobby-v1")',
   'net:SetAttribute("FixedLobbySHA256","ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2")',
   'local ok,err=pcall(function() game:GetService("AssetService"):SavePlaceAsync({PlaceId='+PLACE_ID+',SaveWithoutPublish=false}) end)',
   'assert(ok,"Could not persist fixed lobby asset ID: "..tostring(err))',
   'return {ok=true,id='+id+',version=game.PlaceVersion}'
  ].join('\n');
  const persisted=first(await execute(luau));
  console.log('FIXED_LOBBY_ID_PERSISTED',JSON.stringify(persisted));
 }
 return id;
}

async function ensureFillVoiceAssets(){
 const state=await readPersistedFillVoiceState();
 const existing=state.revision===FILL_VOICE_REVISION?state.ids:[];
 const ids=[];
 let created=false;
 for(const spec of FILL_VOICE_SPECS){
  const prior=Number(existing[spec.index-1])||0;
  if(prior>0){ids[spec.index-1]=prior; continue;}
  const bytes=readFillVoice(spec);
  const id=await createFillAudioAsset(spec,bytes);
  ids[spec.index-1]=id;
  created=true;
  console.log('FILL_VOICE_UPLOADED',JSON.stringify({index:spec.index,assetId:id,bytes:bytes.length,sha256:spec.sha256}));
 }
 if(ids.some(id=>!Number.isFinite(id)||id<=0)) throw new Error('Not all six Fill voice assets are available');
 await grantFillVoiceUniversePermission(ids);
 if(created){
  const persisted=first(await execute(`
   local net=assert(game:GetService("ReplicatedStorage"):FindFirstChild("Survival"),"Survival runtime missing")
   local ids={${ids.join(',')}}
   for i,id in ipairs(ids) do net:SetAttribute("FillVoice"..i,id) end
   net:SetAttribute("FillVoiceRevision","2026-10-25-v3-exact-mp3")
   local ok,err=pcall(function() game:GetService("AssetService"):SavePlaceAsync({PlaceId=79738710219521,SaveWithoutPublish=false}) end)
   assert(ok,"Could not persist Fill audio asset IDs: "..tostring(err))
   return {ok=true,ids=ids,version=game.PlaceVersion}
  `));
  console.log('FILL_VOICE_IDS_PERSISTED',JSON.stringify(persisted));
 }
 return ids;
}


const read=n=>fs.readFileSync('roblox-integrations/sakura97/'+n+'.luau','utf8');
const sources={CONFIG:'survival-config',RULES:'round-rules',AI:'pursuer-ai',KILLER_FACTORY:'killer-factory',SURVIVAL_SERVER:'survival-server',SURVIVAL_CLIENT:'survival-client',ANIMATION:'pursuer-animation',PROFILE:'profile-service',MAP_BUILDER:'map-builder',ISLAND_SERVER:'island-server',VOID:'void-client',AMBIENCE:'ambience-client',SETTINGS:'settings-panel',NAMETAG:'nametag-server',FRIENDS:'friends-client'};
let install=read('jason-install');
for(const [key,name] of Object.entries(sources)) install=install.replace(`__${key}_SOURCE__`,JSON.stringify(read(name)));
const menu=read('install-menu').replaceAll('__SURVIVERS_LOGO_ID__','136450401317962').replace('__MENU_SOURCE__',JSON.stringify(read('menu-client'))).replace('__LOADING_SOURCE__',JSON.stringify(read('loading-client')));
const syntax=Object.values(sources).concat(['menu-client','loading-client','lobby-guide-client','lobby-guide-install','shop-stage-install','player-profile','profile-client']).map((name,i)=>`local function s${i}()\n${read(name)}\nend`).join('\n')+'\nreturn {ok=true}';
console.log('SYNTAX',JSON.stringify(first(await execute(syntax))));
const atlasManifest=JSON.parse(fs.readFileSync('roblox-integrations/sakura97/action-atlas.json','utf8'));
const actionAtlasId=atlasManifest.assetId || await createActionAtlas(Buffer.from(fs.readFileSync('roblox-integrations/sakura97/action-atlas.b64','utf8'),'base64'));
console.log('ACTION_ATLAS_ASSET_ID',actionAtlasId);
let settingsBookAssetId=0;
let bookUploaded=false;
try {
 const state=first(await execute(`
  local net=game:GetService("ReplicatedStorage"):FindFirstChild("Survival")
  return {id=net and (net:GetAttribute("SettingsBookAssetId") or 0) or 0}
 `));
 settingsBookAssetId=Number(state?.id)||0;
} catch {}
if(!settingsBookAssetId && fs.existsSync('roblox-integrations/sakura97/settings-book-reference.b64')){
 settingsBookAssetId=await createSettingsBookAsset(Buffer.from(fs.readFileSync('roblox-integrations/sakura97/settings-book-reference.b64','utf8'),'base64'));
 bookUploaded=true;
}
if(!settingsBookAssetId) throw new Error('Settings book artwork was not uploaded');
if(bookUploaded){
const bookReady=first(await execute(`
 local net=game.ReplicatedStorage:FindFirstChild("Survival")
 local asset=game:GetService("AssetService"):LoadAssetAsync(${settingsBookAssetId})
 local decal=asset:FindFirstChildWhichIsA("Decal",true)
 local image=decal and tonumber(decal.Texture:match("%d+")) or ${settingsBookAssetId}
 asset:Destroy()
 if net then net:SetAttribute("SettingsBookAssetId",image) end
 game:GetService("AssetService"):SavePlaceAsync({PlaceId=79738710219521,SaveWithoutPublish=false})
 return {id=image}
`));
settingsBookAssetId=Number(bookReady.id);
}
console.log('SETTINGS_BOOK_ASSET_ID',settingsBookAssetId);
const fillVoiceIds=await ensureFillVoiceAssets();
console.log('FILL_VOICE_IDS',JSON.stringify(fillVoiceIds));
const fixedLobbyAssetId=await ensureFixedLobbyAsset();
console.log('FIXED_LOBBY_ASSET_ID',fixedLobbyAssetId);
install=install.replace('__FIXED_LOBBY_ASSET_ID__',String(fixedLobbyAssetId));
const test=read('survival-runtime-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end').replace('local RESULT_PRESENTATION_SECONDS=9','local RESULT_PRESENTATION_SECONDS=.05'));
const clientTest=read('survival-client-tests').replace('__SURVIVAL_CLIENT_TEST_SOURCE__',read('survival-client'));
const roleTest=read('jason-role-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end').replace('local RESULT_PRESENTATION_SECONDS=9','local RESULT_PRESENTATION_SECONDS=.05'));
const menuTest=read('menu-runtime-tests').replace('__MENU_TEST_SOURCE__',read('menu-client').replace('local v=camera.ViewportSize','local v=TEST_VIEWPORT'));
const animationTest=read('animation-runtime-tests').replace('__ANIMATION_TEST_SOURCE__',read('pursuer-animation'));
const guideTest=read('lobby-guide-tests').replace('__GUIDE_CLIENT_TEST_SOURCE__',read('lobby-guide-client').replace('local prompt=npc:WaitForChild("ProximityPrompt")','local prompt=TEST_PROMPT'));
const profileTest=read('profile-ui-tests').replace('__PROFILE_CLIENT_TEST_SOURCE__',read('profile-client'));
const aiTest=read('jason-ai-tests').replace('__AI_TEST_SOURCE__',read('pursuer-ai').replace('local Run=game:GetService("RunService")','local Run=TEST_RUN'));
const script=`
local sourceVersion=game.PlaceVersion
local function install()
${install}
end
local result=install()
game.ReplicatedStorage.Survival:SetAttribute("SettingsBookAssetId",${settingsBookAssetId})
result.settingsBookAssetId=${settingsBookAssetId}
result.actionSources={}
for _,name in ipairs({"Parry","BreakPallet","CrouchWalk","InjuredCrouchWalk","Stun","Vault"}) do
 local folder=game.ReplicatedStorage.Survival.SurvivorActionClips
 result.actionSources[name]={requested=folder:GetAttribute(name.."RequestedAssetId"),actual=folder:GetAttribute(name.."AssetId"),fallback=folder:GetAttribute(name.."Fallback")==true,unavailable=folder:GetAttribute(name.."Unavailable")==true}
end
do
 local asset=game:GetService("InsertService"):LoadAsset(${actionAtlasId})
 local decal=assert(asset:FindFirstChildWhichIsA("Decal",true),"Action atlas decal missing")
 assert(decal.Texture~="","Action atlas texture missing")
 game.ReplicatedStorage.Survival:SetAttribute("ActionAtlasTexture",decal.Texture)
 game.ReplicatedStorage.Survival:SetAttribute("ActionAtlasAssetId",${actionAtlasId})
 asset:Destroy()
end
do
 local ids={${fillVoiceIds.join(',')}}
 local net=assert(game.ReplicatedStorage:FindFirstChild("Survival"),"Survival runtime missing after install")
 for i,id in ipairs(ids) do net:SetAttribute("FillVoice"..i,id) end
end
do
 local net=game.ReplicatedStorage.Survival
 local old=net:FindFirstChild("PlayerProfile") if old then old:Destroy() end
 local module=Instance.new("ModuleScript") module.Name="PlayerProfile" module.Source=${JSON.stringify(read('player-profile'))} module.Parent=net
 local scripts=game.StarterPlayer.StarterPlayerScripts
 local previous=scripts:FindFirstChild("PlayerProfileController") if previous then previous:Destroy() end
 local client=Instance.new("LocalScript") client.Name="PlayerProfileController" client.Source=${JSON.stringify(read('profile-client'))} client.Parent=scripts
end
do
${menu}
end
result.lobbyGuide=(function()
${read('lobby-guide-install').replace('__GUIDE_CLIENT_SOURCE__',JSON.stringify(read('lobby-guide-client')))}
end)()
result.shopStage=(function()
${read('shop-stage-install')}
end)()
result.playerProfile=(function()
${profileTest}
end)()
result.guideClient=(function()
${guideTest}
end)()
assert(workspace.JediLibrary:GetAttribute("SourceAssetId")==${fixedLobbyAssetId},"Wrong fixed lobby asset")
assert(workspace.JediLibrary:GetAttribute("FixedLobbyRevision")=="violence-district-lobby-v1","Fixed lobby revision missing")
assert(workspace.JediLibrary:GetAttribute("FixedLobbySHA256")=="ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2","Fixed lobby hash missing")
assert(game.ReplicatedStorage.SweanRuntime:GetAttribute("SurvivorRig")=="R6","R6 survivor runtime missing")
local assets=game.ServerStorage.SurvivalAssets
assert(#assets.Maps:GetChildren()==7 and assets.Maps.DoomspireBrickbattle and assets.Maps.JuggernautFightArena and assets.Maps.PirateBayIsland and assets.Maps.NaturalDisasterSurvival and assets.Maps.RocketArena and assets.Maps.PiggySewers and assets.Maps.PiggyMappleDonut)
assert(#assets.Killers:GetChildren()==5 and assets.Killers.Jason and assets.Killers.JohnDoe and assets.Killers.Chucky and assets.Killers.Krampus and assets.Killers.Piggy and not assets.Killers:FindFirstChild("Jeff") and not assets.Killers:FindFirstChild("Freddy"),"Expected exactly five pursuers")
assert(assets.Killers.Jason.MotionClips:FindFirstChild("Jason Slash"))
assert(game.ReplicatedStorage.Survival.SurvivorClips:GetAttribute("SourceAssetId")==127092032896760)
assert(not game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Removed crouch package returned")
assert((game.ReplicatedStorage.Survival.SurvivorClips:GetAttribute("ClipCount") or 0)>0)
local survivorActions=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorActionClips"),"Survivor action clips missing")
assert((survivorActions:GetAttribute("ClipCount") or 0)>=3,"Required survivor action clips missing")
assert(survivorActions:GetAttribute("RequestedClipCount")==6 and survivorActions:GetAttribute("RequiredClipCount")==3,"Survivor action request metadata missing")
assert(
 (survivorActions:GetAttribute("CrouchWalkAssetId")==126965695851149 or (survivorActions:GetAttribute("CrouchWalkFallback")==true and survivorActions:GetAttribute("CrouchWalkAssetId")==127092032896760))
 and
 (survivorActions:GetAttribute("InjuredCrouchWalkAssetId")==135084204086504 or (survivorActions:GetAttribute("InjuredCrouchWalkFallback")==true and survivorActions:GetAttribute("InjuredCrouchWalkAssetId")==127092032896760)),
 "Crouch action assets/fallbacks missing"
)
assert(
 survivorActions:GetAttribute("StunAssetId")==123047897844134
 or (survivorActions:GetAttribute("StunFallback")==true and survivorActions:GetAttribute("StunAssetId")==127092032896760),
 "Stun action asset/fallback missing"
)
local ui=game.StarterGui.TomiaszMenu
assert(ui.Enabled==false and ui:GetAttribute("MenuRemoved")==true and ui:GetAttribute("LegacyMenuWidgetsPurged")==true)
assert(not ui:FindFirstChild("MenuPrincipal") and not ui:FindFirstChild("Escenarios"),"Legacy menu widgets survived purge")
assert(game.ReplicatedStorage.SweanMenuConfig:GetAttribute("LogoAssetId")==136450401317962)
result.logoTexture="removed-menu-logo-asset-"..tostring(game.ReplicatedStorage.SweanMenuConfig:GetAttribute("LogoAssetId"))
local ser=game:GetService("SerializationService")
result.mapBytes=buffer.len(ser:SerializeInstancesAsync({assets.Maps}))
result.rigBytes=buffer.len(ser:SerializeInstancesAsync({assets.Killers}))
result.motionLibraryBytes=buffer.len(ser:SerializeInstancesAsync({game.ReplicatedStorage.Survival.KillerMotionLibraries}))
result.killerBytes={}
for _,killer in ipairs(assets.Killers:GetChildren()) do
 local ok,b=pcall(function() return ser:SerializeInstancesAsync({killer}) end)
 result.killerBytes[killer.Name]=ok and buffer.len(b) or -1
end
local function testController()
${roleTest}
end
result.profiles=(function()\n${read('profile-tests')}\nend)()
result.controller=testController()
local function testClient()
${clientTest}
end
result.client=testClient()
local function testRole()
${roleTest}
end
result.playerJason=testRole()
local function testAI()
${aiTest}
end
result.ai=testAI()
result.menu=(function()
${menuTest}
end)()
result.animations=(function()
${animationTest}
end)()
local function testContent()
${read('jason-content-tests')}
end
result.content=testContent()
result.lobbyAccess=(function()
${read('lobby-access-tests')}
end)()
result.sourceVersion=sourceVersion result.ok=true result.saved=false
result.loadingGeometry=(function()
${read('loading-geometry-tests').replace('__LOADING_COMPOSITION__',read('loading-client').slice(read('loading-client').indexOf('local tv=assert'),read('loading-client').indexOf('local handDriver=')).replace('viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeCamera)',''))}
end)()
if ${process.env.SURVIVERS_DRY_RUN==='1'?'false':'true'} then
 game.ReplicatedStorage.Survival:SetAttribute("Phase","Aguardando")
 game.ReplicatedStorage.Survival:SetAttribute("EndsAt",0)
 game.ReplicatedStorage.Survival:SetAttribute("Count",0)
 game.ReplicatedStorage.SweanRuntime:SetAttribute("LogoSHA256","286b7e57276a5d593b38c10c3a4cd41518d027c0e9346dfa6db3daf36521897e")
 local saveOk,saveError=pcall(function() game:GetService("AssetService"):SavePlaceAsync({PlaceId=79738710219521,SaveWithoutPublish=false}) end)
 result.saved=saveOk result.saveError=saveOk and nil or tostring(saveError)
 result.sizes={}
 result.serverStorageChildren={}
 for _,name in ipairs({"Workspace","ReplicatedStorage","ServerStorage","ServerScriptService","StarterPlayer","StarterGui","ReplicatedFirst"}) do
  local copy=Instance.new("Folder") for _,child in ipairs(game:GetService(name):GetChildren()) do local ok,c=pcall(function() return child:Clone() end) if ok and c then c.Parent=copy end end
  local ok,b=pcall(function() return ser:SerializeInstancesAsync({copy}) end) result.sizes[name]=ok and buffer.len(b) or -1 copy:Destroy()
 end
 for _,child in ipairs(game.ServerStorage:GetChildren()) do
  local ok,clone=pcall(function() return child:Clone() end)
  if ok and clone then
   local holder=Instance.new("Folder") clone.Parent=holder
   local ok2,b=pcall(function() return ser:SerializeInstancesAsync({holder}) end)
   table.insert(result.serverStorageChildren,{name=child.Name,class=child.ClassName,bytes=ok2 and buffer.len(b) or -1})
   holder:Destroy()
  else
   table.insert(result.serverStorageChildren,{name=child.Name,class=child.ClassName,bytes=-1})
  end
 end
 table.sort(result.serverStorageChildren,function(a,b) return a.bytes>b.bytes end)
end
return result
`;
const applied=first(await execute(script));
console.log('JASON_VALIDATED_BUILD',JSON.stringify(applied));
if(applied?.saved){
 const persisted=first(await execute(`
  assert(workspace.JediLibrary:GetAttribute("SourceAssetId")==${fixedLobbyAssetId},"Wrong fixed lobby asset")
  assert(workspace.JediLibrary:GetAttribute("FixedLobbyRevision")=="violence-district-lobby-v1","Fixed lobby revision missing")
  assert(workspace.JediLibrary:GetAttribute("FixedLobbySHA256")=="ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2","Fixed lobby hash missing")
  assert(workspace.JediLibrary:GetAttribute("FixedLobbySourceFile")=="Violence_District.rbxlx","Fixed lobby source file metadata missing")
local assets=game.ServerStorage.SurvivalAssets
  assert(game.PlaceVersion>${applied.sourceVersion},"Published version did not advance")
  assert(#assets.Maps:GetChildren()==7,"Expected seven requested maps")
  assert(assets.Maps.DoomspireBrickbattle:GetAttribute("SourceAssetId")==109440846094241)
  assert(assets.Maps.JuggernautFightArena:GetAttribute("SourceAssetId")==137884561019081)
  assert(assets.Maps.PirateBayIsland:GetAttribute("SourceAssetId")==127398591748883)
  assert(assets.Maps.NaturalDisasterSurvival:GetAttribute("SourceAssetId")==92220535332787)
  assert(assets.Maps.RocketArena:GetAttribute("SourceAssetId")==112232657511704)
  assert(assets.Maps.PiggySewers:GetAttribute("SourceAssetId")==7757562864)
  assert(assets.Maps.PiggyMappleDonut:GetAttribute("SourceAssetId")==16440225099)
  assert(assets.Maps.RocketArena:GetAttribute("RequestedScale")==2,"RocketArena did not persist at 2x scale")
  assert(not assets.Maps:FindFirstChild("HorrorMap") and not assets.Maps:FindFirstChild("MilitaryBase") and not assets.Maps:FindFirstChild("AlpineFortress"),"Old maps persisted")
  assert(#assets.Killers:GetChildren()==5 and assets.Killers.Jason:GetAttribute("SourceAssetId")==125165599816440 and assets.Killers.Krampus:GetAttribute("SourceAssetId")==92081889778550 and assets.Killers.Piggy:GetAttribute("SourceAssetId")==8762062897 and not assets.Killers:FindFirstChild("Jeff") and not assets.Killers:FindFirstChild("Freddy"),"Five-pursuer roster did not persist")
  assert(game.ReplicatedStorage.Survival:GetAttribute("Version")==126)
  assert(game.ServerStorage.SurvivalAssets.Items.Flashlight:GetAttribute("SourceAssetId")==11906391298)
  local persistedLantern=game.ServerStorage.SurvivalAssets.Items.Flashlight
  assert(persistedLantern:GetAttribute("CrackleSoundAssetId")==129037248569146,"Lantern crackle metadata did not persist")
  local persistedLanternHandle=assert(persistedLantern:FindFirstChild("Handle",true),"Persisted lantern handle missing")
  local persistedCrackle=assert(persistedLanternHandle:FindFirstChild("LanternFireCrackle"),"Persisted lantern crackle missing")
  assert(persistedCrackle.SoundId=="rbxassetid://129037248569146" and persistedCrackle.Looped,"Persisted lantern crackle is wrong")
  local persistedConfig=require(game.ReplicatedStorage.Survival.Config)
  assert(persistedConfig.Lantern and persistedConfig.Lantern.AssetId==11906391298 and persistedConfig.Lantern.SoundAssetId==129037248569146,"Persisted lantern config assets invalid")
  assert(table.concat(persistedConfig.Lantern.UpgradeCosts,",")=="10,30,50,80,100,170" and persistedConfig.Lantern.Durations[1]==70 and persistedConfig.Lantern.Durations[#persistedConfig.Lantern.Durations]==170,"Persisted lantern durability tiers invalid")
  assert(game.ServerScriptService.SurvivalServer.Source:find('action=="buyLanternUpgrade"',1,true) and game.ServerScriptService.SurvivalServer.Source:find("LanternSeconds",1,true) and game.ServerScriptService.SurvivalServer.Source:find("resetLanternBattery",1,true),"Server-owned lantern battery runtime missing")
  assert(game.ServerScriptService.ProfileService.Source:find("buyLanternUpgrade",1,true) and game.ServerScriptService.ProfileService.Source:find("lanternTier",1,true),"Lantern durability profile persistence missing")
  assert(game.ServerStorage.SurvivalAssets.Killers.Jason.MotionClips:FindFirstChild("Jason Run"))
  assert(game.ServerStorage.SurvivalAssets.Killers.Jason.MotionClips:FindFirstChild("Jason Intro"))
  assert(game.ReplicatedStorage.Survival.KillerMotionLibraries.Default:GetAttribute("ClipCount")==7)
  assert(game.ReplicatedStorage.Survival.KillerMotionLibraries.Cool:GetAttribute("ClipCount")==7)
  assert(not game.ServerStorage.SurvivalAssets.Killers.JohnDoe:FindFirstChild("MotionClips"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredIdle"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredWalk"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredRun"))
  local survivorActions=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorActionClips"),"Survivor action clips did not persist")
  assert((survivorActions:GetAttribute("ClipCount") or 0)>=3,"Required survivor action clips incomplete after publish")
  assert(survivorActions:GetAttribute("RequestedClipCount")==6 and survivorActions:GetAttribute("RequiredClipCount")==3)
  assert(survivorActions:GetAttribute("ParryRequestedAssetId")==127096285501517)
  assert(survivorActions:GetAttribute("BreakPalletRequestedAssetId")==112166042383605)
  assert(survivorActions:GetAttribute("CrouchWalkRequestedAssetId")==126965695851149)
  assert(survivorActions:GetAttribute("InjuredCrouchWalkRequestedAssetId")==135084204086504)
  assert(survivorActions:GetAttribute("StunRequestedAssetId")==123047897844134)
  assert(survivorActions:GetAttribute("StunAssetId")==123047897844134 or (survivorActions:GetAttribute("StunFallback")==true and survivorActions:GetAttribute("StunAssetId")==127092032896760))
  assert(survivorActions:GetAttribute("VaultRequestedAssetId")==83873880822918)
  assert(survivorActions:GetAttribute("CrouchWalkAssetId")==126965695851149 or (survivorActions:GetAttribute("CrouchWalkFallback")==true and survivorActions:GetAttribute("CrouchWalkAssetId")==127092032896760))
  assert(survivorActions:GetAttribute("InjuredCrouchWalkAssetId")==135084204086504 or (survivorActions:GetAttribute("InjuredCrouchWalkFallback")==true and survivorActions:GetAttribute("InjuredCrouchWalkAssetId")==127092032896760))
  assert(typeof(workspace.JediLibrary:GetAttribute("FormerDoorCFrame"))=="CFrame","Former door reference missing")
  assert(workspace.JediLibrary:GetAttribute("LobbySpawnMode")=="DoorFront","Lobby spawn is not centered in front of the authored door")
  assert((workspace.JediLibrary:GetAttribute("LobbySpawnDoorDistance") or math.huge)<=8,"Lobby spawn is too far from the entrance door")
  assert(workspace.JediLibrary:GetAttribute("LobbySpawnFacing")=="IntoHouse","Lobby spawn is not facing into the house")
  assert(typeof(workspace.JediLibrary:GetAttribute("FrontDoorFrameCenter"))=="Vector3","Centered front-door reference missing")
  assert(not workspace.JediLibrary:FindFirstChild("Door") and not workspace.JediLibrary:FindFirstChild("OriginalLobbyDoor"),"Lobby door geometry/marker returned")
  assert(game.StarterGui.TomiaszMenu.Enabled==false and game.StarterGui.TomiaszMenu:GetAttribute("LegacyMenuWidgetsPurged")==true and not game.StarterGui.TomiaszMenu:FindFirstChild("MenuPrincipal"),"Legacy main menu persisted")
  assert(not workspace:FindFirstChild("LobbyJoinPortal"),"Removed lobby join portal returned")
  assert(not workspace:FindFirstChild("SurviversLobbyDoorVisual"),"Removed lobby join door visual returned")
  assert(workspace.JediLibrary:GetAttribute("AutomaticRoundAdmission")==true,"Automatic lobby admission missing")
  assert(workspace.JediLibrary:FindFirstChild("InvisibleBounds") and #workspace.JediLibrary.InvisibleBounds:GetChildren()>=5,"Lobby invisible bounds missing")
  for _,arena in ipairs(assets.Maps:GetChildren()) do
   assert(arena:FindFirstChild("InvisibleBounds") and #arena.InvisibleBounds:GetChildren()>=5,"Arena invisible bounds missing: "..arena.Name)
   assert((arena:GetAttribute("KillerSpawnClearance") or 0)>= (arena:GetAttribute("RequiredKillerClearance") or 10),"Unsafe killer spawn persisted: "..arena.Name)
   assert(arena:GetAttribute("KillerSpawnPathValidated")==true,"Disconnected pursuer spawn persisted: "..arena.Name)
  end
  assert(not game.ServerScriptService.SurvivalServer.Source:find('FireClient(p,"jasonIntro"',1,true),"Removed killer intro returned")
  assert(game.ServerScriptService.SurvivalServer.Source:find('CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)',1,true),"R6 appearance-preserving conversion missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('Instance.new("Model") visual.Name="EquippedFlashlight"',1,true),"Pose-safe flashlight visual missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("LanternFireCrackle",1,true) and game.ServerScriptService.SurvivalServer.Source:find("129037248569146",1,true),"Lantern crackle runtime missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('run.InputBegan',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('event:FireServer("mode","walk")',1,true),"Hold-run/release-walk control missing")
  local winnerTemplate=game.ReplicatedStorage:FindFirstChild("MenuSceneTemplate")
  assert(winnerTemplate and winnerTemplate:GetAttribute("SourceAssetId")==13327565335 and winnerTemplate:GetAttribute("WinnerSceneOnly")==true,"Old menu background template missing from winner scene")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("buildResultScene",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("WinnerPursuer",1,true),"Winner scene pursuer runtime missing")
  local survivalClientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(survivalClientSource:find('local lantern=cleanAction(topActions,"Lantern"',1,true) and survivalClientSource:find('event:FireServer("flashlight")',1,true),"Lantern HUD control missing")
  assert(survivalClientSource:find("11906391298",1,true) and survivalClientSource:find("129037248569146",1,true),"Lantern HUD metadata missing")
  assert(survivalClientSource:find('roundMusic.Name="SuviversMatchMusic"',1,true),"Match soundtrack missing")
  assert(survivalClientSource:find('roundMusic.SoundId="rbxassetid://108879410219148"',1,true),"Wrong match soundtrack asset")
  assert(survivalClientSource:find('roundMusic.Volume=.35',1,true),"Match soundtrack must stay below half volume")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("captureLoadingCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("restoreLoadingCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("loadingAvatar.Visible=false",1,true),"Real full-screen map loading camera missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('"GOOD LUCK"',1,true),"GOOD LUCK missing from map loading")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find("blendFrom",1,true),"Smooth locomotion blend missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find("SurvivorActionClips",1,true) and game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('"CrouchWalk"',1,true) and game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('"InjuredCrouchWalk"',1,true),"Dedicated crouch action animation runtime missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('"Stun"',1,true) and game.ServerScriptService.SurvivalServer.Source:find("StunnedUntil",1,true),"Survivor stun action runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("expectedReplacement",1,true),"R6 replacement false-death guard missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('local executionDuration=attacker:GetAttribute("ExecutionLength")',1,true),"Synchronized execution duration missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('p:GetAttribute("BeingExecuted")==true',1,true),"Execution pose does not override downed pose")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('model:GetAttribute("ExecutionDuration")',1,true),"Pursuer execution animation duration is not synchronized")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("restoreResultCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("captureResultCamera",1,true),"Result camera restoration missing")\n  assert(game.ServerScriptService.SurvivalServer.Source:find("local RESULT_PRESENTATION_SECONDS=9",1,true) and game.ServerScriptService.SurvivalServer.Source:find('state.phase="Resultados"',1,true),"Server does not preserve the real arena for the full-screen result camera")
  assert(game.StarterGui.TomiaszMenu.Enabled==false and game.StarterGui.TomiaszMenu:GetAttribute("MenuRemoved")==true,"Main menu still opens")
  assert(game.StarterGui.TomiaszMenu:GetAttribute("LegacyMenuWidgetsPurged")==true and not game.StarterGui.TomiaszMenu:FindFirstChild("MenuPrincipal"),"Old menu UI still exists")
  local loadingController=assert(game.ReplicatedFirst:FindFirstChild("SweanLoadingController"),"Initial loading controller missing")
  local loadingAssets=assert(game.ReplicatedFirst:FindFirstChild("LoadingCinematicAssets"),"TV loading cinematic assets missing")
  assert(loadingController:GetAttribute("CinematicInitialLoading")==true and loadingController:GetAttribute("CinematicDuration")==10,"Ten-second loading cinematic metadata missing")
  assert(loadingAssets:GetAttribute("TVAssetId")==421148437 and loadingAssets:GetAttribute("TableAssetId")==397786287,"Wrong loading TV/table assets")
  local loadingTV=assert(loadingAssets:FindFirstChild("TV"),"Requested Old Television model missing")
  local loadingTable=assert(loadingAssets:FindFirstChild("Mesa"),"Requested Mesa model missing")
  assert(loadingTV:GetAttribute("SourceAssetId")==421148437 and loadingTable:GetAttribute("SourceAssetId")==397786287,"Loading asset source IDs missing")
  local loadingSource=loadingController.Source
  assert(loadingSource:find("CINEMATIC_DURATION=10",1,true) and loadingSource:find("LOGO_END=5",1,true),"Loading cinematic timing missing")
  assert(loadingSource:find("screenNormal=Vector3.new(0,0,1)",1,true) and loadingSource:find("screenUp=Vector3.new(-1,0,0)",1,true),"TV upright-axis correction missing")
  assert(loadingSource:find("fitDistance",1,true) and loadingSource:find("cameraDistance",1,true) and not loadingSource:find("tv:ScaleTo(1.5)",1,true),"TV adaptive framing/stretch fix missing")
  assert(loadingSource:find('hand.Name="HandInsideTelevision"',1,true) and loadingSource:find("cameraImpact",1,true),"Hand impact cinematic missing")
  assert(loadingSource:find('logo.Texture="rbxassetid://99002027743613"',1,true),"Game logo is not inside the TV")
  assert(loadingSource:find('screen.CFrame*CFrame.new(screen.Size.X/2+.028,0,0)',1,true),"Logo was not placed on the TV glass")
  assert(loadingSource:find("waitUntil(9.05)",1,true) and loadingSource:find("CINEMATIC_DURATION",1,true),"Final cinematic fade timing missing")
  assert(not loadingSource:find("GOOD LUCK",1,true) and not loadingSource:find("LoadingAvatar",1,true),"Map loading content leaked into initial loading")
  assert(game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("Lighting.ClockTime=.5",1,true) and game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("SuviversDistrictBloom",1,true) and game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("SuviversAtmosphere",1,true),"Night lobby ambience missing")
  local settingsSource=game.ReplicatedStorage.Survival.SettingsPanel.Source
  assert(settingsSource:find('key="CameraFOV"',1,true) and settingsSource:find('default=62',1,true),"Gameplay FOV setting missing")
  assert(not settingsSource:find('key="visual"',1,true) and not settingsSource:find('VisualSaturation',1,true) and not settingsSource:find('VisualTime',1,true),"Removed visual/environment settings returned")
  assert(not settingsSource:find('key="ReducedMotion"',1,true) and settingsSource:find('frame:SetAttribute("Style","RedBinderBook")',1,true) and settingsSource:find('scroll.Name="PageScroll"',1,true) and settingsSource:find('addRibbon("game","JOGO","GAME"',1,true),"Book settings panel missing")
  assert(game.StarterPlayer.StarterPlayerScripts.VoidSequence.Source:find('local media=RS:WaitForChild("XNMedia")',1,true),"Death presentation media reference is unsafe")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('shopOverlay.Name="KillerShop"',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('event:FireServer("buyKiller"',1,true),"Killer shop HUD missing")
  local shopSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(shopSource:find('shopPanel:SetAttribute("Style","LostInspiredStage")',1,true) and shopSource:find('StyleRevision","2026-10-26-killer-stage-v2"',1,true),"Full-screen shop stage marker missing")
  assert(shopSource:find('local shopLayout=Instance.new("UIListLayout",shopList)',1,true) and shopSource:find('shopPanel.Size=UDim2.fromScale(1,1)',1,true) and shopSource:find('tabBar.Visible=false',1,true),"Full-screen shop name list missing")
  assert(shopSource:find('shopSearch.Name="Search"',1,true) and shopSource:find('tabBar.Name="Tabs"',1,true),"Shop tabs/search layout missing")
  assert(shopSource:find('detailPanel.Name="DetailPanel"',1,true) and shopSource:find('detailPortrait.Name="SelectedPortrait"',1,true),"Selected killer detail panel missing")
  assert(shopSource:find('local killerOrder={"Jason","JohnDoe","Chucky","Piggy","Krampus"}',1,true),"Five-killer reference shop order missing")
  assert(shopSource:find('model:SetAttribute("PresentationState","ShopIdle")',1,true) and game.ReplicatedStorage.Survival:FindFirstChild("ShopScene"),"Animated selected killer or DOORS backdrop missing")
  assert(not shopSource:find("forgot a",1,true) and not shopSource:find("lmao",1,true),"Reference meme text leaked into game shop")
  assert(shopSource:find('{"Items",L("ITENS","ITEMS")}',1,true) and not shopSource:find('{"Survivors",L("SOBREVIVENTES"',1,true),"Items tab did not replace Survivors")
  assert(shopSource:find('lanternCard.Name="LanternUpgrade"',1,true) and shopSource:find('event:FireServer("buyLanternUpgrade")',1,true),"Lantern durability item shop missing")
  assert(shopSource:find('matchTV.Name="MatchLoadingTelevision"',1,true) and shopSource:find('gameCornerTitle=text(loading,"GameCornerTitle","SUVIVERS"',1,true),"TV match loading/SUVIVERS corner title missing")
  assert(shopSource:find("task.delay(5,function()",1,true) and shopSource:find("loadingStarted+10",1,true) and shopSource:find("KillerPlayerName",1,true),"Five-second roster reveal or ten-second match loading missing")
  assert(shopSource:find("SuviversRoundExposure",1,true) and shopSource:find("covered>=2",1,true) and shopSource:find("Lighting.FogEnd=isKiller and 118 or 92",1,true),"Outdoor fog/indoor lantern darkness missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('action=="buyKiller"',1,true) and game.ServerScriptService.ProfileService.Source:find("ownedKillers",1,true),"Persistent killer shop server path missing")
  assert(not game.ServerScriptService.SurvivalServer.Source:find('action=="adminReset"',1,true) and not game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("AdminReset",1,true),"Reset/test control returned")
  assert(not game.ServerScriptService.SurvivalServer.Source:find("adminResetRequested",1,true),"Hidden reset/test state returned")
  assert(not game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Removed crouch payload returned")
  assert(not game.ServerScriptService.SurvivalServer.Source:find('action=="boost"',1,true) and not game.ServerScriptService.SurvivalServer.Source:find('action=="musicPlay"',1,true) and not game.ServerScriptService.SurvivalServer.Source:find('value=="slow"',1,true),"Legacy gameplay actions returned")
  assert(workspace.LobbyGuide:GetAttribute("OutfitUserId")==8344738123 and workspace.LobbyGuide.Head.Transparency==1,"Guide outfit/headless missing")
  assert(workspace.LobbyGuide:GetAttribute("OutfitFrozen")==true and workspace.LobbyGuide:GetAttribute("OutfitSource")=="FillFrozenAppearance","Fill outfit is not frozen")
  assert(workspace.LobbyGuide:GetAttribute("OutfitPants")==110421904136844 and workspace.LobbyGuide:GetAttribute("CrossbodyBagAssetId")==97665507839365,"Requested Fill pants/satchel metadata missing")
  assert(workspace.LobbyGuide:FindFirstChild("FillCrossbodySatchel",true),"Requested Fill satchel accessory missing")
  assert(workspace.LobbyGuide:GetAttribute("OutfitRevision")=="2026-10-26-mafia-satchel-v1","Fill outfit revision not frozen")
  local frozen=game:GetService("ServerStorage"):FindFirstChild("FillFrozenAppearance")
  assert(frozen and frozen:IsA("HumanoidDescription") and frozen:GetAttribute("Frozen")==true and frozen:GetAttribute("SourceUserId")==8344738123,"Persistent frozen Fill appearance missing")
  local fillTable=assert(workspace.LobbyGuide.Tabletop.Value,"Fill tabletop reference missing")
  assert(fillTable:IsDescendantOf(workspace.JediLibrary.House) and fillTable.Name=="Furniture_Console_A" and fillTable:GetFullName():find("Console Desk",1,true),"Fill is not seated on the authored lobby console table")
  assert(not workspace.JediLibrary:FindFirstChild("GuideTable") and not workspace.JediLibrary:FindFirstChild("FillGuideStool"),"Generated Fill furniture returned")
  assert(typeof(workspace.LobbyGuide:GetAttribute("ReceptionPosition"))=="Vector3" and (workspace.LobbyGuide:GetAttribute("ReceptionPieceCount") or 0)>=1,"Fill authored-table geometry metadata missing")
  assert(workspace.LobbyGuide:GetAttribute("ReceptionAccessMode")=="AuthoredTable" and workspace.LobbyGuide:GetAttribute("GuideStation")==fillTable:GetFullName(),"Fill authored table metadata missing")
  local exteriorGround=assert(workspace.JediLibrary:FindFirstChild("OutdoorGround"),"Exterior ground missing")
  assert(workspace.JediLibrary:GetAttribute("OutdoorGroundReady")==true and workspace.JediLibrary:GetAttribute("OutdoorGroundMaterial")=="Ground","Exterior ground metadata missing")
  assert(exteriorGround.Material==Enum.Material.Ground and exteriorGround.Transparency==0,"Exterior ground is still grass/invisible")
  assert(math.abs((exteriorGround.Position.Y+exteriorGround.Size.Y/2)-625.031494140625)<.25,"Exterior ground is vertically misaligned")
  local passage=assert(workspace.JediLibrary:FindFirstChild("PassageColliders"),"Lobby passage colliders missing")
  for _,part in ipairs(passage:GetDescendants()) do
   if part:IsA("BasePart") then
    assert(not part:GetAttribute("WalkableStairStep") and not part:GetAttribute("UpperLandingBridge"),"Invisible stair floor returned")
   end
  end
  assert((workspace.JediLibrary:GetAttribute("PassageRepairRevision") or 0)>=4 and workspace.JediLibrary:GetAttribute("StairAccessClosed")==true,"Stair closure revision missing")
  assert((workspace.JediLibrary:GetAttribute("WalkableStairSteps") or 0)==0,"Invisible stair path count returned")
  local stairWarning=assert(workspace.JediLibrary:FindFirstChild("StairClosedSign"),"Requested construction sign missing")
  assert(workspace.JediLibrary:GetAttribute("StairWarningAssetId")==17143448214 and stairWarning:GetAttribute("SourceAssetId")==17143448214,"Wrong construction sign asset")
  assert(not workspace.JediLibrary:FindFirstChild("UnderStairWallRepair"),"Removed interior under-stair wall returned")
  assert(workspace.JediLibrary:GetAttribute("UnderStairWallRepaired")==false and workspace.JediLibrary:GetAttribute("InteriorWallRemoved")==true,"Interior wall removal metadata missing")
  assert(workspace.JediLibrary:GetAttribute("GeneratedUnderStairWallRemoved")==true,"Generated wall removal metadata missing")
  assert(not workspace.JediLibrary:FindFirstChild("DoorsMerchantRoom"),"Physical monster shop returned to the lobby")
  local shopMerchant=assert(workspace.JediLibrary:FindFirstChild("ShopMerchant"),"Kitchen shop NPC missing")
  assert(shopMerchant:GetAttribute("Placement")=="KitchenNearSpawn" and shopMerchant:FindFirstChild("SuviversShopPrompt",true),"Shop NPC is not active in the kitchen")
  assert(workspace.JediLibrary:GetAttribute("PhysicalMonsterShopRemoved")==true and workspace.JediLibrary:GetAttribute("ShopMerchantPlacement")=="KitchenNearSpawn","Kitchen shop placement metadata missing")
  assert((workspace.JediLibrary:GetAttribute("ShopMerchantDistanceFromSpawn") or math.huge)<=90,"Kitchen shop NPC is too far from spawn")
  assert(stairWarning:GetAttribute("BlocksUpperFloor")==true and stairWarning:FindFirstChild("NoUpstairsLabel",true),"NÃO SUBA stair warning incomplete")
  assert(game.StarterPlayer.DevCameraOcclusionMode==Enum.DevCameraOcclusionMode.Zoom,"Camera still uses wall transparency/Invisicam behavior")
  assert(workspace.LobbyGuide.GuideInteraction.RunContext==Enum.RunContext.Client,"NPC gaze must be local")\n  assert(workspace.LobbyGuide:GetAttribute("DisplayName")=="Fill" and workspace.LobbyGuide.ProximityPrompt.ObjectText=="Fill" and workspace.LobbyGuide.Head.gui.name.Text=="Fill","Fill display name was not persisted")
  assert(workspace.LobbyGuide:GetAttribute("AuthoredPosePreserved")==true and workspace.LobbyGuide:GetAttribute("Placement")=="ReceptionTabletopSeated" and workspace.LobbyGuide:GetAttribute("SeatedOnReception")==true,"Fill is not seated on top of the authored lobby table")
  local fillSource=workspace.LobbyGuide.GuideInteraction.Source
  assert(fillSource:find("portugueseGreeting",1,true) and fillSource:find("englishGreeting",1,true) and fillSource:find("GameLanguage",1,true),"Settings-driven bilingual Fill text missing")
  assert(not fillSource:find("languageButton",1,true) and not fillSource:find("AudioTextToSpeech",1,true),"Fill manual language/TTS controls returned")
  assert(fillSource:find('voice.Name="FillVoice"',1,true) and fillSource:find("How does the game work?",1,true) and fillSource:find("Nothing right now.",1,true),"Fill fixed English uploaded-audio dialogue missing")
  assert(fillSource:find('SoundService',1,true) and fillSource:find('ContentProvider:PreloadAsync',1,true),"Fill voice is not preloaded from SoundService")
  assert(fillSource:find('bubble.Size=UDim2.fromOffset(250,92)',1,true) and fillSource:find('label.TextSize=11',1,true) and fillSource:find('nameLabel.TextSize=12',1,true),"Fill overhead dialogue is not compact")
  assert(workspace.LobbyGuide:GetAttribute("VoiceLanguage")=="English" and workspace.LobbyGuide.ProximityPrompt.ActionText=="Talk","Fill fixed English voice metadata/prompt missing")
  for i=1,6 do assert((game.ReplicatedStorage.Survival:GetAttribute("FillVoice"..i) or 0)>0,"Persisted Fill English voice asset "..i.." missing") end
  local settingsSource=game.ReplicatedStorage.Survival.SettingsPanel.Source
  local clientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(clientSource:find("ViewportFrame",1,true) and clientSource:find("KillerPreviews",1,true),"3D killer shop source not persisted")
  assert(clientSource:find('local killerOrder={"Jason","JohnDoe","Chucky","Piggy","Krampus"}',1,true),"Five-character killer order not persisted")
  local previewFolder=assert(game.ReplicatedStorage.Survival:FindFirstChild("KillerPreviews"),"Killer shop previews missing")
  assert(#previewFolder:GetChildren()==5 and not previewFolder:FindFirstChild("Jeff") and not previewFolder:FindFirstChild("Freddy"),"Killer shop preview roster is not five")
  assert(settingsSource:find("GameLanguage",1,true) and settingsSource:find('key="language"',1,true),"Game language setting not persisted")
  assert(clientSource:find('BackgroundTransparency=.82',1,true) and clientSource:find('settingsOverlay.ZIndex=40',1,true),"Readable settings overlay fix not persisted")
  assert(clientSource:find("GameLanguage",1,true) and clientSource:find('L("PERSEGUIDORES","KILLERS")',1,true),"Settings-driven HUD translations not persisted")
  assert(game.StarterGui.TomiaszMenu.MenuController.Source:find('player:SetAttribute("InMenu",false)',1,true),"Direct-lobby menu controller missing")
  assert(game.ReplicatedStorage.Survival.SettingsPanel.Source:find('frame.Name="ReferenceSettings"',1,true),"Restored compact settings panel not persisted")
  assert(game.ReplicatedStorage.Survival.PlayerProfile.Source:find("CompactProfile",1,true),"Compact private profile not persisted")
  assert(game.StarterPlayer.StarterPlayerScripts.PlayerProfileController,"Profile interaction not persisted")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('UDim2.fromOffset(18,132)',1,true),"XP/level HUD was not lowered enough")
  assert(game.ServerScriptService.RoundRules.Source:find("Duration=660",1,true) and game.ServerScriptService.RoundRules.Source:find("Intermission=60",1,true) and game.ServerScriptService.RoundRules.Source:find("VoteDuration=6",1,true),"11-minute round, one-minute intermission, or six-second voting rules missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('state.phase="Votação"',1,true) and game.ServerScriptService.SurvivalServer.Source:find("setupObjectives",1,true) and game.ServerScriptService.SurvivalServer.Source:find("toggleCarry",1,true),"Objective gameplay runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("MapVoteOptions",1,true) and game.ServerScriptService.SurvivalServer.Source:find('RANDOM=0',1,true),"Four-map plus random voting runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("KillerPlayerName",1,true) and game.ServerScriptService.SurvivalServer.Source:find("LoadingRoster",1,true),"Match loading killer/roster metadata missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("4 NA VOTAÇÃO",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("7 MAPAS TOTAIS",1,true),"Four-map plus random voting UI missing")
  local survivalClientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(
   survivalClientSource:find('cleanAction(topActions,"Crouch",L("AGACHAR","CROUCH")',1,true)
   and survivalClientSource:find('staminaTrack.Name="Stamina"',1,true)
   and survivalClientSource:find("ObjectiveInventory",1,true)
   and survivalClientSource:find("MissionBanner",1,true),
   "Current localized objective HUD/stamina/crouch UI missing"
  )
  assert(game.ServerStorage.SurvivalAssets.Items.ComputerTemplate:GetAttribute("SourceAssetId")==4845271739 and game.ServerStorage.SurvivalAssets.Items.KeyTemplate:GetAttribute("SourceAssetId")==11471202845,"PC/key objective assets missing")
  assert(game.ReplicatedStorage.Survival:GetAttribute("InventoryAssetId")==73852738603629 and game.ReplicatedStorage.Survival:GetAttribute("FootstepAssetId")==137365042825200,"Inventory/footstep assets missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('requested=="RoundVictory"',1,true),"Animated winner runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('p~=selectionPlayer',1,true),"Private selection guard missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('net:GetAttribute("Phase")=="Votação"',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('voteTimer.Text=tostring(seconds)',1,true),"Full six-second voting overlay missing")
  assert(game.ReplicatedStorage.Survival.CoinDisplay:GetAttribute("SourceAssetId")==10737243803,"Exact coin missing")
  assert(#game.ReplicatedStorage.Survival.VictimMotionLibraries:GetChildren()==5,"Missing victim pairs")
  for _,map in ipairs(assets.Maps:GetChildren()) do assert(#map.ObjectiveSites:GetChildren()>=9 and #map.ArrivalSpawns:GetChildren()>=7,"Map layout missing: "..map.Name) end
  assert(game.ServerScriptService.SurvivalServer.Source:find("profiles:ownsKiller",1,true) and game.ServerScriptService.SurvivalServer.Source:find("profiles:buyKiller",1,true),"Killer shop authority missing")
  return {survivorActionAnimations=true,crouchAnimation=true,injuredCrouchAnimation=true,objectiveChecks=true,fiveVictimAnimations=true,noResetControl=true,coinAsset=10737243803,simplifiedSettings=true,compactProfile=true,privateKillerSelection=true,killerShop=true,voteDismissal=true,guide=true,guideAvatar="ch_ckz2n",guideHeadless=true,guideReception=true,guideEnglishUploadedVoice=true,objectiveEscape=true,stamina=true,crouch=true,carryDowned=true,dedicatedVoting=true,winnerMenuScene=true,animatedWinner=true,atomicShopPurchase=true,noMainMenu=true,ok=true,version=game.PlaceVersion,build=158,logo=true,mapCount=7,pursuerCount=5,lobbyPreserved=true,noLobbyPortal=true,noLobbyDoorGeometry=true,invisibleBounds=true,holdRun=true,fullScreenKillerResult=true,synchronizedExecution=true,resultCameraRestored=true,initialLogoOnly=true,mapAnimatedLoading=true,smoothLocomotion=true,fixedViolenceDistrictEnvironment=true,requestedSevenMaps=true,rocketArena2x=true,pursuersNormalized=true,legacySystemsRemoved=true,buckshotRoundMusic=true,lowVolumeRoundMusic=true}
 `));
 console.log('PERSISTED_PUBLICATION',JSON.stringify(persisted));
}

if(!applied.saved && process.env.SURVIVERS_DRY_RUN!=='1'){
 throw new Error('Suvivers build was not published; inspect saveError above');
}




