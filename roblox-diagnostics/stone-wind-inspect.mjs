const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9419478735/places/79738710219521/';
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  const r=await fetch(CLOUD+path,{method:body?'POST':'GET',headers:{'x-api-key':key,'content-type':'application/json'},body:body?JSON.stringify(body):undefined});
  const t=await r.text(); let d; try{d=JSON.parse(t)}catch{d={raw:t}}
  if(!r.ok) throw new Error(JSON.stringify(d)); return d;
}
async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){await sleep(1200);task=await req(task.path);}
  if(task.state!=='COMPLETE'||task.error) throw new Error(JSON.stringify(task));
  return task.output?.results?.[0] ?? null;
}
const result=await execute(String.raw`
local A=game:GetService("AssetService")
local out={}

local ok,asset=pcall(function() return A:LoadAssetAsync(136068114177879) end)
out.stoneLoaded=ok and asset~=nil
if ok and asset then
  local model=asset:FindFirstChildWhichIsA("Model",true)
  out.stoneModelName=model and model.Name or nil
  if model then
    local cf,size=model:GetBoundingBox()
    out.stoneModelSize={size.X,size.Y,size.Z}
    out.stoneModelPivot={cf.Position.X,cf.Position.Y,cf.Position.Z}
    out.stoneDirectChildren=#model:GetChildren()
    out.stonePartCount=0
    out.stoneRanges={minX=1e9,maxX=-1e9,minZ=1e9,maxZ=-1e9}
    for _,d in ipairs(model:GetDescendants()) do
      if d:IsA("BasePart") then
        out.stonePartCount+=1
        local rel=model:GetPivot():ToObjectSpace(d.CFrame).Position
        out.stoneRanges.minX=math.min(out.stoneRanges.minX,rel.X)
        out.stoneRanges.maxX=math.max(out.stoneRanges.maxX,rel.X)
        out.stoneRanges.minZ=math.min(out.stoneRanges.minZ,rel.Z)
        out.stoneRanges.maxZ=math.max(out.stoneRanges.maxZ,rel.Z)
      end
    end
  end
  asset:Destroy()
end

local wok,wasset=pcall(function() return A:LoadAssetAsync(11946229834) end)
out.windLoaded=wok and wasset~=nil
if wok and wasset then
  out.windModels=0; out.windParts=0; out.windParticles=0; out.windBeams=0; out.windTrails=0; out.windAttachments=0
  out.windTopChildren={}
  for _,c in ipairs(wasset:GetChildren()) do table.insert(out.windTopChildren,{name=c.Name,class=c.ClassName}) end
  for _,d in ipairs(wasset:GetDescendants()) do
    if d:IsA("Model") then out.windModels+=1 end
    if d:IsA("BasePart") then out.windParts+=1 end
    if d:IsA("ParticleEmitter") then out.windParticles+=1 end
    if d:IsA("Beam") then out.windBeams+=1 end
    if d:IsA("Trail") then out.windTrails+=1 end
    if d:IsA("Attachment") then out.windAttachments+=1 end
  end
  wasset:Destroy()
end

local path=workspace:FindFirstChild("StonePath")
out.currentStonePathChildren=path and #path:GetChildren() or 0
local wind=workspace:FindFirstChild("WindEffects")
out.currentWindChildren=wind and #wind:GetChildren() or 0
out.currentGlobalWind={workspace.GlobalWind.X,workspace.GlobalWind.Y,workspace.GlobalWind.Z}
return out
`);
console.log(JSON.stringify(result,null,2));
