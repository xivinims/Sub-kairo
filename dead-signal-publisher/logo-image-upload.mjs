import fs from 'node:fs/promises';
import {Buffer} from 'node:buffer';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
const parts=['assets/menu/still-here-logo.part1.b64','assets/menu/still-here-logo.part2.b64','assets/menu/still-here-logo.part3.b64'];
const encoded=(await Promise.all(parts.map(path=>fs.readFile(new URL('./'+path,import.meta.url),'utf8')))).join('').replace(/\s/g,'');
const bytes=Buffer.from(encoded,'base64');
if(bytes.length<10000||bytes[0]!==0x89||bytes[1]!==0x50||bytes[2]!==0x4e||bytes[3]!==0x47)throw Error('Still Here logo PNG base64 invalid');
console.log('LOGO_IMAGE_SOURCE '+JSON.stringify({bytes:bytes.length,format:'PNG',transparent:true}));
const form=new FormData();
form.set('request',JSON.stringify({assetType:'Image',displayName:'STILL HERE - Main Menu Logo',description:'Creator-provided transparent STILL HERE logo for the main menu.',creationContext:{creator:{userId:8344738123}}}));
form.set('fileContent',new Blob([bytes],{type:'image/png'}),'still-here-logo.png');
const response=await fetch('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers:{'x-api-key':key},body:form,signal:AbortSignal.timeout(45000)});
const raw=await response.text();
if(!response.ok)throw Error('LOGO_UPLOAD_FAILED '+response.status+' '+raw.slice(0,1800));
const operation=JSON.parse(raw);console.log('LOGO_UPLOAD_OPERATION '+JSON.stringify(operation));
const path=operation.path||operation.operation?.path;
if(!path)throw Error('No logo upload operation path');
for(let retry=0;retry<26;retry++){
 const poll=await fetch('https://apis.roblox.com/assets/v1/'+path,{headers:{'x-api-key':key},signal:AbortSignal.timeout(15000)});
 const data=await poll.json();
 if(!poll.ok)throw Error('LOGO_STATUS_FAILED '+poll.status+' '+JSON.stringify(data).slice(0,900));
 if(data.done){
  if(data.error)throw Error('LOGO_MODERATION_ERROR '+JSON.stringify(data.error));
  const id=data.response?.assetId;
  if(!id)throw Error('LOGO_OPERATION_DONE_WITHOUT_ASSET '+JSON.stringify(data));
  console.log('STILL_HERE_LOGO_ASSET_ID '+id);
  console.log('LOGO_READY '+JSON.stringify({id,assetType:data.response?.assetType,moderationState:data.response?.moderationResult?.moderationState}));
  break;
 }
 await new Promise(resolve=>setTimeout(resolve,1500));
 if(retry===25)throw Error('LOGO_MODERATION_PENDING '+path);
}
