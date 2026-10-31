import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

export const cwd=new URL('.',import.meta.url);
export const lune='/tmp/still-here-hotel-lune/lune';
export async function prepareHotel(){
 const key=process.env.ROBLOX_API_KEY;
 if(!key)throw Error('Missing ROBLOX_API_KEY');
 const delivery=await fetch('https://apis.roblox.com/asset-delivery-api/v1/assetId/7902470429',{headers:{'x-api-key':key},signal:AbortSignal.timeout(60000)});
 if(!delivery.ok)throw Error('Mansion UI download metadata HTTP '+delivery.status);
 const metadata=await delivery.json();
 const location=metadata.location||metadata.locations?.[0]?.location;
 if(!location)throw Error('Original mansion UI source unavailable');
 const source=await fetch(location,{signal:AbortSignal.timeout(180000)});
 if(!source.ok)throw Error('Mansion UI source HTTP '+source.status);
 await fs.writeFile('/tmp/asset-7902470429.rbxl',Buffer.from(await source.arrayBuffer()));
 const response=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(120000)});
 if(!response.ok)throw Error('Lune download HTTP '+response.status);
 const zip=Buffer.from(await response.arrayBuffer());
 if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
 await fs.writeFile('/tmp/still-here-hotel-lune.zip',zip);
 execFileSync('unzip',['-q','-o','/tmp/still-here-hotel-lune.zip','-d','/tmp/still-here-hotel-lune']);
 await fs.chmod(lune,0o755);
}
export function run(file){execFileSync(lune,['run',file],{cwd,stdio:'inherit'});}
