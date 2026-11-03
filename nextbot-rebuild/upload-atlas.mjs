import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
const key=process.env.ROBLOX_API_KEY;const hash=b=>createHash('sha256').update(b).digest('hex');
const dir=new URL('.',import.meta.url);const manifest=JSON.parse(await fs.readFile(new URL('atlas-manifest.json',dir)));
const data=Buffer.concat(await Promise.all(Array.from({length:manifest.count},(_,i)=>fs.readFile(new URL(`assets/atlas.part${i}`,dir)))));
if(hash(data)!==manifest.sha256)throw Error('Atlas integrity mismatch');
await fs.writeFile('/tmp/nb-assets/menu-atlas.png',data);
const api=async(url,opts={})=>{const r=await fetch(url,{...opts,headers:{'x-api-key':key,...opts.headers},signal:AbortSignal.timeout(60000)});if(!r.ok)throw Error(`Atlas API HTTP ${r.status}: ${(await r.text()).slice(0,300)}`);return r.json()};
try{
 let existing;try{existing=JSON.parse(await fs.readFile(new URL('atlas-published.json',dir)))}catch{}
 if(existing?.sha256===manifest.sha256&&existing.imageId){await fs.writeFile('/tmp/nb-assets/atlas-result.json',JSON.stringify(existing));console.log('Atlas reused',existing.imageId);}
 else{
  const probe=JSON.parse(await fs.readFile('/tmp/nb-assets/access-probe.json'));
  const results=probe.engine?.result?.output?.results;
  let creator=Array.isArray(results)?results[0]:results;
  if(typeof creator==='string')creator=JSON.parse(creator);
  if(!creator?.creatorId||!['User','Group'].includes(creator.creatorType))throw Error('Verified creator not available');
  const form=new FormData();form.set('request',JSON.stringify({assetType:'Decal',displayName:'Exact Run - Menu Cards',description:'Temporary menu artwork supplied for the Exact Run test.',creationContext:{creator:{[creator.creatorType==='Group'?'groupId':'userId']:String(creator.creatorId)}}}));form.set('fileContent',new Blob([data],{type:'image/png'}),'menu-atlas.png');
  let operation=await api('https://apis.roblox.com/assets/v1/assets',{method:'POST',body:form});
  const path=operation.path||'operations/'+operation.operationId;
  for(let i=0;i<50&&!operation.done;i++){await new Promise(r=>setTimeout(r,2000));operation=await api('https://apis.roblox.com/assets/v1/'+path);}
  if(operation.error)throw Error(JSON.stringify(operation.error));
  const assetId=operation.response?.assetId;if(!assetId)throw Error('Atlas operation pending');
  let imageId=assetId;
  try{const delivery=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+assetId);const location=delivery.location||delivery.locations?.[0]?.location;if(location){const bytes=Buffer.from(await(await fetch(location)).arrayBuffer());if(bytes.slice(0,100).toString().includes('<roblox')){const m=bytes.toString().match(/(?:id=|rbxassetid:\/\/)(\d+)/);if(m)imageId=m[1];}}}catch{}
  const result={assetId,imageId,sha256:manifest.sha256};await fs.writeFile('/tmp/nb-assets/atlas-result.json',JSON.stringify(result,null,2));console.log('Atlas created',JSON.stringify(result));
 }
}catch(e){await fs.writeFile('/tmp/nb-assets/atlas-result.json',JSON.stringify({error:String(e)}));console.log('Atlas unavailable',String(e));}
