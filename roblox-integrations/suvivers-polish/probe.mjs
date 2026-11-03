const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(60000)});
  const raw=await res.text(); let data; try{data=JSON.parse(raw)}catch{data={raw}};
  if(!res.ok) throw new Error('HTTP '+res.status+': '+raw.slice(0,1200)); return data;
}
async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+300000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){if(Date.now()>deadline) throw new Error('timeout');await sleep(1500);task=await req(task.path);}
  if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task.error||task));
  const v=task?.output?.results?.[0]; if(typeof v!=='string') return v??null; try{return JSON.parse(v)}catch{return v}
}
const script=String.raw`
local function describe(model)
 local parts={}
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") then table.insert(parts,{name=p:GetFullName(),size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},collide=p.CanCollide,transparency=p.Transparency,attributes=p:GetAttributes()}) end
 end
 return parts
end
local assets=game.ReplicatedFirst.LoadingCinematicAssets
return game.HttpService:JSONEncode({version=game.PlaceVersion,tv=describe(assets.TV),mesa=describe(assets.Mesa),house=describe(workspace.JediLibrary.House)})
`;
execute(script).then(r=>console.log('GEOMETRY_PROBE '+JSON.stringify(r))).catch(e=>{console.error(e.stack||e);process.exit(1)});
