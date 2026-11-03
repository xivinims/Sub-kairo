import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const universe = 9421311218;
const place = 118064584465155;
const sourceId = 15864801103;
const expectedSha = '6cd1bc3e7a71505b38965acc3e8219bc84bda1b8ac4ca64ae0ca4151800a2d02';
const apiKey = process.env.ROBLOX_API_KEY;
if (!apiKey) throw Error('ROBLOX_API_KEY missing');
const trigger = (await fs.readFile(new URL('fps-equip-first-weapon.trigger', import.meta.url), 'utf8')).trim();
if (!/^fps-equip-first-weapon-publish-[a-zA-Z0-9-]+$/.test(trigger)) throw Error('Unexpected FPS weapon operation');
const cloud = 'https://apis.roblox.com/cloud/v2/';
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

async function api(url, {method = 'GET', body, contentType = 'application/json'} = {}) {
  const response = await fetch(url, {
    method,
    headers: {'x-api-key': apiKey, 'content-type': contentType},
    body,
    signal: AbortSignal.timeout(240000),
  });
  const raw = await response.text();
  let data;
  try { data = JSON.parse(raw); } catch { data = {message: raw.slice(0, 1200)}; }
  if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}

async function assetBytes(assetId, version) {
  const suffix = version ? `/version/${version}` : '';
  const delivery = await api(`https://apis.roblox.com/asset-delivery-api/v1/assetId/${assetId}${suffix}`);
  const location = delivery.location || delivery.locations?.[0]?.location;
  if (!location) throw Error(`No Roblox download URL for ${assetId}`);
  const response = await fetch(location, {signal: AbortSignal.timeout(240000)});
  if (!response.ok) throw Error(`Roblox asset download failed: ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}

async function publish(bytes) {
  return api(`https://apis.roblox.com/universes/v1/${universe}/places/${place}/versions?versionType=Published`, {
    method: 'POST', contentType: 'application/octet-stream', body: bytes,
  });
}

async function setupLune() {
  const response = await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip', {signal: AbortSignal.timeout(120000)});
  if (!response.ok) throw Error('Could not download the pinned Luau compiler');
  const zip = Buffer.from(await response.arrayBuffer());
  if (sha256(zip) !== '39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1') throw Error('Pinned Luau compiler checksum mismatch');
  await fs.writeFile('/tmp/fps-equip-lune.zip', zip);
  execFileSync('unzip', ['-q', '-o', '/tmp/fps-equip-lune.zip', '-d', '/tmp/fps-equip-lune'], {stdio: 'ignore'});
  await fs.chmod('/tmp/fps-equip-lune/lune', 0o755);
}

const metaResponse = await fetch(`https://economy.roblox.com/v2/assets/${sourceId}/details`, {signal: AbortSignal.timeout(60000)});
const meta = await metaResponse.json().catch(() => ({}));
if (!metaResponse.ok || meta.Name !== 'FPS System Demo (uncopylocked)' || meta.AssetTypeId !== 9) throw Error('Original FPS asset metadata changed');

const original = await assetBytes(sourceId);
const originalSha = sha256(original);
if (originalSha !== expectedSha) throw Error('Pinned original FPS place hash changed');
const current = await assetBytes(place);
const currentSha = sha256(current);
if (currentSha !== originalSha) throw Error('The live place is no longer the exact original; refusing to overwrite unexpected changes');

await fs.writeFile('/tmp/fps-system-demo-source', original);
await setupLune();
const output = execFileSync('/tmp/fps-equip-lune/lune', ['run', 'fps-equip-first-weapon.luau'], {
  cwd: new URL('.', import.meta.url).pathname,
  encoding: 'utf8',
  maxBuffer: 16 * 1024 * 1024,
});
const patchSummary = JSON.parse(output.trim().split('\n').at(-1));
if (!patchSummary.ok || patchSummary.changedScript !== 'ServerScriptService.Weapons.StarterWeapons' || patchSummary.changedScripts.length !== 1) {
  throw Error('Original weapon equip patch failed its one-line preservation check: ' + JSON.stringify(patchSummary));
}
const candidate = await fs.readFile('/tmp/fps-equip-first-weapon-place');
console.log('FPS_EQUIP_FIRST_WEAPON_PREFLIGHT ' + JSON.stringify({...patchSummary, sourceId, sourceSha: originalSha, candidateBytes: candidate.length}));

let attempted = false;
try {
  attempted = true;
  const result = await publish(candidate);
  if (!result.versionNumber) throw Error('Roblox did not return a published place version');
  const restored = await assetBytes(place, result.versionNumber);
  const publishedSha = sha256(restored);
  if (publishedSha !== sha256(candidate)) throw Error('Published place bytes differ from the verified one-line patch');
  await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
  console.log('FPS_EQUIP_FIRST_WEAPON_RELEASE_COMPLETE ' + JSON.stringify({
    version: result.versionNumber,
    sourceId,
    changedScript: patchSummary.changedScript,
    changedScripts: patchSummary.changedScripts,
    equipCall: patchSummary.equipCall,
    sourceSha: originalSha,
    publishedSha,
    restarted: true,
  }));
} catch (error) {
  if (attempted) {
    try {
      const rollback = await publish(original);
      await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
      console.error('FPS_EQUIP_FIRST_WEAPON_ROLLBACK ' + JSON.stringify({restoredVersion: rollback.versionNumber, sourceSha: originalSha}));
    } catch (rollbackError) {
      console.error('FPS_EQUIP_FIRST_WEAPON_ROLLBACK_ERROR ' + String(rollbackError));
    }
  }
  throw error;
}
