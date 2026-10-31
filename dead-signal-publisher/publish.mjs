import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
try{
 if(process.argv.includes('--dry-run')){
  const files=['hotel-native-publish.mjs','hotel-build.mjs','hotel-assemble.luau','hotel-map-extract.luau','hotel-initialize.luau','hotel-file-verify.luau','hotel-verify.luau','mystery-ui-extract.luau','mystery-ui-client.luau','mystery-map-interactions.luau','settings-schema.luau','settings-server.luau','session-interface.luau','session-loading-client.luau','original-portuguese-text.luau'];
  const sources=await Promise.all(files.map(file=>fs.readFile(new URL('./'+file,import.meta.url),'utf8')));
  if(sources.some(source=>source.length<40))throw Error('Missing hotel release source');
  for(const [file,sha] of [
   ['assets/hotel/1940sHotelLobby.rbxm','03520ce828d3a652b58133424577df2fd1125497dc2a40d2b9fdc45b786b3700'],
   ['assets/ui/mystery-interface.rbxm','6e4b2f1e7454cc4b69148ef99c0e55497779e0d2944178c568ff02fc9641dd8f']
  ])if(createHash('sha256').update(await fs.readFile(new URL('./'+file,import.meta.url))).digest('hex')!==sha)throw Error('Asset checksum mismatch: '+file);
  console.log(JSON.stringify({dryRun:true,build:'still-here-hotel-mystery-ui-v1',sourceFiles:files.length,separateMapAndUI:true}));
 }else{
  const {runHotelRelease}=await import('./hotel-native-publish.mjs');
  await runHotelRelease({publish:true});
 }
}catch(error){
 const key=process.env.ROBLOX_API_KEY;const message=String(error?.stack||error);
 console.error(key?message.split(key).join('[REDACTED]'):message);process.exit(1);
}

