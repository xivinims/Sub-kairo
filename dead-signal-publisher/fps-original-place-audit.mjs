import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const sourceId=15864801103,key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
async function api(url){const r=await fetch(url,{headers:{'x-api-key':key},signal:AbortSignal.timeout(180000)});const t=await r.text();let d;try{d=JSON.parse(t)}catch{d={raw:t.slice(0,1000)}}if(!r.ok)throw Error('Roblox HTTP '+r.status+' '+JSON.stringify(d));return d;}
const meta=await api('https://economy.roblox.com/v2/assets/'+sourceId+'/details');
if(meta.Name!=='FPS System Demo (uncopylocked)'||meta.AssetTypeId!==9)throw Error('Unexpected FPS source metadata '+JSON.stringify({name:meta.Name,type:meta.AssetTypeId}));
const delivery=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+sourceId);const url=delivery.location||delivery.locations?.[0]?.location;if(!url)throw Error('Source place URL missing');
const res=await fetch(url,{signal:AbortSignal.timeout(240000)});if(!res.ok)throw Error('Source download failed');const bytes=Buffer.from(await res.arrayBuffer());
if(createHash('sha256').update(bytes).digest('hex')!=='6cd1bc3e7a71505b38965acc3e8219bc84bda1b8ac4ca64ae0ca4151800a2d02')throw Error('FPS source hash changed');
await fs.writeFile('/tmp/fps-system-demo-source',bytes);
const lr=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(120000)});if(!lr.ok)throw Error('Lune download failed');const zip=Buffer.from(await lr.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/fps-original-audit-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/fps-original-audit-lune.zip','-d','/tmp/fps-original-audit-lune'],{stdio:'ignore'});await fs.chmod('/tmp/fps-original-audit-lune/lune',0o755);
const output=execFileSync('/tmp/fps-original-audit-lune/lune',['run','fps-original-place-audit.luau'],{cwd:new URL('.',import.meta.url).pathname,encoding:'utf8',maxBuffer:16*1024*1024});
console.log('FPS_ORIGINAL_PLACE_AUDIT '+JSON.stringify({sourceId,sourceSha:createHash('sha256').update(bytes).digest('hex'),...JSON.parse(output.trim().split('\n').at(-1))}));
