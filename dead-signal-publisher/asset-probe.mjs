const UNIVERSE_ID='9421311218';
const PLACE_ID='118064584465155';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/'+UNIVERSE_ID+'/places/'+PLACE_ID+'/';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function api(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(url,{
    method:options.method||'GET',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:options.body,
    signal:AbortSignal.timeout(240000),
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}};
  if(!res.ok) throw new Error('HTTP '+res.status+': '+raw.slice(0,1400));
  return data;
}

async function execute(script){
  let task=await api(CLOUD+TARGET+'luau-execution-session-tasks',{
    method:'POST',
    body:JSON.stringify({timeout:'300s',script})
  });
  const deadline=Date.now()+420000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('probe timeout');
    await sleep(1400);
    task=await api(CLOUD+task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task.error||task));
  const value=task.output?.results?.[0];
  if(typeof value==='string'){try{return JSON.parse(value)}catch{return {raw:value}}}
  return value;
}

const script = "\nlocal AssetService=game:GetService(\"AssetService\")\nlocal MarketplaceService=game:GetService(\"MarketplaceService\")\nlocal HttpService=game:GetService(\"HttpService\")\nlocal list={{role=\"floor\",id=11961684378},{role=\"door-frame\",id=96103787859080},{role=\"grabpack-reference\",id=10468403169},{role=\"chapter4-idea-kit\",id=72028919182927},{role=\"model-kit\",id=16390129962},{role=\"power-station\",id=9609111841},{role=\"door\",id=8593730677},{role=\"stalker-reference\",id=115602504342753},{role=\"batteries\",id=16551049618},{role=\"power-links\",id=16592756903},{role=\"map-reference\",id=10231610849},{role=\"stairs\",id=120661626985584}}\nlocal report={}\nlocal function summarize(entry)\n    local item={role=entry.role,id=entry.id,ok=false}\n    local infoOk,info=pcall(function()\n        return MarketplaceService:GetProductInfo(entry.id,Enum.InfoType.Asset)\n    end)\n    if infoOk and type(info)==\"table\" then\n        item.name=info.Name\n        item.assetTypeId=info.AssetTypeId\n        if info.Creator then\n            item.creatorName=info.Creator.Name\n            item.creatorId=info.Creator.CreatorTargetId or info.Creator.Id\n        end\n    end\n\n    local ok,model=pcall(function()\n        return AssetService:LoadAssetAsync(entry.id)\n    end)\n    if not ok then\n        item.error=tostring(model)\n        return item\n    end\n\n    item.ok=true\n    local counts={parts=0,meshParts=0,models=0,scripts=0,moduleScripts=0,localScripts=0,sounds=0,animations=0,humanoids=0,attachments=0,constraints=0,prompts=0}\n    local top={}\n    for _,child in ipairs(model:GetChildren())do\n        if #top<20 then top[#top+1]=child.ClassName..\":\"..child.Name end\n    end\n    for _,d in ipairs(model:GetDescendants())do\n        if d:IsA(\"BasePart\")then counts.parts+=1 end\n        if d:IsA(\"MeshPart\")then counts.meshParts+=1 end\n        if d:IsA(\"Model\")then counts.models+=1 end\n        if d:IsA(\"Script\")then counts.scripts+=1 end\n        if d:IsA(\"ModuleScript\")then counts.moduleScripts+=1 end\n        if d:IsA(\"LocalScript\")then counts.localScripts+=1 end\n        if d:IsA(\"Sound\")then counts.sounds+=1 end\n        if d:IsA(\"Animation\")then counts.animations+=1 end\n        if d:IsA(\"Humanoid\")then counts.humanoids+=1 end\n        if d:IsA(\"Attachment\")then counts.attachments+=1 end\n        if d:IsA(\"Constraint\")then counts.constraints+=1 end\n        if d:IsA(\"ProximityPrompt\")then counts.prompts+=1 end\n    end\n    item.counts=counts\n    item.top=top\n    local boxOk,cf,size=pcall(function() return model:GetBoundingBox() end)\n    if boxOk and size then\n        item.size={size.X,size.Y,size.Z}\n    end\n    model:Destroy()\n    return item\nend\nfor _,entry in ipairs(list)do\n    report[#report+1]=summarize(entry)\nend\nreturn HttpService:JSONEncode(report)\n";

const result=await execute(script);
console.log(JSON.stringify({stage:'dead-signal-asset-probe',result},null,2));