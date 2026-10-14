import fs from 'node:fs';
import crypto from 'node:crypto';
import {editPlace} from './place-settings.mjs';

async function main() {
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');
  const api = 'https://apis.roblox.com/cloud/v2/';
  const target = 'universes/9421311218/places/118064584465155/';
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
    let task = await request(target + 'luau-execution-session-tasks', {timeout: '180s', script});
    const deadline = Date.now() + 240000;
    while (['QUEUED', 'PENDING', 'PROCESSING'].includes(task.state)) {
      if (Date.now() > deadline || !task.path.startsWith(target)) throw new Error('Task timeout or wrong target');
      await new Promise(resolve => setTimeout(resolve, 1600));
      task = await request(task.path);
    }
    if (task.state !== 'COMPLETE' || task.error) throw new Error(JSON.stringify(task));
    return task;
  }
  const script = fs.readFileSync(new URL('./patch.luau', import.meta.url), 'utf8');
  const installation = await execute(script);
  let publication = null;
  const result = installation.output?.results?.[0];
  if (result?.binaryPlaceBase64) {
    const original = Buffer.from(result.binaryPlaceBase64, 'base64');
    delete result.binaryPlaceBase64;
    const edited = editPlace(original);
    const sha256 = crypto.createHash('sha256').update(edited.buffer).digest('hex');
    publication = {bytes: edited.buffer.length, sha256, changes: edited.changes, classCount: edited.classes.length};
    fs.mkdirSync('out', {recursive: true});
    fs.writeFileSync('out/TreeWorld.rbxl', edited.buffer);
    if (result.exportOnly !== true) {
      const response = await fetch('https://apis.roblox.com/universes/v1/9421311218/places/118064584465155/versions?versionType=Published', {
        method: 'POST', headers: {'x-api-key':key, 'content-type':'application/octet-stream'}, body:edited.buffer, signal:AbortSignal.timeout(60000)
      });
      const data = await response.json();
      if (!response.ok) throw new Error('Place publication rejected: '+JSON.stringify(data));
      publication.versionNumber = data.versionNumber;
      if (data.versionNumber !== result.expectedVersion) throw new Error('Unexpected saved place version '+data.versionNumber);
      result.published = true;
    }
  }
  // Saving succeeds before the independent fresh-session check. Log it immediately.
  const sourceSha256 = crypto.createHash('sha256').update(script).digest('hex');
  console.log(JSON.stringify({installationState: installation.state,
    published: installation.output?.results?.[0]?.published, sourceSha256}));
  let freshVerification = null;
  if (installation.output?.results?.[0]?.published === true) {
    freshVerification = await execute(fs.readFileSync(new URL('./verify.luau', import.meta.url), 'utf8'));
  }
  const report = {sourceSha256, installation, publication, freshVerification};
  fs.mkdirSync('out', {recursive: true});
  fs.writeFileSync('out/result.json', JSON.stringify(report, null, 2));
  fs.writeFileSync('out/index.html', '<!doctype html><title>Overyard publisher</title>Completed');
  console.log(JSON.stringify({state: installation.state, published: installation.output?.results?.[0]?.published,
    freshVersion: freshVerification?.output?.results?.[0]?.version, sourceSha256: report.sourceSha256}));
  const text = JSON.stringify(report);
  for (let i=0; i<text.length; i+=1200) console.log(JSON.stringify({offset: i, length: text.length, data: text.slice(i,i+1200)}));
}
main().catch(error => {
  const key = process.env.ROBLOX_API_KEY;
  console.error(key ? String(error.message).split(key).join('[REDACTED]') : error.message);
  process.exit(1);
});

