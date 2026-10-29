const key=process.env.ROBLOX_API_KEY;
if(!key) throw new Error('Missing ROBLOX_API_KEY');
async function api(path,method='GET',body){
 const r=await fetch('https://apis.roblox.com/cloud/v2/'+path,{method,headers:{'x-api-key':key,'content-type':'application/json'},body:body&&JSON.stringify(body)});
 const text=await r.text();if(!r.ok)throw new Error('HTTP '+r.status+': '+text.slice(0,900));return text?JSON.parse(text):{};
}
for(const path of ['universes/9421311218','universes/9421311218/places/118064584465155']){
 await api(path+'?updateMask=displayName,description','PATCH',{displayName:'Still Here',description:''});
 const v=await api(path);
 if(v.displayName!=='Still Here'||(v.description||'')!=='')throw new Error('Metadata verification failed');
 console.log(JSON.stringify({path,displayName:v.displayName,description:v.description||'',verified:true}));
}
