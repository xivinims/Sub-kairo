import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';

const UNIVERSE_ID = '9419478735';
const PLACE_ID = '79738710219521';
const CLOUD = 'https://apis.roblox.com/cloud/v2/';
const TARGET = `universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function placeKind(buffer) {
  const head = buffer.subarray(0, 32).toString('latin1');
  if (head.startsWith('<roblox!')) return 'rbxl';
  const text = buffer.subarray(0, 240).toString('utf8');
  if (text.includes('<roblox')) return 'rbxlx';
  return null;
}

async function roblox(url, options = {}) {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');
  const headers = { 'x-api-key': key, ...(options.headers || {}) };
  let last;
  for (let attempt = 0; attempt < 6; attempt++) {
    const response = await fetch(url, {
      ...options,
      headers,
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
      if (type.includes('json')) {
        const data = JSON.parse(await response.text());
        if (!data.location) throw new Error(`no location: ${JSON.stringify(data).slice(0, 400)}`);
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
  let task = await (await roblox(CLOUD + TARGET + 'luau-execution-session-tasks', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ timeout: '60s', script }),
    timeoutMs: 60000,
  })).json();
  const deadline = Date.now() + 180000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
    if (Date.now() > deadline) throw new Error('Read-only audit timed out');
    await sleep(1500);
    task = await (await roblox(CLOUD + task.path, { timeoutMs: 60000 })).json();
  }
  if (task.state !== 'COMPLETE' || task.error) throw new Error(`Audit failed: ${JSON.stringify(task.error || task)}`);
  const value = task.output?.results?.[0];
  if (typeof value === 'string') {
    try { return JSON.parse(value); } catch { return value; }
  }
  return value;
}

async function audit() {
  const report = await execute(`
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ServerStorage:FindFirstChild("SurvivalAssets")
local maps = assets and assets:FindFirstChild("Maps")
local killers = assets and assets:FindFirstChild("Killers")
local function names(folder)
  if not folder then return {} end
  local list = {}
  for _, child in ipairs(folder:GetChildren()) do table.insert(list, child.Name) end
  table.sort(list)
  return list
end
return HttpService:JSONEncode({
  ok = true,
  placeVersion = game.PlaceVersion,
  placeId = game.PlaceId,
  universeId = game.GameId,
  lobby = workspace:FindFirstChild("JediLibrary") ~= nil,
  menu = ReplicatedStorage:FindFirstChild("MenuSceneTemplate") ~= nil,
  spawn = workspace:FindFirstChild("IslandSpawn") ~= nil,
  maps = maps and #maps:GetChildren() or 0,
  mapNames = names(maps),
  killers = killers and #killers:GetChildren() or 0,
  killerNames = names(killers),
  workspaceChildren = #workspace:GetChildren()
})
`);
  if (!report || report.ok !== true) throw new Error(`Unexpected audit: ${JSON.stringify(report)}`);
  if (String(report.placeId) !== PLACE_ID || String(report.universeId) !== UNIVERSE_ID) {
    throw new Error(`Audit targeted the wrong place: ${JSON.stringify(report)}`);
  }
  return report;
}

function assertIntact(report) {
  const problems = [];
  if (!report.lobby) problems.push('JediLibrary ausente');
  if (!report.menu) problems.push('MenuSceneTemplate ausente');
  if (!(report.maps >= 4)) problems.push(`mapas=${report.maps}`);
  if (!(report.killers >= 5)) problems.push(`persuasores=${report.killers}`);
  if (problems.length) {
    throw new Error(`Publicação recusada: o place atual não está intacto (${problems.join('; ')})`);
  }
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
  let data;
  try { data = JSON.parse(text); } catch { data = { raw: text }; }
  if (!data.versionNumber) throw new Error(`Publish response missing version: ${text.slice(0, 500)}`);
  return data;
}

async function main() {
  console.log('[Survivers] Reading the current place. No instances will be changed.');
  const before = await audit();
  assertIntact(before);
  console.log(JSON.stringify({ stage: 'current-place', ...before }));

  const file = await downloadCurrentPlace();
  const kind = placeKind(file);
  if (!kind) throw new Error(`Downloaded file is not a Roblox place (${file.length} bytes)`);
  if (file.length < 1024 * 1024) throw new Error(`Downloaded place is unexpectedly small: ${file.length} bytes`);
  const sha256 = createHash('sha256').update(file).digest('hex');
  console.log(JSON.stringify({ stage: 'downloaded-unchanged', kind, bytes: file.length, sha256 }));

  const published = await publishUnchanged(file, kind);
  console.log(JSON.stringify({
    stage: 'published-intact',
    sourceVersion: before.placeVersion,
    publishedVersion: published.versionNumber,
    bytes: file.length,
    sha256,
    maps: before.mapNames,
    killers: before.killerNames,
    lobby: before.lobby,
    menu: before.menu,
  }));
}

main().catch((error) => {
  const key = process.env.ROBLOX_API_KEY;
  const message = key ? String(error.message).split(key).join('[REDACTED]') : error.message;
  console.error(message);
  process.exit(1);
});
