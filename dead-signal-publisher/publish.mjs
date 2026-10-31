import fs from 'node:fs/promises';
try {
 if(process.argv.includes('--dry-run')){
  const state=JSON.parse(await fs.readFile(new URL('./release-state.json',import.meta.url),'utf8'));
  const files=['original-native-publish.mjs','THIRD-PARTY-NOTICES.md','cinematic-environment-client.luau','cinematic-audio-lighting-test.luau','original-gameplay-test.luau','settings-test.luau','door-lock-test.luau','blackhole-layout-test.luau','original-map-prune.luau','original-world-interactions.luau','original-portuguese-text.luau','original-door-fixes.luau','session-interface.luau','settings-schema.luau','settings-server.luau','session-loading-client.luau','original-gameplay-fixes.luau','original-assemble.luau','original-initialize.luau','original-ui-bootstrap.luau','original-verify.luau','original-file-verify.luau','blackhole-extract.luau','blackhole-client.luau'];
  const sources=await Promise.all(files.map(f=>fs.readFile(new URL('./'+f,import.meta.url),'utf8')));
  if(sources.some(s=>s.length<40))throw Error('Missing source file');
  console.log(JSON.stringify({dryRun:true,build:state.buildId,celestial:state.celestialBuildId,sourceFiles:files.length,rollbackVersion:state.rollbackVersion}));
 }else await import('./original-native-publish.mjs');
}catch(error){
 const key=process.env.ROBLOX_API_KEY;const message=String(error?.stack||error);
 console.error(key?message.split(key).join('[REDACTED]'):message);process.exit(1);
}
