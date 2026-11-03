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
local report={assets={}}
for _,id in ipairs({93583640955196,124873348702500}) do
 local ok,asset=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(id) end)
 local rec={id=id,ok=ok,nodes={},scripts={}}
 if ok then
  for _,v in ipairs(asset:GetDescendants()) do
   if v:IsA("LuaSourceContainer") then table.insert(rec.scripts,{path=v:GetFullName(),class=v.ClassName,source=v.Source})
   elseif v:IsA("GuiObject") or v:IsA("ScreenGui") then
    local node={path=v:GetFullName(),class=v.ClassName}
    if v:IsA("GuiObject") then node.size=tostring(v.Size) node.position=tostring(v.Position) node.visible=v.Visible end
    if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then node.text=v.Text end
    table.insert(rec.nodes,node)
   end
  end
  asset:Destroy()
 else rec.error=tostring(asset) end
 table.insert(report.assets,rec)
end
return report
`;
console.log('UI_ASSET_AUDIT',JSON.stringify(first(await execute(script))));
