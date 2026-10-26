const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<8;i++){
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
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(Math.min(30000,3000*(i+1)));
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
  const deadline=Date.now()+180000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Live verify timeout');
    await sleep(1200);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Live verify failed: '+JSON.stringify(task));
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

const result=await execute("\nlocal Http=game:GetService(\"HttpService\")\nlocal lobby=assert(workspace:FindFirstChild(\"JediLibrary\"))\nlocal house=assert(lobby:FindFirstChild(\"House\"))\nlocal out={version=game.PlaceVersion,parts={}}\nlocal function add(p,tag)\n table.insert(out.parts,{\n  tag=tag,path=p:GetFullName(),pos=tostring(p.Position),size=tostring(p.Size),\n  bottom=p.Position.Y-p.Size.Y/2,top=p.Position.Y+p.Size.Y/2,\n  material=tostring(p.Material),color=tostring(p.Color),collide=p.CanCollide,transparency=p.Transparency\n })\nend\nfor _,p in ipairs(lobby:GetDescendants()) do\n if p:IsA(\"BasePart\") then\n  local n=string.lower(p.Name)\n  local full=string.lower(p:GetFullName())\n  if string.find(n,\"porch\",1,true) or string.find(n,\"step\",1,true) or string.find(full,\"garage\",1,true) or string.find(full,\"car.\",1,true) or string.find(n,\"drive\",1,true) or string.find(n,\"ground\",1,true) or string.find(n,\"floor\",1,true) then\n   if p.Transparency<.99 then add(p,\"candidate\") end\n  end\n end\nend\ntable.sort(out.parts,function(a,b)return a.bottom<b.bottom end)\nwhile #out.parts>80 do table.remove(out.parts) end\nreturn Http:JSONEncode(out)\n");
console.log('SUVIVERS_YARD_HEIGHT_DIAGNOSTIC',JSON.stringify(result));
