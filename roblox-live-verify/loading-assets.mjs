const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735', PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 let last;
 for(let i=0;i<8;i++){
  const res=await fetch(CLOUD+path,{
   method:body?'POST':'GET',
   headers:{'x-api-key':key,'content-type':'application/json'},
   body:body?JSON.stringify(body):undefined,
   signal:AbortSignal.timeout(60000)
  });
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
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
  if(Date.now()>deadline) throw new Error('timeout');
  await sleep(1200); task=await req(task.path);
 }
 if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task));
 const v=task?.output?.results?.[0];
 if(typeof v!=='string') return v??null;
 try{return JSON.parse(v)}catch{return v}
}
const luau=`
local Http=game:GetService("HttpService")
local first=game:GetService("ReplicatedFirst")
local controller=assert(first:FindFirstChild("SweanLoadingController"),"SweanLoadingController missing")
local assets=assert(first:FindFirstChild("LoadingCinematicAssets"),"LoadingCinematicAssets missing")
local tv=assert(assets:FindFirstChild("TV"),"TV model missing")
local mesa=assert(assets:FindFirstChild("Mesa"),"Mesa model missing")
local screen=assert(tv:FindFirstChild("Screen",true),"TV Screen part missing")

assert(controller:GetAttribute("CinematicInitialLoading")==true,"Initial loading cinematic flag missing")
assert(controller:GetAttribute("CinematicDuration")==10,"Cinematic duration is not 10 seconds")
assert(assets:GetAttribute("Duration")==10,"Loading asset duration metadata is not 10 seconds")
assert(controller:GetAttribute("TVAssetId")==421148437 and tv:GetAttribute("SourceAssetId")==421148437,"Wrong TV asset persisted")
assert(controller:GetAttribute("TableAssetId")==397786287 and mesa:GetAttribute("SourceAssetId")==397786287,"Wrong table asset persisted")

local source=controller.Source
assert(source:find("CINEMATIC_DURATION=10",1,true),"10-second initial timing source missing")
assert(source:find("LOGO_END=5",1,true),"5-second logo timing missing")
assert(source:find("screenNormal=Vector3.new(0,0,1)",1,true) and source:find("screenUp=Vector3.new(0,1,0)",1,true),"TV upright orientation correction missing")
assert(source:find("fitDistance",1,true) and source:find("cameraDistance",1,true),"Adaptive TV camera framing missing")
assert(not source:find("tv:ScaleTo(1.5)",1,true) and source:find("tv:ScaleTo(1.04)",1,true),"TV is still stretched by the old scale")
assert(source:find('hand.Name="HandInsideTelevision"',1,true) and source:find("cameraImpact",1,true),"Hand/impact loading animation missing")
assert(source:find('logo.Texture="rbxassetid://99002027743613"',1,true),"Game logo missing from TV")
assert(source:find("waitUntil(9.05)",1,true),"10-second final fade cue missing")

local clientSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SurvivalClient"),"SurvivalClient missing").Source
assert(clientSource:find('matchTV.Name="MatchLoadingTelevision"',1,true),"Match loading TV missing")
assert(clientSource:find('gameCornerTitle=text(loading,"GameCornerTitle","SUVIVERS"',1,true),"SUVIVERS top-right loading label missing")
assert(clientSource:find("task.delay(5,function()",1,true),"Five-second roster reveal missing")
assert(clientSource:find("loadingStarted+10",1,true),"Match loading is not held for at least 10 seconds")
assert(clientSource:find("KillerPlayerName",1,true) and clientSource:find("LoadingRoster",1,true),"Killer/roster loading reveal missing")

return Http:JSONEncode({
 ok=true,
 version=game.PlaceVersion,
 cinematicSeconds=controller:GetAttribute("CinematicDuration"),
 tvAsset=tv:GetAttribute("SourceAssetId"),
 tableAsset=mesa:GetAttribute("SourceAssetId"),
 screenSize=tostring(screen.Size),
 uprightCorrection=true,
 adaptiveFraming=true,
 stretchedScaleRemoved=true,
 matchTV=true,
 namesRevealAt=5,
 matchMinimumSeconds=10
})
`;
const result=await execute(luau);
console.log('LOADING_CINEMATIC_LIVE_VERIFY',JSON.stringify(result));
if(!result || result.ok!==true) throw new Error('Published loading cinematic verification failed');
// verify version 196 metadata
