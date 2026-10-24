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
const sources={CONFIG:'survival-config',RULES:'round-rules',AI:'pursuer-ai',KILLER_FACTORY:'killer-factory',SURVIVAL_SERVER:'survival-server',SURVIVAL_CLIENT:'survival-client',ANIMATION:'pursuer-animation',PROFILE:'profile-service',MAP_BUILDER:'map-builder',ISLAND_SERVER:'island-server',VOID:'void-client',AMBIENCE:'ambience-client',SETTINGS:'settings-panel',NAMETAG:'nametag-server',FRIENDS:'friends-client'};
let install=read('jason-install');
for(const [key,name] of Object.entries(sources)) install=install.replace(`__${key}_SOURCE__`,JSON.stringify(read(name)));
const menu=read('install-menu').replaceAll('__SURVIVERS_LOGO_ID__','136450401317962').replace('__MENU_SOURCE__',JSON.stringify(read('menu-client'))).replace('__LOADING_SOURCE__',JSON.stringify(read('loading-client')));
const syntax=Object.values(sources).concat(['menu-client','loading-client']).map((name,i)=>`local function s${i}()\n${read(name)}\nend`).join('\n')+'\nreturn {ok=true}';
console.log('SYNTAX',JSON.stringify(first(await execute(syntax))));
const test=read('survival-runtime-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end'));
const clientTest=read('survival-client-tests').replace('__SURVIVAL_CLIENT_TEST_SOURCE__',read('survival-client'));
const roleTest=read('jason-role-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end'));
const menuTest=read('menu-runtime-tests').replace('__MENU_TEST_SOURCE__',read('menu-client').replace('local v=camera.ViewportSize','local v=TEST_VIEWPORT'));
const animationTest=read('animation-runtime-tests').replace('__ANIMATION_TEST_SOURCE__',read('pursuer-animation'));
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
assert(workspace.JediLibrary:GetAttribute("SourceAssetId")==1043225187,"Wrong lobby asset")
assert(game.ReplicatedStorage.SweanRuntime:GetAttribute("SurvivorRig")=="R6","R6 survivor runtime missing")
local assets=game.ServerStorage.SurvivalAssets
assert(#assets.Maps:GetChildren()==3 and assets.Maps.HorrorMap and assets.Maps.MilitaryBase and assets.Maps.AlpineFortress)
assert(#assets.Killers:GetChildren()==5 and assets.Killers.Jason)
assert(assets.Killers.Jason.MotionClips:FindFirstChild("Jason Slash"))
assert(game.ReplicatedStorage.Survival.SurvivorClips:GetAttribute("SourceAssetId")==127092032896760)
assert(not game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Removed crouch package returned")
assert((game.ReplicatedStorage.Survival.SurvivorClips:GetAttribute("ClipCount") or 0)>0)
local ui=game.StarterGui.TomiaszMenu
assert(ui.MenuPrincipal.Logo:GetAttribute("SourceAssetId")==136450401317962 and ui.MenuPrincipal.Logo.Image~="")
result.logoTexture=ui.MenuPrincipal.Logo.Image
local ser=game:GetService("SerializationService")
result.mapBytes=buffer.len(ser:SerializeInstancesAsync({assets.Maps}))
result.rigBytes=buffer.len(ser:SerializeInstancesAsync({assets.Killers}))
result.motionLibraryBytes=buffer.len(ser:SerializeInstancesAsync({game.ReplicatedStorage.Survival.KillerMotionLibraries}))
result.killerBytes={}
for _,killer in ipairs(assets.Killers:GetChildren()) do
 local ok,b=pcall(function() return ser:SerializeInstancesAsync({killer}) end)
 result.killerBytes[killer.Name]=ok and buffer.len(b) or -1
end
local function testController()
${test}
end
result.profiles=(function()\n${read('profile-tests')}\nend)()
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
result.menu=(function()
${menuTest}
end)()
result.animations=(function()
${animationTest}
end)()
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
  assert(workspace.JediLibrary:GetAttribute("SourceAssetId")==1043225187,"Wrong lobby asset")
local assets=game.ServerStorage.SurvivalAssets
  assert(game.PlaceVersion>${applied.sourceVersion},"Published version did not advance")
  assert(#assets.Maps:GetChildren()==3 and assets.Maps.HorrorMap:GetAttribute("SourceAssetId")==79671648850902 and assets.Maps.MilitaryBase:GetAttribute("SourceAssetId")==13967333450 and assets.Maps.AlpineFortress:GetAttribute("SourceAssetId")==8050959400)
  assert(#assets.Killers:GetChildren()==5 and assets.Killers.Jason:GetAttribute("SourceAssetId")==125165599816440)
  assert(game.ReplicatedStorage.Survival:GetAttribute("Version")==123)
  assert(game.ServerStorage.SurvivalAssets.Items.Flashlight:GetAttribute("SourceAssetId")==4573262309)
  assert(game.ServerStorage.SurvivalAssets.Killers.Jason.MotionClips:FindFirstChild("Jason Run"))
  assert(game.ServerStorage.SurvivalAssets.Killers.Jason.MotionClips:FindFirstChild("Jason Intro"))
  assert(game.ReplicatedStorage.Survival.KillerMotionLibraries.Default:GetAttribute("ClipCount")==7)
  assert(game.ReplicatedStorage.Survival.KillerMotionLibraries.Cool:GetAttribute("ClipCount")==7)
  assert(not game.ServerStorage.SurvivalAssets.Killers.JohnDoe:FindFirstChild("MotionClips"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredIdle"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredWalk"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredRun"))
  assert(typeof(workspace.JediLibrary:GetAttribute("FormerDoorCFrame"))=="CFrame","Former door reference missing")
  assert(not workspace.JediLibrary:FindFirstChild("Door") and not workspace.JediLibrary:FindFirstChild("OriginalLobbyDoor"),"Lobby door geometry/marker returned")
  assert(game.StarterGui.TomiaszMenu.MenuPrincipal.Logo.Image=="rbxassetid://99002027743613")
  assert(not workspace:FindFirstChild("LobbyJoinPortal"),"Removed lobby join portal returned")
  assert(not workspace:FindFirstChild("SurviversLobbyDoorVisual"),"Removed lobby join door visual returned")
  assert(workspace.JediLibrary:GetAttribute("AutomaticRoundAdmission")==true,"Automatic lobby admission missing")
  assert(workspace.JediLibrary:FindFirstChild("InvisibleBounds") and #workspace.JediLibrary.InvisibleBounds:GetChildren()>=5,"Lobby invisible bounds missing")
  for _,arena in ipairs(assets.Maps:GetChildren()) do
   assert(arena:FindFirstChild("InvisibleBounds") and #arena.InvisibleBounds:GetChildren()>=5,"Arena invisible bounds missing: "..arena.Name)
   assert((arena:GetAttribute("KillerSpawnClearance") or 0)>=10,"Unsafe killer spawn persisted: "..arena.Name)
  end
  assert(not game.ServerScriptService.SurvivalServer.Source:find('FireClient(p,"jasonIntro"',1,true),"Removed killer intro returned")
  assert(game.ServerScriptService.SurvivalServer.Source:find('CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)',1,true),"R6 appearance-preserving conversion missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('Instance.new("Model") visual.Name="EquippedFlashlight"',1,true),"Pose-safe flashlight visual missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('run.InputBegan',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('event:FireServer("mode","walk")',1,true),"Hold-run/release-walk control missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('resultView.Size=UDim2.fromScale(1,1)',1,true),"Full-screen killer result missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('loadingAvatar.Name="ArenaAvatar"',1,true),"Animated map loading avatar missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('"GOOD LUCK"',1,true),"GOOD LUCK missing from map loading")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find("blendFrom",1,true),"Smooth locomotion blend missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("expectedReplacement",1,true),"R6 replacement false-death guard missing")
  assert(game.StarterGui.TomiaszMenu.MenuController.Source:find("b.AnchorPoint=Vector2.new(0,.5)",1,true),"Menu navigation is not left aligned")
  assert(game.ReplicatedFirst.SweanLoadingController.Source:find('logo.Name="BrandTitle"',1,true),"Initial logo loading missing")
  assert(not game.ReplicatedFirst.SweanLoadingController.Source:find("GOOD LUCK",1,true) and not game.ReplicatedFirst.SweanLoadingController.Source:find("LoadingAvatar",1,true),"Map loading content leaked into initial loading")
  assert(game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("EnvironmentSpecularScale",1,true) and game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("SuviversArenaBloom",1,true),"Adaptive arena graphics missing")
  local settingsSource=game.ReplicatedStorage.Survival.SettingsPanel.Source
  assert(settingsSource:find('key="CameraFOV"',1,true) and settingsSource:find('default=48',1,true),"Reference FOV setting missing")
  assert(settingsSource:find('key="VisualSaturation"',1,true) and settingsSource:find('default=-.65',1,true),"Reference saturation setting missing")
  assert(settingsSource:find('key="VisualContrast"',1,true) and settingsSource:find('key="VisualExposure"',1,true) and settingsSource:find('key="VisualTime"',1,true),"Reference grading settings missing")
  assert(game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find('VisualSaturation',1,true) and game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find('VisualTime',1,true),"Visual settings are not wired to ambience")
  assert(game.StarterPlayer.StarterPlayerScripts.VoidSequence.Source:find('local media=RS:WaitForChild("XNMedia")',1,true),"Death presentation media reference is unsafe")
  assert(not game.StarterGui.TomiaszMenu.MenuPrincipal:FindFirstChild("Shop") and not game.StarterGui.TomiaszMenu.MenuPrincipal:FindFirstChild("Inventory"),"Removed menu buttons returned")
  assert(not game.StarterGui.TomiaszMenu:FindFirstChild("ReturnToMenu"),"Removed return-to-menu object returned")
  assert(not game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Removed crouch payload returned")
  assert(not game.ServerScriptService.SurvivalServer.Source:find('action=="boost"',1,true) and not game.ServerScriptService.SurvivalServer.Source:find('action=="musicPlay"',1,true) and not game.ServerScriptService.SurvivalServer.Source:find('value=="slow"',1,true),"Legacy gameplay actions returned")
  return {ok=true,version=game.PlaceVersion,build=123,logo=true,mapCount=3,pursuerCount=5,lobbyPreserved=true,noLobbyPortal=true,noLobbyDoorGeometry=true,invisibleBounds=true,holdRun=true,fullScreenKillerResult=true,initialLogoOnly=true,mapAnimatedLoading=true,smoothLocomotion=true,adaptiveGraphics=true,referenceVisualSettings=true,legacySystemsRemoved=true}
 `));
 console.log('PERSISTED_PUBLICATION',JSON.stringify(persisted));
}

if(!applied.saved && process.env.SURVIVERS_DRY_RUN!=='1'){
 throw new Error('Suvivers build was not published; inspect saveError above');
}

