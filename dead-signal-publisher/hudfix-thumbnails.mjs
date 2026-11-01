const groups={
 model:[83500345427472,107334696550674,89233139303617,109832092332101,125455543249809,105626955031074,101022964707613,136607663640668,113042723157882,98662889400052,83154514153036,140681169121557,129880717419683,73571659655933],
 texture:[101245974370250,109939087665590,122689343330229,140271244030746],
};
for(const [kind,ids]of Object.entries(groups)){
 const url='https://thumbnails.roblox.com/v1/assets?assetIds='+ids.join(',')+'&size=150x150&format=Png&isCircular=false';
 const r=await fetch(url,{signal:AbortSignal.timeout(60000)});const raw=await r.text();if(!r.ok)throw Error('Thumbnail API HTTP '+r.status+': '+raw.slice(0,500));
 const parsed=JSON.parse(raw);const results=[];
 for(const row of parsed.data||[]){
  let bytes=0,type='',status='';
  if(row.imageUrl&&row.state==='Completed'){
   const image=await fetch(row.imageUrl,{signal:AbortSignal.timeout(30000)});status='HTTP '+image.status;
   if(image.ok){const data=Buffer.from(await image.arrayBuffer());bytes=data.length;type=image.headers.get('content-type')||'';}
  }
  results.push({id:row.targetId,state:row.state,status,bytes,type});
 }
 console.log('HUDFIX_THUMBNAILS '+JSON.stringify({kind,results}));
}
