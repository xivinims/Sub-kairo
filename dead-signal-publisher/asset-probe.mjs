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
if(trigger.trim().startsWith('cassette-status-audit')){
 const key=process.env.ROBLOX_API_KEY;
 const response=await fetch('https://apis.roblox.com/assets/v1/assets/82560036333396',{headers:{'x-api-key':key}});
 const body=await response.text();
 console.log('CASSETTE_ASSET_STATUS '+JSON.stringify({http:response.status,body:body.slice(0,3500)}));
}else if(trigger.trim().startsWith('cassette-image-upload')){
 await import('./cassette-image-upload.mjs');
}else if(trigger.trim().startsWith('chapter2-map-audit')){
 const fs=await import('node:fs/promises');
 const {execFileSync}=await import('node:child_process');
 const {createHash}=await import('node:crypto');
 const key=process.env.ROBLOX_API_KEY;
 const [metaResponse,deliveryResponse]=await Promise.all([
  fetch('https://economy.roblox.com/v2/assets/3251795155/details'),
  fetch('https://apis.roblox.com/asset-delivery-api/v1/assetId/3251795155',{headers:{'x-api-key':key}}),
 ]);
 const metadata=await metaResponse.json().catch(()=>({}));
 const delivery=await deliveryResponse.json().catch(()=>({}));
 let file=null;
 const location=delivery.location||delivery.locations?.[0]?.location;
 if(location){
  const downloaded=await fetch(location);
  const bytes=Buffer.from(await downloaded.arrayBuffer());
  file={http:downloaded.status,contentType:downloaded.headers.get('content-type'),bytes:bytes.length,magic:bytes.subarray(0,24).toString('hex')};
  if(downloaded.ok&&bytes.length>100000){
   await fs.writeFile('/tmp/chapter2-map.rbxl',bytes);
   const archive=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
   const zip=Buffer.from(await archive.arrayBuffer());
   if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum');
   await fs.writeFile('/tmp/chapter2-lune.zip',zip);
   execFileSync('unzip',['-q','-o','/tmp/chapter2-lune.zip','-d','/tmp/chapter2-lune']);
   await fs.chmod('/tmp/chapter2-lune/lune',0o755);
   execFileSync('/tmp/chapter2-lune/lune',['run','chapter2-map-inspect.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
  }
 }
 const summary={assetId:3251795155,metadataHttp:metaResponse.status,metadata:{name:metadata.Name,description:metadata.Description,assetTypeId:metadata.AssetTypeId,creator:metadata.Creator},deliveryHttp:deliveryResponse.status,delivery:{assetType:delivery.assetType,assetId:delivery.assetId,versionNumber:delivery.versionNumber,error:delivery.errors?.[0]?.message},file};
 console.log('CHAPTER2_MAP_AUDIT '+JSON.stringify(summary));
}else if(trigger.trim().startsWith('cassette-creator-audit')){
 const luau="local HttpService=game:GetService('HttpService')\nreturn HttpService:JSONEncode({creatorId=game.CreatorId,creatorType=tostring(game.CreatorType),universe=game.GameId})";
 console.log('CASSETTE_CREATOR_RESULT '+JSON.stringify(await execute(luau)));
}else if(trigger.trim().startsWith('credits-author-audit')){
 const fs=await import('node:fs/promises');
 const script=await fs.readFile(new URL('./credits-author-audit.luau',import.meta.url),'utf8');
 console.log('CREDITS_AUTHOR_RESULT '+JSON.stringify(await execute(script)));
}else if(trigger.trim().startsWith('emote-id-audit')){
 const fs=await import('node:fs/promises');
 const script=await fs.readFile(new URL('./emote-resolution-audit.luau',import.meta.url),'utf8');
 console.log('EMOTE_RESOLVE_RESULT '+JSON.stringify(await execute(script)));
}else if(trigger.trim().startsWith('blackhole-geometry-audit')){
 await import('./blackhole-geometry-audit.mjs');
}else if(trigger.trim().startsWith('original-native-release')){
 await import('./original-native-publish.mjs');
}else if(trigger.trim().startsWith('mansion-native-release')){
 await import('./mansion-native-publish.mjs');
}else if(trigger.trim().startsWith('islands-door-audit')){
 await import('./islands-door-audit.mjs');
}else if(trigger.trim().startsWith('islands-native-release')){
 await import('./islands-native-publish.mjs');
}else if(trigger.trim().startsWith('islands-')){
 await import('./islands-publish.mjs');
}else if(trigger.trim().startsWith('forest-expansion-publish')){
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
