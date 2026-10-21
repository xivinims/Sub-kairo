async function main() {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');

  const universeId = '9419478735';
  const placeId = '79738710219521';
  const api = 'https://apis.roblox.com/cloud/v2/';
  const target = `universes/${universeId}/places/${placeId}/`;

  async function request(path, body) {
    const response = await fetch(api + path, {
      method: body ? 'POST' : 'GET',
      headers: {'x-api-key': key, 'content-type': 'application/json'},
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(30000),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(JSON.stringify(data));
    return data;
  }

  async function execute(script) {
    let task = await request(target + 'luau-execution-session-tasks', {
      timeout: '180s',
      script,
    });
    const deadline = Date.now() + 240000;
    while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
      if (Date.now() > deadline || !task.path.startsWith(target)) {
        throw new Error('Task timeout or wrong target');
      }
      await new Promise(resolve => setTimeout(resolve, 1600));
      task = await request(task.path);
    }
    if (task.state !== 'COMPLETE' || task.error) throw new Error(JSON.stringify(task));
    return task;
  }

  // Intentionally no edits: save/publish the data model already present in this Place.
  const script = await (await fetch('https://raw.githubusercontent.com/xivinims/Sub-kairo/roblox-publisher/roblox-publisher/sakura-island.luau')).text();
  const result = await execute(script);

  console.log(JSON.stringify({
    state: result.state,
    target: {universeId, placeId},
    output: result.output
  }, null, 2));
}

main().catch(error => {
  const key = process.env.ROBLOX_API_KEY;
  console.error(key ? String(error.message).split(key).join('[REDACTED]') : error.message);
  process.exit(1);
});
