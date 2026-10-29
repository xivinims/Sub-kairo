const UNIVERSE_ID='9421311218';
const PLACE_ID='118064584465155';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/'+UNIVERSE_ID+'/places/'+PLACE_ID+'/';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function api(url,options={}){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(url,{
    method:options.method||'GET',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:options.body,
    signal:AbortSignal.timeout(240000),
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}};
  if(!res.ok) throw new Error('HTTP '+res.status+': '+raw.slice(0,1400));
  return data;
}

async function execute(script){
  let task=await api(CLOUD+TARGET+'luau-execution-session-tasks',{
    method:'POST',
    body:JSON.stringify({timeout:'300s',script})
  });
  const deadline=Date.now()+420000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('probe timeout');
    await sleep(1400);
    task=await api(CLOUD+task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task.error||task));
  const value=task.output?.results?.[0];
  if(typeof value==='string'){try{return JSON.parse(value)}catch{return {raw:value}}}
  return value;
}

const trigger=await (await import('node:fs/promises')).readFile(new URL('./asset-probe.trigger',import.meta.url),'utf8');
if(trigger.trim().startsWith('forest-expansion-publish')){
 await import('./forest-expansion.mjs');
}else if(trigger.trim().startsWith('forest-place-audit')){
 await import('./forest-place-audit.mjs');
}else if(trigger.trim().startsWith('forest-expansion-audit')){
 const fs=await import('node:fs/promises');console.log(JSON.stringify(await execute(await fs.readFile(new URL('./forest-expansion-audit.luau',import.meta.url),'utf8'))));
}else if(trigger.trim().startsWith('wind-audit')){
 const fs=await import('node:fs/promises');console.log(JSON.stringify(await execute(await fs.readFile(new URL('./wind-audit.luau',import.meta.url),'utf8'))));
}else if(trigger.trim().startsWith('native-grass')){
  await import('./native-grass.mjs');
}else if(trigger.trim().startsWith('still-here-metadata')){
  await import('./metadata.mjs');
}else if(trigger.trim().startsWith('spring-verify-staged')){
  await import('./conversion/verify-staged.mjs');
}else if(trigger.trim().startsWith('spring-convert-animations')){
  await import('./conversion/upload-animations.mjs');
}else if(trigger.trim().startsWith('spring-convert-')){
  await import('./conversion/upload-spring.mjs');
}else{
const script = await (await import('node:fs/promises')).readFile(new URL('./visual-asset-probe.luau', import.meta.url),'utf8');

const result=await execute(script);
console.log(JSON.stringify({stage:'dead-signal-asset-probe',result},null,2));

}
