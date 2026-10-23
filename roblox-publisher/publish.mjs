import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';

const UNIVERSE_ID = '9419478735';
const PLACE_ID = '79738710219521';
const CLOUD = 'https://apis.roblox.com/cloud/v2/';
const TARGET = `universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function placeKind(buffer) {
  if (buffer.subarray(0, 8).toString('latin1') === '<roblox!') return 'rbxl';
  if (buffer.subarray(0, 240).toString('utf8').includes('<roblox')) return 'rbxlx';
  return null;
}

async function roblox(url, options = {}) {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');
  let last;
  for (let attempt = 0; attempt < 6; attempt++) {
    const response = await fetch(url, {
      method: options.method || 'GET',
      headers: { 'x-api-key': key, ...(options.headers || {}) },
      body: options.body,
      redirect: options.redirect || 'follow',
      signal: AbortSignal.timeout(options.timeoutMs || 180000),
    });
    if (response.ok || (response.status >= 300 && response.status < 400)) return response;
    const body = await response.text();
    last = new Error(`HTTP ${response.status} ${url}: ${body.slice(0, 700)}`);
    if (![429, 500, 502, 503, 504].includes(response.status)) throw last;
    const retryAfter = Number(response.headers.get('retry-after'));
    await sleep(Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter * 1000 : 4000 * (attempt + 1));
  }
  throw last;
}

async function bytesFrom(response) {
  const buffer = Buffer.from(await response.arrayBuffer());
  if (buffer.length >= 2 && buffer[0] === 0x1f && buffer[1] === 0x8b) return gunzipSync(buffer);
  return buffer;
}

async function downloadCurrentPlace() {
  const endpoints = [
    `https://apis.roblox.com/asset-delivery-api/v1/assetId/${PLACE_ID}`,
    `https://assetdelivery.roblox.com/v1/openCloud/assetId/${PLACE_ID}`,
  ];
  const errors = [];
  for (const endpoint of endpoints) {
    try {
      const response = await roblox(endpoint, {
        headers: { accept: 'application/json' },
        redirect: 'manual',
        timeoutMs: 60000,
      });
      const location = response.headers.get('location');
      if (location) {
        const file = await fetch(location, { redirect: 'follow', signal: AbortSignal.timeout(180000) });
        if (!file.ok) throw new Error(`location HTTP ${file.status}`);
        return bytesFrom(file);
      }
      const type = response.headers.get('content-type') || '';
      if (type.includes('json') || response.headers.get('content-type') === null) {
        const text = await response.text();
        const data = JSON.parse(text);
        if (!data.location) throw new Error(`no location: ${text.slice(0, 400)}`);
        const file = await fetch(data.location, { redirect: 'follow', signal: AbortSignal.timeout(180000) });
        if (!file.ok) throw new Error(`location HTTP ${file.status}`);
        return bytesFrom(file);
      }
      return bytesFrom(response);
    } catch (error) {
      errors.push(`${endpoint}: ${error.message}`);
    }
  }
  throw new Error(errors.join(' | '));
}

async function execute(script) {
  const created = await roblox(CLOUD + TARGET + 'luau-execution-session-tasks', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ timeout: '60s', script }),
    timeoutMs: 60000,
  });
  let task = await created.json();
  const deadline = Date.now() + 180000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
    if (Date.now() > deadline) throw new Error('Read-only inventory timed out');
    await sleep(1500);
    task = await (await roblox(CLOUD + task.path, { timeoutMs: 60000 })).json();
  }
  if (task.state !== 'COMPLETE' || task.error) throw new Error(`Inventory failed: ${JSON.stringify(task.error || task)}`);
  const value = task.output?.results?.[0];
  return typeof value === 'string' ? JSON.parse(value) : value;
}

async function inventory() {
  return execute(`
local HttpService = game:GetService("HttpService")
local function names(parent, limit)
  local list = {}
  if not parent then return list end
  for _, child in ipairs(parent:GetChildren()) do
    table.insert(list, child.ClassName .. ":" .. child.Name)
    if #list >= limit then break end
  end
  table.sort(list)
  return list
end
return HttpService:JSONEncode({
  ok = true,
  placeVersion = game.PlaceVersion,
  placeId = game.PlaceId,
  universeId = game.GameId,
  workspace = names(workspace, 40),
  serverStorage = names(game:GetService("ServerStorage"), 40),
  serverScripts = names(game:GetService("ServerScriptService"), 40),
  replicated = names(game:GetService("ReplicatedStorage"), 40)
})
`);
}

async function publishUnchanged(buffer, kind) {
  const response = await roblox(
    `https://apis.roblox.com/universes/v1/${UNIVERSE_ID}/places/${PLACE_ID}/versions?versionType=Published`,
    {
      method: 'POST',
      headers: { 'content-type': kind === 'rbxlx' ? 'application/xml' : 'application/octet-stream' },
      body: buffer,
      timeoutMs: 300000,
    },
  );
  const text = await response.text();
  const data = JSON.parse(text);
  if (!data.versionNumber) throw new Error(`Publish response missing version: ${text.slice(0, 500)}`);
  return data;
}

async function main() {
  console.log('[Survivers] Inventory only. The data model will not be edited.');
  const before = await inventory();
  if (String(before.placeId) !== PLACE_ID || String(before.universeId) !== UNIVERSE_ID) {
    throw new Error(`Wrong target: ${JSON.stringify(before)}`);
  }
  console.log(JSON.stringify({ stage: 'saved-place', ...before }));

  const file = await downloadCurrentPlace();
  const kind = placeKind(file);
  if (!kind) {
    throw new Error(`Downloaded file is not a Roblox place (${file.length} bytes, head=${file.subarray(0, 24).toString('hex')})`);
  }
  const sha256 = createHash('sha256').update(file).digest('hex');
  console.log(JSON.stringify({ stage: 'downloaded-unchanged', kind, bytes: file.length, sha256 }));

  const published = await publishUnchanged(file, kind);
  console.log(JSON.stringify({
    stage: 'published-intact',
    sourceVersion: before.placeVersion,
    publishedVersion: published.versionNumber,
    bytes: file.length,
    sha256,
    workspace: before.workspace,
  }));
}

main().catch((error) => {
  const key = process.env.ROBLOX_API_KEY;
  console.error(key ? String(error.stack || error.message).split(key).join('[REDACTED]') : (error.stack || error.message));
  process.exit(1);
});
