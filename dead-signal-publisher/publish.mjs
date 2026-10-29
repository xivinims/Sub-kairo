import fs from 'node:fs/promises';
try {
 if(process.argv.includes('--dry-run')){
  const state=JSON.parse(await fs.readFile(new URL('./release-state.json',import.meta.url),'utf8'));
  const files=['SafeAssetImporterFile.luau','islands-stage.luau','islands-assemble.luau','islands-native-install.luau','islands-finalize.luau','islands-chunks.luau','islands-travel-server.luau','islands-travel-client.luau','islands-verify.luau','islands-file-verify.luau','blackhole-extract.luau','blackhole-client.luau'];
  const sources=await Promise.all(files.map(f=>fs.readFile(new URL('./'+f,import.meta.url),'utf8')));
  if(sources.some(s=>s.length<40))throw Error('Missing source file');
  console.log(JSON.stringify({dryRun:true,build:state.buildId,celestial:state.celestialBuildId,sourceFiles:files.length,rollbackVersion:state.rollbackVersion}));
 }else await import('./islands-native-publish.mjs');
}catch(error){
 const key=process.env.ROBLOX_API_KEY;const message=String(error?.stack||error);
 console.error(key?message.split(key).join('[REDACTED]'):message);process.exit(1);
}
