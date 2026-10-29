import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw new Error('Missing ROBLOX_API_KEY');
const target='universes/9421311218/places/118064584465155/';
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function api(url,{method='GET',body,type='application/json'}={}){
 const r=await fetch(url,{method,headers:{'x-api-key':key,'content-type':type},body,signal:AbortSignal.timeout(240000)});
 const raw=await r.text();let j;try{j=JSON.parse(raw)}catch{j={raw}};
 if(!r.ok)throw new Error('HTTP '+r.status+': '+JSON.stringify(j).slice(0,900));return j;
}
async function download(file,version){
 const suffix=version?'/version/'+version:'';
 const j=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/118064584465155'+suffix);
 const location=j.location||j.locations?.[0]?.location;
 if(!location)throw new Error('Asset download location missing');
 const r=await fetch(location);if(!r.ok)throw new Error('File download HTTP '+r.status);
 const data=Buffer.from(await r.arrayBuffer());if(data.length<10000)throw new Error('Unexpected empty place');
 await fs.writeFile(file,data);console.log(JSON.stringify({downloaded:true,version,bytes:data.length}));
}
async function execute(script,version,binaryInput){
 const base='https://apis.roblox.com/cloud/v2/';
 let t=await api(base+target+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput})});
 for(let i=0;['QUEUED','PENDING','PROCESSING'].includes(t.state);i++){
  if(i>240){let logs;try{logs=await api(base+t.path+'/logs?view=FLAT')}catch(e){logs=String(e)}throw new Error('Execution timeout '+JSON.stringify({state:t.state,path:t.path,logs}));}await pause(1500);t=await api(base+t.path);
 }
 if(t.state!=='COMPLETE'||t.error)throw new Error(JSON.stringify(t.error||t));
 const v=t.output?.results?.[0];return typeof v==='string'?JSON.parse(v):v;
}

async function external(id){
 const j=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+id);
 const url=j.location||j.locations?.[0]?.location;if(!url)throw Error('Missing source '+id);
 const r=await fetch(url);if(!r.ok)throw Error('Source download '+r.status);
 await fs.writeFile('/tmp/asset-'+id+'.rbxl',Buffer.from(await r.arrayBuffer()));
}

await download('/tmp/still-here-source.rbxl',177);
await external('186677844');
const binary=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
const zip=Buffer.from(await binary.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum');
await fs.writeFile('/tmp/islands-lune.zip',zip);execFileSync('unzip',['-o','/tmp/islands-lune.zip','-d','/tmp/islands-lune']);await fs.chmod('/tmp/islands-lune/lune',0o755);
execFileSync('/tmp/islands-lune/lune',['run','islands-door-audit.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});

const ids=[86500008,86500036,86500054,86500064,86500078,86499666,86499716,86499753,86499793,86499840,86498048,86487766,86487700,62234425,16630147,48474313,16627494,144076358,144076436,607785314,398633812,144076760,398633584];
console.log('CATALOG AUDIT '+JSON.stringify(await execute(`local M=game:GetService('MarketplaceService');local r={} for _,id in ipairs({${ids.join(',')}}) do local ok,v=pcall(function() return M:GetProductInfo(id) end);table.insert(r,{id=id,ok=ok,name=ok and v.Name or tostring(v),type=ok and v.AssetTypeId or 0}) end return game:GetService('HttpService'):JSONEncode(r)`)));
