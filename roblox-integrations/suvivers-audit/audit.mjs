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



const script=`
local report={version=game.PlaceVersion,assets={},scripts={}}
for _,id in ipairs({4977080604,14495430620,13967333450}) do
 local ok,m=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(id) end)
 local rec={id=id,loaded=ok}
 if ok and m then
  local scripts=0 local count=0 local meshes=0 local large={}
  for _,v in ipairs(m:GetDescendants()) do
   if v:IsA("LuaSourceContainer") then scripts+=1
   elseif v:IsA("BasePart") then
    count+=1 if v:IsA("MeshPart") then meshes+=1 end
    if v.Size.X>30 and v.Size.Z>30 and v.CFrame.UpVector.Y>.8 then table.insert(large,{name=v:GetFullName(),size=tostring(v.Size),pos=tostring(v.Position),collide=v.CanCollide,transparent=v.Transparency}) end
   end
  end
  table.sort(large,function(a,b) return a.name<b.name end)
  while #large>20 do table.remove(large) end
  local cf,size=m:GetBoundingBox()
  rec.parts=count rec.scripts=scripts rec.meshes=meshes rec.size=tostring(size) rec.center=tostring(cf.Position) rec.ground=large rec.children={}
  for _,v in ipairs(m:GetChildren()) do table.insert(rec.children,{name=v.Name,class=v.ClassName}) end
  m:Destroy()
 else rec.error=tostring(m) end
 table.insert(report.assets,rec)
end
for _,v in ipairs(game.ServerScriptService:GetDescendants()) do
 if v:IsA("LuaSourceContainer") then
  local src=v.Source
  table.insert(report.scripts,{name=v.Name,length=#src,source=nil})
 end
end
return report
`;
console.log('EXPANSION_AUDIT',JSON.stringify(first(await execute(script))));
