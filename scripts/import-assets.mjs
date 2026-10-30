import {readFile,writeFile,mkdir} from 'node:fs/promises';
const key=process.env.ROBLOX_API_KEY;if(!key)throw new Error('Missing ROBLOX_API_KEY');
const revision='8c453e7731866e34a0986e3f2c12e64dd9f8c703';
const root=`https://raw.githubusercontent.com/DetectivePikaC2/PlaytimeStarterKit/${revision}/`;
const assets=[
 ["ScannerTextured","Model","dist/source-models/ScannerTextured.glb","model/gltf-binary"],
 ["PanelsTextured","Model","dist/source-models/PanelsTextured.glb","model/gltf-binary"],
 ["BatteryTextured","Model","dist/source-models/BatteryTextured.glb","model/gltf-binary"],
 ['WallColor','Image',root+'Decoration/Materials/Textures/Concrete/T_ConcreteWallRough_BC.png','image/png'],
 ['WallNormal','Image',root+'Decoration/Materials/Textures/Concrete/T_ConcreteWallRough_N.png','image/png'],
 ['FloorColor','Image','https://raw.githubusercontent.com/TheDevvDude/GrabPack-Unity-Project-1.1/44d8f7a52b632dea8c554da62cee63fd5e4b59f7/Assets/Story_2/Area2/CustomTextures/FactoryTiles.png','image/png'],
 ['FloorNormal','Image',root+'Decoration/Materials/Textures/Tiles/T_Tiles_N.png','image/png'],
 ['StudioLogo','Image','assets/branding/aurivane-works.png','image/png'],
 ['ChapterLogo','Image','assets/branding/dead-signal.png','image/png'],
 ['MenuLogo','Image','assets/branding/still-here.png','image/png'],
 ['CassetteChapter1','Image','assets/cassettes/chapter-1.jpg','image/jpeg'],
 ['CassetteMissionFound','Image','assets/cassettes/mission-found.jpg','image/jpeg'],
 ['CassetteYouAreMyTools','Image','assets/cassettes/you-are-my-tools.jpg','image/jpeg'],
 ['BlueHand','Model',root+'Player/Grabpack/Models/Hands/ch4handsblue.glb','model/gltf-binary'],
 ['RedHand','Model',root+'Player/Grabpack/Models/Hands/SM_SimpleHand.glb','model/gltf-binary'],
 ['BlueHandTexture','Image',root+'Player/Grabpack/Models/Hands/T_BlueHand_BC.png','image/png'],
 ['RedHandTexture','Image',root+'Player/Grabpack/Models/Hands/T_RedHand_BC.png','image/png'],
 ['GrabPack','Model',root+'Player/Grabpack/Models/grabpack_2_-_poppy_playtime_chapter_3.glb','model/gltf-binary'],
 ['Battery','Model',root+'Objects/Gameplay/Puzzles/Battery/Model/Ch1PowerCube.glb','model/gltf-binary'],
 ['BatteryHolder','Model',root+'Objects/Gameplay/Puzzles/Battery/Model/ch1BatteryHolder.glb','model/gltf-binary'],
 ['Scanner','Model',root+'Objects/Gameplay/Puzzles/Scanners/Models/scanners.glb','model/gltf-binary'],
 ['Doors','Model',root+'Objects/Gameplay/Gates/Model/doors_colour.glb','model/gltf-binary'],
 ['Panels','Model',root+'Objects/Gameplay/ControlPanel/Mesh/ConsolesPack.glb','model/gltf-binary'],
 ['Pipes','Model',root+'Decoration/Mesh/ch4AirPipes.glb','model/gltf-binary'],
 ['Storage','Model',root+'Decoration/Mesh/ch4storagepack.glb','model/gltf-binary'],
 ['BrickWalls','Model','https://raw.githubusercontent.com/TheDevvDude/GrabPack-Unity-Project-1.1/44d8f7a52b632dea8c554da62cee63fd5e4b59f7/Assets/Models/bricks.fbx','model/fbx'],
];
const existing=JSON.parse(await readFile('assets/imported-asset-ids.json','utf8'));
const manifest={creatorId:'8344738123',sourceRevision:revision,assets:{},errors:{}};
await mkdir('dist',{recursive:true});
async function request(url,options={}){
 const r=await fetch(url,{...options,headers:{...options.headers,'x-api-key':key},signal:AbortSignal.timeout(120000)});
 if(!r.ok)throw new Error(`Asset API HTTP ${r.status}: ${(await r.text()).slice(0,400).split(key).join('[REDACTED]')}`);
 return r.json();
}
for(const [name,assetType,source,type] of assets){
 try{
  if(existing[name]){manifest.assets[name]={id:existing[name],assetType,source,cached:true};continue;}
  const bytes=source.startsWith('https:')?new Uint8Array(await (await fetch(encodeURI(source))).arrayBuffer()):await readFile(source);
  if(bytes.length>20*1024*1024||bytes.length<500)throw new Error('Invalid source size');
  const form=new FormData();form.append('request',JSON.stringify({assetType,displayName:`Bramble Sprout - ${name}`,description:`Imported for Bramble's Sprout. Source: ${source}`,creationContext:{creator:{userId:'8344738123'}}}));
  form.append('fileContent',new Blob([bytes],{type}),source.split('/').at(-1));
  let operation=await request('https://apis.roblox.com/assets/v1/assets',{method:'POST',body:form});
  const deadline=Date.now()+150000;
  while(!operation.done){
   if(Date.now()>deadline)throw new Error('Import operation timeout');
   const path=operation.path;if(!/^operations\/[a-zA-Z0-9-]+$/.test(path))throw new Error('Invalid operation path');
   await new Promise(r=>setTimeout(r,1800));operation=await request('https://apis.roblox.com/assets/v1/'+path);
  }
  const id=Number(operation.response?.assetId);
  if(operation.error||!Number.isSafeInteger(id)||id<1)throw new Error(JSON.stringify(operation.error||operation).slice(0,600));
  manifest.assets[name]={id,assetType,source,bytes:bytes.length};console.log(JSON.stringify({name,id,assetType}));
 }catch(e){manifest.errors[name]=String(e.message);console.error(name+': '+e.message);}
 await writeFile('dist/imported-assets.json',JSON.stringify(manifest,null,2)+'\n');
 // A missing asset permission applies to every upload; do not repeat the same denied request.
 if(/HTTP (401|403)/.test(manifest.errors[name]||''))break;
}
if(Object.keys(manifest.errors).length)process.exitCode=1;
