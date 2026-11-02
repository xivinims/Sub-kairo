// Read-only R6 run animation check: the user's three exact IDs.
// This must not block gameplay publication if Roblox's task queue is busy.
import fs from "node:fs/promises";
const key=process.env.ROBLOX_API_KEY;
if(!key) throw Error("ROBLOX_API_KEY missing");
const ids=[72900620651167,107952007153363,93499989310243,656118852];
const code=`
local Players=game:GetService("Players")
local model=Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R6)
model.Parent=workspace
local animator=model.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",model.Humanoid)
local tracks={}
for _,id in ipairs({${ids.join(",")}}) do
 local anim=Instance.new("Animation")
 anim.AnimationId="rbxassetid://"..tostring(id)
 local ok,track=pcall(function()return animator:LoadAnimation(anim)end)
 if ok and track then track:Play(0,0.02,1) end
 tracks[tostring(id)]={ok=ok,track=track}
end
task.wait(5)
local result={}
for id,v in pairs(tracks) do
 result[id]={loaded=v.ok,length=v.ok and v.track.Length or 0}
 if v.ok then v.track:Stop(0);v.track:Destroy() end
end
model:Destroy()
return game:GetService("HttpService"):JSONEncode(result)
`;
const cloud="https://apis.roblox.com/cloud/v2/";
async function api(path,method="GET",body) {
 const response=await fetch(cloud+path,{method,headers:{"x-api-key":key,"Content-Type":"application/json"},
  body:body&&JSON.stringify(body),signal:AbortSignal.timeout(45000)});
 const text=await response.text();let data;try{data=JSON.parse(text)}catch{data={message:text.slice(0,200)}}
 if(!response.ok)throw Error("R6 probe HTTP "+response.status+" "+JSON.stringify(data).slice(0,300));
 return data;
}
let output={};
try{
 let job=await api("universes/9421311218/places/118064584465155/luau-execution-session-tasks","POST",{timeout:"90s",script:code});
 const deadline=Date.now()+98000;
 while(["QUEUED","PENDING","PROCESSING"].includes(job.state)){
  if(Date.now()>deadline)throw Error("Roblox animation probe budget expired");
  await new Promise(r=>setTimeout(r,1500));
  const route = job.path.startsWith("/cloud/v2/") ? job.path.slice("/cloud/v2/".length) : job.path;
  job=await api(route);
 }
 if(job.state!=="COMPLETE"||job.error)throw Error("R6 probe task "+JSON.stringify(job.error||job.state).slice(0,250));
 const raw=job.output?.results?.[0];
 output=typeof raw==="string"?JSON.parse(raw):raw;
 if(!output||typeof output!=="object")throw Error("Empty run probe");
}catch(error){
 console.warn("RUN_PROBE_UNAVAILABLE "+String(error.message).slice(0,400));
}
await fs.writeFile("r6-test/forbidden-or-available-run-ids.json",JSON.stringify(output,null,2)+"\n");
console.log("R6_RUN_ANIMATIONS "+JSON.stringify(output));
