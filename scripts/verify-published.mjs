import {writeFile} from 'node:fs/promises';
const base='https://apis.roblox.com/cloud/v2/';
const target='universes/9421311218/places/118064584465155/';
const key=process.env.ROBLOX_API_KEY;
if(!key) throw new Error('Missing ROBLOX_API_KEY');
async function api(path,body) {
 const r=await fetch(base+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(60000)});
 if(!r.ok) throw new Error(`Roblox engine verification HTTP ${r.status}`);
 return r.json();
}
const script=`
assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Wrong place")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Campaign=require(RS.Shared.Campaign)
assert(Config.Chapter=="DEAD SIGNAL")
assert(#Config.Sectors==7)
local World=require(game:GetService("ServerScriptService").BrambleServer.World)
World.build()
assert(workspace:GetAttribute("BrambleWorldReady")==true,"World not ready")
local targets=0
for id,part in pairs(World.Targets) do
 assert(part:IsA("BasePart") and part:IsDescendantOf(workspace),id)
 assert(part:FindFirstChildOfClass("ProximityPrompt"),id)
 targets+=1
end
assert(targets==76,"Wrong target count")
for sector=1,7 do
 assert(typeof(World.Spawns[sector])=="Vector3","Missing spawn")
 assert(typeof(World.EnemySpawns[sector])=="Vector3","Missing enemy spawn")
end
local enemy=World.createEnemy(workspace,World.EnemySpawns[4])
assert(enemy:IsA("Model") and enemy:FindFirstChildWhichIsA("BasePart",true),"Enemy failed")
enemy:Destroy()
local state=Campaign.new()
assert(state.sector==1 and not state.finished)
return game:GetService("HttpService"):JSONEncode({ok=true,placeVersion=game.PlaceVersion,targets=targets,sectors=#Config.Sectors,worldReady=true,enemyConstructed=true,clientPlaytested=false})
`;
let task=await api(target+'luau-execution-session-tasks',{timeout:'120s',script});
const deadline=Date.now()+180000;
while(['QUEUED','PENDING','PROCESSING'].includes(task.state)) {
 if(Date.now()>deadline || !String(task.path).startsWith(target)) throw new Error('Engine task timeout or incorrect target');
 await new Promise(r=>setTimeout(r,2000));task=await api(task.path);
}
if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify({state:task.state,error:task.error}));
let receipt=task.output?.results?.[0];if(typeof receipt==='string') receipt=JSON.parse(receipt);
if(!receipt?.ok) throw new Error('Engine did not confirm success');
await writeFile('dist/engine-verification.json',JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt,null,2));
