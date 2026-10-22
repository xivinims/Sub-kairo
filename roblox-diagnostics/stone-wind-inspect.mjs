const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9419478735/places/79738710219521/';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const r=await fetch(CLOUD+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined});
  const t=await r.text(); let d; try{d=JSON.parse(t)}catch{d={raw:t}}
  if(!r.ok) throw new Error(JSON.stringify(d)); return d;
}
async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){await sleep(1200); task=await req(task.path);}
  if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task));
  return task.output?.results?.[0] ?? null;
}
const result=await execute(String.raw`
local A=game:GetService("AssetService")
local T=workspace.Terrain
local out={}

local path=workspace:FindFirstChild("StonePath")
out.currentStoneCount=path and #path:GetChildren() or 0
out.currentStones={}
if path then
  for i,v in ipairs(path:GetChildren()) do
    if i>8 then break end
    if v:IsA("BasePart") then
      local ray=workspace:Raycast(v.Position+Vector3.new(0,5,0),Vector3.new(0,-12,0))
      table.insert(out.currentStones,{
        name=v.Name,class=v.ClassName,size={v.Size.X,v.Size.Y,v.Size.Z},
        pos={v.Position.X,v.Position.Y,v.Position.Z},
        transparency=v.Transparency,
        material=tostring(v.Material),
        belowMaterial=ray and tostring(ray.Material) or "nil"
      })
    end
  end
end

local ok,asset=pcall(function() return A:LoadAssetAsync(136068114177879) end)
out.assetLoaded=ok and asset~=nil
out.assetItems={}
if ok and asset then
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("BasePart") then
      table.insert(out.assetItems,{
        name=d.Name,class=d.ClassName,
        size={d.Size.X,d.Size.Y,d.Size.Z},
        transparency=d.Transparency,
        material=tostring(d.Material)
      })
      if #out.assetItems>=20 then break end
    end
  end
  out.assetBasePartCount=0
  out.assetModelCount=0
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("BasePart") then out.assetBasePartCount+=1 end
    if d:IsA("Model") then out.assetModelCount+=1 end
  end
  asset:Destroy()
end

local wind=workspace:FindFirstChild("WindEffects")
out.windExists=wind~=nil
out.windChildren=wind and #wind:GetChildren() or 0
out.windAssetId=wind and wind:GetAttribute("AssetId") or nil
out.globalWind={workspace.GlobalWind.X,workspace.GlobalWind.Y,workspace.GlobalWind.Z}

local center=workspace:Raycast(Vector3.new(0,80,0),Vector3.new(0,-130,0))
out.centerMaterial=center and tostring(center.Material) or "nil"

return out
`);
console.log(JSON.stringify(result,null,2));
