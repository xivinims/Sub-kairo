import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const reference=JSON.parse(await fs.readFile(new URL('reference-request.json',import.meta.url),'utf8').catch(()=>'{"mode":"build"}'));
if(reference.mode==='inspect'){await import('./reference-audit.mjs');process.exit(0);}
if(reference.mode==='promote'){await import('./promote-tested.mjs');process.exit(0);}
const key=process.env.ROBLOX_API_KEY;
if(!key) throw Error('ROBLOX_API_KEY missing');
const hash=b=>createHash('sha256').update(b).digest('hex');
await fs.mkdir('/tmp/nb-assets',{recursive:true});
async function get(url,auth=false){
 for(let attempt=0;attempt<5;attempt++){
  const r=await fetch(url,{headers:auth?{'x-api-key':key}:{},signal:AbortSignal.timeout(120000)});
  if(r.ok)return r;
  if(r.status===429&&attempt<4){await new Promise(resolve=>setTimeout(resolve,Math.min(5000*2**attempt,40000)));continue;}
  throw Error(`HTTP ${r.status} on ${new URL(url).hostname}`);
 }
}
const original=Buffer.concat(await Promise.all(Array.from({length:7},(_,i)=>fs.readFile(new URL(`assets/emotes.part${i}`,import.meta.url)))));
if(hash(original)!=='acc4f67fa3e686020dc7e4ed1302770156eb106837958ed691ae0acfa4546995')throw Error('Emote source integrity mismatch');
await fs.writeFile(new URL('assets/user-r6-emotes.rbxm',import.meta.url),original);
await import('./probe.mjs');
await import('./upload-atlas.mjs');
await import('./search-catalog.mjs');
const metadata=[];
for(const id of [74987847468722,4951486910,13634611708,14026023204,11128061931,124805122537927,123713126320438,113165227370713,14047690859,10828666356,10828618634,10844642277,10828489513,10819434129,13028240941,11448641842,10844522204]){
 try{
  const meta=await (await get(`https://economy.roblox.com/v2/assets/${id}/details`)).json();
  const delivery=await (await get(`https://apis.roblox.com/asset-delivery-api/v1/assetId/${id}`,true)).json();
  const location=delivery.location||delivery.locations?.[0]?.location;
  if(!location)throw Error('No delivery location');
  const bytes=Buffer.from(await (await get(location)).arrayBuffer());
  const pinned={74987847468722:'a41ef524745b4c47e5d8979969f6e056a590469a344aac4ac014511903a1c4a4',4951486910:'77200224b0658cff0898d06b629f6bf507e9869a6ac2965a839cfd12ef7f0420',13634611708:'5f343b5b702d324997cb28f6d8e006a5c64fc001f9aef932c2a39d573ef87b74'};
  if(pinned[id]&&hash(bytes)!==pinned[id])throw Error('Inspected source changed: '+id);
  const file=`/tmp/nb-assets/${id}.rbxm`;await fs.writeFile(file,bytes);
  metadata.push({id,name:meta.Name,type:meta.AssetTypeId,bytes:bytes.length,creator:meta.Creator,created:meta.Created,updated:meta.Updated,sourceUrl:`https://create.roblox.com/store/asset/${id}`,file,sha256:hash(bytes)});
 }catch(e){metadata.push({id,error:String(e)});}
}
await fs.writeFile('/tmp/nb-assets/meta.json',JSON.stringify(metadata,null,2));
const zip=Buffer.from(await (await get('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip')).arrayBuffer());
if(hash(zip)!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune integrity mismatch');
await fs.writeFile('/tmp/nb-lune.zip',zip);
execFileSync('unzip',['-q','-o','/tmp/nb-lune.zip','-d','/tmp/nb-lune']);
await fs.chmod('/tmp/nb-lune/lune',0o755);
for(const file of ['audit.luau','build.luau'])execFileSync('/tmp/nb-lune/lune',['run',file],{cwd:new URL('.',import.meta.url),stdio:'inherit'});

await import("./stage-test.mjs");
