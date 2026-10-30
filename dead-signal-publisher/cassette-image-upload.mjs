import fs from 'node:fs/promises';
import { Buffer } from 'node:buffer';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
const bytes=Buffer.from((await fs.readFile(new URL('./cassette-sprite.b64',import.meta.url),'utf8')).trim(),'base64');
if(bytes.length<3500||bytes[0]!==0xff||bytes[1]!==0xd8)throw Error('Cassette JPEG base64 invalid');
console.log('CASSETTE_IMAGE_SOURCE '+JSON.stringify({bytes:bytes.length,sprite:'three-original-tapes',frames:['STILL HERE','TEST FOOTAGE','LOST RECORDING']}));
const form=new FormData();
form.set('request',JSON.stringify({assetType:'Image',displayName:'STILL HERE - Cassette Recordings',description:'Original VHS cassette menu art for the Still Here horror game. Three frames; no third-party game branding.',creationContext:{creator:{userId:8344738123}}}));
form.set('fileContent',new Blob([bytes],{type:'image/jpeg'}),'still-here-cassette-archive.jpg');
const result=await fetch('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers:{'x-api-key':key},body:form,signal:AbortSignal.timeout(45000)});
const raw=await result.text();if(!result.ok)throw Error('CASSETTE_UPLOAD_FAILED '+result.status+' '+raw.slice(0,1800));
const response=JSON.parse(raw);
console.log('CASSETTE_UPLOAD_OPERATION '+JSON.stringify(response));
const path=response.path||response.operation?.path;
if(!path)throw Error('No upload operation path');
for(let retry=0;retry<26;retry++){
 const poll=await fetch('https://apis.roblox.com/assets/v1/'+path,{headers:{'x-api-key':key},signal:AbortSignal.timeout(15000)});
 const data=await poll.json();
 if(!poll.ok)throw Error('CASSETTE_STATUS_FAILED '+poll.status+' '+JSON.stringify(data).slice(0,900));
 if(data.done){
  if(data.error)throw Error('CASSETTE_MODERATION_ERROR '+JSON.stringify(data.error));
  const id=data.response?.assetId;
  if(!id)throw Error('CASSETTE_OPERATION_DONE_WITHOUT_ASSET '+JSON.stringify(data));
  console.log('CASSETTE_IMAGE_ASSET_ID '+id);
  console.log('CASSETTE_READY '+JSON.stringify({id,frames:3,frameWidth:300,frameHeight:100,assetType:data.response?.assetType,moderationState:data.response?.moderationResult?.moderationState}));
  break;
 }
 await new Promise(resolve=>setTimeout(resolve,1500));
 if(retry===25)throw Error('CASSETTE_MODERATION_PENDING '+path);
}
