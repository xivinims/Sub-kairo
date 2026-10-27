import fs from 'node:fs/promises';

const UNIVERSE_ID = '9421311218';
const PLACE_ID = '118064584465155';
const BUILD_ID = 'dead-signal-ch01-assets-v4';
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
];
const CLIENT_MODULES = [
  'InputController',
  'ObjectiveController',
  'DialogueController',
  'WireController',
  'ScreenEffectsController',
  'ChapterPresentation',
  'SettingsController',
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
  const [template, verify, serverBootstrap, clientBootstrap, sharedStatements, serverStatements, clientStatements] = await Promise.all([
    fs.readFile(new URL('./chapter-install.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./chapter-validate.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./base/server/ServerBootstrap.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./base/client/ClientBootstrap.luau', import.meta.url), 'utf8'),
    moduleStatements('shared', SHARED_MODULES, 'sharedFolder'),
    moduleStatements('server', SERVER_MODULES, 'services'),
    moduleStatements('client', CLIENT_MODULES, 'clientModules'),
  ]);

  let install = template
    .replace('__VISUAL_DRESSING__', await fs.readFile(new URL('./visual-dressing.luau', import.meta.url), 'utf8'))
    .replace('__CHAPTER_MAP__', await fs.readFile(new URL('./chapter-map.luau', import.meta.url), 'utf8'))
    .replace('__PREPUBLISH_VALIDATE__', 'local validation = (function()\n' + verify + '\nend)()\nassert(validation.ok, HttpService:JSONEncode(validation))')
    .replace('__SHARED_MODULES__', sharedStatements)
    .replace('__SERVER_MODULES__', serverStatements)
    .replace('__CLIENT_MODULES__', clientStatements)
    .replace('__SERVER_BOOTSTRAP__', luaLongString(serverBootstrap))
    .replace('__CLIENT_BOOTSTRAP__', luaLongString(clientBootstrap));

  const leftovers = [
    '__SHARED_MODULES__',
    '__SERVER_MODULES__',
    '__CLIENT_MODULES__',
    '__SERVER_BOOTSTRAP__',
    '__CLIENT_BOOTSTRAP__',
  ].filter((token) => install.includes(token));
  if (leftovers.length) throw new Error('Publisher placeholders remain: ' + leftovers.join(', '));
  if (!install.includes(BUILD_ID)) throw new Error('Build marker missing');

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

