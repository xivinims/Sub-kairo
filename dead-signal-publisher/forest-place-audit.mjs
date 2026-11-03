import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const z=Buffer.from(await (await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip')).arrayBuffer());
if(createHash('sha256').update(z).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('checksum');
await fs.writeFile('/tmp/forest-lune.zip',z);execFileSync('unzip',['-o','/tmp/forest-lune.zip','-d','/tmp/forest-lune']);await fs.chmod('/tmp/forest-lune/lune',0o755);
for(const id of ['186677844','5326950832']){
 try{
  const r=await fetch('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+id,{headers:{'x-api-key':process.env.ROBLOX_API_KEY}});
  const j=await r.json();const url=j.location||j.locations?.[0]?.location;
  if(!r.ok||!url){console.log(JSON.stringify({id,error:j}));continue;}
  const f=await fetch(url);if(!f.ok)throw Error('download '+f.status);
  const bytes=Buffer.from(await f.arrayBuffer());await fs.writeFile('/tmp/place-'+id+'.rbxl',bytes);
  console.log(JSON.stringify({id,bytes:bytes.length}));
  execFileSync('/tmp/forest-lune/lune',['run','forest-place-audit.luau',id],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
 }catch(e){console.log(JSON.stringify({id,error:String(e)}));}
}
