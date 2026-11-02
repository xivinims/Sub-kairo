import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const assetId = 8438960542;
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error('ROBLOX_API_KEY missing');
async function json(url) {
	const response = await fetch(url, {headers: {'x-api-key': key}, signal: AbortSignal.timeout(120000)});
	const text = await response.text();
	let data; try { data = JSON.parse(text); } catch { data = {raw: text.slice(0, 1200)}; }
	if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(data)}`);
	return data;
}
const metaResponse = await fetch(`https://economy.roblox.com/v2/assets/${assetId}/details`, {signal: AbortSignal.timeout(60000)});
const meta = await metaResponse.json().catch(() => ({}));
if (!metaResponse.ok) throw Error('Could not read Fallout map asset metadata: ' + JSON.stringify(meta));
if (!/fallout/i.test(meta.Name || '')) throw Error('Asset name is not Fallout-related: ' + JSON.stringify({id: assetId, name: meta.Name, type: meta.AssetTypeId}));
const delivery = await json(`https://apis.roblox.com/asset-delivery-api/v1/assetId/${assetId}`);
const location = delivery.location || delivery.locations?.[0]?.location;
if (!location) throw Error('Fallout map download URL missing');
const download = await fetch(location, {signal: AbortSignal.timeout(240000)});
if (!download.ok) throw Error('Fallout map download failed: ' + download.status);
const bytes = Buffer.from(await download.arrayBuffer());
await fs.writeFile('/tmp/fps-fallout-map-asset', bytes);

const luneResponse = await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip', {signal: AbortSignal.timeout(120000)});
if (!luneResponse.ok) throw Error('Could not download pinned Lune');
const luneZip = Buffer.from(await luneResponse.arrayBuffer());
if (createHash('sha256').update(luneZip).digest('hex') !== '39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1') throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/fps-fallout-map-lune.zip', luneZip);
execFileSync('unzip', ['-q', '-o', '/tmp/fps-fallout-map-lune.zip', '-d', '/tmp/fps-fallout-map-lune'], {stdio: 'ignore'});
await fs.chmod('/tmp/fps-fallout-map-lune/lune', 0o755);
const output = execFileSync('/tmp/fps-fallout-map-lune/lune', ['run', 'fps-fallout-map-inspect.luau'], {cwd: new URL('.', import.meta.url).pathname, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024});
const summary = JSON.parse(output.trim().split('\n').at(-1));
console.log('FPS_FALLOUT_MAP_INSPECTED ' + JSON.stringify({assetId, name: meta.Name, type: meta.AssetTypeId, creator: meta.Creator, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), ...summary}));
