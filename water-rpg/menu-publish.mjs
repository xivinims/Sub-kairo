import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
const universe=9421311218,place=118064584465155;
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
const base='https://apis.roblox.com/',cloud=base+'cloud/v2/';
async function api(url,method='GET',body){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(240000)});
 const raw=await response.text();let data;try{data=JSON.parse(raw)}catch{data={message:raw.slice(0,500)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(data));return data;
}
async function privateOnly(){
 const info=await api(`https://develop.roblox.com/v1/universes/${universe}`);
 if(info.isActive!==false)throw Error('Experience is not confirmed private; patch stopped');
}
async function execute(script){
 let job=await api(cloud+`universes/${universe}/places/${place}/luau-execution-session-tasks`,'POST',{timeout:'300s',script});
 const until=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(job.state)){
  if(Date.now()>until)throw Error('Native task timeout');await new Promise(r=>setTimeout(r,1500));job=await api(cloud+job.path);
 }
 if(job.state!=='COMPLETE'||job.error)throw Error('Native task failed: '+JSON.stringify(job.error||job));
 const value=job.output?.results?.[0];return typeof value==='string'?JSON.parse(value):value;
}
async function publish(bytes){
 const response=await fetch(base+`universes/v1/${universe}/places/${place}/versions?versionType=Published`,{method:'POST',headers:{'x-api-key':key,'content-type':'application/octet-stream'},body:bytes,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();if(!response.ok)throw Error('Place upload HTTP '+response.status+': '+raw.slice(0,500));return JSON.parse(raw);
}
const snapshot=`local function worldSnapshot()
 local counts={};local n=0;local x,y,z=0,0,0
 for _,v in ipairs(workspace:GetDescendants()) do
  if not v:IsA('Camera') and not v:IsA('Terrain') then counts[v.ClassName]=(counts[v.ClassName] or 0)+1 end
  if v:IsA('BasePart') and not v:IsA('Terrain') then n+=1;x+=v.Position.X;y+=v.Position.Y;z+=v.Position.Z end
 end
 local keys={};for k,v in pairs(counts) do table.insert(keys,k..'='..v) end;table.sort(keys)
 local clothes={};for _,v in ipairs(workspace.Residents:GetChildren()) do table.insert(clothes,v.Name..':'..v:GetAttribute('ExpectedShirt')..':'..v:GetAttribute('ExpectedPants')) end;table.sort(clothes)
 return table.concat(keys,';')..string.format('|%d|%.2f|%.2f|%.2f|',n,x,y,z)..table.concat(clothes,';')
end
`;
async function main(){
 await privateOnly();
 const before=await execute(snapshot+'return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute("WaterRPGBuild"),world=worldSnapshot()})');
 if(before.build!=='water-rpg-v1-assets')throw Error('Unexpected game; refusing patch');
 const delivery=await api(base+`asset-delivery-api/v1/assetId/${place}/version/${before.version}`);
 const location=delivery.location||delivery.locations?.[0]?.location;if(!location)throw Error('Live place location missing');
 const response=await fetch(location,{signal:AbortSignal.timeout(180000)});if(!response.ok)throw Error('Live place download failed');
 const old=Buffer.from(await response.arrayBuffer());await fs.writeFile('water-rpg/live-before-menu.rbxl',old);
 execFileSync('/tmp/water-lune/lune',['run','water-rpg/menu-patch.luau'],{stdio:'inherit'});
 const fresh=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(fresh.version!==before.version)throw Error('Live place changed; patch stopped');
 await privateOnly();
 const verify=await fs.readFile('water-rpg/menu-verify.luau','utf8');
 let version;
 try{
  const uploaded=await publish(await fs.readFile('water-rpg/menu-patched.rbxl'));version=uploaded.versionNumber;if(!version)throw Error('No published version');
  const after=await execute(snapshot+'local report=(function()\n'+verify+'\nend)()\nlocal result=game:GetService("HttpService"):JSONDecode(report)\nresult.world=worldSnapshot()\nreturn game:GetService("HttpService"):JSONEncode(result)');
  if(!after.ok||after.version!==version||after.world!==before.world)throw Error('Saved patch changed world or failed checks');
  await privateOnly();delete after.world;
  after.private=true;after.previousVersion=before.version;after.preservedWorld=true;after.sha256=createHash('sha256').update(await fs.readFile('water-rpg/menu-patched.rbxl')).digest('hex');
  await fs.writeFile('water-rpg/menu-publication.json',JSON.stringify(after,null,2));
  console.log('MENU_3D_PATCH_COMPLETE '+JSON.stringify(after));
  // A successful verification still does not substitute for opening the rendered client.
 }catch(error){
  if(version){const latest=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');if(latest.version===version){await publish(old);console.error('MENU_PATCH_ROLLED_BACK');}}
  throw error;
 }
}
main().catch(error=>{console.error(String(error.stack||error).split(key).join('[REDACTED]'));process.exitCode=1;});
