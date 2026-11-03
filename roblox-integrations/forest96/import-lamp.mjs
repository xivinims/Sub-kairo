import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const data=await readFile('roblox-integrations/forest96/sei-la-sksksks.fbx');
if(createHash('sha256').update(data).digest('hex')!=='02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688')throw Error('FBX checksum mismatch');
const form=new FormData();
form.append('request',JSON.stringify({assetType:'Model',displayName:'TreeWorld Gnarled Lantern Post',description:'User supplied sei-la-sksksks.fbx lantern for TreeWorld.',creationContext:{creator:{userId:'8344738123'}}}));
form.append('fileContent',new Blob([data],{type:'model/fbx'}),'sei-la-sksksks.fbx');
const headers={'x-api-key':process.env.ROBLOX_API_KEY};
const response=await fetch('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers,body:form});
let result=await response.json();
console.log(JSON.stringify({importStatus:response.status,result}));
if(!response.ok)process.exit(1);
for(let i=0;!result.done&&i<80;i++){
 await new Promise(resolve=>setTimeout(resolve,3000));
 const r=await fetch('https://apis.roblox.com/assets/v1/'+result.path,{headers});
 if(!r.ok)throw Error('Operation lookup '+r.status);
 result=await r.json();
}
console.log(JSON.stringify({lampImport:result}));
if(!result.done||result.error)process.exit(1);
