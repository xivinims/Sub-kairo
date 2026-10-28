import fs from 'node:fs/promises';

const UNIVERSE_ID = '9421311218';
const PLACE_ID = '118064584465155';
const BUILD_ID = 'dead-signal-reference-red-stage-v6';
const CLOUD = 'https://apis.roblox.com/cloud/v2/';
const TARGET = 'universes/' + UNIVERSE_ID + '/places/' + PLACE_ID + '/';
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const SHARED_MODULES = ['GameConfig', 'RemoteProtocol', 'AssetManifest'];
const SERVER_MODULES = [
  'SaveService',
  'ChapterService',
  'CheckpointService',
  'PowerService',
  'WireService',
  'DoorService',
  'InteractionService',
  'DialogueService',
  'EventDirector',
  'StalkerService',
  'NoiseService',
  'DebugService',
  'SafeAssetImporter',
  'ChapterRuntime',
  'GrabPackService',
];
const CLIENT_MODULES = [
  'InputController',
  'ObjectiveController',
  'DialogueController',
  'WireController',
  'ScreenEffectsController',
  'ChapterPresentation',
  'SettingsController',
  'GrabPackController',
  'FootstepController',
];

async function roblox(url, options = {}) {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');

  let last;
  for (let attempt = 0; attempt < 6; attempt++) {
    const response = await fetch(url, {
      method: options.method || 'GET',
      headers: {
        'x-api-key': key,
        'content-type': 'application/json',
      },
      body: options.body,
      signal: AbortSignal.timeout(options.timeoutMs || 240000),
    });

    const raw = await response.text();
    let data;
    try { data = JSON.parse(raw); } catch { data = { raw }; }

    if (response.ok) return data;
    last = new Error('HTTP ' + response.status + ': ' + raw.slice(0, 1400));
    if (![429, 500, 502, 503, 504].includes(response.status)) throw last;
    await sleep(2500 * (attempt + 1));
  }
  throw last;
}

async function execute(script, label) {
  let task = await roblox(CLOUD + TARGET + 'luau-execution-session-tasks', {
    method: 'POST',
    body: JSON.stringify({ timeout: '300s', script }),
  });

  const deadline = Date.now() + 420000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
    if (Date.now() > deadline) throw new Error(label + ': timeout');
    if (!String(task.path || '').includes(TARGET)) throw new Error(label + ': wrong target');
    await sleep(1500);
    task = await roblox(CLOUD + task.path);
  }

  if (task.state !== 'COMPLETE' || task.error) {
    throw new Error(label + ': ' + JSON.stringify(task.error || task));
  }

  const value = task.output?.results?.[0];
  if (typeof value === 'string') {
    try { return JSON.parse(value); } catch { return { raw: value }; }
  }
  return value;
}

function luaLongString(source) {
  for (let level = 4; level < 12; level++) {
    const eq = '='.repeat(level);
    const close = ']' + eq + ']';
    if (!source.includes(close)) return '[' + eq + '[' + source + close;
  }
  throw new Error('Unable to encode Luau source safely');
}

async function readModule(group, name) {
  return fs.readFile(new URL('./base/' + group + '/' + name + '.luau', import.meta.url), 'utf8');
}

async function moduleStatements(group, names, parentVar) {
  const sources = await Promise.all(names.map((name) => readModule(group, name)));
  return names.map((name, index) =>
    'module(' + parentVar + ', ' + JSON.stringify(name) + ', ' + luaLongString(sources[index]) + ')'
  ).join('\n');
}

async function main() {
  const [template,verify,door,guard,server,client,loading,settings,menuView,wingSource,statueSource,scenicSource,menuSceneSource]=await Promise.all(
    ['atrium-install.luau','atrium-validate.luau','base/server/DoorService.luau','base/server/MapInteractionGuard.luau','atrium-server.luau','atrium-client.luau','atrium-loading.luau','atrium-settings.luau','atrium-menu-view.luau','atrium-wings.luau','atrium-avatar-statue.luau','atrium-scenic-refinement.luau','menu-cinematic-stage.luau'].map(path=>fs.readFile(new URL('./'+path,import.meta.url),'utf8')));
  let logoId=1;
  if (!process.argv.includes('--dry-run')) {
    const existing=await execute('return game:GetService("HttpService"):JSONEncode({logo=game:GetService("ServerStorage"):GetAttribute("AurivaneLogoAsset")})','logo-query');
    logoId=existing?.logo;
    if (!logoId) {
      const bytes=Buffer.from(await fs.readFile(new URL('./aurivane-logo.base64',import.meta.url),'utf8'),'base64');
      const form=new FormData();
      form.set('request',JSON.stringify({assetType:'Decal',displayName:'Aurivane Works - loading logo',description:'User supplied Aurivane Works studio logo',creationContext:{creator:{userId:'8344738123'}}}));
      form.set('fileContent',new Blob([bytes],{type:'image/jpeg'}),'aurivane.jpg');
      const response=await fetch('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers:{'x-api-key':process.env.ROBLOX_API_KEY},body:form});
      let operation=await response.json();if(!response.ok)throw new Error('Logo upload: '+JSON.stringify(operation));
      for(let i=0;i<120&&!operation.done;i++){await sleep(1500);const r=await fetch('https://apis.roblox.com/assets/v1/'+operation.path,{headers:{'x-api-key':process.env.ROBLOX_API_KEY}});operation=await r.json();}
      if(operation.error||!operation.done)throw new Error('Logo upload processing failed '+JSON.stringify(operation));
      logoId=Number(operation.response.assetId);console.log('Aurivane logo asset: '+logoId);
    }
  }
  const install=template
    .replace('__DOOR_SERVICE__',luaLongString(door))
    .replace('__INTERACTION_GUARD__',luaLongString(guard))
    .replace('__SERVER__',luaLongString(server))
    .replace('__CLIENT__',luaLongString(client))
    .replace('__LOADING__',luaLongString(loading))
    .replace('__SETTINGS__',luaLongString(settings))
    .replace('__MENU_VIEW__',luaLongString(menuView))
    .replace('__WINGS_SOURCE__',wingSource)
    .replace('__SCENIC_REFINEMENT__',scenicSource)
    .replace('__MENU_SCENE__',menuSceneSource)
    .replace('__STATUE_SOURCE__',luaLongString(statueSource))
    .replace('__LOGO_ID__',String(logoId))
    .replace('__PREPUBLISH_VALIDATE__','game:GetService("ServerStorage"):SetAttribute("AurivaneLogoAsset",'+logoId+')\nlocal validation=(function()\n'+verify+'\nend)()\nassert(validation.ok,Http:JSONEncode(validation))');
  if (/__[A-Z_]+__/.test(install.replaceAll('__ALL_STATIC__',''))) throw new Error('Unexpanded map placeholder');
  if (process.argv.includes('--dry-run')) {
    await fs.writeFile(new URL('./assembled-install.luau',import.meta.url),install);
    console.log(JSON.stringify({build:BUILD_ID,bytes:install.length,dryRun:true})); return;
  }
  const installed = await execute(install, 'chapter-install');
  if (!installed?.ok || !installed?.published || installed.build !== BUILD_ID) {
    throw new Error('Install failed: ' + JSON.stringify(installed));
  }

  await sleep(4000);
  const verified = await execute('return game:GetService("HttpService"):JSONEncode((function()\n' + verify + '\nend)())', 'chapter-verify');
  if (!verified?.ok || verified.build !== BUILD_ID) {
    throw new Error('Verification failed: ' + JSON.stringify(verified));
  }

  let restart = {};
  try {
    restart = await roblox(CLOUD + 'universes/' + UNIVERSE_ID + ':restartServers', {
      method: 'POST',
      body: '{}',
    });
  } catch (error) {
    restart = { warning: String(error?.message || error) };
  }

  console.log(JSON.stringify({
    stage: 'dead-signal-chapter-published',
    universeId: UNIVERSE_ID,
    placeId: PLACE_ID,
    installed,
    verified,
    restart,
  }, null, 2));
}

main().catch((error) => {
  const key = process.env.ROBLOX_API_KEY;
  const message = String(error?.stack || error?.message || error);
  console.error(key ? message.split(key).join('[REDACTED]') : message);
  process.exit(1);
});

