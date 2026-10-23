import fs from 'node:fs';
import { inflateSync, deflateSync } from 'node:zlib';
import { createHash } from 'node:crypto';

function crc32(buf){
  let crc=0xffffffff;
  for(const byte of buf){
    crc^=byte;
    for(let k=0;k<8;k++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);
  }
  return (crc^0xffffffff)>>>0;
}
function pngChunk(type,data=Buffer.alloc(0)){
  const t=Buffer.from(type,'ascii');
  const len=Buffer.alloc(4); len.writeUInt32BE(data.length);
  const sum=Buffer.alloc(4); sum.writeUInt32BE(crc32(Buffer.concat([t,data])));
  return Buffer.concat([len,t,data,sum]);
}
function paeth(a,b,c){
  const p=a+b-c, pa=Math.abs(p-a), pb=Math.abs(p-b), pc=Math.abs(p-c);
  return pa<=pb&&pa<=pc?a:pb<=pc?b:c;
}
function normalizeLogoPng(input){
  const sig=Buffer.from([137,80,78,71,13,10,26,10]);
  if(input.length<33 || !input.subarray(0,8).equals(sig)) throw new Error('Logo is not PNG');
  let off=8, ihdr=null, palette=null, alpha=null;
  const idats=[];
  while(off+12<=input.length){
    const n=input.readUInt32BE(off); const type=input.subarray(off+4,off+8).toString('ascii');
    const data=input.subarray(off+8,off+8+n); off+=12+n;
    if(type==='IHDR') ihdr=Buffer.from(data);
    else if(type==='PLTE') palette=Buffer.from(data);
    else if(type==='tRNS') alpha=Buffer.from(data);
    else if(type==='IDAT') idats.push(Buffer.from(data));
    else if(type==='IEND') break;
  }
  if(!ihdr) throw new Error('Logo PNG has no IHDR');
  const w=ihdr.readUInt32BE(0), h=ihdr.readUInt32BE(4), depth=ihdr[8], color=ihdr[9], interlace=ihdr[12];
  if(depth===8 && color===6) return input;
  if(depth!==8 || color!==3 || interlace!==0 || !palette || !idats.length){
    throw new Error(`Unsupported logo PNG format depth=${depth} color=${color} interlace=${interlace}`);
  }
  const packed=inflateSync(Buffer.concat(idats));
  const stride=w, rows=Buffer.alloc(stride*h);
  let src=0;
  for(let y=0;y<h;y++){
    const filter=packed[src++], row=rows.subarray(y*stride,(y+1)*stride), prev=y?rows.subarray((y-1)*stride,y*stride):null;
    for(let x=0;x<stride;x++){
      const raw=packed[src++], left=x?row[x-1]:0, up=prev?prev[x]:0, ul=prev&&x?prev[x-1]:0;
      let val;
      if(filter===0) val=raw;
      else if(filter===1) val=(raw+left)&255;
      else if(filter===2) val=(raw+up)&255;
      else if(filter===3) val=(raw+Math.floor((left+up)/2))&255;
      else if(filter===4) val=(raw+paeth(left,up,ul))&255;
      else throw new Error('Unsupported PNG filter '+filter);
      row[x]=val;
    }
  }
  const rgba=Buffer.alloc((w*4+1)*h);
  for(let y=0;y<h;y++){
    let out=y*(w*4+1); rgba[out++]=0;
    for(let x=0;x<w;x++){
      const idx=rows[y*w+x], pi=idx*3;
      rgba[out++]=palette[pi]??0; rgba[out++]=palette[pi+1]??0; rgba[out++]=palette[pi+2]??0;
      rgba[out++]=alpha&&idx<alpha.length?alpha[idx]:255;
    }
  }
  const next=Buffer.alloc(13); ihdr.copy(next); next[8]=8; next[9]=6; next[10]=0; next[11]=0; next[12]=0;
  return Buffer.concat([sig,pngChunk('IHDR',next),pngChunk('IDAT',deflateSync(rgba,{level:9})),pngChunk('IEND')]);
}

const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<12;i++){
    const res=await fetch(CLOUD+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(60000)
    });
    const raw=await res.text();
    let data; try{data=JSON.parse(raw)}catch{data={raw}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      const retry=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(60000,5000*(i+1));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function patchCloud(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:'PATCH',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:JSON.stringify(body),
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('PATCH '+path+' HTTP '+res.status+': '+JSON.stringify(data));
  return data;
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau timeout');
    await sleep(1500);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}


const read=n=>fs.readFileSync('roblox-integrations/sakura97/'+n+'.luau','utf8');
const sources={CONFIG:'survival-config',RULES:'round-rules',AI:'pursuer-ai',KILLER_FACTORY:'killer-factory',SURVIVAL_SERVER:'survival-server',SURVIVAL_CLIENT:'survival-client',ANIMATION:'pursuer-animation'};
let install=read('jason-install');
for(const [key,name] of Object.entries(sources)) install=install.replace(`__${key}_SOURCE__`,JSON.stringify(read(name)));
const menu=read('install-menu').replaceAll('__SURVIVERS_LOGO_ID__','136450401317962').replace('__MENU_SOURCE__',JSON.stringify(read('menu-client'))).replace('__LOADING_SOURCE__',JSON.stringify(read('loading-client')));
const syntax=Object.values(sources).concat(['menu-client','loading-client']).map((name,i)=>`local function s${i}()\n${read(name)}\nend`).join('\n')+'\nreturn {ok=true}';
console.log('SYNTAX',JSON.stringify(first(await execute(syntax))));
const test=read('survival-runtime-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end'));
const clientTest=read('survival-client-tests').replace('__SURVIVAL_CLIENT_TEST_SOURCE__',read('survival-client'));
const roleTest=read('jason-role-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end'));
const aiTest=read('jason-ai-tests').replace('__AI_TEST_SOURCE__',read('pursuer-ai').replace('local Run=game:GetService("RunService")','local Run=TEST_RUN'));
const script=`
local sourceVersion=game.PlaceVersion
local function install()
${install}
end
local result=install()
do
${menu}
end
local assets=game.ServerStorage.SurvivalAssets
assert(#assets.Maps:GetChildren()==1 and assets.Maps.HorrorMap)
assert(#assets.Killers:GetChildren()==1 and assets.Killers.Jason)
assert(assets.Killers.Jason.MotionClips:FindFirstChild("Jason Slash"))
assert(game.ReplicatedStorage.Survival.SurvivorClips:GetAttribute("SourceAssetId")==127092032896760)
assert(game.ReplicatedStorage.Survival.CrouchClips:GetAttribute("SourceAssetId")==134326820545987)
assert((game.ReplicatedStorage.Survival.SurvivorClips:GetAttribute("ClipCount") or 0)>0)
assert((game.ReplicatedStorage.Survival.CrouchClips:GetAttribute("ClipCount") or 0)>0)
local ui=game.StarterGui.TomiaszMenu
assert(ui.MenuPrincipal.Logo:GetAttribute("SourceAssetId")==136450401317962 and ui.MenuPrincipal.Logo.Image~="")
result.logoTexture=ui.MenuPrincipal.Logo.Image
local ser=game:GetService("SerializationService")
result.mapBytes=buffer.len(ser:SerializeInstancesAsync({assets.Maps}))
result.rigBytes=buffer.len(ser:SerializeInstancesAsync({assets.Killers}))
local function testController()
${test}
end
result.controller=testController()
local function testClient()
${clientTest}
end
result.client=testClient()
local function testRole()
${roleTest}
end
result.playerJason=testRole()
local function testAI()
${aiTest}
end
result.ai=testAI()
local function testContent()
${read('jason-content-tests')}
end
result.content=testContent()
result.sourceVersion=sourceVersion result.ok=true result.saved=false
if ${process.env.SURVIVERS_DRY_RUN==='1'?'false':'true'} then
 game.ReplicatedStorage.Survival:SetAttribute("Phase","Aguardando")
 game.ReplicatedStorage.Survival:SetAttribute("EndsAt",0)
 game.ReplicatedStorage.Survival:SetAttribute("Count",0)
 game.ReplicatedStorage.SweanRuntime:SetAttribute("LogoSHA256","286b7e57276a5d593b38c10c3a4cd41518d027c0e9346dfa6db3daf36521897e")
 local saveOk,saveError=pcall(function() game:GetService("AssetService"):SavePlaceAsync({PlaceId=79738710219521,SaveWithoutPublish=false}) end)
 result.saved=saveOk result.saveError=saveOk and nil or tostring(saveError)
 result.sizes={}
 result.serverStorageChildren={}
 for _,name in ipairs({"Workspace","ReplicatedStorage","ServerStorage","ServerScriptService","StarterPlayer","StarterGui","ReplicatedFirst"}) do
  local copy=Instance.new("Folder") for _,child in ipairs(game:GetService(name):GetChildren()) do local ok,c=pcall(function() return child:Clone() end) if ok and c then c.Parent=copy end end
  local ok,b=pcall(function() return ser:SerializeInstancesAsync({copy}) end) result.sizes[name]=ok and buffer.len(b) or -1 copy:Destroy()
 end
 for _,child in ipairs(game.ServerStorage:GetChildren()) do
  local ok,clone=pcall(function() return child:Clone() end)
  if ok and clone then
   local holder=Instance.new("Folder") clone.Parent=holder
   local ok2,b=pcall(function() return ser:SerializeInstancesAsync({holder}) end)
   table.insert(result.serverStorageChildren,{name=child.Name,class=child.ClassName,bytes=ok2 and buffer.len(b) or -1})
   holder:Destroy()
  else
   table.insert(result.serverStorageChildren,{name=child.Name,class=child.ClassName,bytes=-1})
  end
 end
 table.sort(result.serverStorageChildren,function(a,b) return a.bytes>b.bytes end)
end
return result
`;
const applied=first(await execute(script));
console.log('JASON_VALIDATED_BUILD',JSON.stringify(applied));
if(applied?.saved){
 const persisted=first(await execute(`
  local assets=game.ServerStorage.SurvivalAssets
  assert(game.PlaceVersion>${applied.sourceVersion},"Published version did not advance")
  assert(#assets.Maps:GetChildren()==1 and assets.Maps.HorrorMap:GetAttribute("SourceAssetId")==79671648850902)
  assert(#assets.Killers:GetChildren()==1 and assets.Killers.Jason:GetAttribute("SourceAssetId")==125165599816440)
  assert(game.ReplicatedStorage.Survival:GetAttribute("Version")==120)
  assert(game.ServerStorage.SurvivalAssets.Items.Flashlight:GetAttribute("SourceAssetId")==4573262309)
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredIdle"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredWalk"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredRun"))
  assert(workspace.JediLibrary.Door:GetAttribute("HeldOpen"))
  assert(game.StarterGui.TomiaszMenu.MenuPrincipal.Logo.Image=="rbxassetid://99002027743613")
  assert(game.ServerScriptService.SurvivalServer.Source:find('LobbyJoinPortal',1,true))
  return {ok=true,version=game.PlaceVersion,build=120,logo=true,singleMap=true,singleJason=true,lobbyPreserved=true}
 `));
 console.log('PERSISTED_PUBLICATION',JSON.stringify(persisted));
}

if(!applied.saved && process.env.SURVIVERS_DRY_RUN!=='1'){
 console.log('UNCHANGED_SAVE_DIAGNOSTIC',JSON.stringify(first(await execute(`
 local before=game.PlaceVersion
 local ok,err=pcall(function() game:GetService("AssetService"):SavePlaceAsync({PlaceId=79738710219521,SaveWithoutPublish=false}) end)
 return {sourceVersion=before,ok=ok,error=ok and nil or tostring(err)}
 `))));
 throw new Error('Jason build was not published; inspect diagnostic above');
}
