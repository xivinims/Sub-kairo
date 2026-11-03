const universe = 9421311218;
const place = 118064584465155;
const apiBase = 'https://apis.roblox.com/cloud/v2/';
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error('ROBLOX_API_KEY missing');

async function api(url, {method = 'GET', body} = {}) {
  const response = await fetch(url, {
    method,
    headers: {'x-api-key': key, 'content-type': 'application/json'},
    body,
    signal: AbortSignal.timeout(60000),
  });
  const raw = await response.text();
  let value;
  try { value = JSON.parse(raw); } catch { value = {message: raw.slice(0, 1500)}; }
  if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(value)}`);
  return value;
}

const path = `${apiBase}universes/${universe}/places/${place}`;
const before = await api(path);
console.log('FPS_SERVER_SIZE_BEFORE ' + JSON.stringify({serverSize: before.serverSize}));
if (Number(before.serverSize) !== 10) {
  await api(path + '?updateMask=serverSize', {
    method: 'PATCH',
    body: JSON.stringify({serverSize: 10}),
  });
}

let after = await api(path);
for (let attempt = 0; Number(after.serverSize) !== 10 && attempt < 8; attempt++) {
  await new Promise(resolve => setTimeout(resolve, 2500));
  after = await api(path);
}
if (Number(after.serverSize) !== 10) throw Error('Roblox did not confirm a server size of 10: ' + JSON.stringify(after));
await api(`${apiBase}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
console.log('FPS_SERVER_SIZE_COMPLETE ' + JSON.stringify({serverSize: Number(after.serverSize), place, universe, restarted: true}));
