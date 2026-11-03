import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
const apply=fs.readFileSync('treeworld-map-v14/apply.luau','utf8');
const verify=fs.readFileSync('treeworld-map-v14/verify.luau','utf8');
const result=first(await execute(apply));
if(!result?.ok) throw new Error('Map detail pass did not return ok');
console.log(JSON.stringify({stage:'map-pass-saved',...result}));
let persisted=null,last=null;
for(let i=0;i<10;i++){
  if(i) await sleep(3500);
  try{
    persisted=first(await execute(verify));
    if(!persisted?.ok) throw new Error('verify returned no ok');
    last=null;break;
  }catch(e){last=e;}
}
if(last) throw last;
console.log(JSON.stringify({stage:'map-pass-verified',...persisted}));
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'whole-map-v14-'+persisted.placeVersion,kind:'game-update'});
const quote=(s)=>'[====['+s.replaceAll(']====]','')+']====]';
const broadcast=first(await execute(`local ok,err=pcall(function()game:GetService('MessagingService'):PublishAsync('Overyard_Update_v1',${quote(payload)})end)return {ok=ok,error=ok and nil or tostring(err)}`));
console.log(JSON.stringify({stage:'update-migration',...broadcast}));
console.log(JSON.stringify({ok:true,verify:persisted,broadcast:!!broadcast?.ok}));