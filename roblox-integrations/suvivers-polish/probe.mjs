const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:body?'POST':'GET',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:body?JSON.stringify(body):undefined,
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('HTTP '+res.status+': '+raw.slice(0,1200));
  return data;
}
async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+300000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('timeout');
    await sleep(1500);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task.error||task));
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}
const script=String.raw`
local HttpService=game:GetService("HttpService")
local report={version=game.PlaceVersion,gameId=game.GameId,placeId=game.PlaceId,services={},workspace={},sounds={},scripts={}}

local function childSummary(parent)
 local out={}
 for _,c in ipairs(parent:GetChildren()) do
  table.insert(out,{name=c.Name,class=c.ClassName})
 end
 table.sort(out,function(a,b)return a.name<b.name end)
 return out
end

local function addService(name,parent)
 report.services[name]=childSummary(parent)
end
addService("ServerScriptService",game:GetService("ServerScriptService"))
addService("StarterPlayerScripts",game:GetService("StarterPlayer").StarterPlayerScripts)
addService("StarterCharacterScripts",game:GetService("StarterPlayer").StarterCharacterScripts)
addService("StarterGui",game:GetService("StarterGui"))
addService("ReplicatedStorage",game:GetService("ReplicatedStorage"))
addService("ServerStorage",game:GetService("ServerStorage"))

for _,name in ipairs({"Lobby","ActiveMap","ActiveNextbots","MenuCameraAnchor","NB_LobbySpawn"}) do
 local obj=workspace:FindFirstChild(name)
 if obj then
  local rec={class=obj.ClassName,children=childSummary(obj)}
  if obj:IsA("Model") then local cf,size=obj:GetBoundingBox(); rec.center=tostring(cf.Position); rec.size=tostring(size) end
  if obj:IsA("BasePart") then rec.pos=tostring(obj.Position); rec.size=tostring(obj.Size) end
  report.workspace[name]=rec
 end
end

for _,d in ipairs(game:GetDescendants()) do
 if d:IsA("Sound") and d.SoundId~="" then
  table.insert(report.sounds,{name=d.Name,path=d:GetFullName(),id=d.SoundId,volume=d.Volume,playing=d.Playing})
 end
end

local wanted={"NextbotsRoundServer","NB_MotionService","NB_NametagService","NB_R6MotionController","NBMenu","NB_Client","NBClient","NB_AIController","RoundLoop","JoinHandler","NB_Server"}
for _,name in ipairs(wanted) do
 local found=nil
 for _,root in ipairs({game:GetService("ServerScriptService"),game:GetService("StarterPlayer").StarterPlayerScripts,game:GetService("StarterGui")}) do
  found=root:FindFirstChild(name,true)
  if found then break end
 end
 if found and found:IsA("LuaSourceContainer") then
  local src=found.Source or ""
  report.scripts[name]={path=found:GetFullName(),class=found.ClassName,enabled=(found:IsA("BaseScript") and found.Enabled or nil),length=#src,source=string.sub(src,1,30000)}
 end
end

local maps=game:GetService("ServerStorage"):FindFirstChild("NB_Maps")
if maps then
 report.maps={}
 for _,m in ipairs(maps:GetChildren()) do
  local rec={name=m.Name,class=m.ClassName}
  if m:IsA("Model") then local cf,size=m:GetBoundingBox(); rec.center=tostring(cf.Position); rec.size=tostring(size) end
  local sp=m:FindFirstChild("SpawnPoints",true)
  local bp=m:FindFirstChild("NBBotSpawns",true)
  rec.playerSpawns=sp and #sp:GetChildren() or 0
  rec.botSpawns=bp and #bp:GetChildren() or 0
  table.insert(report.maps,rec)
 end
end

local gui=game:GetService("StarterGui")
report.guiTree={}
local function walk(obj,depth,out)
 if depth>3 then return end
 for _,c in ipairs(obj:GetChildren()) do
  local rec={name=c.Name,class=c.ClassName}
  if c:IsA("GuiObject") then rec.visible=c.Visible; rec.position=tostring(c.Position); rec.size=tostring(c.Size); rec.backgroundTransparency=c.BackgroundTransparency end
  table.insert(out,rec)
  rec.children={}
  walk(c,depth+1,rec.children)
 end
end
walk(gui,0,report.guiTree)

return HttpService:JSONEncode(report)
`;
execute(script).then(r=>console.log('SURVIVORS_POLISH_PROBE '+JSON.stringify(r))).catch(e=>{console.error(e.stack||e);process.exit(1)});
