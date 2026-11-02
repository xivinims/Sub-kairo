import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const assets = [
  {id: 15864801103, kind: 'original-fps'},
  {id: 8438960542, kind: 'fps-map'},
  {id: 95512398319263, kind: 'lobby'},
  {id: 18145857971, kind: 'overhauled-fps-reference'},
];
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error('ROBLOX_API_KEY missing');
async function api(url) {
  const response = await fetch(url, {headers: {'x-api-key': key}, signal: AbortSignal.timeout(180000)});
  const raw = await response.text();
  let data; try { data = JSON.parse(raw); } catch { data = {raw: raw.slice(0, 1000)}; }
  if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}
const summaries = [];
for (const asset of assets) {
  const metadata = await api(`https://economy.roblox.com/v2/assets/${asset.id}/details`);
  const delivery = await api(`https://apis.roblox.com/asset-delivery-api/v1/assetId/${asset.id}`);
  const location = delivery.location || delivery.locations?.[0]?.location;
  if (!location) throw Error(`Asset ${asset.id} has no download URL`);
  const response = await fetch(location, {signal: AbortSignal.timeout(240000)});
  if (!response.ok) throw Error(`Asset ${asset.id} download failed: ${response.status}`);
  const bytes = Buffer.from(await response.arrayBuffer());
  await fs.writeFile(`/tmp/fps-recovery-${asset.kind}`, bytes);
  summaries.push({id: asset.id, kind: asset.kind, name: metadata.Name, type: metadata.AssetTypeId, creator: metadata.Creator, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex')});
}
await fs.writeFile('/tmp/fps-recovery-meta.json', JSON.stringify(summaries));

const luneResponse = await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip', {signal: AbortSignal.timeout(120000)});
if (!luneResponse.ok) throw Error('Could not download pinned Lune');
const zip = Buffer.from(await luneResponse.arrayBuffer());
if (createHash('sha256').update(zip).digest('hex') !== '39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1') throw Error('Pinned Lune checksum mismatch');
await fs.writeFile('/tmp/fps-recovery-lune.zip', zip);
execFileSync('unzip', ['-q', '-o', '/tmp/fps-recovery-lune.zip', '-d', '/tmp/fps-recovery-lune'], {stdio: 'ignore'});
await fs.chmod('/tmp/fps-recovery-lune/lune', 0o755);
const output = execFileSync('/tmp/fps-recovery-lune/lune', ['run', 'fps-recovery-assets-inspect.luau'], {cwd: new URL('.', import.meta.url).pathname, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024});
const inspection = JSON.parse(output.trim().split('\n').at(-1));
console.log('FPS_RECOVERY_ASSET_INSPECTION ' + JSON.stringify({assets: summaries, inspection}));
