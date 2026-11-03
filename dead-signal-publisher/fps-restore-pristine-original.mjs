import {createHash} from 'node:crypto';
import fs from 'node:fs/promises';

const universe = 9421311218;
const place = 118064584465155;
const sourceAsset = 15864801103;
const expectedSourceSha = '6cd1bc3e7a71505b38965acc3e8219bc84bda1b8ac4ca64ae0ca4151800a2d02';
const apiKey = process.env.ROBLOX_API_KEY;
if (!apiKey) throw Error('ROBLOX_API_KEY missing');
const trigger = (await fs.readFile(new URL('fps-restore-pristine-original.trigger', import.meta.url), 'utf8')).trim();
if (!/^fps-restore-pristine-original-publish-[a-zA-Z0-9-]+$/.test(trigger)) throw Error('Unexpected restore operation');

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
  if (!location) throw Error(`No Roblox download URL for asset ${assetId}`);
  const response = await fetch(location, {signal: AbortSignal.timeout(240000)});
  if (!response.ok) throw Error(`Roblox asset download failed: ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}
async function publish(bytes) {
  return api(`https://apis.roblox.com/universes/v1/${universe}/places/${place}/versions?versionType=Published`, {
    method: 'POST', contentType: 'application/octet-stream', body: bytes,
  });
}
async function restartServers() {
  await api(`https://apis.roblox.com/cloud/v2/universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
}

const metadataResponse = await fetch(`https://economy.roblox.com/v2/assets/${sourceAsset}/details`, {signal: AbortSignal.timeout(60000)});
const metadata = await metadataResponse.json().catch(() => ({}));
if (!metadataResponse.ok || metadata.Name !== 'FPS System Demo (uncopylocked)' || metadata.AssetTypeId !== 9) {
  throw Error('Roblox original FPS place metadata changed; refusing to replace the game');
}
const original = await assetBytes(sourceAsset);
const originalSha = sha256(original);
if (originalSha !== expectedSourceSha) throw Error('Original FPS place bytes changed; refusing to replace the game');

const previous = await assetBytes(place);
const previousSha = sha256(previous);
if (previousSha === originalSha) {
  console.log('FPS_PRISTINE_ORIGINAL_ALREADY_RESTORED ' + JSON.stringify({place, sourceAsset, originalSha}));
  process.exit(0);
}

console.log('FPS_PRISTINE_ORIGINAL_VERIFIED ' + JSON.stringify({place, sourceAsset, name: metadata.Name, originalSha, bytes: original.length, previousSha}));
let attempted = false;
try {
  attempted = true;
  const result = await publish(original);
  if (!result.versionNumber) throw Error('Roblox did not return a new place version');
  const restored = await assetBytes(place, result.versionNumber);
  const restoredSha = sha256(restored);
  if (restoredSha !== originalSha) throw Error('Published bytes do not match the unmodified Roblox original');
  await restartServers();
  console.log('FPS_PRISTINE_ORIGINAL_RESTORED ' + JSON.stringify({place, version: result.versionNumber, sourceAsset, sourceSha: originalSha, bytes: restored.length, previousSha, restarted: true, serverSettingsChanged: false}));
} catch (error) {
  if (attempted) {
    try {
      const rollback = await publish(previous);
      await restartServers();
      console.error('FPS_PRISTINE_ORIGINAL_ROLLBACK ' + JSON.stringify({restoredVersion: rollback.versionNumber, previousSha}));
    } catch (rollbackError) {
      console.error('FPS_PRISTINE_ORIGINAL_ROLLBACK_ERROR ' + String(rollbackError));
    }
  }
  throw error;
}
