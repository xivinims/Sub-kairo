import fs from 'node:fs/promises';
const key=process.env.ROBLOX_API_KEY;const base='https://apis.roblox.com';
const evidence={};
for(const [name,url,body]of[
 ['universe','https://games.roblox.com/v1/games?universeIds=9421311218',null],
 ['engine',base+'/cloud/v2/universes/9421311218/places/118064584465155/luau-execution-session-tasks',{script:'return {placeId=game.PlaceId, version=game.PlaceVersion, creatorId=game.CreatorId, creatorType=game.CreatorType.Name, engine=true}'}]
]){
 try{const r=await fetch(url,{method:body?'POST':'GET',headers:body?{'x-api-key':key,'content-type':'application/json'}:{},body:body?JSON.stringify(body):undefined});const data=await r.json();evidence[name]={status:r.status,data};}catch(e){evidence[name]={error:String(e)}}
}
if(evidence.engine?.data?.path){let task=evidence.engine.data;for(let i=0;i<40&&task.state==='PROCESSING';i++){await new Promise(r=>setTimeout(r,1500));const r=await fetch(base+'/cloud/v2/'+task.path,{headers:{'x-api-key':key}});task=await r.json();}evidence.engine.result=task;}
await fs.writeFile('/tmp/nb-assets/access-probe.json',JSON.stringify(evidence,null,2));
console.log('Access probe',JSON.stringify(evidence));
