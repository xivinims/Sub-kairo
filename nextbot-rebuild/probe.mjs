import fs from 'node:fs/promises';
const key=process.env.ROBLOX_API_KEY;const base='https://apis.roblox.com';
const evidence={};
for(const [name,url,body]of[
 ['universe','https://games.roblox.com/v1/games?universeIds=9421311218',null],
 ['engine',base+'/cloud/v2/universes/9421311218/places/118064584465155/luau-execution-session-tasks',{script:'return {placeId=game.PlaceId, version=game.PlaceVersion, engine=true}'}]
]){
 try{const r=await fetch(url,{method:body?'POST':'GET',headers:body?{'x-api-key':key,'content-type':'application/json'}:{},body:body?JSON.stringify(body):undefined});const data=await r.json();evidence[name]={status:r.status,data};}catch(e){evidence[name]={error:String(e)}}
}
await fs.writeFile('/tmp/nb-assets/access-probe.json',JSON.stringify(evidence,null,2));
console.log('Access probe',JSON.stringify(evidence));
