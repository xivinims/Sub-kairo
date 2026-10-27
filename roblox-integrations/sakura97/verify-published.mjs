import fs from 'node:fs';
import { inflateSync, deflateSync, gunzipSync } from 'node:zlib';
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
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'300s',script});
  const deadline=Date.now()+480000;
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


 const persisted=first(await execute(`
  assert((game.ReplicatedStorage.Survival:GetAttribute("SettingsIconImageId") or 0)>0,"Settings hex icon image missing")
  assert(game.ReplicatedStorage.Survival.SettingsPanel.Source==${JSON.stringify(fs.readFileSync('roblox-integrations/sakura97/settings-panel.luau','utf8'))},"Published settings source differs from tested source")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source==${JSON.stringify(fs.readFileSync('roblox-integrations/sakura97/survival-client.luau','utf8'))},"Published HUD differs from tested source")
  assert(workspace.JediLibrary:GetAttribute("SourceAssetId")==110584744116489,"Wrong fixed lobby asset")
  assert(workspace.JediLibrary:GetAttribute("FixedLobbyRevision")=="violence-district-lobby-v1","Fixed lobby revision missing")
  assert(workspace.JediLibrary:GetAttribute("FixedLobbySHA256")=="ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2","Fixed lobby hash missing")
  assert(workspace.JediLibrary:GetAttribute("FixedLobbySourceFile")=="Violence_District.rbxlx","Fixed lobby source file metadata missing")
local assets=game.ServerStorage.SurvivalAssets
  assert(game.PlaceVersion>199,"Published version did not advance")
  assert(#assets.Maps:GetChildren()==7,"Expected seven requested maps")
  assert(assets.Maps.DoomspireBrickbattle:GetAttribute("SourceAssetId")==109440846094241)
  assert(assets.Maps.JuggernautFightArena:GetAttribute("SourceAssetId")==137884561019081)
  assert(assets.Maps.PirateBayIsland:GetAttribute("SourceAssetId")==127398591748883)
  assert(assets.Maps.NaturalDisasterSurvival:GetAttribute("SourceAssetId")==92220535332787)
  assert(assets.Maps.RocketArena:GetAttribute("SourceAssetId")==112232657511704)
  assert(assets.Maps.PiggySewers:GetAttribute("SourceAssetId")==7757562864)
  assert(assets.Maps.PiggyMappleDonut:GetAttribute("SourceAssetId")==16440225099)
  assert(assets.Maps.RocketArena:GetAttribute("RequestedScale")==2,"RocketArena did not persist at 2x scale")
  assert(not assets.Maps:FindFirstChild("HorrorMap") and not assets.Maps:FindFirstChild("MilitaryBase") and not assets.Maps:FindFirstChild("AlpineFortress"),"Old maps persisted")
  assert(#assets.Killers:GetChildren()==5 and assets.Killers.Jason:GetAttribute("SourceAssetId")==125165599816440 and assets.Killers.Krampus:GetAttribute("SourceAssetId")==92081889778550 and assets.Killers.Piggy:GetAttribute("SourceAssetId")==8762062897 and not assets.Killers:FindFirstChild("Jeff") and not assets.Killers:FindFirstChild("Freddy"),"Five-pursuer roster did not persist")
  assert(game.ReplicatedStorage.Survival:GetAttribute("Version")==126)
  assert(game.ServerStorage.SurvivalAssets.Items.Flashlight:GetAttribute("SourceAssetId")==11906391298)
  local persistedLantern=game.ServerStorage.SurvivalAssets.Items.Flashlight
  assert(persistedLantern:GetAttribute("CrackleSoundAssetId")==129037248569146,"Lantern crackle metadata did not persist")
  local persistedLanternHandle=assert(persistedLantern:FindFirstChild("Handle",true),"Persisted lantern handle missing")
  local persistedCrackle=assert(persistedLanternHandle:FindFirstChild("LanternFireCrackle"),"Persisted lantern crackle missing")
  assert(persistedCrackle.SoundId=="rbxassetid://129037248569146" and persistedCrackle.Looped,"Persisted lantern crackle is wrong")
  local persistedConfig=require(game.ReplicatedStorage.Survival.Config)
  assert(persistedConfig.Lantern and persistedConfig.Lantern.AssetId==11906391298 and persistedConfig.Lantern.SoundAssetId==129037248569146,"Persisted lantern config assets invalid")
  assert(table.concat(persistedConfig.Lantern.UpgradeCosts,",")=="10,30,50,80,100,170" and persistedConfig.Lantern.Durations[1]==70 and persistedConfig.Lantern.Durations[#persistedConfig.Lantern.Durations]==170,"Persisted lantern durability tiers invalid")
  assert(game.ServerScriptService.SurvivalServer.Source:find('action=="buyLanternUpgrade"',1,true) and game.ServerScriptService.SurvivalServer.Source:find("LanternSeconds",1,true) and game.ServerScriptService.SurvivalServer.Source:find("resetLanternBattery",1,true),"Server-owned lantern battery runtime missing")
  assert(game.ServerScriptService.ProfileService.Source:find("buyLanternUpgrade",1,true) and game.ServerScriptService.ProfileService.Source:find("lanternTier",1,true),"Lantern durability profile persistence missing")
  assert(game.ServerStorage.SurvivalAssets.Killers.Jason.MotionClips:FindFirstChild("Jason Run"))
  assert(game.ServerStorage.SurvivalAssets.Killers.Jason.MotionClips:FindFirstChild("Jason Intro"))
  assert(game.ReplicatedStorage.Survival.KillerMotionLibraries.Default:GetAttribute("ClipCount")==7)
  assert(game.ReplicatedStorage.Survival.KillerMotionLibraries.Cool:GetAttribute("ClipCount")==7)
  assert(not game.ServerStorage.SurvivalAssets.Killers.JohnDoe:FindFirstChild("MotionClips"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredIdle"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredWalk"))
  assert(game.ReplicatedStorage.Survival.SurvivorClips:FindFirstChild("InjuredRun"))
  local survivorActions=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorActionClips"),"Survivor action clips did not persist")
  assert((survivorActions:GetAttribute("ClipCount") or 0)>=3,"Required survivor action clips incomplete after publish")
  assert(survivorActions:GetAttribute("RequestedClipCount")==6 and survivorActions:GetAttribute("RequiredClipCount")==3)
  assert(survivorActions:GetAttribute("ParryRequestedAssetId")==127096285501517)
  assert(survivorActions:GetAttribute("BreakPalletRequestedAssetId")==112166042383605)
  assert(survivorActions:GetAttribute("CrouchWalkRequestedAssetId")==126965695851149)
  assert(survivorActions:GetAttribute("InjuredCrouchWalkRequestedAssetId")==135084204086504)
  assert(survivorActions:GetAttribute("StunRequestedAssetId")==123047897844134)
  assert(survivorActions:GetAttribute("StunAssetId")==123047897844134 or (survivorActions:GetAttribute("StunFallback")==true and survivorActions:GetAttribute("StunAssetId")==127092032896760))
  assert(survivorActions:GetAttribute("VaultRequestedAssetId")==83873880822918)
  assert(survivorActions:GetAttribute("CrouchWalkAssetId")==126965695851149 or (survivorActions:GetAttribute("CrouchWalkFallback")==true and survivorActions:GetAttribute("CrouchWalkAssetId")==127092032896760))
  assert(survivorActions:GetAttribute("InjuredCrouchWalkAssetId")==135084204086504 or (survivorActions:GetAttribute("InjuredCrouchWalkFallback")==true and survivorActions:GetAttribute("InjuredCrouchWalkAssetId")==127092032896760))
  assert(typeof(workspace.JediLibrary:GetAttribute("FormerDoorCFrame"))=="CFrame","Former door reference missing")
  assert(workspace.JediLibrary:GetAttribute("LobbySpawnMode")=="DoorFront","Lobby spawn is not centered in front of the authored door")
  assert((workspace.JediLibrary:GetAttribute("LobbySpawnDoorDistance") or math.huge)<=8,"Lobby spawn is too far from the entrance door")
  assert(workspace.JediLibrary:GetAttribute("LobbySpawnFacing")=="IntoHouse","Lobby spawn is not facing into the house")
  assert(typeof(workspace.JediLibrary:GetAttribute("FrontDoorFrameCenter"))=="Vector3","Centered front-door reference missing")
  assert(not workspace.JediLibrary:FindFirstChild("Door") and not workspace.JediLibrary:FindFirstChild("OriginalLobbyDoor"),"Lobby door geometry/marker returned")
  assert(game.StarterGui.TomiaszMenu.Enabled==false and game.StarterGui.TomiaszMenu:GetAttribute("LegacyMenuWidgetsPurged")==true and not game.StarterGui.TomiaszMenu:FindFirstChild("MenuPrincipal"),"Legacy main menu persisted")
  assert(not workspace:FindFirstChild("LobbyJoinPortal"),"Removed lobby join portal returned")
  assert(not workspace:FindFirstChild("SurviversLobbyDoorVisual"),"Removed lobby join door visual returned")
  assert(workspace.JediLibrary:GetAttribute("AutomaticRoundAdmission")==true,"Automatic lobby admission missing")
  assert(workspace.JediLibrary:FindFirstChild("InvisibleBounds") and #workspace.JediLibrary.InvisibleBounds:GetChildren()>=5,"Lobby invisible bounds missing")
  for _,arena in ipairs(assets.Maps:GetChildren()) do
   assert(arena:FindFirstChild("InvisibleBounds") and #arena.InvisibleBounds:GetChildren()>=5,"Arena invisible bounds missing: "..arena.Name)
   assert((arena:GetAttribute("KillerSpawnClearance") or 0)>= (arena:GetAttribute("RequiredKillerClearance") or 10),"Unsafe killer spawn persisted: "..arena.Name)
   assert(arena:GetAttribute("KillerSpawnPathValidated")==true,"Disconnected pursuer spawn persisted: "..arena.Name)
  end
  assert(not game.ServerScriptService.SurvivalServer.Source:find('FireClient(p,"jasonIntro"',1,true),"Removed killer intro returned")
  assert(game.ServerScriptService.SurvivalServer.Source:find('CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)',1,true),"R6 appearance-preserving conversion missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('Instance.new("Model") visual.Name="EquippedFlashlight"',1,true),"Pose-safe flashlight visual missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("LanternFireCrackle",1,true) and game.ServerScriptService.SurvivalServer.Source:find("129037248569146",1,true),"Lantern crackle runtime missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('run.InputBegan',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('event:FireServer("mode","walk")',1,true),"Hold-run/release-walk control missing")
  local winnerTemplate=game.ReplicatedStorage:FindFirstChild("MenuSceneTemplate")
  assert(winnerTemplate and winnerTemplate:GetAttribute("SourceAssetId")==13327565335 and winnerTemplate:GetAttribute("WinnerSceneOnly")==true,"Old menu background template missing from winner scene")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("buildResultScene",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("WinnerPursuer",1,true),"Winner scene pursuer runtime missing")
  local survivalClientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(survivalClientSource:find('local lantern=cleanAction(topActions,"Lantern"',1,true) and survivalClientSource:find('event:FireServer("flashlight")',1,true),"Lantern HUD control missing")
  assert(survivalClientSource:find("11906391298",1,true) and survivalClientSource:find("129037248569146",1,true),"Lantern HUD metadata missing")
  assert(survivalClientSource:find('roundMusic.Name="SuviversMatchMusic"',1,true),"Match soundtrack missing")
  assert(survivalClientSource:find('roundMusic.SoundId="rbxassetid://108879410219148"',1,true),"Wrong match soundtrack asset")
  assert(survivalClientSource:find('roundMusic.Volume=.35',1,true),"Match soundtrack must stay below half volume")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("captureLoadingCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("restoreLoadingCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("loadingAvatar.Visible=false",1,true),"Real full-screen map loading camera missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('"GOOD LUCK"',1,true),"GOOD LUCK missing from map loading")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find("blendFrom",1,true),"Smooth locomotion blend missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find("SurvivorActionClips",1,true) and game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('"CrouchWalk"',1,true) and game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('"InjuredCrouchWalk"',1,true),"Dedicated crouch action animation runtime missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('"Stun"',1,true) and game.ServerScriptService.SurvivalServer.Source:find("StunnedUntil",1,true),"Survivor stun action runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("expectedReplacement",1,true),"R6 replacement false-death guard missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('local executionDuration=attacker:GetAttribute("ExecutionLength")',1,true),"Synchronized execution duration missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('p:GetAttribute("BeingExecuted")==true',1,true),"Execution pose does not override downed pose")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('model:GetAttribute("ExecutionDuration")',1,true),"Pursuer execution animation duration is not synchronized")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("restoreResultCamera",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("captureResultCamera",1,true),"Result camera restoration missing")\n  assert(game.ServerScriptService.SurvivalServer.Source:find("local RESULT_PRESENTATION_SECONDS=9",1,true) and game.ServerScriptService.SurvivalServer.Source:find('state.phase="Resultados"',1,true),"Server does not preserve the real arena for the full-screen result camera")
  assert(game.StarterGui.TomiaszMenu.Enabled==false and game.StarterGui.TomiaszMenu:GetAttribute("MenuRemoved")==true,"Main menu still opens")
  assert(game.StarterGui.TomiaszMenu:GetAttribute("LegacyMenuWidgetsPurged")==true and not game.StarterGui.TomiaszMenu:FindFirstChild("MenuPrincipal"),"Old menu UI still exists")
  local loadingController=assert(game.ReplicatedFirst:FindFirstChild("SweanLoadingController"),"Initial loading controller missing")
  local loadingAssets=assert(game.ReplicatedFirst:FindFirstChild("LoadingCinematicAssets"),"TV loading cinematic assets missing")
  assert(loadingController:GetAttribute("CinematicInitialLoading")==true and loadingController:GetAttribute("CinematicDuration")==10,"Ten-second loading cinematic metadata missing")
  assert(loadingAssets:GetAttribute("TVAssetId")==421148437 and loadingAssets:GetAttribute("TableAssetId")==397786287 and loadingAssets:GetAttribute("HandAssetId")==8091676187,"Wrong loading TV/table/hand assets")
  local loadingTV=assert(loadingAssets:FindFirstChild("TV"),"Requested Old Television model missing")
  local loadingTable=assert(loadingAssets:FindFirstChild("Mesa"),"Requested Mesa model missing")
  local loadingHand=assert(loadingAssets:FindFirstChild("BloodHand"),"Requested blood hand model missing")
  assert(loadingTV:GetAttribute("SourceAssetId")==421148437 and loadingTable:GetAttribute("SourceAssetId")==397786287 and loadingHand:GetAttribute("SourceAssetId")==8091676187,"Loading asset source IDs missing")
  local loadingSource=loadingController.Source
  assert(loadingSource:find("CINEMATIC_DURATION=10",1,true) and loadingSource:find("LOGO_END=5",1,true),"Loading cinematic timing missing")
  assert(loadingSource:find("screenNormal=Vector3.new(0,0,1)",1,true) and loadingSource:find("screenUp=Vector3.new(-1,0,0)",1,true),"TV upright-axis correction missing")
  assert(loadingSource:find("fitDistance",1,true) and loadingSource:find("cameraDistance",1,true) and not loadingSource:find("tv:ScaleTo(1.5)",1,true),"TV adaptive framing/stretch fix missing")
  assert(loadingSource:find('assets:FindFirstChild("BloodHand"',1,true) and loadingSource:find("cameraImpact",1,true),"Blood hand impact cinematic missing")
  assert(loadingSource:find('logo.Texture="rbxassetid://99002027743613"',1,true) and loadingSource:find('logoPanel:SetAttribute("PreserveLogoAspect",true)',1,true),"Game logo is missing or distorted inside the TV")
  assert(loadingSource:find("screen.Material=Enum.Material.Neon",1,true) and loadingSource:find('vignetteLayer("HorizontalVignette"',1,true),"Dark-focus luminous TV treatment missing")
   assert(loadingSource:find('letterbox("CinematicTopBar"',1,true) and loadingSource:find('filmTitle.Name="FilmTitle"',1,true) and loadingSource:find("RunService.RenderStepped",1,true),"Film-style loading camera/text treatment missing")
  assert(loadingSource:find("waitUntil(9.05)",1,true) and loadingSource:find("CINEMATIC_DURATION",1,true),"Final cinematic fade timing missing")
  assert(not loadingSource:find("GOOD LUCK",1,true) and not loadingSource:find("LoadingAvatar",1,true),"Map loading content leaked into initial loading")
  assert(game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("Lighting.ClockTime=.5",1,true) and game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("SuviversDistrictBloom",1,true) and game.StarterPlayer.StarterPlayerScripts.ArenaAmbience.Source:find("SuviversAtmosphere",1,true),"Night lobby ambience missing")
  local settingsSource=game.ReplicatedStorage.Survival.SettingsPanel.Source
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('coinView.Image="rbxasset://textures/ui/common/robux@3x.png"',1,true),"Official Robux HUD icon missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('settingsIcon.Name="SettingsHexIcon"',1,true),"Settings hex HUD icon missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("settingsCameraState",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("SuviversSettingsBlur",1,true),"Frozen camera settings backdrop missing")
  assert(settingsSource:find('CameraFOV=62',1,true) and settingsSource:find('addSlider("CAMPO DE VISÃO","CameraFOV"',1,true),"Gameplay FOV setting missing")
  assert(not settingsSource:find('key="visual"',1,true) and not settingsSource:find('VisualSaturation',1,true) and not settingsSource:find('VisualTime',1,true),"Removed visual/environment settings returned")
  assert(not settingsSource:find('key="ReducedMotion"',1,true) and settingsSource:find('frame:SetAttribute("Style","CinematicSideSettings")',1,true) and settingsSource:find('nav.Name="CategoryRail"',1,true) and settingsSource:find('panel.Name="OptionsPanel"',1,true),"Cinematic side settings panel missing")
   assert(settingsSource:find('click.SoundId="rbxassetid://6102885802"',1,true) and settingsSource:find('frame:SetAttribute("FrozenCameraBackdrop",true)',1,true),"Settings open audio/frozen-camera metadata missing")
  assert(game.StarterPlayer.StarterPlayerScripts.VoidSequence.Source:find('local media=RS:WaitForChild("XNMedia")',1,true),"Death presentation media reference is unsafe")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('shopOverlay.Name="KillerShop"',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('event:FireServer("buyKiller"',1,true),"Killer shop HUD missing")
  local shopSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(shopSource:find('shopPanel:SetAttribute("Style","LostInspiredStage")',1,true) and shopSource:find('StyleRevision","2026-10-26-killer-stage-v2"',1,true) and shopSource:find('ResponsiveLayout","StackedPortraitV3"',1,true),"Full-screen responsive shop stage marker missing")
  assert(shopSource:find('local shopLayout=Instance.new("UIListLayout",shopList)',1,true) and shopSource:find('shopPanel.Size=UDim2.fromScale(1,1)',1,true) and shopSource:find('tabBar.Visible=false',1,true),"Full-screen shop name list missing")
  assert(shopSource:find('shopSearch.Name="Search"',1,true) and shopSource:find('tabBar.Name="Tabs"',1,true),"Shop tabs/search layout missing")
  assert(shopSource:find('detailPanel.Name="DetailPanel"',1,true) and shopSource:find('detailPortrait.Name="SelectedPortrait"',1,true),"Selected killer detail panel missing")
  assert(shopSource:find('local killerOrder={"Jason","JohnDoe","Chucky","Piggy","Krampus"}',1,true),"Five-killer reference shop order missing")
  assert(shopSource:find('model:SetAttribute("PresentationState","ShopIdle")',1,true) and game.ReplicatedStorage.Survival:FindFirstChild("ShopScene"),"Animated selected killer or DOORS backdrop missing")
  assert(not shopSource:find("forgot a",1,true) and not shopSource:find("lmao",1,true),"Reference meme text leaked into game shop")
  assert(shopSource:find('{"Items",L("ITENS","ITEMS")}',1,true) and not shopSource:find('{"Survivors",L("SOBREVIVENTES"',1,true),"Items tab did not replace Survivors")
  assert(shopSource:find('lanternCard.Name="LanternUpgrade"',1,true) and shopSource:find('event:FireServer("buyLanternUpgrade")',1,true),"Lantern durability item shop missing")
  assert(shopSource:find('matchTV.Name="MatchLoadingTelevision"',1,true) and shopSource:find('gameCornerTitle=text(loading,"GameCornerTitle","SUVIVERS"',1,true),"TV match loading/SUVIVERS corner title missing")
  assert(shopSource:find("task.delay(5,function()",1,true) and shopSource:find("loadingStarted+10",1,true) and shopSource:find("KillerPlayerName",1,true),"Five-second roster reveal or ten-second match loading missing")
  assert(shopSource:find("SuviversRoundExposure",1,true) and shopSource:find("covered>=2",1,true) and shopSource:find("Lighting.FogEnd=isKiller and 118 or 92",1,true),"Outdoor fog/indoor lantern darkness missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('action=="buyKiller"',1,true) and game.ServerScriptService.ProfileService.Source:find("ownedKillers",1,true),"Persistent killer shop server path missing")
  assert(not game.ServerScriptService.SurvivalServer.Source:find('action=="adminReset"',1,true) and not game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("AdminReset",1,true),"Reset/test control returned")
  assert(not game.ServerScriptService.SurvivalServer.Source:find("adminResetRequested",1,true),"Hidden reset/test state returned")
  assert(not game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Removed crouch payload returned")
  assert(not game.ServerScriptService.SurvivalServer.Source:find('action=="boost"',1,true) and not game.ServerScriptService.SurvivalServer.Source:find('action=="musicPlay"',1,true) and not game.ServerScriptService.SurvivalServer.Source:find('value=="slow"',1,true),"Legacy gameplay actions returned")
  assert(workspace.LobbyGuide:GetAttribute("OutfitUserId")==8344738123 and workspace.LobbyGuide.Head.Transparency==1,"Guide outfit/headless missing")
  assert(workspace.LobbyGuide:GetAttribute("OutfitFrozen")==true and workspace.LobbyGuide:GetAttribute("OutfitSource")=="FillFrozenAppearance","Fill outfit is not frozen")
  assert(workspace.LobbyGuide:GetAttribute("OutfitPants")==110421904136844 and workspace.LobbyGuide:GetAttribute("CrossbodyBagAssetId")==97665507839365,"Requested Fill pants/satchel metadata missing")
  assert(workspace.LobbyGuide:FindFirstChild("FillCrossbodySatchel",true),"Requested Fill satchel accessory missing")
  assert(workspace.LobbyGuide:GetAttribute("OutfitRevision")=="2026-10-26-mafia-satchel-v1","Fill outfit revision not frozen")
  local frozen=game:GetService("ServerStorage"):FindFirstChild("FillFrozenAppearance")
  assert(frozen and frozen:IsA("HumanoidDescription") and frozen:GetAttribute("Frozen")==true and frozen:GetAttribute("SourceUserId")==8344738123,"Persistent frozen Fill appearance missing")
  local fillTable=assert(workspace.LobbyGuide.Tabletop.Value,"Fill tabletop reference missing")
  assert(fillTable:IsDescendantOf(workspace.JediLibrary.House) and fillTable.Name=="Furniture_Console_A" and fillTable:GetFullName():find("Console Desk",1,true),"Fill is not seated on the authored lobby console table")
  assert(not workspace.JediLibrary:FindFirstChild("GuideTable") and not workspace.JediLibrary:FindFirstChild("FillGuideStool"),"Generated Fill furniture returned")
  assert(typeof(workspace.LobbyGuide:GetAttribute("ReceptionPosition"))=="Vector3" and (workspace.LobbyGuide:GetAttribute("ReceptionPieceCount") or 0)>=1,"Fill authored-table geometry metadata missing")
  assert(workspace.LobbyGuide:GetAttribute("ReceptionAccessMode")=="AuthoredTable" and workspace.LobbyGuide:GetAttribute("GuideStation")==fillTable:GetFullName(),"Fill authored table metadata missing")
  local exteriorGround=assert(workspace.JediLibrary:FindFirstChild("OutdoorGround"),"Exterior ground missing")
  assert(workspace.JediLibrary:GetAttribute("OutdoorGroundReady")==true and workspace.JediLibrary:GetAttribute("OutdoorGroundMaterial")=="Ground","Exterior ground metadata missing")
  assert(exteriorGround.Material==Enum.Material.Ground and exteriorGround.Transparency==0,"Exterior ground is still grass/invisible")
  assert(math.abs((exteriorGround.Position.Y+exteriorGround.Size.Y/2)-625.031494140625)<.25,"Exterior ground is vertically misaligned")
  local passage=assert(workspace.JediLibrary:FindFirstChild("PassageColliders"),"Lobby passage colliders missing")
  for _,part in ipairs(passage:GetDescendants()) do
   if part:IsA("BasePart") then
    assert(not part:GetAttribute("WalkableStairStep") and not part:GetAttribute("UpperLandingBridge"),"Invisible stair floor returned")
   end
  end
  assert((workspace.JediLibrary:GetAttribute("PassageRepairRevision") or 0)>=4 and workspace.JediLibrary:GetAttribute("StairAccessClosed")==true,"Stair closure revision missing")
  assert((workspace.JediLibrary:GetAttribute("WalkableStairSteps") or 0)==0,"Invisible stair path count returned")
  local stairWarning=assert(workspace.JediLibrary:FindFirstChild("StairClosedSign"),"Requested construction sign missing")
  assert(workspace.JediLibrary:GetAttribute("StairWarningAssetId")==17143448214 and stairWarning:GetAttribute("SourceAssetId")==17143448214,"Wrong construction sign asset")
  assert(not workspace.JediLibrary:FindFirstChild("UnderStairWallRepair"),"Removed interior under-stair wall returned")
  assert(workspace.JediLibrary:GetAttribute("UnderStairWallRepaired")==false and workspace.JediLibrary:GetAttribute("InteriorWallRemoved")==true,"Interior wall removal metadata missing")
  assert(workspace.JediLibrary:GetAttribute("GeneratedUnderStairWallRemoved")==true,"Generated wall removal metadata missing")
  assert(not workspace.JediLibrary:FindFirstChild("DoorsMerchantRoom"),"Physical monster shop returned to the lobby")
  local shopMerchant=assert(workspace.JediLibrary:FindFirstChild("ShopMerchant"),"Kitchen shop NPC missing")
  local shopPrompt=assert(shopMerchant:FindFirstChild("SuviversShopPrompt",true),"Shop prompt missing")
  assert(shopMerchant:GetAttribute("Placement")=="KitchenNearSpawn" and shopPrompt.ObjectText=="" and shopPrompt.ActionText=="" and shopPrompt:GetAttribute("TextlessInteraction")==true,"Shop NPC is not active/textless in the kitchen")
  assert(workspace.JediLibrary:GetAttribute("PhysicalMonsterShopRemoved")==true and workspace.JediLibrary:GetAttribute("ShopMerchantPlacement")=="KitchenNearSpawn","Kitchen shop placement metadata missing")
  assert((workspace.JediLibrary:GetAttribute("ShopMerchantDistanceFromSpawn") or math.huge)<=90,"Kitchen shop NPC is too far from spawn")
  assert(stairWarning:GetAttribute("BlocksUpperFloor")==true and stairWarning:FindFirstChild("NoUpstairsLabel",true),"NÃO SUBA stair warning incomplete")
  assert(game.StarterPlayer.DevCameraOcclusionMode==Enum.DevCameraOcclusionMode.Zoom,"Camera still uses wall transparency/Invisicam behavior")
  assert(workspace.LobbyGuide:GetAttribute("DisplayName")=="Fill" and workspace.LobbyGuide.ProximityPrompt.ObjectText=="" and workspace.LobbyGuide.ProximityPrompt.ActionText=="" and workspace.LobbyGuide.ProximityPrompt:GetAttribute("TextlessInteraction")==true,"Fill textless prompt was not persisted")
  assert(workspace.LobbyGuide:GetAttribute("AuthoredPosePreserved")==true and workspace.LobbyGuide:GetAttribute("Placement")=="ReceptionTabletopSeated" and workspace.LobbyGuide:GetAttribute("SeatedOnReception")==true,"Fill is not seated on top of the authored lobby table")
  local fillSource=workspace.LobbyGuide.GuideInteraction.Source
  assert(fillSource:find("portugueseGreeting",1,true) and fillSource:find("englishGreeting",1,true) and fillSource:find("GameLanguage",1,true),"Settings-driven bilingual Fill text missing")
  assert(not fillSource:find("languageButton",1,true) and not fillSource:find("AudioTextToSpeech",1,true),"Fill manual language/TTS controls returned")
  assert(fillSource:find('voice.Name="FillVoice"',1,true) and fillSource:find("How does the game work?",1,true) and fillSource:find("Nothing right now.",1,true),"Fill fixed English uploaded-audio dialogue missing")
  assert(fillSource:find('SoundService',1,true) and fillSource:find('ContentProvider:PreloadAsync',1,true),"Fill voice is not preloaded from SoundService")
  assert(fillSource:find('subtitle.Name="CinematicSubtitle"',1,true) and fillSource:find('bubble.Enabled=false',1,true) and fillSource:find("local explain=talking",1,true),"Fill cinematic subtitles/body explanation gestures missing")
  assert(workspace.LobbyGuide:GetAttribute("VoiceLanguage")=="English" and workspace.LobbyGuide.ProximityPrompt.ActionText=="" and workspace.LobbyGuide.ProximityPrompt:GetAttribute("TextlessInteraction")==true,"Fill fixed English voice/textless prompt metadata missing")
  for i=1,6 do assert((game.ReplicatedStorage.Survival:GetAttribute("FillVoice"..i) or 0)>0,"Persisted Fill English voice asset "..i.." missing") end
  local settingsSource=game.ReplicatedStorage.Survival.SettingsPanel.Source
  local clientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(clientSource:find("ViewportFrame",1,true) and clientSource:find("KillerPreviews",1,true),"3D killer shop source not persisted")
  assert(clientSource:find('local killerOrder={"Jason","JohnDoe","Chucky","Piggy","Krampus"}',1,true),"Five-character killer order not persisted")
  local previewFolder=assert(game.ReplicatedStorage.Survival:FindFirstChild("KillerPreviews"),"Killer shop previews missing")
  assert(#previewFolder:GetChildren()==5 and not previewFolder:FindFirstChild("Jeff") and not previewFolder:FindFirstChild("Freddy"),"Killer shop preview roster is not five")
  assert(settingsSource:find("GameLanguage",1,true) and settingsSource:find("addLanguage",1,true) and settingsSource:find('key="interface"',1,true),"Game language setting not persisted")
  assert(clientSource:find('BackgroundTransparency=.82',1,true) and clientSource:find('settingsOverlay.ZIndex=40',1,true),"Readable settings overlay fix not persisted")
  assert(clientSource:find("GameLanguage",1,true) and clientSource:find('L("PERSEGUIDORES","KILLERS")',1,true),"Settings-driven HUD translations not persisted")
  assert(game.StarterGui.TomiaszMenu.MenuController.Source:find('player:SetAttribute("InMenu",false)',1,true),"Direct-lobby menu controller missing")
  assert(game.ReplicatedStorage.Survival.SettingsPanel.Source:find('frame.Name="ReferenceSettings"',1,true),"Restored compact settings panel not persisted")
  assert(game.ReplicatedStorage.Survival.PlayerProfile.Source:find("CompactProfile",1,true),"Compact private profile not persisted")
  assert(game.StarterPlayer.StarterPlayerScripts.PlayerProfileController,"Profile interaction not persisted")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('UDim2.fromOffset(18,132)',1,true),"XP/level HUD was not lowered enough")
  assert(game.ServerScriptService.RoundRules.Source:find("Duration=660",1,true) and game.ServerScriptService.RoundRules.Source:find("Intermission=60",1,true) and game.ServerScriptService.RoundRules.Source:find("VoteDuration=6",1,true),"11-minute round, one-minute intermission, or six-second voting rules missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('state.phase="Votação"',1,true) and game.ServerScriptService.SurvivalServer.Source:find("setupObjectives",1,true) and game.ServerScriptService.SurvivalServer.Source:find("toggleCarry",1,true),"Objective gameplay runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("MapVoteOptions",1,true) and game.ServerScriptService.SurvivalServer.Source:find('RANDOM=0',1,true),"Four-map plus random voting runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find("KillerPlayerName",1,true) and game.ServerScriptService.SurvivalServer.Source:find("LoadingRoster",1,true),"Match loading killer/roster metadata missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("4 NA VOTAÇÃO",1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find("7 MAPAS TOTAIS",1,true),"Four-map plus random voting UI missing")
  local survivalClientSource=game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source
  assert(
   survivalClientSource:find('cleanAction(topActions,"Crouch",L("AGACHAR","CROUCH")',1,true)
   and survivalClientSource:find('staminaTrack.Name="Stamina"',1,true)
   and survivalClientSource:find("ObjectiveInventory",1,true)
   and survivalClientSource:find("MissionBanner",1,true),
   "Current localized objective HUD/stamina/crouch UI missing"
  )
  assert(game.ServerStorage.SurvivalAssets.Items.ComputerTemplate:GetAttribute("SourceAssetId")==4845271739 and game.ServerStorage.SurvivalAssets.Items.KeyTemplate:GetAttribute("SourceAssetId")==11471202845,"PC/key objective assets missing")
  assert(game.ReplicatedStorage.Survival:GetAttribute("InventoryAssetId")==73852738603629 and game.ReplicatedStorage.Survival:GetAttribute("FootstepAssetId")==137365042825200,"Inventory/footstep assets missing")
  assert(game.StarterPlayer.StarterPlayerScripts.PursuerAnimation.Source:find('requested=="RoundVictory"',1,true),"Animated winner runtime missing")
  assert(game.ServerScriptService.SurvivalServer.Source:find('p~=selectionPlayer',1,true),"Private selection guard missing")
  assert(game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('net:GetAttribute("Phase")=="Votação"',1,true) and game.StarterPlayer.StarterPlayerScripts.SurvivalClient.Source:find('voteTimer.Text=tostring(seconds)',1,true),"Full six-second voting overlay missing")
  assert(game.ReplicatedStorage.Survival.CoinDisplay:GetAttribute("SourceAssetId")==10737243803,"Exact coin missing")
  assert(#game.ReplicatedStorage.Survival.VictimMotionLibraries:GetChildren()==5,"Missing victim pairs")
  for _,map in ipairs(assets.Maps:GetChildren()) do assert(#map.ObjectiveSites:GetChildren()>=9 and #map.ArrivalSpawns:GetChildren()>=7,"Map layout missing: "..map.Name) end
  assert(game.ServerScriptService.SurvivalServer.Source:find("profiles:ownsKiller",1,true) and game.ServerScriptService.SurvivalServer.Source:find("profiles:buyKiller",1,true),"Killer shop authority missing")
  return {survivorActionAnimations=true,crouchAnimation=true,injuredCrouchAnimation=true,objectiveChecks=true,fiveVictimAnimations=true,noResetControl=true,coinAsset=10737243803,simplifiedSettings=true,compactProfile=true,privateKillerSelection=true,killerShop=true,voteDismissal=true,guide=true,guideAvatar="ch_ckz2n",guideHeadless=true,guideReception=true,guideEnglishUploadedVoice=true,objectiveEscape=true,stamina=true,crouch=true,carryDowned=true,dedicatedVoting=true,winnerMenuScene=true,animatedWinner=true,atomicShopPurchase=true,noMainMenu=true,ok=true,version=game.PlaceVersion,build=158,logo=true,mapCount=7,pursuerCount=5,lobbyPreserved=true,noLobbyPortal=true,noLobbyDoorGeometry=true,invisibleBounds=true,holdRun=true,fullScreenKillerResult=true,synchronizedExecution=true,resultCameraRestored=true,initialLogoOnly=true,mapAnimatedLoading=true,smoothLocomotion=true,fixedViolenceDistrictEnvironment=true,requestedSevenMaps=true,rocketArena2x=true,pursuersNormalized=true,legacySystemsRemoved=true,buckshotRoundMusic=true,lowVolumeRoundMusic=true}
 `));
console.log('PERSISTED_PUBLICATION',JSON.stringify(persisted));
