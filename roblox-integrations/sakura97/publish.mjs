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


const result=first(await execute("\nlocal out={assets={},properties={}}\nfor _,id in ipairs({11946229834,123212555736117,110144096035671}) do\n local ok,a=pcall(function() return game:GetService(\"AssetService\"):LoadAssetAsync(id) end)\n local e={id=id,ok=ok,items={}}\n if ok then\n  local cf,sz=a:GetBoundingBox() e.size=tostring(sz)\n  for _,d in ipairs(a:GetDescendants()) do\n   local v={path=d:GetFullName(),class=d.ClassName}\n   if d:IsA(\"LuaSourceContainer\") then v.source=d.Source\n   elseif d:IsA(\"GuiObject\") then\n    v.size=tostring(d.Size) if d:IsA(\"TextLabel\") then v.text=d.Text end\n   elseif d:IsA(\"ParticleEmitter\") then v.texture=d.Texture v.rate=d.Rate\n   elseif d:IsA(\"BasePart\") then v.size=tostring(d.Size)\n   elseif not d:IsA(\"BillboardGui\") and not d:IsA(\"Model\") and not d:IsA(\"Folder\") then continue end\n   table.insert(e.items,v)\n  end a:Destroy()\n else e.error=tostring(a) end\n table.insert(out.assets,e)\nend\nfor _,name in ipairs({\"StreamingEnabled\",\"StreamingMinRadius\",\"StreamingTargetRadius\"}) do\n local ok,v=pcall(function() return workspace[name] end)\n out.properties[name]={ok=ok,value=tostring(v)}\nend\nlocal island=workspace:FindFirstChild(\"FloatingIsland\")\nlocal ok,err=pcall(function() island.ModelStreamingMode=Enum.ModelStreamingMode.Persistent end)\nout.persistent={ok=ok,value=tostring(err)}\nlocal ok2,err2=pcall(function() workspace.StreamingEnabled=false end)\nout.disableStreaming={ok=ok2,value=tostring(err2)}\nreturn out"));console.log(JSON.stringify(result));
