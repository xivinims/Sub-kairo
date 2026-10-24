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
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer").StarterPlayerScripts
local SG=game:GetService("StarterGui")
local RF=game:GetService("ReplicatedFirst")
local survival=assert(RS:FindFirstChild("Survival"))
local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local server=assert(SSS:FindFirstChild("SurvivalServer"))
local client=assert(SP:FindFirstChild("SurvivalClient"))
local builder=assert(SSS:FindFirstChild("MapBuilder"))
local menu=assert(SG.TomiaszMenu:FindFirstChild("MenuController"))
local loading=assert(RF:FindFirstChild("SweanLoadingController"))
local assets=assert(game.ServerStorage:FindFirstChild("SurvivalAssets"))
local report={
 placeVersion=game.PlaceVersion,
 build=survival:GetAttribute("Version"),
 lobbySource=lobby:GetAttribute("SourceAssetId"),
 survivorRig=survival:GetAttribute("SurvivorRig"),
 runtimeRig=RS.SweanRuntime:GetAttribute("SurvivorRig"),
 lobbyHeldOpen=lobby.Door:GetAttribute("HeldOpen"),
 automaticThemeAbsent=survival:FindFirstChild("JasonTheme")==nil and game:GetService("SoundService"):FindFirstChild("LocalJasonTheme")==nil,
 r6UserAppearance=server.Source:find("GetHumanoidDescriptionFromUserIdAsync",1,true)~=nil and server.Source:find("Enum.HumanoidRigType.R6",1,true)~=nil,
 playerRoster=client.Source:find("PlayerRoster",1,true)~=nil,
 spectatorNoSelf=client.Source:find("Spectator UI must",1,true)==nil and client.Source:find("spectate.Visible=false",1,true)~=nil,
 fakeArenaDoorAbsent=builder.Source:find("InvisibleMarker",1,true)~=nil and builder.Source:find('smallPart(entrance,"Left"',1,true)==nil,
 winnerActualKiller=client.Source:find("WinnerPursuer",1,true)~=nil,
 finalSurvivorScene=client.Source:find("VictorySurvivor",1,true)~=nil,
 doorsVictoryScene=client.Source:find("VictoryDoorsScene",1,true)~=nil,
 loadingLogoOnly=loading:GetAttribute("LogoOnlyLoading")==true,
 menuClosePortrait=menu.Source:find("ClosePortrait",1,true)~=nil,
 menuDelayedBlackout=menu.Source:find("HorrorBlackout",1,true)~=nil,
 mapCount=#assets.Maps:GetChildren(),
 killerCount=#assets.Killers:GetChildren(),
 maps={}
}
for _,map in ipairs(assets.Maps:GetChildren()) do
 table.insert(report.maps,{name=map.Name,source=map:GetAttribute("SourceAssetId"),killerClearance=map:GetAttribute("KillerSpawnClearance"),arrivalCount=#map.ArrivalSpawns:GetChildren(),safeCount=#map.SafePoints:GetChildren()})
end
return HttpService:JSONEncode(report)
`;
execute(script).then(r=>console.log('SURVIVORS_POLISH_PROBE '+JSON.stringify(r))).catch(e=>{console.error(e.stack||e);process.exit(1)});
