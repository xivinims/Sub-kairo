import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const request=JSON.parse(await fs.readFile(new URL('reference-request.json',import.meta.url),'utf8'));
const dir='/tmp/nb-assets';await fs.mkdir(dir,{recursive:true});
const get=async(url,auth=false)=>{for(let attempt=0;attempt<4;attempt++){const r=await fetch(url,{headers:auth?{'x-api-key':process.env.ROBLOX_API_KEY}:{},signal:AbortSignal.timeout(60000)});if(r.ok)return r;if(r.status===429&&attempt<3){await new Promise(resolve=>setTimeout(resolve,5000*2**attempt));continue;}throw Error(`${r.status} ${url}`);}};
for(const q of request.queries||[]){try{
 const list=await(await get('https://apis.roblox.com/toolbox-service/v1/marketplace/10?limit=10&pageNumber=0&keyword='+encodeURIComponent(q))).json();
 const ids=(list.data||[]).map(x=>x.id).filter(Boolean);
 const details=ids.length?await(await get('https://apis.roblox.com/toolbox-service/v1/items/details?assetIds='+ids.join(','))).json():{};
 console.log('Reference search',JSON.stringify({q,items:(details.data||[]).map(x=>({id:x.asset?.id,name:x.asset?.name,creator:x.creator}))}));
}catch(e){console.log('Reference search error',q,String(e));}}
const metadata=[];const bulk=(request.assetIds||[]).length?await(await get('https://apis.roblox.com/toolbox-service/v1/items/details?assetIds='+request.assetIds.join(','))).json():{};
for(const id of request.assetIds||[]){try{
 const detail=(bulk.data||[]).find(x=>x.asset?.id===id);const meta={Name:detail?.asset?.name,Creator:detail?.creator};
 const delivery=await(await get(`https://apis.roblox.com/asset-delivery-api/v1/assetId/${id}`,true)).json();
 const location=delivery.location||delivery.locations?.[0]?.location;
 const bytes=Buffer.from(await(await get(location)).arrayBuffer());
 await fs.writeFile(`${dir}/${id}.rbxm`,bytes);metadata.push({id,name:meta.Name,creator:meta.Creator,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')});
}catch(e){metadata.push({id,error:String(e)});}}
await fs.writeFile(`${dir}/reference-meta.json`,JSON.stringify(metadata));
const zip=Buffer.from(await(await get('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip')).arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune integrity mismatch');
await fs.writeFile('/tmp/nb-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/nb-lune.zip','-d','/tmp/nb-lune']);await fs.chmod('/tmp/nb-lune/lune',0o755);
execFileSync('/tmp/nb-lune/lune',['run','reference-audit.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
