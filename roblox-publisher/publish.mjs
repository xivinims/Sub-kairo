const UNIVERSE_ID = '9419478735';
const PLACE_ID = '79738710219521';
const CLOUD = 'https://apis.roblox.com/cloud/v2/';
const TARGET = `universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function roblox(url, options = {}) {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');
  let last;
  for (let attempt = 0; attempt < 6; attempt++) {
    const response = await fetch(url, {
      method: options.method || 'GET',
      headers: { 'x-api-key': key, 'content-type': 'application/json' },
      body: options.body,
      signal: AbortSignal.timeout(options.timeoutMs || 60000),
    });
    const text = await response.text();
    let data;
    try { data = JSON.parse(text); } catch { data = { raw: text }; }
    if (response.ok) return data;
    last = new Error(`HTTP ${response.status}: ${text.slice(0, 800)}`);
    if (![429, 500, 502, 503, 504].includes(response.status)) throw last;
    const retryAfter = Number(response.headers.get('retry-after'));
    await sleep(Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter * 1000 : 4000 * (attempt + 1));
  }
  throw last;
}

async function execute(script) {
  let task = await roblox(CLOUD + TARGET + 'luau-execution-session-tasks', {
    method: 'POST',
    body: JSON.stringify({ timeout: '180s', script }),
  });
  const deadline = Date.now() + 240000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
    if (Date.now() > deadline || !String(task.path || '').includes(TARGET)) {
      throw new Error('Task timeout or wrong target');
    }
    await sleep(1600);
    task = await roblox(CLOUD + task.path);
  }
  if (task.state !== 'COMPLETE' || task.error) throw new Error(JSON.stringify(task.error || task));
  const value = task.output?.results?.[0];
  return typeof value === 'string' ? JSON.parse(value) : value;
}

async function main() {
  // No instances are created, deleted, or rewritten. This only publishes the saved data model.
  const result = await execute(`
local HttpService = game:GetService("HttpService")
local function names(parent)
  local list = {}
  for _, child in ipairs(parent:GetChildren()) do
    table.insert(list, child.ClassName .. ":" .. child.Name)
  end
  table.sort(list)
  return list
end
local before = game.PlaceVersion
if game.GameId ~= ${UNIVERSE_ID} or game.PlaceId ~= ${PLACE_ID} then
  error("Wrong target place")
end
game:GetService("AssetService"):SavePlaceAsync()
return HttpService:JSONEncode({
  ok = true,
  beforeVersion = before,
  placeVersion = game.PlaceVersion,
  placeId = game.PlaceId,
  universeId = game.GameId,
  workspace = names(workspace),
  serverScripts = names(game:GetService("ServerScriptService")),
  serverStorage = names(game:GetService("ServerStorage")),
  replicated = names(game:GetService("ReplicatedStorage"))
})
`);
  if (!result?.ok || String(result.placeId) !== PLACE_ID) {
    throw new Error(`Publish did not confirm the target place: ${JSON.stringify(result)}`);
  }
  console.log(JSON.stringify({ stage: 'published-unchanged', ...result }, null, 2));
}

main().catch((error) => {
  const key = process.env.ROBLOX_API_KEY;
  console.error(key ? String(error.stack || error.message).split(key).join('[REDACTED]') : (error.stack || error.message));
  process.exit(1);
});
