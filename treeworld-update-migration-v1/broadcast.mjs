const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
const UNIVERSE_ID='9421311218';
const TOPIC='Overyard_Update_v1';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function jsonReq(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let attempt=0;attempt<10;attempt++){
    const res=await fetch(url,{...options,headers:{...(options.headers||{}),'x-api-key':key},signal:AbortSignal.timeout(60000)});
    const text=await res.text();
    let data; try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok) return {data,status:res.status};
    if([429,500,502,503].includes(res.status)){
      const waitMs=Math.min(60000,5000*(attempt+1));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs); continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Request retries exhausted');
}

async function execute(script){
  let task=(await jsonReq(CLOUD+TARGET+'luau-execution-session-tasks',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({timeout:'60s',script})})).data;
  const deadline=Date.now()+180000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau execution timeout');
    await sleep(1500);
    task=(await jsonReq(CLOUD+task.path)).data;
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

const current=await execute('return {placeVersion=game.PlaceVersion,placeId=game.PlaceId,gameId=game.GameId}');
if(Number(current?.gameId)!==9421311218 || Number(current?.placeId)!==118064584465155) throw new Error('Wrong Roblox target');
const targetPlaceVersion=Number(process.env.TARGET_PLACE_VERSION||current.placeVersion);
if(!targetPlaceVersion) throw new Error('Could not determine target place version');
const releaseId=process.env.RELEASE_ID||('place-v'+targetPlaceVersion+'-'+Date.now());
const message=JSON.stringify({placeId:118064584465155,targetPlaceVersion,releaseId,kind:'game-update'});

try{
  const sent=await jsonReq(CLOUD+'universes/'+UNIVERSE_ID+':publishMessage',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({topic:TOPIC,message})});
  console.log(JSON.stringify({ok:true,mode:'open-cloud',status:sent.status,targetPlaceVersion,releaseId,topic:TOPIC}));
}catch(openErr){
  console.log(JSON.stringify({openCloudFailed:true,error:String(openErr)}));
  const luau='local MessagingService=game:GetService("MessagingService")\nlocal ok,err=pcall(function() MessagingService:PublishAsync("'+TOPIC+'",'+JSON.stringify(message)+') end)\nreturn {ok=ok,error=ok and nil or tostring(err)}';
  const fallback=await execute(luau);
  if(!fallback?.ok) throw new Error('Update broadcast failed: '+JSON.stringify(fallback));
  console.log(JSON.stringify({ok:true,mode:'luau',targetPlaceVersion,releaseId,topic:TOPIC}));
}
