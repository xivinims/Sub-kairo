import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const id=72094860266497,key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('Missing ROBLOX_API_KEY');
async function json(url){const r=await fetch(url,{headers:{'x-api-key':key},signal:AbortSignal.timeout(120000)});if(!r.ok)throw Error('HTTP '+r.status);return r.json();}
const meta=await json('https://economy.roblox.com/v2/assets/'+id+'/details');
const delivery=await json('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+id);
const url=delivery.location||delivery.locations?.[0]?.location;if(!url)throw Error('Asset unavailable');
const response=await fetch(url,{signal:AbortSignal.timeout(120000)});if(!response.ok)throw Error('Asset download failed');const bytes=Buffer.from(await response.arrayBuffer());
await fs.writeFile('/tmp/nametag-source.rbxm',bytes);
console.log('NAMETAG_ASSET '+JSON.stringify({id,name:meta.Name,creator:meta.Creator,type:meta.AssetTypeId,description:meta.Description,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}));
const r=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');if(!r.ok)throw Error('Lune download failed');const zip=Buffer.from(await r.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/nametag-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/nametag-lune.zip','-d','/tmp/nametag-lune']);await fs.chmod('/tmp/nametag-lune/lune',0o755);
execFileSync('/tmp/nametag-lune/lune',['run','nametag-audit.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
