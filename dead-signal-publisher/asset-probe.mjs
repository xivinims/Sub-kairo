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
 const script=`local H=game:GetService('HttpService')
local ok,root=pcall(function() return game:GetService('InsertService'):LoadAsset(3251795155) end)
if not ok then return H:JSONEncode({ok=false,error=tostring(root)}) end
local counts={parts=0,models=0,folders=0,scripts=0,localscripts=0,modules=0,prompts=0,lights=0,decals=0,meshes=0}
local names={}
for _,item in ipairs(root:GetDescendants()) do
 if item:IsA('BasePart') then counts.parts+=1 end
 if item:IsA('Model') then counts.models+=1 end
 if item:IsA('Folder') then counts.folders+=1 end
 if item:IsA('Script') then counts.scripts+=1 end
 if item:IsA('LocalScript') then counts.localscripts+=1 end
 if item:IsA('ModuleScript') then counts.modules+=1 end
 if item:IsA('ProximityPrompt') then counts.prompts+=1 end
 if item:IsA('Light') then counts.lights+=1 end
 if item:IsA('Decal') or item:IsA('Texture') or item:IsA('SurfaceAppearance') then counts.decals+=1 end
 if item:IsA('MeshPart') or item:IsA('SpecialMesh') then counts.meshes+=1 end
end
for _,item in ipairs(root:GetChildren()) do table.insert(names,item.Name..' ['..item.ClassName..']') end
local bounds
if root:IsA('Model') then local okBox,cf,size=pcall(function() return root:GetBoundingBox() end);if okBox then bounds={x=size.X,y=size.Y,z=size.Z} end end
root:Destroy()
return H:JSONEncode({ok=true,name='Light Bulb Reillumination map',asset=3251795155,rootClass=root.ClassName,children=names,counts=counts,bounds=bounds})`;
 const result=await execute(script);
 console.log('CHAPTER2_MAP_AUDIT '+JSON.stringify(result));
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
