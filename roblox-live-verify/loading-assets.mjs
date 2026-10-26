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
local first=game:GetService("ReplicatedFirst")
local controller=assert(first:FindFirstChild("SweanLoadingController"),"SweanLoadingController missing")
local assets=assert(first:FindFirstChild("LoadingCinematicAssets"),"LoadingCinematicAssets missing")
local tv=assert(assets:FindFirstChild("TV"),"TV model missing")
local mesa=assert(assets:FindFirstChild("Mesa"),"Mesa model missing")
local screen=assert(tv:FindFirstChild("Screen",true),"TV Screen part missing")
assert(controller:GetAttribute("CinematicInitialLoading")==true,"CinematicInitialLoading flag missing")
assert(controller:GetAttribute("CinematicDuration")==8,"Cinematic duration is not 8 seconds")
assert(controller:GetAttribute("TVAssetId")==421148437,"Wrong TV asset persisted")
assert(controller:GetAttribute("TableAssetId")==397786287,"Wrong table asset persisted")
assert(assets:GetAttribute("TVAssetId")==421148437 and assets:GetAttribute("TableAssetId")==397786287,"Loading asset folder IDs wrong")
assert(tv:GetAttribute("SourceAssetId")==421148437 and mesa:GetAttribute("SourceAssetId")==397786287,"Loading model source IDs missing")
local source=controller.Source
assert(source:find("CINEMATIC_DURATION=8",1,true),"8-second timing source missing")
assert(source:find("LOGO_END=4",1,true),"4-second logo cutoff missing")
assert(source:find('hand.Name="HandInsideTelevision"',1,true),"Hand-in-TV scene missing")
assert(source:find("cameraImpact",1,true),"Impact camera shake missing")
assert(source:find('logo.Texture="rbxassetid://99002027743613"',1,true),"Game logo texture missing from TV")
assert(source:find("waitUntil(7.05)",1,true),"Final fade cue missing")
assert(source:find("screen.Size.X/2+.028",1,true),"Logo is not attached to TV glass")
return Http:JSONEncode({
 ok=true,
 version=game.PlaceVersion,
 tvAsset=tv:GetAttribute("SourceAssetId"),
 tableAsset=mesa:GetAttribute("SourceAssetId"),
 screen=screen.Name,
 cinematicSeconds=controller:GetAttribute("CinematicDuration"),
 logoUntil=4,
 handImpact=true,
 finalFade=true
})
`;
const result=await execute(luau);
console.log('LOADING_CINEMATIC_LIVE_VERIFY',JSON.stringify(result));
if(!result || result.ok!==true) throw new Error('Published loading cinematic verification failed');
