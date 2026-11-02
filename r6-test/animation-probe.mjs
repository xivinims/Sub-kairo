// Read-only candidate animation probe in the private R6 test experience.
// Tests the ACTUAL Roblox assets before installing locomotion; no place update.
import fs from "node:fs/promises";
const universe = 9421311218, place = 118064584465155;
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error("ROBLOX_API_KEY missing");
const ids = [45828430,1721906652,15256643328,11872298900,102425446560812,17747141146,11605590459,11123175969,
17747185294,17747187834,11605578996,180435571,180435792,
180426354,125750702,180436148,180436334,178130996];
const script = `
local Players=game:GetService("Players")
local model=Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R6)
model.Name="CandidateAnimationProbeR6"
model.Parent=workspace
local humanoid=model:FindFirstChildOfClass("Humanoid")
local animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",humanoid)
local tracks={}
for _,id in ipairs({${ids.join(",")}}) do
 local asset=Instance.new("Animation")
 asset.AnimationId="rbxassetid://"..tostring(id)
 local ok,track=pcall(function()return animator:LoadAnimation(asset)end)
 if ok then track:Play(0,0.01,1) end
 tracks[tostring(id)]={ok=ok,track=ok and track or nil}
end
task.wait(6)
local result={}
for id,data in pairs(tracks) do
 result[id]={loaded=data.ok,length=data.track and data.track.Length or 0}
 if data.track then data.track:Stop(0);data.track:Destroy() end
end
model:Destroy()
return game:GetService("HttpService"):JSONEncode(result)
`;
async function api(url,method="GET",body) {
 const r=await fetch(url,{method,headers:{"x-api-key":key,"Content-Type":"application/json"},body:body&&JSON.stringify(body),signal:AbortSignal.timeout(90000)});
 const data=await r.json();
 if(!r.ok) throw Error("Roblox HTTP "+r.status+" "+JSON.stringify(data).slice(0,500));
 return data;
}
const cloud="https://apis.roblox.com/cloud/v2/";
let task=await api(cloud+`universes/${universe}/places/${place}/luau-execution-session-tasks`,"POST",{timeout:"180s",script});
const deadline=Date.now()+210000;
while(["QUEUED","PROCESSING","PENDING"].includes(task.state)){
 if(Date.now()>deadline)throw Error("Probe timeout");
 await new Promise(r=>setTimeout(r,1500));
 task=await api(cloud+task.path);
}
if(task.state!=="COMPLETE"||task.error)throw Error("Probe error: "+JSON.stringify(task.error||task).slice(0,1500));
const raw=task.output?.results?.[0];
const results=typeof raw==="string"?JSON.parse(raw):raw;
if(!results||typeof results!=="object")throw Error("Empty Roblox animation result");
await fs.writeFile("r6-test/animation-probe.json",JSON.stringify(results,null,2)+"\n");
console.log("R6_ANIMATION_PROBE "+JSON.stringify(results));
