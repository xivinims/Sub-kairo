import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const universe = 9421311218;
const place = 118064584465155;
const sourceId = 15864801103;
const expectedSourceSha = '6cd1bc3e7a71505b38965acc3e8219bc84bda1b8ac4ca64ae0ca4151800a2d02';
const cloud = 'https://apis.roblox.com/cloud/v2/';
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error('ROBLOX_API_KEY missing');

const trigger = (await fs.readFile(new URL('fps-template-menu.trigger', import.meta.url), 'utf8')).trim();
if (!/^fps-template-menu-(preview|publish)-[a-zA-Z0-9-]+$/.test(trigger)) throw Error('Unexpected FPS template operation');

async function api(url, {method = 'GET', body, type = 'application/json'} = {}) {
	const response = await fetch(url, {method, headers: {'x-api-key': key, 'content-type': type}, body, signal: AbortSignal.timeout(240000)});
	const raw = await response.text();
	let data; try { data = JSON.parse(raw); } catch { data = {raw: raw.slice(0, 1200)}; }
	if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(data)}`);
	return data;
}
async function fetchBytes(url) {
	const response = await fetch(url, {signal: AbortSignal.timeout(240000)});
	if (!response.ok) throw Error(`Roblox download HTTP ${response.status}`);
	return Buffer.from(await response.arrayBuffer());
}
async function assetBytes(assetId, version) {
	const suffix = version ? `/version/${version}` : '';
	const delivery = await api(`https://apis.roblox.com/asset-delivery-api/v1/assetId/${assetId}${suffix}`);
	const location = delivery.location || delivery.locations?.[0]?.location;
	if (!location) throw Error(`No asset download URL for ${assetId}`);
	return fetchBytes(location);
}
async function setupLune() {
	const response = await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip', {signal: AbortSignal.timeout(120000)});
	if (!response.ok) throw Error('Could not download the pinned Lune compiler');
	const zip = Buffer.from(await response.arrayBuffer());
	if (createHash('sha256').update(zip).digest('hex') !== '39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1') throw Error('Pinned Luau tool checksum mismatch');
	await fs.writeFile('/tmp/fps-template-menu-lune.zip', zip);
	execFileSync('unzip', ['-q', '-o', '/tmp/fps-template-menu-lune.zip', '-d', '/tmp/fps-template-menu-lune'], {stdio: 'ignore'});
	execFileSync('chmod', ['+x', '/tmp/fps-template-menu-lune/lune']);
}
function runLune(script) {
	return execFileSync('/tmp/fps-template-menu-lune/lune', ['run', script], {cwd: new URL('.', import.meta.url).pathname, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024});
}
function verifyOriginal() {
	const output = runLune('fps-demo-verify.luau');
	return JSON.parse(output.trim().split('\n').at(-1));
}
function patchTemplate() {
	const output = runLune('fps-template-menu-patch.luau');
	console.log(output.trim());
}
function verifyPatched() {
	const output = runLune('fps-template-menu-verify.luau');
	return JSON.parse(output.trim().split('\n').at(-1));
}
function stable(value) {
	if (Array.isArray(value)) return '[' + value.map(stable).join(',') + ']';
	if (value && typeof value === 'object') return '{' + Object.keys(value).sort().map(key => JSON.stringify(key) + ':' + stable(value[key])).join(',') + '}';
	return JSON.stringify(value);
}
async function publish(bytes) {
	return api(`https://apis.roblox.com/universes/v1/${universe}/places/${place}/versions?versionType=Published`, {method: 'POST', type: 'application/octet-stream', body: bytes});
}
async function restart() {
	await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
}

const metaResponse = await fetch(`https://economy.roblox.com/v2/assets/${sourceId}/details`, {signal: AbortSignal.timeout(60000)});
const meta = await metaResponse.json().catch(() => ({}));
if (!metaResponse.ok || meta.Name !== 'FPS System Demo (uncopylocked)' || meta.AssetTypeId !== 9) throw Error('FPS source metadata changed; refusing to publish');
const source = await assetBytes(sourceId);
const sourceSha = createHash('sha256').update(source).digest('hex');
if (sourceSha !== expectedSourceSha) throw Error('FPS source hash differs from the audited template');
await fs.writeFile('/tmp/fps-system-demo-source', source);
await setupLune();

const original = verifyOriginal();
if (original.containerType !== 'Place' || original.descendantCount !== 198476 || original.scriptCount !== 236 || original.suspiciousPatterns.length) {
	throw Error('Original FPS template failed its pinned structure/source audit');
}
console.log('FPS_TEMPLATE_ORIGINAL_VERIFIED ' + JSON.stringify({sourceId, sourceSha, bytes: source.length, instances: original.descendantCount, scripts: original.scriptCount, map: 'Map3', weapons: 'ServerScriptService.Weapons'}));

patchTemplate();
const candidate = await fs.readFile('/tmp/fps-system-demo-source');
const patched = verifyPatched();
if (patched.descendantCount !== 198477 || patched.scriptCount !== 237 || patched.suspiciousPatterns.length || patched.map !== 'Map3') throw Error('The menu patch changed the template beyond one LocalScript');
console.log('FPS_TEMPLATE_MENU_PREFLIGHT ' + JSON.stringify(patched));
if (trigger.startsWith('fps-template-menu-preview-')) {
	console.log('FPS_TEMPLATE_MENU_PREVIEW_COMPLETE published=false');
	process.exit(0);
}

const rollback = await assetBytes(place);
const rollbackSha = createHash('sha256').update(rollback).digest('hex');
if (rollbackSha === createHash('sha256').update(candidate).digest('hex')) throw Error('Target already contains the prepared template/menu bytes');
let attempted = false;
try {
	attempted = true;
	const result = await publish(candidate);
	if (!result.versionNumber) throw Error('Roblox did not return a published place version');
	console.log('FPS_TEMPLATE_MENU_PUBLISHED ' + JSON.stringify({versionNumber: result.versionNumber, sourceId, sourceSha}));
	const live = await assetBytes(place, result.versionNumber);
	await fs.writeFile('/tmp/fps-system-demo-source', live);
	const liveSummary = verifyPatched();
	if (stable(liveSummary) !== stable(patched)) throw Error('Published place differs from the verified original template plus menu');
	const config = await api(`${cloud}universes/${universe}/places/${place}`);
	if (Number(config.serverSize) !== 10) {
		await api(`${cloud}universes/${universe}/places/${place}?updateMask=serverSize`, {method: 'PATCH', body: JSON.stringify({serverSize: 10})});
	}
	const verifiedConfig = await api(`${cloud}universes/${universe}/places/${place}`);
	if (Number(verifiedConfig.serverSize) !== 10) throw Error('Could not retain ten player slots');
	await restart();
console.log('FPS_TEMPLATE_MENU_RELEASE_COMPLETE ' + JSON.stringify({...liveSummary, sourceId, sourceSha, versionNumber: result.versionNumber, serverSize: Number(verifiedConfig.serverSize), restarted: true}));
} catch (error) {
	if (attempted) {
		const recovered = await publish(rollback);
		await restart();
		console.error('FPS_TEMPLATE_MENU_ROLLBACK ' + JSON.stringify({restoredVersion: recovered.versionNumber, previousSha: rollbackSha}));
	}
	throw error;
}
