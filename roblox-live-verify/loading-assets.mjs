const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735', PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 let last;
 for(let i=0;i<8;i++){
  const res=await fetch(CLOUD+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(60000)});
  const raw=await res.text(); let data; try{data=JSON.parse(raw)}catch{data={raw}};
  if(res.ok) return data;
  if([429,500,502,503].includes(res.status)){
   last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
   await sleep(Math.min(30000,3000*(i+1)));
   continue;
  }
  throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
 }
 throw last||new Error('Request retries exhausted');
}
async function execute(script){
 let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
 const deadline=Date.now()+180000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){if(Date.now()>deadline) throw new Error('timeout'); await sleep(1200); task=await req(task.path);}
 if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task));
 const v=task?.output?.results?.[0]; if(typeof v!=='string') return v??null; try{return JSON.parse(v)}catch{return v}
}
const luau="\nlocal Http=game:GetService(\"HttpService\")\nlocal first=game:GetService(\"ReplicatedFirst\")\nlocal assets=assert(first:FindFirstChild(\"LoadingCinematicAssets\"))\nlocal tv=assert(assets:FindFirstChild(\"TV\"))\nlocal all={}\nfor _,p in ipairs(tv:GetDescendants()) do\n if p:IsA(\"BasePart\") then\n  table.insert(all,{path=p:GetFullName(),name=p.Name,size=tostring(p.Size),pos=tostring(p.Position)})\n end\nend\nreturn Http:JSONEncode({ok=true,version=game.PlaceVersion,partCount=#all,parts=all})\n";
const result=await execute(luau);
console.log('LOADING_TV_PARTS_DIAGNOSTIC',JSON.stringify(result));
if(!result || result.ok!==true) throw new Error('Published loading cinematic verification failed');
