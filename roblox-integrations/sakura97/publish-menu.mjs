import fs from 'node:fs';

const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<12;i++){
    const res=await fetch(CLOUD+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(60000)
    });
    const raw=await res.text();
    let data; try{data=JSON.parse(raw)}catch{data={raw}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      const retry=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(60000,5000*(i+1));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function patchCloud(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:'PATCH',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:JSON.stringify(body),
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('PATCH '+path+' HTTP '+res.status+': '+JSON.stringify(data));
  return data;
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau timeout');
    await sleep(1500);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}


const read=(name)=>fs.readFileSync(`roblox-integrations/sakura97/${name}.luau`,'utf8');
const install=read('install-menu').replace('__MENU_SOURCE__',JSON.stringify(read('menu-client'))).replace('__LOADING_SOURCE__',JSON.stringify(read('loading-client')));
const mapVerify=read('verify');
const uiVerify=read('verify-menu');
const verification=`local function mapChecks()
${mapVerify}
end
local function uiChecks()
${uiVerify}
end
local m=mapChecks() local u=uiChecks()
assert(m.ok and u.ok)
`;
const patch=`local previous=game.PlaceVersion
${install}
${verification}
game:GetService("AssetService"):SavePlaceAsync()
return {ok=true,sourceVersion=previous,menu=u}`;
const applied=first(await execute(patch));
if(!applied?.ok) throw new Error('Menu install failed');
console.log(JSON.stringify({stage:'menu-saved',...applied}));
let verified=false;
for(let i=0;i<8;i++){
 const check=first(await execute(`${verification}
return {ok=true,placeVersion=game.PlaceVersion,map=m,menu=u}`));
 if(check?.ok && check.placeVersion>applied.sourceVersion){console.log(JSON.stringify({stage:'verified-persisted',...check}));verified=true;break;}
 await sleep(3000);
}
if(!verified) throw new Error('Saved menu version not verified');
