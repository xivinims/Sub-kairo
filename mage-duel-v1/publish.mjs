import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';

const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
const quote=(s)=>{
  if(s.includes(']====]')) throw new Error('Runtime source contains delimiter');
  return '[====['+s+']====]';
};

const server=fs.readFileSync('mage-duel-v1/magic-server.luau','utf8');
const client=fs.readFileSync('mage-duel-v1/magic-client.luau','utf8');
let installer=fs.readFileSync('mage-duel-v1/install.luau','utf8');
installer=installer.replace('__SERVER_SOURCE__',quote(server)).replace('__CLIENT_SOURCE__',quote(client));

const applied=first(await execute(installer));
if(!applied?.ok) throw new Error('Installer did not return ok=true: '+JSON.stringify(applied));
console.log(JSON.stringify({stage:'installed-and-saved',...applied}));

const verifySource=fs.readFileSync('mage-duel-v1/verify.luau','utf8');
let persisted=null,last=null;
for(let i=0;i<12;i++){
  if(i) await sleep(3500);
  try{
    persisted=first(await execute(verifySource));
    if(!persisted?.ok) throw new Error('verify returned no ok');
    last=null;break;
  }catch(e){last=e;console.log(JSON.stringify({verifyRetry:i+1,error:String(e)}));}
}
if(last) throw last;
if(Number(persisted.placeVersion)<=Number(applied.sourceVersion)) throw new Error('Place version did not advance');
console.log(JSON.stringify({stage:'verified-persisted',...persisted}));

const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'mage-duel-v1-'+persisted.placeVersion,kind:'game-update'});
const broadcastScript="local MessagingService=game:GetService('MessagingService')\nlocal ok,err=pcall(function() MessagingService:PublishAsync('Overyard_Update_v1',"+quote(payload)+") end)\nreturn {ok=ok,error=ok and nil or tostring(err)}";
try{
  const broadcast=first(await execute(broadcastScript));
  console.log(JSON.stringify({stage:'update-migration',...broadcast}));
}catch(e){
  console.log(JSON.stringify({stage:'update-migration-warning',error:String(e)}));
}
console.log(JSON.stringify({ok:true,verify:persisted}));
