// Verify the user's R6 combat animation IDs INSIDE their actual Roblox universe.
// Safe fallback: an unavailable Roblox task records no usable animations;
// imported models/scripts are never blindly executed.
import fs from "node:fs/promises";
const key=process.env.ROBLOX_API_KEY;
if(!key) throw Error("ROBLOX_API_KEY missing");
const ids=[
10469493270,10469630950,10469639222,10469643643,
10470389827,10479335397,10491993682,10503381238,
10470104242,12983333733,10466974800,2515090838,
13874028312
];
const code=`
local Players=game:GetService("Players")
local model=Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
model.Name="R6CombatAssetsProbe"
model.Parent=workspace
local hum=model.Humanoid
local animator=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
local tracks={}
for _,id in ipairs({${ids.join(",")}}) do
 local clip=Instance.new("Animation")
 clip.AnimationId="rbxassetid://"..tostring(id)
 local ok,track=pcall(function()return animator:LoadAnimation(clip)end)
 if ok and track then track.Priority=Enum.AnimationPriority.Action;track:Play(0,0.01,1) end
 tracks[tostring(id)]={ok=ok,track=ok and track or nil}
end
task.wait(6)
local result={}
for id,value in pairs(tracks) do
 local len=value.track and value.track.Length or 0
 result[id]={loaded=value.ok,length=len,usable=value.ok and len>0.07}
 if value.track then value.track:Stop(0);value.track:Destroy() end
end
model:Destroy()
return game:GetService("HttpService"):JSONEncode(result)
`;
const cloud="https://apis.roblox.com/cloud/v2/";
async function api(route,method="GET",body){
 const url=route.startsWith("https://")?route:cloud+route.replace(/^\/cloud\/v2\//,"");
 const r=await fetch(url,{method,headers:{"x-api-key":key,"Content-Type":"application/json"},
 body:body&&JSON.stringify(body),signal:AbortSignal.timeout(45000)});
 const raw=await r.text();let obj;try{obj=JSON.parse(raw)}catch{obj={message:raw.slice(0,300)}}
 if(!r.ok)throw Error("R6 combat probe HTTP "+r.status+" "+JSON.stringify(obj).slice(0,280));
 return obj;
}
let result={};
try{
 let task=await api("universes/9421311218/places/118064584465155/luau-execution-session-tasks","POST",
  {timeout:"90s",script:code});
 const until=Date.now()+112000;
 while(["QUEUED","PENDING","PROCESSING"].includes(task.state)){
  if(Date.now()>until)throw Error("Roblox combat probe task timeout");
  await new Promise(r=>setTimeout(r,1800));
  task=await api(task.path);
 }
 if(task.state!=="COMPLETE"||task.error)throw Error("Native combat probe: "+JSON.stringify(task.error||task.state));
 let raw=task.output?.results?.[0];
 result=typeof raw==="string"?JSON.parse(raw):raw;
 if(!result||typeof result!=="object")throw Error("Missing combat probe result");
}catch(e){
 console.warn("R6_COMBAT_PROBE_UNAVAILABLE "+String(e).slice(0,400));
}
await fs.writeFile("r6-test/combat-probe.json",JSON.stringify(result,null,2)+"\n");
console.log("R6_COMBAT_PROBE "+JSON.stringify(result));
