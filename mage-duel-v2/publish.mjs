import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
const quote=(s)=>{if(s.includes(']====]'))throw new Error('source delimiter collision');return '[====['+s+']====]';};
const server=fs.readFileSync('mage-duel-v2/magic-server.luau','utf8');
const client=fs.readFileSync('mage-duel-v2/magic-client.luau','utf8');
let installer=fs.readFileSync('mage-duel-v2/install.luau','utf8');
installer=installer.replace('__SERVER_SOURCE__',quote(server)).replace('__CLIENT_SOURCE__',quote(client));
const applied=first(await execute(installer));
if(!applied?.ok)throw new Error('V2 installer failed: '+JSON.stringify(applied));
console.log(JSON.stringify({stage:'v2-installed-and-saved',...applied}));
const verify=fs.readFileSync('mage-duel-v2/verify.luau','utf8');
let persisted=null,last=null;
for(let i=0;i<12;i++){
 if(i)await sleep(3500);
 try{persisted=first(await execute(verify));if(!persisted?.ok)throw new Error('verify returned no ok');last=null;break}catch(e){last=e;console.log(JSON.stringify({verifyRetry:i+1,error:String(e)}));}
}
if(last)throw last;
console.log(JSON.stringify({stage:'v2-verified-persisted',...persisted}));
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'mage-duel-v2-'+persisted.placeVersion,kind:'game-update'});
const broadcastScript="local ok,err=pcall(function()game:GetService('MessagingService'):PublishAsync('Overyard_Update_v1',"+quote(payload)+")end)return {ok=ok,error=ok and nil or tostring(err)}";
try{const b=first(await execute(broadcastScript));console.log(JSON.stringify({stage:'update-migration',...b}));}catch(e){console.log(JSON.stringify({stage:'update-migration-warning',error:String(e)}));}
console.log(JSON.stringify({ok:true,verify:persisted}));