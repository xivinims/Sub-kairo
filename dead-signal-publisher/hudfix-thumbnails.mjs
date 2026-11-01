import {createHash} from 'node:crypto';
const ids=[83500345427472,107334696550674,89233196303717,109832092332101,125455543249809,105626955031074,101022964707613,136607663640668,113042723157882,98662889400052,83154514153036,140681169121557,129880717419683,73571659655933,101245974370250,109939087665590,122689343330229,140271244030746];
const url='https://thumbnails.roblox.com/v1/assets?assetIds='+ids.join(',')+'&size=150x150&format=Png&isCircular=false';
const r=await fetch(url,{signal:AbortSignal.timeout(60000)});const raw=await r.text();if(!r.ok)throw Error('Thumbnail API HTTP '+r.status+': '+raw.slice(0,500));
const parsed=JSON.parse(raw);const results=[];
for(const row of parsed.data||[]){let details={id:row.targetId,state:row.state,imageUrl:row.imageUrl};
 if(row.imageUrl&&row.state==='Completed'){
  const image=await fetch(row.imageUrl,{signal:AbortSignal.timeout(30000)});details.status=image.status;
  if(image.ok){const data=Buffer.from(await image.arrayBuffer());details.bytes=data.length;details.sha256=createHash('sha256').update(data).digest('hex');details.size=data.length>=24?[data.readUInt32BE(16),data.readUInt32BE(20)]:[];if(row.targetId===83500345427472)details.sampleBase64=data.toString('base64');}
 }
 results.push(details)
}
console.log('HUDFIX_THUMBNAILS '+JSON.stringify(results));
