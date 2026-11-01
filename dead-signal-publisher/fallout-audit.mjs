import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('Missing ROBLOX_API_KEY');
const base='https://apis.roblox.com/cloud/v2/';
async function json(url,options={}) {
 const r=await fetch(url,{...options,headers:{'x-api-key':key,'content-type':'application/json',...options.headers},signal:AbortSignal.timeout(240000)});
 const text=await r.text();let data;try{data=JSON.parse(text)}catch{data={message:text.slice(0,1000)}}
 if(!r.ok)throw Error('HTTP '+r.status+' '+JSON.stringify(data));return data;
}
for(const [name,id] of [['current',118064584465155],['fallout',8438960542],['lobby',95512398319263],['animations',86582491164528],['fps',15864801103]]) {
 try {
 let metadata={};try{metadata=await json('https://economy.roblox.com/v2/assets/'+id+'/details')}catch(e){console.log('METADATA_WARNING '+name+' '+String(e))}
 const delivery=await json('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+id);
 const location=delivery.location||delivery.locations?.[0]?.location;
 if(!location)throw Error('Asset has no download location');
 const response=await fetch(location,{signal:AbortSignal.timeout(240000)});if(!response.ok)throw Error('Asset download HTTP '+response.status);
 const bytes=Buffer.from(await response.arrayBuffer());await fs.writeFile('/tmp/fallout-'+name,bytes);
 console.log('ASSET_METADATA '+JSON.stringify({name,id,title:metadata.Name,type:metadata.AssetTypeId,creator:metadata.Creator,description:metadata.Description,sha256:createHash('sha256').update(bytes).digest('hex'),bytes:bytes.length}));
 }catch(e){console.log('ASSET_ERROR '+JSON.stringify({name,id,error:String(e)}));}
}
const response=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
if(!response.ok)throw Error('Lune download failed');const zip=Buffer.from(await response.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/fallout-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/fallout-lune.zip','-d','/tmp/fallout-lune']);await fs.chmod('/tmp/fallout-lune/lune',0o755);
execFileSync('/tmp/fallout-lune/lune',['run','fallout-audit.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
try{console.log('PLACE_CONFIGURATION '+JSON.stringify(await json(base+'universes/9421311218/places/118064584465155')))}catch(e){console.log('PLACE_CONFIGURATION_ERROR '+String(e))}
const script=`local P=game:GetService('Players')
local result={place=game.PlaceId,version=game.PlaceVersion,universe=game.GameId,creatorId=game.CreatorId,creatorType=game.CreatorType.Name,maxPlayers=P.MaxPlayers,attributes=workspace:GetAttributes(),tools={}}
for _,i in ipairs(game:GetDescendants()) do if i:IsA('Tool') then table.insert(result.tools,i:GetFullName()) end end
if game.CreatorType==Enum.CreatorType.User then local ok,name=pcall(function() return P:GetNameFromUserIdAsync(game.CreatorId) end);result.creatorName=ok and name or nil end
return game:GetService('HttpService'):JSONEncode(result)`;
let task=await json(base+'universes/9421311218/places/118064584465155/luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'180s',script})});
const deadline=Date.now()+300000;
while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<deadline){await new Promise(r=>setTimeout(r,1500));task=await json(base+task.path)}
console.log('LIVE_SNAPSHOT '+JSON.stringify(task));
