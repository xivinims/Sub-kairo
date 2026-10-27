import fs from 'node:fs/promises';

const UNIVERSE_ID = '9421311218';
const PLACE_ID = '118064584465155';
const BUILD_ID = 'dead-signal-social-lobby-v1';
const CLOUD = 'https://apis.roblox.com/cloud/v2/';
const TARGET = 'universes/' + UNIVERSE_ID + '/places/' + PLACE_ID + '/';
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function roblox(url, options = {}) {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');
  let last;
  for (let attempt = 0; attempt < 6; attempt++) {
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

    if (response.ok) return data;
    last = new Error('HTTP ' + response.status + ': ' + raw.slice(0, 1200));
    if (![429, 500, 502, 503, 504].includes(response.status)) throw last;
    await sleep(2500 * (attempt + 1));
  }
  throw last;
}

async function execute(script, label) {
  let task = await roblox(CLOUD + TARGET + 'luau-execution-session-tasks', {
    method: 'POST',
    body: JSON.stringify({ timeout: '300s', script }),
  });

  const deadline = Date.now() + 420000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
    if (Date.now() > deadline) throw new Error(label + ': timeout');
    if (!String(task.path || '').includes(TARGET)) throw new Error(label + ': wrong target');
    await sleep(1600);
    task = await roblox(CLOUD + task.path);
  }

  if (task.state !== 'COMPLETE' || task.error) {
    throw new Error(label + ': ' + JSON.stringify(task.error || task));
  }

  const value = task.output?.results?.[0];
  if (typeof value === 'string') {
    try { return JSON.parse(value); } catch { return { raw: value }; }
  }
  return value;
}

function luaLongString(source) {
  const close = ']====]';
  if (source.includes(close)) throw new Error('Luau source delimiter collision');
  return '[====[' + source + close;
}

async function main() {
  const [patch, server, client, loading, verify] = await Promise.all([
    fs.readFile(new URL('./patch.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./server.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./client.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./loading.luau', import.meta.url), 'utf8'),
    fs.readFile(new URL('./verify.luau', import.meta.url), 'utf8'),
  ]);

  let install = patch
    .replace('__SERVER_SOURCE__', luaLongString(server))
    .replace('__CLIENT_SOURCE__', luaLongString(client))
    .replace('__LOADING_SOURCE__', luaLongString(loading));

  if (install.includes('__SERVER_SOURCE__') || install.includes('__CLIENT_SOURCE__') || install.includes('__LOADING_SOURCE__')) {
    throw new Error('Publisher source placeholder replacement failed');
  }
  if (!install.includes(BUILD_ID)) throw new Error('Build marker missing');

  const installed = await execute(install, 'install');
  if (!installed?.ok || !installed?.published || installed.build !== BUILD_ID) {
    throw new Error('Install failed: ' + JSON.stringify(installed));
  }

  await sleep(3500);
  const verified = await execute(verify, 'verify');
  if (!verified?.ok || verified.build !== BUILD_ID) {
    throw new Error('Verification failed: ' + JSON.stringify(verified));
  }

  let restart = {};
  try {
    restart = await roblox(CLOUD + 'universes/' + UNIVERSE_ID + ':restartServers', {
      method: 'POST',
      body: '{}',
    });
  } catch (error) {
    restart = { warning: String(error?.message || error) };
  }

  console.log(JSON.stringify({
    stage: 'dead-signal-social-lobby-published',
    universeId: UNIVERSE_ID,
    placeId: PLACE_ID,
    installed,
    verified,
    restart,
  }, null, 2));
}

main().catch((error) => {
  const key = process.env.ROBLOX_API_KEY;
  const message = String(error?.stack || error?.message || error);
  console.error(key ? message.split(key).join('[REDACTED]') : message);
  process.exit(1);
});
