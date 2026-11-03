import fs from 'node:fs/promises';
const queries=[[10,'Evade map'],[10,'Evade backrooms'],[10,'Evade emotes'],[10,'Evade nextbots'],[3,'Evade lobby'],[3,'Jumpstyle'],[3,'Electro Shuffle']];
const records=[];
for(const [type,q]of queries){
 try{
  const url='https://apis.roblox.com/toolbox-service/v1/marketplace/'+type+'?limit=20&pageNumber=0&keyword='+encodeURIComponent(q);
  const r=await fetch(url);if(!r.ok){records.push({q,status:r.status});continue;}
  const result=await r.json();const ids=(result.data||[]).map(x=>x.id).filter(Boolean);
  const details=ids.length?await(await fetch('https://apis.roblox.com/toolbox-service/v1/items/details?assetIds='+ids.join(','))).json():{};
  records.push({q,result,details});
  console.log('Store search',q,JSON.stringify(details).slice(0,12000));
 }catch(e){records.push({q,error:String(e)});}
}
await fs.writeFile('/tmp/nb-assets/store-search.json',JSON.stringify(records,null,2));
