import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
const patch=fs.readFileSync('treeworld-caio-ground-v15/fix.luau','utf8');
const verify=fs.readFileSync('treeworld-caio-ground-v15/verify.luau','utf8');
const applied=first(await execute(patch));
if(!applied?.ok) throw new Error('Grounding patch failed');
console.log(JSON.stringify({stage:'grounded-and-saved',...applied}));
let persisted=null,last=null;
for(let i=0;i<10;i++){
  if(i) await sleep(3500);
  try{persisted=first(await execute(verify));if(!persisted?.ok)throw new Error('verify failed');last=null;break}catch(e){last=e;}
}
if(last)throw last;
if(persisted.placeVersion<=applied.sourceVersion)throw new Error('Place version did not advance');
console.log(JSON.stringify({stage:'verified-persisted',...persisted}));
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'caio-ground-v15-'+persisted.placeVersion,kind:'game-update'});
const quote=s=>'[====['+s.replaceAll(']====]','')+']====]';
const broadcast=first(await execute(`local ok,err=pcall(function()game:GetService('MessagingService'):PublishAsync('Overyard_Update_v1',${quote(payload)})end)return {ok=ok,error=ok and nil or tostring(err)}`));
console.log(JSON.stringify({stage:'update-migration',...broadcast}));
console.log(JSON.stringify({ok:true,verify:persisted,broadcast:!!broadcast?.ok}));