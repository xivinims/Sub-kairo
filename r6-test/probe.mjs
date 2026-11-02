import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
const universe=9421311218,place=118064584465155;
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
const base='https://apis.roblox.com/',cloud=base+'cloud/v2/';
async function api(url,method='GET',body){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(240000)});
 const raw=await response.text();let data;try{data=JSON.parse(raw)}catch{data={message:raw.slice(0,500)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(data));return data;
}
async function privateOnly(){
 const info=await api(`https://develop.roblox.com/v1/universes/${universe}`);
 if(info.isActive!==false)throw Error('Experience is not confirmed private; patch stopped');
}
async function execute(script,version){
 let job=await api(cloud+`universes/${universe}/places/${place}/${version?'versions/'+version+'/':''}luau-execution-session-tasks`,'POST',{timeout:'300s',script});
 const until=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(job.state)){
  if(Date.now()>until)throw Error('Native task timeout');await new Promise(r=>setTimeout(r,1500));job=await api(cloud+job.path);
 }
 if(job.state!=='COMPLETE'||job.error)throw Error('Native task failed: '+JSON.stringify(job.error||job));
 const value=job.output?.results?.[0];return typeof value==='string'?JSON.parse(value):value;
}
async function publish(bytes){
 const response=await fetch(base+`universes/v1/${universe}/places/${place}/versions?versionType=Published`,{method:'POST',headers:{'x-api-key':key,'content-type':'application/octet-stream'},body:bytes,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();if(!response.ok)throw Error('Place upload HTTP '+response.status+': '+raw.slice(0,500));return JSON.parse(raw);
}
async function main(){
 const result=await execute(`local list={};local n=0;for _,x in ipairs(game:GetDescendants()) do if x:IsA('LuaSourceContainer') and x:GetAttribute('OriginalId') then n+=1;table.insert(list,{id=x:GetAttribute('OriginalId'),path=x:GetFullName()}) end end;return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion,count=n,list=list})`,269);
 console.log('NATIVE_INVENTORY '+JSON.stringify(result));
 const verify=(await fs.readFile('r6-test/verify.luau','utf8')).replace("assert(count==132,'Imported script count changed')",'');
 console.log('DIAGNOSTIC_TEST '+JSON.stringify(await execute(verify,269)));
}
main().catch(error=>{console.error(String(error.stack||error).split(key).join('[REDACTED]'));process.exitCode=1;});
