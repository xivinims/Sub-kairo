import fs from 'node:fs/promises';
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;if(!key)throw Error('Missing ROBLOX_API_KEY');
async function api(path,method='GET',body){const r=await fetch(cloud+path,{method,headers:{'x-api-key':key,'content-type':'application/json'},body:body&&JSON.stringify(body),signal:AbortSignal.timeout(240000)});const data=await r.json();if(!r.ok)throw Error('HTTP '+r.status+' '+JSON.stringify(data));return data;}
const script=await fs.readFile(new URL('./hudfix-audit.luau',import.meta.url),'utf8');
let task=await api('universes/9421311218/places/118064584465155/luau-execution-session-tasks','POST',{timeout:'300s',script});
const deadline=Date.now()+420000;
while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<deadline){await new Promise(r=>setTimeout(r,1500));task=await api(task.path);}
if(task.state!=='COMPLETE'||task.error)throw Error(JSON.stringify(task));
const value=task.output?.results?.[0];console.log('HUDFIX_AUDIT '+(typeof value==='string'?value:JSON.stringify(value)));
