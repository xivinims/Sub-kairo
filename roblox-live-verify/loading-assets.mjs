const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735', PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 const res=await fetch(CLOUD+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(60000)});
 const raw=await res.text(); let data; try{data=JSON.parse(raw)}catch{data={raw}};
 if(!res.ok) throw new Error('HTTP '+res.status+': '+JSON.stringify(data)); return data;
}
async function execute(script){
 let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
 const deadline=Date.now()+180000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){if(Date.now()>deadline) throw new Error('timeout'); await sleep(1200); task=await req(task.path);}
 if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task));
 const v=task?.output?.results?.[0]; if(typeof v!=='string') return v??null; try{return JSON.parse(v)}catch{return v}
}
const luau=`
local Http=game:GetService("HttpService")
local AssetService=game:GetService("AssetService")
local out={}
for _,id in ipairs({421148437,397786287}) do
 local asset=AssetService:LoadAssetAsync(id)
 local row={id=id,children={},parts={}}
 for _,c in ipairs(asset:GetChildren()) do table.insert(row.children,{name=c.Name,class=c.ClassName}) end
 for _,d in ipairs(asset:GetDescendants()) do
  if d:IsA("BasePart") then
   local cf,size
   if d:IsA("Model") then cf,size=d:GetBoundingBox() end
   table.insert(row.parts,{name=d.Name,class=d.ClassName,size=tostring(d.Size),cf=tostring(d.CFrame),trans=d.Transparency,material=tostring(d.Material),color=tostring(d.Color)})
  end
 end
 table.sort(row.parts,function(a,b)return a.name<b.name end)
 while #row.parts>80 do table.remove(row.parts) end
 table.insert(out,row)
 asset:Destroy()
end
return Http:JSONEncode(out)
`;
const result=await execute(luau);
console.log('LOADING_ASSET_DIAG',JSON.stringify(result));
