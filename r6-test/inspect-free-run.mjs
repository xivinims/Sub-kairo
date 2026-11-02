// Fetch the publicly listed, free R6 RUN MODEL for source inspection only.
// Do not execute or copy any model's scripts.
import fs from "node:fs/promises";
const id="136548520660837";
const apiKey=process.env.ROBLOX_API_KEY;
const urls=[
 "https://assetdelivery.roblox.com/v1/asset/?id="+id,
 "https://apis.roblox.com/asset-delivery-api/v1/assetId/"+id,
];
let data=null;
for(const url of urls){
 try{
  const response=await fetch(url,{headers:apiKey?{"x-api-key":apiKey}:{},
   signal:AbortSignal.timeout(22000)});
  const bytes=Buffer.from(await response.arrayBuffer());
  console.log("SOURCE_CHECK",response.status,response.headers.get("content-type"),bytes.length,url.split("/")[2]);
  if(!response.ok)continue;
  if(bytes.slice(0,8).toString("latin1").startsWith("<roblox")||bytes.slice(0,5).toString("utf8")==="<roblox"){
   data=bytes;break;
  }
  const item=JSON.parse(bytes.toString("utf8"));
  const location=item.location||item.locations?.[0]?.location;
  if(!location){console.log("NO_DELIVERY_LOCATION",JSON.stringify(item).slice(0,300));continue}
  const blob=await fetch(location,{signal:AbortSignal.timeout(22000)});
  const raw=Buffer.from(await blob.arrayBuffer());
  console.log("BLOB_SOURCE",blob.status,raw.length);
  if(blob.ok&&raw.length>1000){data=raw;break}
 }catch(error){console.log("DOWNLOAD_ERROR",String(error).slice(0,260))}
}
if(!data)throw Error("Public R6 creator-store model cannot be accessed from automated Roblox tools. Do not claim the model was imported.");
await fs.writeFile("r6-test/free-r6-run-model.rbxm",data);
console.log("R6_RUN_MODEL_FETCHED_BYTES",data.length);
