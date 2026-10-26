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

const result=await execute("\nlocal Http=game:GetService(\"HttpService\")\nlocal lobby=assert(workspace:FindFirstChild(\"JediLibrary\"))\nlocal house=assert(lobby:FindFirstChild(\"House\"))\nlocal ground=assert(lobby:FindFirstChild(\"OutdoorGround\"),\"OutdoorGround missing\")\nlocal out={\n version=game.PlaceVersion,\n ground={pos=tostring(ground.Position),size=tostring(ground.Size),cf=tostring(ground.CFrame),collide=ground.CanCollide,query=ground.CanQuery,material=tostring(ground.Material),top=ground.Position.Y+ground.Size.Y/2},\n attrY=lobby:GetAttribute(\"OutdoorGroundY\"),\n attrSize=tostring(lobby:GetAttribute(\"OutdoorGroundSize\")),\n rays={}\n}\nlocal excludes={}\nfor _,name in ipairs({\"InvisibleBounds\",\"PassageColliders\"}) do\n local x=lobby:FindFirstChild(name)\n if x then table.insert(excludes,x) end\nend\nlocal params=RaycastParams.new()\nparams.FilterType=Enum.RaycastFilterType.Exclude\nparams.FilterDescendantsInstances=excludes\nparams.RespectCanCollide=true\n\nlocal xs={80,120,160,180,200,220,250,300,350,400,450,500,540}\nlocal zs={-140,-100,-60,0,60,100,140}\nfor _,x in ipairs(xs) do\n for _,z in ipairs(zs) do\n  local hit=workspace:Raycast(Vector3.new(x,680,z),Vector3.new(0,-100,0),params)\n  table.insert(out.rays,{\n   x=x,z=z,\n   hit=hit and hit.Instance:GetFullName() or nil,\n   pos=hit and tostring(hit.Position) or nil,\n   isGround=hit and hit.Instance==ground or false\n  })\n end\nend\nreturn Http:JSONEncode(out)\n");
console.log('SUVIVERS_GROUND_DIAGNOSTIC',JSON.stringify(result));
