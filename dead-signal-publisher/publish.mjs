import fs from 'node:fs/promises';
try {
 if(process.argv.includes('--dry-run')){
  const state=JSON.parse(await fs.readFile(new URL('./release-state.json',import.meta.url),'utf8'));
  const files=['original-native-publish.mjs','chapter-two-place.luau','chapter-two-verify.luau','chapter-two-file-verify.luau','original-weapon-fixes.luau','original-touch-prompt.luau','original-weapon-test.luau','session-interface.luau','session-menu-client.luau','settings-schema.luau','settings-server.luau','session-loading-client.luau','original-gameplay-fixes.luau','original-mission-hud.luau','original-assemble.luau','original-initialize.luau','original-ui-bootstrap.luau','original-weapon-pickups.luau','original-verify.luau','original-file-verify.luau','menu-layout-test.luau','blackhole-extract.luau','blackhole-client.luau'];
  const sources=await Promise.all(files.map(f=>fs.readFile(new URL('./'+f,import.meta.url),'utf8')));
  if(sources.some(s=>s.length<40))throw Error('Missing source file');
  console.log(JSON.stringify({dryRun:true,build:state.buildId,celestial:state.celestialBuildId,sourceFiles:files.length,rollbackVersion:state.rollbackVersion}));
 }else await import('./original-native-publish.mjs');
}catch(error){
 const key=process.env.ROBLOX_API_KEY;const message=String(error?.stack||error);
 console.error(key?message.split(key).join('[REDACTED]'):message);process.exit(1);
}
