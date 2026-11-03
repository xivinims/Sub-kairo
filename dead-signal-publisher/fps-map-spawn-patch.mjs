import fs from 'node:fs/promises';

const universe = 9421311218;
const place = 118064584465155;
const sourceVersion = 300;
const cloud = 'https://apis.roblox.com/cloud/v2/';
const key = process.env.ROBLOX_API_KEY;
if (!key) throw Error('ROBLOX_API_KEY missing');
const trigger = (await fs.readFile(new URL('fps-map-spawn-patch.trigger', import.meta.url), 'utf8')).trim();
if (!/^fps-map-spawn-(preview|publish)-[a-zA-Z0-9-]+$/.test(trigger)) throw Error('Unexpected map/spawn operation');

async function api(url, {method = 'GET', body} = {}) {
  const response = await fetch(url, {
    method,
    headers: {'x-api-key': key, 'content-type': 'application/json'},
    body,
    signal: AbortSignal.timeout(240000),
  });
  const raw = await response.text();
  let data;
  try { data = JSON.parse(raw); } catch { data = {message: raw.slice(0, 1500)}; }
  if (!response.ok) throw Error(`Roblox HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}

async function execute(script, version) {
  const target = `${cloud}universes/${universe}/places/${place}/`;
  let task = await api(target + (version ? `versions/${version}/` : '') + 'luau-execution-session-tasks', {
    method: 'POST', body: JSON.stringify({timeout: '300s', script}),
  });
  const deadline = Date.now() + 420000;
  while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state) && Date.now() < deadline) {
    await new Promise(resolve => setTimeout(resolve, 1400));
    task = await api(cloud + task.path);
  }
  if (task.state !== 'COMPLETE' || task.error) {
    let logs;
    try { logs = await api(cloud + task.path + '/logs?view=FLAT'); } catch {}
    throw Error('Roblox native execution failed ' + JSON.stringify({task, logs}));
  }
  const result = task.output?.results?.[0];
  return typeof result === 'string' ? JSON.parse(result) : result;
}

const patch = await fs.readFile(new URL('fps-map-spawn-patch.luau', import.meta.url), 'utf8');
const liveBefore = await execute(`assert(game.GameId==${universe} and game.PlaceId==${place})\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,map=workspace:FindFirstChild("Map3")~=nil,spawn=workspace:FindFirstChild("SpawnLocation")~=nil,menu=game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DeadSignalMenu")~=nil})`);
if (liveBefore.version !== sourceVersion || !liveBefore.map || !liveBefore.spawn || !liveBefore.menu) {
  throw Error('Live FPS place is not the expected original build with its requested menu: ' + JSON.stringify(liveBefore));
}

const candidate = await execute(`assert(game.PlaceVersion==${sourceVersion},"Unexpected FPS source version")\nlocal result=(function()\n${patch}\nend)()\nreturn result`, sourceVersion);
if (!candidate?.mapRemoved || !candidate.spawnMoved || !candidate.weaponsPreserved || candidate.newSpawn?.x !== 500 || candidate.newSpawn?.z !== 500) {
  throw Error('Map/spawn preflight did not pass: ' + JSON.stringify(candidate));
}
console.log('FPS_MAP_SPAWN_PREFLIGHT ' + JSON.stringify({...candidate, sourceVersion, menuPreserved: true}));
if (trigger.startsWith('fps-map-spawn-preview-')) {
  console.log('FPS_MAP_SPAWN_PREVIEW_COMPLETE published=false');
  process.exit(0);
}

const current = await execute(`assert(game.GameId==${universe} and game.PlaceId==${place})\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})`);
if (current.version !== sourceVersion) throw Error('FPS place changed after preview; refusing to publish');
let saved = false;
try {
  const published = await execute(`assert(game.PlaceVersion==${sourceVersion},"Unexpected FPS source version")\nlocal result=(function()\n${patch}\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({saved=true,result=result})`, sourceVersion);
  saved = true;
  if (!published?.saved) throw Error('Roblox did not confirm the map/spawn save');
  const live = await execute(`assert(game.GameId==${universe} and game.PlaceId==${place})\nlocal spawn=workspace:FindFirstChild("SpawnLocation")\nassert(not workspace:FindFirstChild("Map3"),"Map3 still exists")\nassert(spawn and math.abs(spawn.Position.X-500)<0.01 and math.abs(spawn.Position.Z-500)<0.01,"Spawn position is incorrect")\nassert(game:GetService("ServerScriptService").Weapons:FindFirstChild("WeaponsServer"),"Original weapon server script missing")\nassert(game:GetService("ReplicatedStorage").Game.Weapons:FindFirstChild("M4A1"),"Original weapon data missing")\nassert(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DeadSignalMenu"),"Requested menu missing")\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,mapRemoved=true,spawn={x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z},weaponsPreserved=true,menuPreserved=true})`);
  if (live.version <= sourceVersion || !live.mapRemoved || !live.weaponsPreserved || !live.menuPreserved) throw Error('Published FPS place failed verification: ' + JSON.stringify(live));
  await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
  console.log('FPS_MAP_SPAWN_RELEASE_COMPLETE ' + JSON.stringify({...live, restarted: true}));
} catch (error) {
  if (saved) {
    try {
      await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restored=true})', sourceVersion);
      await api(`${cloud}universes/${universe}:restartServers`, {method: 'POST', body: '{}'});
      console.error('FPS_MAP_SPAWN_ROLLBACK restoredVersion=' + sourceVersion);
    } catch (rollbackError) {
      console.error('FPS_MAP_SPAWN_ROLLBACK_ERROR ' + String(rollbackError));
    }
  }
  throw error;
}
