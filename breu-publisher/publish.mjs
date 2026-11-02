import fs from 'node:fs/promises';
const universe=9421311218,place=118064584465155;
const base='https://apis.roblox.com/';
const cloud=base+'cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key) throw Error('ROBLOX_API_KEY missing in repository secrets');
const root=new URL('./',import.meta.url);
const read=name=>fs.readFile(new URL(name,root),'utf8');
async function api(url,{method='GET',body}={}){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(240000)});
 const raw=await response.text();let result;try{result=JSON.parse(raw)}catch{result={message:raw.slice(0,500)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(result));
 return result;
}
async function privateState(){
 const v=await api(cloud+`universes/${universe}`);
 if(v.visibility==='PRIVATE')return {private:true,name:v.displayName};
 const publicInfo=await api(`https://develop.roblox.com/v1/universes/${universe}`);
 if(typeof publicInfo.isActive!=='boolean')throw Error('Roblox did not expose a verifiable privacy status');
 return {private:publicInfo.isActive===false,name:v.displayName};
}
async function requirePrivate(){
 const before=await privateState();
 if(!before.private){
  await api(base+`legacy-develop/v1/universes/${universe}/deactivate`,{method:'POST',body:{}});
 }
 for(let i=0;i<6;i++){
  const current=await privateState();if(current.private){console.log('BREU_PRIVACY_CONFIRMED '+JSON.stringify({universe,private:true,previousName:current.name}));return;}
  await new Promise(r=>setTimeout(r,2000));
 }
 throw Error('Privacy could not be confirmed; no BREU version will be published');
}
async function execute(script,input,version){
 let job=await api(cloud+`universes/${universe}/places/${place}/`+(version?`versions/${version}/`:'')+'luau-execution-session-tasks',{method:'POST',body:{timeout:'300s',script,binaryInput:input}});
 const deadline=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(job.state)){
  if(Date.now()>deadline)throw Error('Native execution timed out; check version before retrying');
  await new Promise(r=>setTimeout(r,1600));job=await api(cloud+job.path);
 }
 if(job.state!=='COMPLETE'||job.error)throw Error('Native task failed: '+JSON.stringify(job.error||job));
 const v=job.output?.results?.[0];return typeof v==='string'?JSON.parse(v):v;
}
async function main(){
 // This gate precedes every write to the place. No activation endpoint is called.
 await requirePrivate();
 if((await read('publish.trigger')).includes('inspect')){
  const verify=await read('verify.luau');
  const diagnostic=await execute('local result={version=game.PlaceVersion,build=workspace:GetAttribute("BreuBuild"),scripts={}}\nfor _,v in ipairs(game:GetDescendants()) do if v:IsA("LuaSourceContainer") then table.insert(result.scripts,v:GetFullName()) end end\nlocal ok,value=pcall(function()\n'+verify+'\nend)\nresult.verified=ok;result.detail=tostring(value)\nreturn game:GetService("HttpService"):JSONEncode(result)');
  console.log('BREU_LIVE_DIAGNOSTIC '+JSON.stringify(diagnostic));return;
 }
 const baseline=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,gameId=game.GameId,placeId=game.PlaceId})');
 if(baseline.gameId!==universe||baseline.placeId!==place)throw Error('Wrong target');
 console.log('BREU_BASELINE '+JSON.stringify(baseline));
 const bytes=await fs.readFile(new URL('payload.rbxm',root));
 const upload=await api(cloud+`universes/${universe}/luau-execution-session-task-binary-inputs`,{method:'POST',body:{size:bytes.length}});
 const put=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bytes,signal:AbortSignal.timeout(120000)});
 if(!put.ok)throw Error('Binary upload failed: '+put.status);
 const install=await read('install.luau');const verify=await read('verify.luau');
 const checked=await execute(install+'\n'+verify,upload.path);
 if(!checked?.ok)throw Error('Preflight failed');
 console.log('BREU_NATIVE_PREFLIGHT '+JSON.stringify(checked));
 await requirePrivate();
 const fresh=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(fresh.version!==baseline.version)throw Error('Place changed during preflight; refusing overwrite');
 const guarded=`assert(game.PlaceVersion==${baseline.version},'Place changed before save')\n`+install;
 let saved=false;
 try{
  await execute(guarded+'\nlocal checked=(function()\n'+verify+'\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked',upload.path);
  saved=true;
  const live=await execute(verify);
  if(!live?.ok||live.version!==baseline.version+1)throw Error('Published verification mismatch: '+JSON.stringify(live));
  await requirePrivate();
  // Rename only after the tested build is saved. Visibility is never widened.
  await api(cloud+`universes/${universe}?updateMask=displayName,description`,{method:'PATCH',body:{displayName:'BREU [Playtest privado]',description:'Playtest privado de sobrevivência cooperativa. Em desenvolvimento por Aurivane Works.'}});
  await api(cloud+`universes/${universe}/places/${place}?updateMask=displayName,serverSize`,{method:'PATCH',body:{displayName:'BREU [Playtest privado]',serverSize:12}});
  try{await api(cloud+`universes/${universe}:restartServers`,{method:'POST',body:{}})}catch{console.log('BREU_NOTICE existing servers could not be restarted');}
  const report={...live,private:true,universe,place,rollbackVersion:baseline.version,url:`https://www.roblox.com/games/${place}/`};
  await fs.writeFile(new URL('publication.json',root),JSON.stringify(report,null,2));
  console.log('BREU_PRIVATE_RELEASE_COMPLETE '+JSON.stringify(report));
 }catch(error){
  console.error('BREU_POST_SAVE_ERROR '+String(error));
  if(saved){
   const latest=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
   if(latest.version===baseline.version+1){
    await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restored=true})',undefined,baseline.version);
    console.error('BREU_ROLLBACK restored version '+baseline.version+'; universe remains private');
   }
  }
  throw error;
 }
}
main().catch(error=>{console.error(String(error.stack||error).split(key).join('[REDACTED]'));process.exitCode=1;});
