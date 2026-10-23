import fs from 'node:fs';
const key=process.env.ROBLOX_API_KEY;
const form=new FormData();
form.append('request',JSON.stringify({assetType:'Image',displayName:'XN-VOICE Logo',description:'Logo original enviada por ch_ckz2n para o menu XN-VOICE.',creationContext:{creator:{userId:'8344738123'}}}));
form.append('fileContent',new Blob([fs.readFileSync('roblox-integrations/sakura97/branding/xn-voice.png')],{type:'image/png'}),'xn-voice.png');
const r=await fetch('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers:{'x-api-key':key},body:form});
const result=await r.json();
console.log('UPLOAD',r.status,JSON.stringify(result));
if(r.ok && result.path){
 for(let i=0;i<30;i++){
  await new Promise(resolve=>setTimeout(resolve,2000));
  const p=await fetch('https://apis.roblox.com/assets/v1/'+result.path,{headers:{'x-api-key':key}});
  const op=await p.json();
  if(op.done || !p.ok){console.log('LOGO_RESULT',JSON.stringify(op));break;}
 }
}
