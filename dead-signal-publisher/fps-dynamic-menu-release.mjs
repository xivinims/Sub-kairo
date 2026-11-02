// Restore the last verified FPS place version, add the sliding menu, and publish as one new place version.
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
const fpsVersion = state.lastVerifiedVersion;
if (!Number.isInteger(fpsVersion) || fpsVersion < 1 || state.buildId !== 'fallout-5v5-v1') throw Error('No verified FPS source version is recorded');

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
if (invariant === originalInvariant) throw Error('Could not scope preservation to the new menu script');
const restoreVerify = await read('fps-original-restore-verify.luau');
const menuVerify = await read('fps-dynamic-menu-verify.luau');
const restoreAssertions = restoreVerify.split('return game:GetService(\'HttpService\'):JSONEncode({')[0];
if (restoreAssertions === restoreVerify) throw Error('Could not locate the original FPS verifier result');

const liveBefore = await execute(`assert(game.GameId==${universe} and game.PlaceId==${place})\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,menu=workspace:GetAttribute("DeadSignalMenuRevision")})`);
if (liveBefore.menu === revision) {
  const alreadyInstalled = await execute(invariant + '\n' + restoreAssertions + '\n' + menuVerify);
  if (!alreadyInstalled?.ok || alreadyInstalled.revision !== revision || alreadyInstalled.version !== liveBefore.version) {
    throw Error('The menu marker exists, but the current live FPS could not be verified');
  }
  const currentConfig = await api(`${cloud}universes/${universe}/places/${place}`);
  if (Number(currentConfig.serverSize) !== 10) {
    await api(`${cloud}universes/${universe}/places/${place}?updateMask=serverSize`, {method: 'PATCH', body: JSON.stringify({serverSize: 10})});
  }
  const verifiedConfig = await api(`${cloud}universes/${universe}/places/${place}`);
  if (Number(verifiedConfig.serverSize) !== 10) throw Error('Could not set the FPS server limit to 10 players');
  await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
  console.log('FPS_DYNAMIC_MENU_RELEASE_COMPLETE ' + JSON.stringify({...alreadyInstalled, sourceVersion: fpsVersion, serverSize: Number(verifiedConfig.serverSize), restarted: true, published: false}));
  process.exit(0);
}
console.log('FPS_DYNAMIC_MENU_CURRENT_PLACE ' + JSON.stringify(liveBefore));

// Validate the exact last verified FPS version before using it as the restoration source.
const sourceCheck = await execute(invariant + '\n' + restoreVerify, undefined, fpsVersion);
if (!sourceCheck?.ok || sourceCheck.version !== fpsVersion || sourceCheck.originalGui !== true || sourceCheck.gunCount !== 8 || !sourceCheck.mapAndItemsPreserved) {
  throw Error('The recorded FPS restoration source did not pass the original-system verifier: ' + JSON.stringify(sourceCheck));
}
console.log('FPS_DYNAMIC_MENU_RESTORATION_SOURCE ' + JSON.stringify(sourceCheck));

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
const installPrefix = invariant + `\nassert(game.PlaceVersion==${fpsVersion},"Unexpected restoration source version")\nlocal beforeSnapshot=${JSON.stringify(sourceCheck.preserved)}\n`;
const preflight = await execute(installPrefix + restoreAssertions + '\n' + install + '\n' + menuVerify, slot.path, fpsVersion);
if (!preflight?.ok || preflight.preserved !== sourceCheck.preserved || preflight.revision !== revision || preflight.originalFpsPreserved !== true) {
  throw Error('FPS restoration plus sliding menu did not pass isolated preflight: ' + JSON.stringify(preflight));
}
console.log('FPS_DYNAMIC_MENU_PREFLIGHT ' + JSON.stringify(preflight));
if (mode.startsWith('fps-dynamic-menu-preview-')) {
  console.log('FPS_DYNAMIC_MENU_PREVIEW_COMPLETE ' + JSON.stringify({published: false, sourceVersion: fpsVersion, currentVersion: liveBefore.version, verified: true}));
  process.exit(0);
}

const fresh = await execute(`assert(game.GameId==${universe} and game.PlaceId==${place})\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})`);
if (fresh.version !== liveBefore.version) throw Error('The live place changed after restoration preflight');

let saved = false;
try {
  const publishScript = installPrefix + restoreAssertions + '\n' + install + '\nlocal checked=(function()\n' + menuVerify + '\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
  const published = await execute(publishScript, slot.path, fpsVersion);
  saved = true;
  console.log('FPS_DYNAMIC_MENU_NATIVE_SAVE ' + JSON.stringify(published));

  const live = await execute(invariant + '\n' + restoreAssertions + '\n' + menuVerify);
  if (!live?.ok || live.version <= liveBefore.version || live.preserved !== sourceCheck.preserved || live.revision !== revision || live.originalFpsPreserved !== true) {
    throw Error('Published place did not match the verified FPS and menu: ' + JSON.stringify(live));
  }
  const config = await api(`${cloud}universes/${universe}/places/${place}`);
  if (Number(config.serverSize) !== 10) {
    await api(`${cloud}universes/${universe}/places/${place}?updateMask=serverSize`, {method: 'PATCH', body: JSON.stringify({serverSize: 10})});
  }
  const verifiedConfig = await api(`${cloud}universes/${universe}/places/${place}`);
  if (Number(verifiedConfig.serverSize) !== 10) throw Error('Could not set the FPS server limit to 10 players');
  await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
  console.log('FPS_DYNAMIC_MENU_RELEASE_COMPLETE ' + JSON.stringify({...live, sourceVersion: fpsVersion, previousVersion: liveBefore.version, serverSize: Number(verifiedConfig.serverSize), restarted: true}));
} catch (error) {
  if (saved) {
    try {
      const current = await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
      if (current.version > liveBefore.version) {
        // A failed menu release falls back to the same verified FPS, without experimental RPG content.
        await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restored:game.PlaceVersion})', undefined, fpsVersion);
        await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
        console.error('FPS_DYNAMIC_MENU_FALLBACK_TO_VERIFIED_FPS ' + fpsVersion);
      }
    } catch (rollbackError) {
      console.error('FPS_DYNAMIC_MENU_FALLBACK_ERROR ' + String(rollbackError));
    }
  }
  throw error;
}
