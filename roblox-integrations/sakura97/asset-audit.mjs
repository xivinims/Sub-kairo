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



const meta=await fetch('https://apis.roblox.com/assets/v1/assets/89648072626653',{headers:{'x-api-key':process.env.ROBLOX_API_KEY}});
console.log(JSON.stringify({stage:'logo-status',http:meta.status,result:await meta.json()}));
const audit=first(await execute(`
local CP=game:GetService("ContentProvider")
local Market=game:GetService("MarketplaceService")
local report={}
for _,id in ipairs({89648072626653,12221967,97031842441992,87437544236708}) do
 local ok,info=pcall(function() return Market:GetProductInfoAsync(id,Enum.InfoType.Asset) end)
 report[tostring(id)]={metadataOk=ok,name=ok and info.Name or tostring(info),assetType=ok and info.AssetTypeId or nil}
end
local failures={} local completed=0 local done=false
local pending=task.spawn(function()
 local ok,err=pcall(function()
  CP:PreloadAsync({workspace.FloatingIsland,workspace.BigCenterTree,workspace.MysticalSpawn,game.ReplicatedStorage.GrassWindTemplate,game.Lighting},function(id,status)
   completed+=1 if status~=Enum.AssetFetchStatus.Success then failures[#failures+1]={id=id,status=tostring(status)} end
  end)
 end)
 if not ok then failures[#failures+1]={error=tostring(err)} end
 done=true
end)
local deadline=os.clock()+65
while not done and os.clock()<deadline do task.wait(.1) end
if not done then pcall(task.cancel,pending) end
local ui=game.StarterGui.TomiaszMenu
local mediaStatus={}
local mediaDone=false
local mediaThread=task.spawn(function()
 pcall(function() CP:PreloadAsync({game.ReplicatedStorage.XNMedia,ui.MenuPrincipal.Logo},function(id,status) mediaStatus[id]=tostring(status) end) end)
 mediaDone=true
end)
local mediaDeadline=os.clock()+30
while not mediaDone and os.clock()<mediaDeadline do task.wait(.1) end
if not mediaDone then pcall(task.cancel,mediaThread) end
return {mediaStatus=mediaStatus,mediaCompleted=mediaDone,assets=report,mapPreloadCompleted=done,mapContentCount=completed,mapContentFailures=failures,logo=ui.MenuPrincipal.Logo.Image,logoAnchor=tostring(ui.MenuPrincipal.Logo.AnchorPoint),credits=ui.Escenarios.MenuCreditos.CreditosFrame.TextCreditos.Text,placeVersion=game.PlaceVersion}
`));
console.log(JSON.stringify({stage:'asset-audit',...audit}));
