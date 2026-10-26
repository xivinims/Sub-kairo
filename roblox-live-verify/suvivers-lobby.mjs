const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9419478735/places/79738710219521/';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
 const key=process.env.ROBLOX_API_KEY;
 if(!key) throw new Error('Missing ROBLOX_API_KEY');
 let last;
 for(let i=0;i<8;i++){
  const res=await fetch(CLOUD+path,{
   method:body?'POST':'GET',
   headers:{'x-api-key':key,'content-type':'application/json'},
   body:body?JSON.stringify(body):undefined,
   signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}};
  if(res.ok) return data;
  if([429,500,502,503].includes(res.status)){
   last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
   await sleep(Math.min(30000,3000*(i+1)));
   continue;
  }
  throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
 }
 throw last||new Error('Request retries exhausted');
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
const result=await execute("\nlocal Http=game:GetService(\"HttpService\")\nlocal PhysicsService=game:GetService(\"PhysicsService\")\nlocal lobby=assert(workspace:FindFirstChild(\"JediLibrary\"),\"JediLibrary missing\")\nlocal house=assert(lobby:FindFirstChild(\"House\"),\"Lobby house missing\")\nlocal npc=assert(workspace:FindFirstChild(\"LobbyGuide\"),\"Fill missing\")\nlocal survival=assert(game.ReplicatedStorage:FindFirstChild(\"Survival\"),\"Survival runtime missing\")\nlocal assets=assert(game.ServerStorage:FindFirstChild(\"SurvivalAssets\"),\"SurvivalAssets missing\")\nlocal killers=assert(assets:FindFirstChild(\"Killers\"),\"Killer folder missing\")\n\n-- Five pursuers, no removed characters anywhere in active game content.\nassert(#killers:GetChildren()==5,\"Published killer count is not five\")\nfor _,name in ipairs({\"Jason\",\"JohnDoe\",\"Chucky\",\"Piggy\",\"Krampus\"}) do\n assert(killers:FindFirstChild(name),\"Missing published killer \"..name)\nend\nassert(not killers:FindFirstChild(\"Jeff\") and not killers:FindFirstChild(\"Freddy\"),\"Jeff/Freddy still published\")\nlocal configSource=assert(survival:FindFirstChild(\"Config\"),\"Config missing\").Source\nassert(not configSource:find(\"Jeff=\",1,true) and not configSource:find(\"Freddy=\",1,true),\"Jeff/Freddy still present in Config source\")\n\n-- Shop uses real 3D preview models, not rbxthumb asset pictures.\nlocal previews=assert(survival:FindFirstChild(\"KillerPreviews\"),\"KillerPreviews missing\")\nassert(#previews:GetChildren()==5,\"Published killer preview count is not five\")\nassert(not previews:FindFirstChild(\"Jeff\") and not previews:FindFirstChild(\"Freddy\"),\"Removed killer previews returned\")\nlocal clientSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild(\"SurvivalClient\"),\"SurvivalClient missing\").Source\nassert(clientSource:find('local killerOrder={\"Jason\",\"JohnDoe\",\"Chucky\",\"Piggy\",\"Krampus\"}',1,true),\"Five-killer shop order missing\")\nassert(clientSource:find('Instance.new(\"ViewportFrame\",row)',1,true),\"Shop is not using ViewportFrame portraits\")\nlocal shopStart=clientSource:find(\"local killerOrder=\",1,true) or 1\nlocal shopTail=clientSource:sub(shopStart,math.min(#clientSource,shopStart+9000))\nassert(not shopTail:find(\"rbxthumb://type=Asset\",1,true),\"Old automatic asset thumbnail remains in killer shop\")\n\n-- Exterior floor is visible, neutral, and flush with authored car/garage/gate props.\nlocal ground=assert(lobby:FindFirstChild(\"OutdoorGround\"),\"OutdoorGround missing\")\nassert(ground:IsA(\"BasePart\") and ground.CanCollide and ground.Transparency==0,\"Outdoor ground is not visible/physical\")\nassert(ground.Material==Enum.Material.Ground,\"Outdoor ground is still grass\")\nlocal groundTop=ground.Position.Y+ground.Size.Y/2\nassert(math.abs(groundTop-625.031494140625)<.25,\"Outdoor ground is still vertically misaligned\")\nassert(lobby:GetAttribute(\"OutdoorGroundMaterial\")==\"Ground\",\"Outdoor ground material metadata missing\")\nlocal sample=workspace:Raycast(\n Vector3.new(220,680,-100),\n Vector3.new(0,-100,0),\n RaycastParams.new()\n)\nassert(sample and sample.Instance==ground,\"Exterior sample does not land on the new visible ground\")\n\n-- No invisible stair floor; upstairs is intentionally closed with the requested sign.\nlocal passage=assert(lobby:FindFirstChild(\"PassageColliders\"),\"PassageColliders missing\")\nlocal invisibleStairSupports=0\nfor _,p in ipairs(passage:GetDescendants()) do\n if p:IsA(\"BasePart\") and (p:GetAttribute(\"WalkableStairStep\") or p:GetAttribute(\"UpperLandingBridge\")) then\n  invisibleStairSupports+=1\n end\nend\nassert(invisibleStairSupports==0,\"Invisible staircase supports still exist\")\nassert((lobby:GetAttribute(\"WalkableStairSteps\") or 0)==0,\"WalkableStairSteps metadata is not zero\")\nassert(lobby:GetAttribute(\"StairAccessClosed\")==true,\"Stair closed metadata missing\")\nassert(lobby:GetAttribute(\"StairWarningAssetId\")==17143448214,\"Wrong stair warning asset id\")\nlocal sign=assert(lobby:FindFirstChild(\"StairClosedSign\"),\"StairClosedSign missing\")\nassert(sign:GetAttribute(\"SourceAssetId\")==17143448214 and sign:GetAttribute(\"BlocksUpperFloor\")==true,\"Stair sign metadata invalid\")\nlocal signLabel=assert(sign:FindFirstChild(\"NoUpstairsLabel\",true),\"NÃO SUBA sign label missing\")\nlocal signText=signLabel:FindFirstChildWhichIsA(\"TextLabel\",true)\nassert(signText and signText.Text:find(\"NÃO SUBA\",1,true),\"Stair warning text missing\")\n\n-- Camera uses Zoom collision, not transparent-wall Invisicam behavior.\nassert(game.StarterPlayer.DevCameraOcclusionMode==Enum.DevCameraOcclusionMode.Zoom,\"Camera occlusion is not Zoom\")\n\n-- Fill remains on the real desk, gets the requested revised outfit, and stays ghosted.\nlocal tabletop=assert(npc:FindFirstChild(\"Tabletop\") and npc.Tabletop.Value,\"Fill tabletop reference missing\")\nassert(tabletop.Name==\"Furniture_Console_A\" and tabletop:GetFullName():find(\"Console Desk\",1,true),\"Fill is no longer on authored console desk\")\nassert(npc:GetAttribute(\"OutfitFrozen\")==true,\"Fill outfit is not frozen\")\nassert(npc:GetAttribute(\"OutfitRevision\")==\"2026-10-26-mafia-satchel-v1\",\"Fill outfit revision missing\")\nassert(npc:GetAttribute(\"OutfitPants\")==110421904136844,\"Requested Fill pants missing\")\nassert(npc:GetAttribute(\"CrossbodyBagAssetId\")==97665507839365,\"Requested Fill bag metadata missing\")\nassert(npc:FindFirstChild(\"FillCrossbodySatchel\",true),\"Requested Fill bag accessory missing\")\nassert(npc:GetAttribute(\"VoiceLanguage\")==\"English\",\"Fill voice is no longer fixed to English\")\nassert(npc:GetAttribute(\"NonBlockingGuide\")==true,\"Fill nonblocking flag missing\")\nassert(npc:GetAttribute(\"CollisionGroup\")==\"LobbyGuideGhost\",\"Fill ghost collision metadata missing\")\nassert(not PhysicsService:CollisionGroupsAreCollidable(\"LobbyGuideGhost\",\"Default\"),\"Fill still collides with players\")\n\nreturn Http:JSONEncode({\n ok=true,\n version=game.PlaceVersion,\n killers=#killers:GetChildren(),\n killerPreviews=#previews:GetChildren(),\n shopPortraitMode=\"ViewportFrame\",\n groundMaterial=tostring(ground.Material),\n groundTop=groundTop,\n invisibleStairSupports=invisibleStairSupports,\n stairClosed=true,\n stairSignAsset=lobby:GetAttribute(\"StairWarningAssetId\"),\n cameraOcclusion=tostring(game.StarterPlayer.DevCameraOcclusionMode),\n fillTable=tabletop:GetFullName(),\n fillPants=npc:GetAttribute(\"OutfitPants\"),\n fillBag=npc:GetAttribute(\"CrossbodyBagAssetId\"),\n fillFrozen=npc:GetAttribute(\"OutfitFrozen\"),\n fillVoiceLanguage=npc:GetAttribute(\"VoiceLanguage\")\n})\n");
console.log('SUVIVERS_QUALITY_LIVE_VERIFY',JSON.stringify(result));
if(!result?.ok) throw new Error('Quality live verification did not return ok');
