import fs from 'node:fs';

const API='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';

async function request(path, body) {
  const key=process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Missing ROBLOX_API_KEY');
  const response=await fetch(API+path,{
    method: body ? 'POST' : 'GET',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body: body ? JSON.stringify(body) : undefined,
    signal:AbortSignal.timeout(30000),
  });
  const data=await response.json();
  if (!response.ok) throw new Error(JSON.stringify(data));
  return data;
}

async function execute(script) {
  let task=await request(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+240000;
  while (['QUEUED','PENDING','PROCESSING'].includes(task.state)) {
    if (Date.now()>deadline || !task.path.startsWith(TARGET)) throw new Error('Task timeout or wrong target');
    await new Promise(resolve=>setTimeout(resolve,1500));
    task=await request(task.path);
  }
  if (task.state!=='COMPLETE' || task.error) throw new Error(JSON.stringify(task));
  return task;
}

function firstResult(task) {
  const value=task.output?.results?.[0];
  if (typeof value!=='string') return value ?? null;
  try { return JSON.parse(value); } catch { return value; }
}

async function main() {
  const patch=firstResult(await execute(fs.readFileSync(new URL('./ui-zone-patch.luau',import.meta.url),'utf8')));
  let verifyTask=null;
  let lastError=null;
  for (let attempt=0; attempt<5; attempt++) {
    if (attempt) await new Promise(resolve=>setTimeout(resolve,2500));
    try {
      verifyTask=await execute(fs.readFileSync(new URL('./ui-zone-verify.luau',import.meta.url),'utf8'));
      lastError=null;
      break;
    } catch (error) {
      lastError=error;
    }
  }
  if (lastError) throw lastError;
  const verify=firstResult(verifyTask);
  const report={ok:true,patch,verify};
  console.log(JSON.stringify(report));
  fs.mkdirSync('out',{recursive:true});
  fs.writeFileSync('out/ui-zone-hotfix-result.json',JSON.stringify(report,null,2));
}

main().catch(error=>{
  const key=process.env.ROBLOX_API_KEY;
  console.error(key ? String(error.message).split(key).join('[REDACTED]') : error.message);
  process.exit(1);
});
