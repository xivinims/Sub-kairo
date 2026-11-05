// ExtasyCatBOY: safe additive installer for one Roblox universe.
// Never uploads a blank place and never modifies unrelated folders or map instances.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const target = JSON.parse(fs.readFileSync(path.join(root,"deploy/target.json"),"utf8"));
const universeId = String(target.roblox.universeId);
const key = process.env.ROBLOX_API_KEY;
const manualPlaceId = process.env.EXTASYCATBOY_PLACE_ID ||
  (target.roblox.placeId ? String(target.roblox.placeId) : null);
if (universeId !== "9421505041") throw Error("Universe mismatch: refusing deployment.");
const sleep = ms => new Promise(resolve => setTimeout(resolve,ms));
async function getJson(url,headers={},options={}) {
  const res=await fetch(url,{
    ...options,
    headers:{"accept":"application/json",...headers},
    signal:AbortSignal.timeout(25000),
  });
  const body=await res.text();
  let result;
  try { result=JSON.parse(body); }
  catch { result={raw:body.slice(0,200)}; }
  if (!res.ok) throw Error("Roblox HTTP "+res.status+" on "+new URL(url).hostname+": "+JSON.stringify(result).slice(0,280));
  return result;
}
function rootId(obj) {
  const value=obj?.rootPlaceId ?? obj?.rootPlace?.id ?? obj?.rootPlace?.placeId ?? obj?.root_place_id ?? obj?.universe?.rootPlaceId;
  return /^[1-9][0-9]{3,20}$/.test(String(value)) ? String(value) : null;
}
async function resolvePlaceId() {
  if (manualPlaceId) {
    if (!/^[1-9][0-9]{3,20}$/.test(manualPlaceId)) throw Error("Invalid EXTASYCATBOY_PLACE_ID.");
    console.log("Place configured for ExtasyCatBOY:",manualPlaceId);
    return manualPlaceId;
  }
  const sources=[
    ["games metadata","https://games.roblox.com/v1/games?universeIds="+universeId,{},d=>rootId(d.data?.find(x=>String(x.id)===universeId))],
    ["develop universe","https://develop.roblox.com/v1/universes/"+universeId,{},rootId],
  ];
  if(key) sources.push(["cloud universe","https://apis.roblox.com/cloud/v2/universes/"+universeId,{"x-api-key":key},rootId]);
  for(const [name,url,headers,extract] of sources) {
    try {
      const id=extract(await getJson(url,headers));
      if(id) {
        console.log("Resolved Place ID:",id,"using",name);
        return id;
      }
      console.log("No rootPlaceId from",name);
    } catch(error) { console.warn("Lookup "+name+" failed:",String(error.message).slice(0,120)); }
  }
  throw Error("Unable to resolve root Place ID for universe 9421505041. Set the GitHub Actions variable EXTASYCATBOY_PLACE_ID to the ID from Creator Dashboard > Places. No changes have been made.");
}
const files=[
  ["ReplicatedStorage","ExtasyShared","Config","ModuleScript","src/shared/Config.lua"],
  ["ReplicatedStorage","ExtasyShared","Dialogue","ModuleScript","src/shared/Dialogue.lua"],
  ["ServerScriptService","ExtasyServer","Main","Script","src/server/Main.server.lua"],
  ["StarterPlayerScripts","ExtasyClient","Main","LocalScript","src/client/Main.client.lua"],
  ["StarterPlayerScripts","ExtasyClient","Animations","LocalScript","src/client/Animations.client.lua"],
];
function buildLuau(placeId) {
  const values=files.map(([service,folder,name,kind,file])=>{
    const source=fs.readFileSync(path.join(root,file),"utf8");
    if(source.length<100) throw Error("Missing script: "+file);
    return "{service="+JSON.stringify(service)+",folder="+JSON.stringify(folder)+",name="+JSON.stringify(name)+",kind="+JSON.stringify(kind)+",source="+JSON.stringify(source)+"}";
  });
  const lines=[
    'local HttpService=game:GetService("HttpService")',
    'assert(tostring(game.GameId)=='+JSON.stringify(universeId)+',"Wrong universe: "..tostring(game.GameId))',
    'assert(tostring(game.PlaceId)=='+JSON.stringify(placeId)+',"Wrong place: "..tostring(game.PlaceId))',
    'local entries={'+values.join(",\n")+'}',
    'local services={',
    'ReplicatedStorage=game:GetService("ReplicatedStorage"),',
    'ServerScriptService=game:GetService("ServerScriptService"),',
    'StarterPlayerScripts=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")',
    '}',
    'local groups={}',
    'for _, item in ipairs(entries) do',
    '  local id=item.service.."/"..item.folder',
    '  if not groups[id] then',
    '    groups[id]={root=services[item.service],folder=Instance.new("Folder")}',
    '    groups[id].folder.Name=item.folder',
    '  end',
    '  local obj=Instance.new(item.kind)',
    '  obj.Name=item.name',
    '  if obj:IsA("BaseScript") then obj.Enabled=false end',
    '  obj.Source=item.source',
    '  obj.Parent=groups[id].folder',
    'end',
    'local installed=0',
    'local paths={}',
    'for _,group in pairs(groups) do',
    '  local old=group.root:FindFirstChild(group.folder.Name)',
    '  assert(not old or old:IsA("Folder"),"Unexpected managed folder type")',
    '  group.folder.Parent=group.root',
    '  if old then old:Destroy() end',
    '  for _,obj in ipairs(group.folder:GetChildren()) do',
    '    if obj:IsA("BaseScript") then obj.Enabled=true end',
    '    installed+=1',
    '  end',
    '  table.insert(paths,group.root.Name.."/"..group.folder.Name)',
    'end',
    'table.sort(paths)',
    'game:GetService("AssetService"):SavePlaceAsync()',
    'return HttpService:JSONEncode({ok=true,universeId=tostring(game.GameId),placeId=tostring(game.PlaceId),installed=installed,paths=paths})'
  ];
  return lines.join("\n");
}
async function deploy(placeId,source) {
  if(!key) throw Error("GitHub secret ROBLOX_API_KEY is missing or unavailable.");
  const base="https://apis.roblox.com/cloud/v2/";
  const prefix="universes/"+universeId+"/places/"+placeId+"/";
  const opts={ "x-api-key":key,"content-type":"application/json" };
  let task=await getJson(base+prefix+"luau-execution-session-tasks",opts,{
    method:"POST",body:JSON.stringify({script:source,timeout:"180s"})
  });
  const deadline=Date.now()+240000;
  while(["QUEUED","PENDING","PROCESSING"].includes(task.state)) {
    if(Date.now()>deadline) throw Error("Roblox Luau execution timed out.");
    if(!String(task.path??"").startsWith(prefix)) throw Error("Roblox task returned mismatched path.");
    await sleep(2300);
    task=await getJson(base+task.path,{"x-api-key":key});
  }
  if(task.state!=="COMPLETE" || task.error) throw Error("Open Cloud failed: "+JSON.stringify(task.error??task).slice(0,700));
  let output=task.output?.results?.[0];
  if(typeof output==="string") {
    try {output=JSON.parse(output);} catch {}
  }
  if(output?.ok!==true || String(output.placeId)!==placeId || String(output.universeId)!==universeId || output.installed!==5) {
    throw Error("Could not confirm saved game: "+JSON.stringify(output).slice(0,600));
  }
  console.log("Saved ExtasyCatBOY scripts to Roblox:",JSON.stringify(output));
}
async function main() {
  const placeId=await resolvePlaceId();
  const source=buildLuau(placeId);
  console.log("Installer prepared: universe="+universeId+", place="+placeId+", source length="+source.length);
  if(process.env.EXTASYCATBOY_DRY_RUN==="true") {
    console.log("Dry run complete: nothing changed in Roblox.");
    return;
  }
  await deploy(placeId,source);
}
main().catch(error=>{
  let msg=String(error.stack||error);
  if(key) msg=msg.split(key).join("[REDACTED]");
  console.error(msg);
  process.exitCode=1;
});
