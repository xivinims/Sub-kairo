import fs from 'node:fs/promises';

const UNIVERSE_ID = '9421311218';
const PLACE_ID = '118064584465155';
const CLOUD = 'https://apis.roblox.com/cloud/v2/';
const TARGET = `universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function roblox(url, options = {}) {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');

  const response = await fetch(url, {
    method: options.method || 'GET',
    headers: {
      'x-api-key': key,
      'content-type': 'application/json',
    },
    body: options.body,
    signal: AbortSignal.timeout(options.timeoutMs || 240000),
  });

  const raw = await response.text();
  let data;
  try { data = JSON.parse(raw); } catch { data = { raw }; }

  if (!response.ok) {
    throw new Error('HTTP ' + response.status + ': ' + raw.slice(0, 1200));
  }
  return data;
}

async function execute(script) {
  let task = await roblox(CLOUD + TARGET + 'luau-execution-session-tasks', {
    method: 'POST',
    body: JSON.stringify({ timeout: '300s', script }),
  });

  const deadline = Date.now() + 420000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
    if (Date.now() > deadline) throw new Error('Execution timeout');
    if (!String(task.path || '').includes(TARGET)) throw new Error('Roblox returned a task for the wrong place');
    await sleep(1600);
    task = await roblox(CLOUD + task.path);
  }

  if (task.state !== 'COMPLETE' || task.error) {
    throw new Error(JSON.stringify(task.error || task));
  }

  const value = task.output?.results?.[0];
  if (typeof value === 'string') {
    try { return JSON.parse(value); } catch { return { raw: value }; }
  }
  return value;
}

async function main() {
  const source = await fs.readFile(new URL('./patch.luau', import.meta.url), 'utf8');
  if (!source.includes('DEAD_SIGNAL_PUBLISHER')) {
    throw new Error('patch.luau is missing the DEAD_SIGNAL_PUBLISHER safety marker');
  }

  const result = await execute(source);
  console.log(JSON.stringify({
    stage: 'dead-signal-publisher-complete',
    universeId: UNIVERSE_ID,
    placeId: PLACE_ID,
    result,
  }, null, 2));
}

main().catch((error) => {
  const key = process.env.ROBLOX_API_KEY;
  const message = String(error?.stack || error?.message || error);
  console.error(key ? message.split(key).join('[REDACTED]') : message);
  process.exit(1);
});
