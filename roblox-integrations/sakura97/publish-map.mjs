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
const syntax=Object.values(sources).concat(['menu-client','loading-client','lobby-guide-client','lobby-guide-install','player-profile','profile-client']).map((name,i)=>`local function s${i}()\n${read(name)}\nend`).join('\n')+'\nreturn {ok=true}';
console.log('SYNTAX',JSON.stringify(first(await execute(syntax))));
const test=read('survival-runtime-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end').replace('local RESULT_PRESENTATION_SECONDS=9','local RESULT_PRESENTATION_SECONDS=.05'));
const clientTest=read('survival-client-tests').replace('__SURVIVAL_CLIENT_TEST_SOURCE__',read('survival-client'));
const roleTest=read('jason-role-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',read('survival-server').replace('local function now() return workspace:GetServerTimeNow() end','local function now() return TEST_NOW() end').replace('local RESULT_PRESENTATION_SECONDS=9','local RESULT_PRESENTATION_SECONDS=.05'));
const menuTest=read('menu-runtime-tests').replace('__MENU_TEST_SOURCE__',read('menu-client').replace('local v=camera.ViewportSize','local v=TEST_VIEWPORT'));
const animationTest=read('animation-runtime-tests').replace('__ANIMATION_TEST_SOURCE__',read('pursuer-animation'));
const guideTest=read('lobby-guide-tests').replace('__GUIDE_CLIENT_TEST_SOURCE__',read('lobby-guide-client').replace('local prompt=npc:WaitForChild("ProximityPrompt")','local prompt=TEST_PROMPT').replace('voice:LoadAsync()','voice:SetAttribute("TestLoadRequested",true)').replace('voice:Play()','voice:SetAttribute("TestPlayRequested",true)').replace('output.Player=player','output.Name="TestOutput"'));
const profileTest=read('profile-ui-tests').replace('__PROFILE_CLIENT_TEST_SOURCE__',read('profile-client'));
const aiTest=read('jason-ai-tests').replace('__AI_TEST_SOURCE__',read('pursuer-ai').replace('local Run=game:GetService("RunService")','local Run=TEST_RUN'));
const script=`
local sourceVersion=game.PlaceVersion
local function install()
${install}
end
local result=install()
do
 local net=game.ReplicatedStorage.Survival
 local old=net:FindFirstChild("PlayerProfile") if old then old:Destroy() end
 local module=Instance.new("ModuleScript") module.Name="PlayerProfile" module.Source=${JSON.stringify(read('player-profile'))} module.Parent=net
 local scripts=game.StarterPlayer.StarterPlayerScripts
 local previous=scripts:FindFirstChild("PlayerProfileController") if previous then previous:Destroy() end
 local client=Instance.new("LocalScript") client.Name="PlayerProfileController" client.Source=${JSON.stringify(read('profile-client'))} client.Parent=scripts
end
do
${menu}
end
result.lobbyGuide=(function()
${read('lobby-guide-install').replace('__GUIDE_CLIENT_SOURCE__',JSON.stringify(read('lobby-guide-client')))}
end)()
result.playerProfile=(function()
${profileTest}
end)()
result.guideClient=(function()
${guideTest}
end)()
assert(workspace.JediLibrary:GetAttribute("SourceAssetId")==1043225187,"Wrong lobby asset")
assert(game.ReplicatedStorage.SweanRuntime:GetAttribute("SurvivorRig")=="R6","R6 survivor runtime missing")
local assets=game.ServerStorage.SurvivalAssets
assert(#assets.Maps:GetChildren()==5 and assets.Maps.DoomspireBrickbattle and assets.Maps.JuggernautFightArena and assets.Maps.PirateBayIsland and assets.Maps.NaturalDisasterSurvival and assets.Maps.RocketArena)
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
${roleTest}
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
  assert(#assets.Maps:GetChildren()==5,"Expected five requested maps")
  assert(assets.Maps.DoomspireBrickbattle:GetAttribute("SourceAssetId")==109440846094241)
  assert(assets.Maps.JuggernautFightArena:GetAttribute("SourceAssetId")==137884561019081)
  assert(assets.Maps.PirateBayIsland:GetAttribute("SourceAssetId")==127398591748883)
  assert(assets.Maps.NaturalDisasterSurvival:GetAttribute("SourceAssetId")==92220535332787)
  assert(assets.Maps.RocketArena:GetAttribute("SourceAssetId")==112232657511704)
  assert(assets.Maps.RocketArena:GetAttribute("RequestedScale")==2,"RocketArena did not persist at 2x scale")
  assert(not assets.Maps:FindFirstChild("HorrorMap") and not assets.Maps:FindFirstChild("MilitaryBase") and not assets.Maps:FindFirstChild("AlpineFortress"),"Old maps persisted")
  assert(#assets.Killers:GetChildren()==5 and assets.Killers.Jason:GetAttribute("SourceAssetId")==125165599816440)
  assert(game.ReplicatedStorage.Survival:GetAttribute("Version")==124)
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
   assert(arena:GetAttribute("KillerSpawnPathValidated")==true,"Disconnected pursuer spawn persisted: "..arena.Name)
  end
  assert(not game.ServerScriptService.SurvivalServer.Source:find('FireClient(p,"jasonIntro"',1,true),"Removed killer intro returned")
  assert(game.ServerScriptService.SurvivalServer.Source:find('CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)',1,true),"R6 appearance-preserving conversion missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('Instance.new("Model") visual.Name="EquippedFlashlight"',1,true),"Pose-safe flashlight visual missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('run.InputBegan',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('event:FireServer("mode","walk")',1,true),"Hold-run/release-walk control missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('result.BackgroundTransparency=1',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("startResultCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('resultView.Visible=false',1,true),"Real full-screen winner camera missing")
  local survivalClientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(survivalClientSource:find('roundMusic.Name="SuviversMatchMusic"',1,true),"Match soundtrack missing")
  assert(survivalClientSource:find('roundMusic.SoundId="rbxassetid://108879410219148"',1,true),"Wrong match soundtrack asset")
  assert(survivalClientSource:find('roundMusic.Volume=.35',1,true),"Match soundtrack must stay below half volume")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("captureLoadingCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("restoreLoadingCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("loadingAvatar.Visible=false",1,true),"Real full-screen map loading camera missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('"GOOD LUCK"',1,true),"GOOD LUCK missing from map loading")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find("blendFrom",1,true),"Smooth locomotion blend missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("expectedReplacement",1,true),"R6 replacement false-death guard missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("local executionDuration=1.85",1,true),"Synchronized execution duration missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('p:GetAttribute("BeingExecuted")==true',1,true),"Execution pose does not override downed pose")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('model:GetAttribute("ExecutionDuration")',1,true),"Pursuer execution animation duration is not synchronized")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("restoreResultCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("captureResultCamera",1,true),"Result camera restoration missing")\n  assert(game.ServerScriptService.SurvivalServer.Source:find("local RESULT_PRESENTATION_SECONDS=9",1,true) and game.ServerScriptService.SurvivalServer.Source:find('state.phase="Resultados"',1,true),"Server does not preserve the real arena for the full-screen result camera")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('d:IsA("Motor6D") then d.Transform=CFrame.identity',1,true),"Victory victim stale pose reset missing")
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
  assert(workspace.LobbyGuide:GetAttribute("OutfitUserId")==8344738123 and workspace.LobbyGuide.Head.Transparency==1,"Guide outfit/headless missing")
  assert(workspace.LobbyGuide.Tabletop.Value==workspace.JediLibrary.GuideTable.Tabletop,"Guide is not on its table")
  assert(workspace.LobbyGuide.GuideInteraction.RunContext==Enum.RunContext.Client,"NPC gaze must be local")
  assert(workspace.LobbyGuide:GetAttribute("AuthoredPosePreserved")==true and workspace.LobbyGuide:GetAttribute("Placement")=="TabletopOnly","Guide seated/table pose was not preserved")
  assert(workspace.LobbyGuide.GuideInteraction.Source:find('VoiceId="1001"',1,true) and workspace.LobbyGuide.GuideInteraction.Source:find('voice.Pitch=.88',1,true),"Guide deeper Portuguese male voice missing")
  assert(game.StarterGui.TomiaszMenu.MenuController.Source:find("97293342453669",1,true),"Horror menu music asset missing")
  assert(game.StarterGui.TomiaszMenu.MenuController.Source:find("local targetHeight=2.55",1,true) and game.StarterGui.TomiaszMenu.MenuController.Source:find("menuCameraCF.LookVector*13.8",1,true),"Menu killer is still too large or too close")
  assert(game.ReplicatedStorage.Survival.SettingsPanel.Source:find('frame.Name="ReferenceSettings"',1,true),"Restored compact settings panel not persisted")
  assert(game.ReplicatedStorage.Survival.PlayerProfile.Source:find("124873348702500",1,true),"Requested profile design not persisted")
  assert(game.StarterPlayer.StarterPlayerScripts.PlayerProfileController,"Profile interaction not persisted")
  assert(game.ServerScriptService.SurvivalServer.Source:find('p~=selectionPlayer',1,true),"Private selection guard missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('player:GetAttribute("MapVote")==nil',1,true),"Vote dismissal missing")
  return {restoredCompactSettings=true,profileAsset=124873348702500,privateKillerSelection=true,voteDismissal=true,guide=true,guideAvatar="ch_ckz2n",guideHeadless=true,guideTabletop=true,guideDeepMaleVoice=true,horrorMenuMusic=true,smallerMenuKiller=true,ok=true,version=game.PlaceVersion,build=124,logo=true,mapCount=5,pursuerCount=5,lobbyPreserved=true,noLobbyPortal=true,noLobbyDoorGeometry=true,invisibleBounds=true,holdRun=true,fullScreenKillerResult=true,synchronizedExecution=true,resultCameraRestored=true,initialLogoOnly=true,mapAnimatedLoading=true,smoothLocomotion=true,adaptiveGraphics=true,referenceVisualSettings=true,requestedFiveMaps=true,rocketArena2x=true,pursuersNormalized=true,legacySystemsRemoved=true,buckshotRoundMusic=true,lowVolumeRoundMusic=true}
 `));
 console.log('PERSISTED_PUBLICATION',JSON.stringify(persisted));
}

if(!applied.saved && process.env.SURVIVERS_DRY_RUN!=='1'){
 throw new Error('Suvivers build was not published; inspect saveError above');
}

