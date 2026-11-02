import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const universe = 9421311218;
const place = 118064584465155;
const revision = 'fps-menu-sliding-v1';
const cloud = 'https://apis.roblox.com/cloud/v2/';
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error('ROBLOX_API_KEY missing');
const read = name => fs.readFile(new URL(name, import.meta.url), 'utf8');
const mode = (await read('fps-dynamic-menu.trigger')).trim();
if (!/^fps-dynamic-menu-(preview|publish)-[a-zA-Z0-9-]+$/.test(mode)) throw Error('Unexpected dynamic menu operation');
const state = JSON.parse(await read('release-state.json'));

async function api(url, {method = 'GET', body} = {}) {
  const response = await fetch(url, {
    method,
    headers: {'x-api-key': key, 'content-type': 'application/json'},
    body,
    signal: AbortSignal.timeout(240000),
  });
  const raw = await response.text();
  let data;
  try { data = JSON.parse(raw); } catch { data = {message: raw.slice(0, 1500)}; }
  if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}

async function execute(script, input, version) {
  const target = `${cloud}universes/${universe}/places/${place}/`;
  let task = await api(target + (version ? `versions/${version}/` : '') + 'luau-execution-session-tasks', {
    method: 'POST', body: JSON.stringify({timeout: '300s', script, binaryInput: input}),
  });
  const deadline = Date.now() + 420000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state) && Date.now() < deadline) {
    await new Promise(resolve => setTimeout(resolve, 1400));
    task = await api(cloud + task.path);
  }
  if (task.state !== 'COMPLETE' || task.error) {
    let logs;
    try { logs = await api(cloud + task.path + '/logs?view=FLAT'); } catch {}
    throw Error('Roblox native execution failed ' + JSON.stringify({task, logs}));
  }
  const result = task.output?.results?.[0];
  return typeof result === 'string' ? JSON.parse(result) : result;
}

const originalInvariant = await read('fps-bots-hud-invariants.luau');
const invariant = originalInvariant.replace(
  "['Workspace.FalloutCombatBots']=true,",
  "['Workspace.FalloutCombatBots']=true,\n  ['StarterPlayer.StarterPlayerScripts.DeadSignalMenu']=true,",
);
if (invariant === originalInvariant) throw Error('Could not scope the preservation check to the new menu script');

const baseline = await execute(invariant + `\nassert(game.GameId==${universe} and game.PlaceId==${place})\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute("DeadSignalBuildId"),combatHud=workspace:GetAttribute("FalloutCombatHUDRevision"),botBuild=workspace:GetAttribute("FalloutBotsBuild"),options=workspace:GetAttribute("FalloutOptionsVisualRevision"),menu=workspace:GetAttribute("DeadSignalMenuRevision"),preserved=protectedSnapshot()})`);
if (baseline.menu === revision) {
  console.log('FPS_DYNAMIC_MENU_ALREADY_CURRENT ' + JSON.stringify({published: false, version: baseline.version, revision}));
  process.exit(0);
}
if (baseline.version !== state.lastVerifiedVersion || baseline.build !== 'fallout-5v5-v1' ||
    baseline.combatHud !== 'original-fps-v1' || baseline.botBuild !== 'disabled-original-fps' ||
    baseline.options !== 'fps-gear-icon-settings-v2') {
  throw Error('Live FPS differs from the verified original state; refusing to publish: ' + JSON.stringify(baseline));
}
console.log('FPS_DYNAMIC_MENU_BASELINE ' + JSON.stringify(baseline));

const luneResponse = await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip', {signal: AbortSignal.timeout(90000)});
if (!luneResponse.ok) throw Error('Could not download the pinned Luau compiler');
const luneZip = Buffer.from(await luneResponse.arrayBuffer());
if (createHash('sha256').update(luneZip).digest('hex') !== '39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1') throw Error('Luau compiler checksum mismatch');
await fs.writeFile('/tmp/fps-dynamic-menu-lune.zip', luneZip);
execFileSync('unzip', ['-q', '-o', '/tmp/fps-dynamic-menu-lune.zip', '-d', '/tmp/fps-dynamic-menu-lune'], {stdio: 'ignore'});
await fs.chmod('/tmp/fps-dynamic-menu-lune/lune', 0o755);
execFileSync('/tmp/fps-dynamic-menu-lune/lune', ['run', 'fps-dynamic-menu-build.luau'], {cwd: new URL('.', import.meta.url).pathname, stdio: 'inherit'});

const payload = await fs.readFile('/tmp/fps-dynamic-menu-patch.rbxm');
const slot = await api(`${cloud}universes/${universe}/luau-execution-session-task-binary-inputs`, {
  method: 'POST', body: JSON.stringify({size: payload.length}),
});
const uploaded = await fetch(slot.uploadUri, {method: 'PUT', headers: {'content-type': 'application/octet-stream'}, body: payload, signal: AbortSignal.timeout(90000)});
if (!uploaded.ok) throw Error('Could not upload the menu patch bundle');

const install = await read('fps-dynamic-menu-install.luau');
const verify = await read('fps-dynamic-menu-verify.luau');
const prefix = invariant + `\nassert(game.PlaceVersion==${baseline.version},"FPS place changed during preflight")\nlocal beforeSnapshot=${JSON.stringify(baseline.preserved)}\n`;
const preflight = await execute(prefix + install + '\n' + verify, slot.path);
if (!preflight?.ok || preflight.preserved !== baseline.preserved || preflight.revision !== revision || !preflight.originalFpsPreserved) {
  throw Error('Sliding menu preflight failed ' + JSON.stringify(preflight));
}
console.log('FPS_DYNAMIC_MENU_PREFLIGHT ' + JSON.stringify(preflight));
if (mode.startsWith('fps-dynamic-menu-preview-')) {
  console.log('FPS_DYNAMIC_MENU_PREVIEW_COMPLETE ' + JSON.stringify({published: false, version: baseline.version, verified: true}));
  process.exit(0);
}

const latest = await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
if (latest.version !== baseline.version) throw Error('FPS place changed after preflight');
let saved = false;
try {
  const published = await execute(prefix + install + '\nlocal checked=(function()\n' + verify + '\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked', slot.path);
  saved = true;
  console.log('FPS_DYNAMIC_MENU_NATIVE_SAVE ' + JSON.stringify(published));
  const live = await execute(invariant + '\n' + verify);
  if (!live?.ok || live.version !== baseline.version + 1 || live.preserved !== baseline.preserved || live.revision !== revision || !live.originalFpsPreserved) {
    throw Error('Published FPS menu did not pass live verification ' + JSON.stringify(live));
  }
  const config = await api(`${cloud}universes/${universe}/places/${place}`);
  if (config.serverSize !== 10) throw Error('FPS server size changed unexpectedly');
  await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
  console.log('FPS_DYNAMIC_MENU_RELEASE_COMPLETE ' + JSON.stringify({...live, serverSize: config.serverSize, rollbackVersion: baseline.version, restarted: true}));
} catch (error) {
  if (saved) {
    try {
      const current = await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
      if (current.version === baseline.version + 1) {
        await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restored:game.PlaceVersion})', undefined, baseline.version);
        await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
        console.error('FPS_DYNAMIC_MENU_ROLLED_BACK ' + baseline.version);
      } else {
        console.error('FPS_DYNAMIC_MENU_ROLLBACK_SKIPPED: a later version exists');
      }
    } catch (rollbackError) {
      console.error('FPS_DYNAMIC_MENU_ROLLBACK_ERROR ' + String(rollbackError));
    }
  }
  throw error;
}
