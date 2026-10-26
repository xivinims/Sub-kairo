const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<8;i++){
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
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(Math.min(30000,3000*(i+1)));
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
  const deadline=Date.now()+180000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Live verify timeout');
    await sleep(1200);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Live verify failed: '+JSON.stringify(task));
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

const result=await execute("\nlocal Http=game:GetService(\"HttpService\")\nlocal lobby=assert(workspace:FindFirstChild(\"JediLibrary\"),\"JediLibrary missing\")\nlocal house=assert(lobby:FindFirstChild(\"House\"),\"Lobby house missing\")\nlocal npc=assert(workspace:FindFirstChild(\"LobbyGuide\"),\"Fill missing\")\nassert(game.PlaceVersion>=162,\"Expected published lobby hotfix version\")\nassert(lobby:GetAttribute(\"OutdoorGroundReady\")==true,\"Outdoor ground metadata missing\")\nlocal groundSize=lobby:GetAttribute(\"OutdoorGroundSize\")\nassert(typeof(groundSize)==\"Vector3\" and groundSize.X>=500 and groundSize.Z>=480,\"Outdoor ground dimensions invalid\")\n\nlocal exclusions={}\nfor _,name in ipairs({\"InvisibleBounds\",\"PassageColliders\"}) do local x=lobby:FindFirstChild(name) if x then table.insert(exclusions,x) end end\nlocal params=RaycastParams.new()\nparams.FilterType=Enum.RaycastFilterType.Exclude\nparams.FilterDescendantsInstances=exclusions\nparams.RespectCanCollide=true\nlocal physicalGround=assert(lobby:FindFirstChild(\"OutdoorGround\"),\"Persistent exterior grass floor missing\")\nassert(physicalGround:IsA(\"BasePart\") and physicalGround.CanCollide and physicalGround.Material==Enum.Material.Grass,\"Exterior grass floor is not physical\")\nassert(physicalGround:GetAttribute(\"PersistentOutdoorGround\")==true,\"Exterior grass floor persistence marker missing\")\nlocal groundHit=workspace:Raycast(Vector3.new(171.9,680,6.59),Vector3.new(0,-100,0),params)\nassert(groundHit and groundHit.Instance==physicalGround,\"Physical exterior ground is still missing outside the lobby\")\nassert(math.abs(groundHit.Position.Y-(lobby:GetAttribute(\"OutdoorGroundY\") or 0))<1.2,\"Exterior ground height does not match porch ground\")\n\nassert((lobby:GetAttribute(\"PassageRepairRevision\") or 0)>=3,\"Lobby passage repair v3 missing\")\nlocal access=assert(lobby:FindFirstChild(\"PassageColliders\"),\"PassageColliders missing\")\nlocal bridge,highest=0,nil\nfor _,p in ipairs(access:GetChildren()) do\n if p:IsA(\"BasePart\") and p:GetAttribute(\"UpperLandingBridge\") then\n  assert(p.CanCollide and p.Transparency>=.98,\"Upper landing step must be invisible and solid\")\n  bridge+=1\n  if not highest or p.Position.Y>highest.Position.Y then highest=p end\n end\nend\nassert(bridge==6 and highest,\"Upper landing bridge incomplete\")\nlocal mainFoyer=nil\nfor _,p in ipairs(house:GetDescendants()) do\n if p:IsA(\"BasePart\") and string.find(string.lower(p.Name),\"house_foyer_stairs_lower\",1,true) then mainFoyer=p break end\nend\nassert(mainFoyer and not mainFoyer.CanCollide,\"Main foyer mesh still has blocking collision\")\nlocal targetTop=mainFoyer.Position.Y+mainFoyer.Size.Y/2\nassert(highest.Position.Y+highest.Size.Y/2>=targetTop-.7,\"Stair path still stops below the upper floor\")\nlocal cleared=0\nfor _,p in ipairs(house:GetDescendants()) do\n if p:IsA(\"BasePart\") and p:GetAttribute(\"FoyerRailPassThrough\") then assert(not p.CanCollide,\"Cleared foyer rail still collides\") cleared+=1 end\nend\nassert(cleared>=3,\"Upper stair landing rails were not cleared\")\n\nassert(not lobby:FindFirstChild(\"FillGuideStool\"),\"Generated Fill stool still exists\")\nlocal tabletop=assert(npc:FindFirstChild(\"Tabletop\") and npc.Tabletop.Value,\"Fill tabletop reference missing\")\nassert(tabletop.Name==\"Furniture_Console_A\" and tabletop:GetFullName():find(\"Console Desk\",1,true),\"Fill is not on the authored console table\")\nassert(npc:GetAttribute(\"ReceptionAccessMode\")==\"AuthoredTable\" and npc:GetAttribute(\"GuideStation\")==tabletop:GetFullName(),\"Fill authored table metadata missing\")\nlocal torso=assert(npc:FindFirstChild(\"Torso\"),\"Fill torso missing\")\nlocal gap=(torso.Position.Y-torso.Size.Y/2)-(tabletop.Position.Y+tabletop.Size.Y/2)\nassert(math.abs(gap-.025)<.12,\"Fill is not sitting directly on the tabletop\")\nfor _,p in ipairs(npc:GetDescendants()) do if p:IsA(\"BasePart\") then assert(not p.CanCollide,\"Fill body is blocking the lobby\") end end\n\nlocal settings=assert(game.ReplicatedStorage.Survival:FindFirstChild(\"SettingsPanel\"),\"SettingsPanel missing\").Source\nlocal client=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild(\"SurvivalClient\"),\"SurvivalClient missing\").Source\nlocal guide=assert(npc:FindFirstChild(\"GuideInteraction\"),\"Fill GuideInteraction missing\").Source\nassert(settings:find(\"GameLanguage\",1,true) and settings:find('key=\"language\"',1,true) and settings:find(\"Português (Brasil)\",1,true),\"Game language selector missing\")\nassert(client:find('BackgroundTransparency=.82',1,true) and client:find('settingsOverlay.ZIndex=40',1,true),\"Settings dark-overlay fix missing\")\nassert(client:find('L(\"PERSEGUIDORES\",\"KILLERS\")',1,true) and client:find(\"GameLanguage\",1,true),\"HUD text is not settings-driven\")\nassert(not guide:find(\"languageButton\",1,true),\"Fill manual language button still exists\")\nassert(not guide:find(\"AudioTextToSpeech\",1,true),\"Portuguese Fill TTS still exists\")\nassert(guide:find(\"GameLanguage\",1,true) and guide:find('voice.Name=\"FillVoice\"',1,true),\"Fill text/voice language split missing\")\nassert(guide:find('prompt.ActionText=language==\"pt\" and \"Falar\" or \"Talk\"',1,true),\"Fill prompt is not tied to game text language\")\nassert(npc:GetAttribute(\"VoiceLanguage\")==\"English\",\"Fill voice metadata is not fixed to English\")\n\nreturn Http:JSONEncode({\n ok=true,\n version=game.PlaceVersion,\n exteriorGround=true,\n groundY=groundHit.Position.Y,\n groundSize=tostring(groundSize),\n stairBridge=bridge,\n upperLandingReached=true,\n clearedRails=cleared,\n fillTable=tabletop:GetFullName(),\n fillGap=gap,\n settingsReadable=true,\n gameLanguageSelector=true,\n hudTranslations=true,\n fillManualLanguageButton=false,\n fillPortugueseVoice=false,\n fillVoiceLanguage=npc:GetAttribute(\"VoiceLanguage\")\n})\n");
console.log('SUVIVERS_LOBBY_FINAL_VERIFY',JSON.stringify(result));
if(!result?.ok) throw new Error('Final lobby verification did not return ok');
