// recheck universe display name
// trigger mirkwood inspection
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
  out.windControllerSource=nil
  for _,c in ipairs(wasset:GetChildren()) do
    table.insert(out.windTopChildren,{name=c.Name,class=c.ClassName})
    if c:IsA("LocalScript") and c.Name=="WindController" then
      out.windControllerSource=c.Source
    end
  end
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

local tok,tasset=pcall(function() return A:LoadAssetAsync(9626366517) end)
out.treeLoaded=tok and tasset~=nil
out.treeParts={}
if tok and tasset then
  local tree=tasset:FindFirstChildWhichIsA("Model",true)
  out.treeModelName=tree and tree.Name or nil
  if tree then
    local n=0
    for _,d in ipairs(tree:GetDescendants()) do
      if d:IsA("BasePart") then
        n+=1
        if #out.treeParts<40 then
          table.insert(out.treeParts,{
            name=d.Name,class=d.ClassName,
            material=tostring(d.Material),
            color={d.Color.R,d.Color.G,d.Color.B},
            size={d.Size.X,d.Size.Y,d.Size.Z}
          })
        end
      end
    end
    out.treePartCount=n
  end
  tasset:Destroy()
end

out.treeGroundOffsets={}
local treeFolder=workspace:FindFirstChild("SakuraTrees")
if treeFolder then
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={treeFolder,workspace:FindFirstChild("StonePath"),workspace:FindFirstChild("Wildflowers")}
  for i,tree in ipairs(treeFolder:GetChildren()) do
    if i>27 then break end
    local trunk=nil
    for _,d in ipairs(tree:GetDescendants()) do
      if d:IsA("BasePart") and d.Name~="Leaves" then trunk=d break end
    end
    if trunk then
      local minY=math.huge
      for _,sx in ipairs({-1,1}) do
        for _,sy in ipairs({-1,1}) do
          for _,sz in ipairs({-1,1}) do
            local world=trunk.CFrame:PointToWorldSpace(Vector3.new(trunk.Size.X*.5*sx,trunk.Size.Y*.5*sy,trunk.Size.Z*.5*sz))
            minY=math.min(minY,world.Y)
          end
        end
      end
      local ray=workspace:Raycast(Vector3.new(trunk.Position.X,80,trunk.Position.Z),Vector3.new(0,-150,0),params)
      table.insert(out.treeGroundOffsets,{
        name=tree.Name,
        trunk=trunk.Name,
        trunkBottom=minY,
        groundY=ray and ray.Position.Y or nil,
        offset=ray and (minY-ray.Position.Y) or nil
      })
    end
  end
end

local pok,passet=pcall(function() return A:LoadAssetAsync(3671107938) end)
out.petalsLoaded=pok and passet~=nil
out.petalEmitters={}
if pok and passet then
  for _,d in ipairs(passet:GetDescendants()) do
    if d:IsA("ParticleEmitter") then
      table.insert(out.petalEmitters,{
        name=d.Name,
        texture=d.Texture,
        rate=d.Rate,
        lifetime={d.Lifetime.Min,d.Lifetime.Max},
        speed={d.Speed.Min,d.Speed.Max},
        drag=d.Drag,
        windAffectsDrag=d.WindAffectsDrag,
        acceleration={d.Acceleration.X,d.Acceleration.Y,d.Acceleration.Z}
      })
    end
  end
  out.petalScriptCount=0
  for _,d in ipairs(passet:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then out.petalScriptCount+=1 end
  end
  passet:Destroy()
end


local pok2,passet2=pcall(function() return A:LoadAssetAsync(125247029116844) end)
out.petals2Loaded=pok2 and passet2~=nil
out.petal2Emitters={}
if pok2 and passet2 then
  for _,d in ipairs(passet2:GetDescendants()) do
    if d:IsA("ParticleEmitter") then
      table.insert(out.petal2Emitters,{
        name=d.Name,
        texture=d.Texture,
        rate=d.Rate,
        lifetime={d.Lifetime.Min,d.Lifetime.Max},
        speed={d.Speed.Min,d.Speed.Max},
        drag=d.Drag,
        windAffectsDrag=d.WindAffectsDrag,
        acceleration={d.Acceleration.X,d.Acceleration.Y,d.Acceleration.Z}
      })
    end
  end
  out.petal2ScriptCount=0
  for _,d in ipairs(passet2:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then out.petal2ScriptCount+=1 end
  end
  passet2:Destroy()
end


local savedPath=workspace:FindFirstChild("StonePath")
out.savedPathSegments=0
out.savedPathParts=0
out.savedVisiblePathParts=0
out.savedPathAssetId=savedPath and savedPath:GetAttribute("AssetId") or nil
out.savedUsesGroundPatches=savedPath and savedPath:GetAttribute("UsesGroundPatches") or nil
if savedPath then
  for _,seg in ipairs(savedPath:GetChildren()) do
    if seg:IsA("Model") and string.find(seg.Name,"Stone Path (Long)",1,true) then
      out.savedPathSegments+=1
      for _,d in ipairs(seg:GetDescendants()) do
        if d:IsA("BasePart") then
          out.savedPathParts+=1
          if d.Transparency<.95 then out.savedVisiblePathParts+=1 end
        end
      end
    end
  end
end

local scripts=game.StarterPlayer.StarterPlayerScripts
local savedWind=scripts:FindFirstChild("WindController")
out.savedWindController=savedWind~=nil
out.savedWindAssetId=savedWind and savedWind:GetAttribute("AssetId") or nil
out.savedWindExact=savedWind and savedWind:GetAttribute("ExactCreatorStoreController") or nil
out.savedWindLines=savedWind and savedWind:FindFirstChild("WindLines")~=nil or false
out.savedWindShake=savedWind and savedWind:FindFirstChild("WindShake")~=nil or false
out.savedWindDisabled=savedWind and savedWind.Disabled or nil
out.savedGlobalWind={workspace.GlobalWind.X,workspace.GlobalWind.Y,workspace.GlobalWind.Z}


local function inspectAsset(id)
  local result={id=id,loaded=false,top={},classes={},scripts={}}
  local ok,asset=pcall(function() return A:LoadAssetAsync(id) end)
  if not ok or not asset then
    result.error=tostring(asset)
    return result
  end
  result.loaded=true
  for _,child in ipairs(asset:GetChildren()) do
    table.insert(result.top,{name=child.Name,class=child.ClassName})
  end
  for _,d in ipairs(asset:GetDescendants()) do
    result.classes[d.ClassName]=(result.classes[d.ClassName] or 0)+1
    if d:IsA("LuaSourceContainer") and #result.scripts<12 then
      table.insert(result.scripts,{name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""})
    end
  end
  asset:Destroy()
  return result
end

out.nametagAsset=inspectAsset(123212555736117)
out.loadingAsset=inspectAsset(73186563008540)

out.spawnObjects={}
for _,d in ipairs(workspace:GetDescendants()) do
  if d:IsA("SpawnLocation") then
    table.insert(out.spawnObjects,{
      name=d.Name,
      position={d.Position.X,d.Position.Y,d.Position.Z},
      transparency=d.Transparency,
      enabled=d.Enabled
    })
  end
end


local function scriptSources(id)
  local result={id=id,loaded=false,scripts={}}
  local ok,asset=pcall(function() return A:LoadAssetAsync(id) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then
      table.insert(result.scripts,{
        name=d.Name,
        class=d.ClassName,
        parent=d.Parent and d.Parent.Name or "",
        source=d.Source
      })
    end
  end
  asset:Destroy()
  return result
end
out.nametagSources=scriptSources(123212555736117)
out.loadingSources=scriptSources(73186563008540)


local function inspectDeep(id)
  local result={id=id,loaded=false,top={},models={},parts={},scripts={}}
  local ok,asset=pcall(function() return A:LoadAssetAsync(id) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  for _,child in ipairs(asset:GetChildren()) do
    table.insert(result.top,{name=child.Name,class=child.ClassName})
  end
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("Model") and #result.models<60 then
      local okb,cf,size=pcall(function() return d:GetBoundingBox() end)
      table.insert(result.models,{
        name=d.Name,
        parent=d.Parent and d.Parent.Name or "",
        parts=(function()
          local n=0
          for _,x in ipairs(d:GetDescendants()) do if x:IsA("BasePart") then n+=1 end end
          return n
        end)(),
        size=okb and {size.X,size.Y,size.Z} or nil
      })
    elseif d:IsA("BasePart") and #result.parts<120 then
      table.insert(result.parts,{
        name=d.Name,
        class=d.ClassName,
        parent=d.Parent and d.Parent.Name or "",
        material=tostring(d.Material),
        color={d.Color.R,d.Color.G,d.Color.B},
        size={d.Size.X,d.Size.Y,d.Size.Z},
        transparency=d.Transparency
      })
    elseif d:IsA("LuaSourceContainer") and #result.scripts<20 then
      table.insert(result.scripts,{name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""})
    end
  end
  result.totalModels=0
  result.totalParts=0
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("Model") then result.totalModels+=1 end
    if d:IsA("BasePart") then result.totalParts+=1 end
  end
  asset:Destroy()
  return result
end

out.pristinePark=inspectDeep(13366955960)
out.eerieTomb=inspectDeep(12489961338)


local function summarizeNamed(id)
  local result={id=id,loaded=false,matches={}}
  local ok,asset=pcall(function() return A:LoadAssetAsync(id) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  local keys={"tree","rock","stone","pumpkin","tomb","grave","skull","head","grass","path","bench","fountain","car","shop","bush","plant","flower"}
  for _,d in ipairs(asset:GetDescendants()) do
    local name=d.Name:lower()
    for _,k in ipairs(keys) do
      if string.find(name,k,1,true) then
        result.matches[k]=result.matches[k] or {}
        if #result.matches[k] < 80 then
          local entry={name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""}
          if d:IsA("Model") then
            local okb,cf,size=pcall(function() return d:GetBoundingBox() end)
            entry.parts=0
            for _,x in ipairs(d:GetDescendants()) do if x:IsA("BasePart") then entry.parts+=1 end end
            if okb then entry.size={size.X,size.Y,size.Z} end
          elseif d:IsA("BasePart") then
            entry.size={d.Size.X,d.Size.Y,d.Size.Z}
            entry.material=tostring(d.Material)
          end
          table.insert(result.matches[k],entry)
        end
        break
      end
    end
  end
  asset:Destroy()
  return result
end
out.pristineNamed=summarizeNamed(13366955960)
out.eerieNamed=summarizeNamed(12489961338)


local function auditParkTreeCandidates()
  local result={loaded=false,candidates={},totalParts=0,candidateParts=0}
  local ok,asset=pcall(function() return A:LoadAssetAsync(13366955960) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  local park=asset:FindFirstChild("Park",true)
  if not park then asset:Destroy() return result end
  for _,d in ipairs(park:GetDescendants()) do if d:IsA("BasePart") then result.totalParts+=1 end end

  local function greenish(c)
    return c.G>c.R*.9 and c.G>c.B*.75 and c.G>.22
  end
  local function validBounds(model)
    local okb,cf,size=pcall(function() return model:GetBoundingBox() end)
    if not okb or not size or size.X<=0 or size.Y<=0 or size.Z<=0 then return nil end
    return cf,size
  end
  local function treeLikeModel(m)
    local name=m.Name:lower()
    if name:find("streetlight",1,true) or name:find("light",1,true)
      or name:find("shop",1,true) or name:find("fountain",1,true)
      or name:find("bench",1,true) or name:find("car",1,true)
      or name:find("basket",1,true) or name:find("blender",1,true) then
      return false
    end
    local partCount=0
    local wood,foliage=false,false
    for _,x in ipairs(m:GetDescendants()) do
      if x:IsA("BasePart") then
        partCount+=1
        local n=x.Name:lower()
        if x.Material==Enum.Material.Wood or x.Material==Enum.Material.WoodPlanks or n:find("trunk",1,true) then wood=true end
        if n:find("leaf",1,true) or n:find("foliage",1,true)
          or (greenish(x.Color) and (x.Material==Enum.Material.Grass or x.Material==Enum.Material.Fabric or x:IsA("MeshPart"))) then
          foliage=true
        end
      end
    end
    local _,size=validBounds(m)
    if not size then return false,partCount end
    if name:find("tree",1,true) then
      return partCount<=40 and size.Y>8 and size.X<60 and size.Z<60,partCount,size
    end
    return wood and foliage and partCount<=24 and size.Y>10 and size.X<45 and size.Z<45,partCount,size
  end

  for _,m in ipairs(park:GetDescendants()) do
    if m:IsA("Model") then
      local yes,pc,size=treeLikeModel(m)
      if yes then
        table.insert(result.candidates,{
          name=m.Name,
          parent=m.Parent and m.Parent.Name or "",
          parts=pc,
          size=size and {size.X,size.Y,size.Z} or nil
        })
        result.candidateParts+=pc or 0
      end
    end
  end
  asset:Destroy()
  return result
end
out.parkTreeAudit=auditParkTreeCandidates()


local function auditParkGrassSurfaces()
  local result={loaded=false,grassParts={},total=0}
  local ok,asset=pcall(function() return A:LoadAssetAsync(13366955960) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  local park=asset:FindFirstChild("Park",true)
  if not park then asset:Destroy() return result end
  for _,d in ipairs(park:GetDescendants()) do
    if d:IsA("BasePart") and d.Material==Enum.Material.Grass then
      result.total+=1
      if #result.grassParts<160 then
        table.insert(result.grassParts,{
          name=d.Name,
          class=d.ClassName,
          parent=d.Parent and d.Parent.Name or "",
          size={d.Size.X,d.Size.Y,d.Size.Z},
          upY=d.CFrame.UpVector.Y,
          area=d.Size.X*d.Size.Z,
          color={d.Color.R,d.Color.G,d.Color.B}
        })
      end
    end
  end
  asset:Destroy()
  table.sort(result.grassParts,function(a,b) return a.area>b.area end)
  return result
end
out.parkGrassAudit=auditParkGrassSurfaces()


local function inspectMirkwood()
  local result={id=12489980589,loaded=false,top={},models={},materials={},colors={},scripts={},totalParts=0,totalModels=0}
  local ok,asset=pcall(function() return A:LoadAssetAsync(12489980589) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  for _,child in ipairs(asset:GetChildren()) do
    table.insert(result.top,{name=child.Name,class=child.ClassName})
  end
  local colorBuckets={}
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("Model") then
      result.totalModels+=1
      if #result.models<100 then
        local okb,cf,size=pcall(function() return d:GetBoundingBox() end)
        local parts=0
        for _,x in ipairs(d:GetDescendants()) do if x:IsA("BasePart") then parts+=1 end end
        table.insert(result.models,{
          name=d.Name,
          parent=d.Parent and d.Parent.Name or "",
          parts=parts,
          size=okb and {size.X,size.Y,size.Z} or nil
        })
      end
    elseif d:IsA("BasePart") then
      result.totalParts+=1
      local mat=tostring(d.Material)
      result.materials[mat]=(result.materials[mat] or 0)+1
      local r=math.floor(d.Color.R*5+.5)/5
      local g=math.floor(d.Color.G*5+.5)/5
      local b=math.floor(d.Color.B*5+.5)/5
      local key=string.format("%.1f,%.1f,%.1f",r,g,b)
      colorBuckets[key]=(colorBuckets[key] or 0)+1
    elseif d:IsA("LuaSourceContainer") and #result.scripts<20 then
      table.insert(result.scripts,{name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""})
    end
  end
  for key,n in pairs(colorBuckets) do
    table.insert(result.colors,{color=key,count=n})
  end
  table.sort(result.colors,function(a,b) return a.count>b.count end)
  while #result.colors>15 do table.remove(result.colors) end
  asset:Destroy()
  return result
end
out.mirkwood=inspectMirkwood()


local function inspectBigMap()
  local result={id=9435523981,loaded=false,top={},models={},materials={},scripts={},totalParts=0,totalModels=0}
  local ok,asset=pcall(function() return A:LoadAssetAsync(9435523981) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  for _,child in ipairs(asset:GetChildren()) do
    table.insert(result.top,{name=child.Name,class=child.ClassName})
  end
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("Model") then
      result.totalModels+=1
      if #result.models<80 then
        local okb,cf,size=pcall(function() return d:GetBoundingBox() end)
        local pc=0
        for _,x in ipairs(d:GetDescendants()) do if x:IsA("BasePart") then pc+=1 end end
        table.insert(result.models,{
          name=d.Name,
          parent=d.Parent and d.Parent.Name or "",
          parts=pc,
          size=okb and {size.X,size.Y,size.Z} or nil
        })
      end
    elseif d:IsA("BasePart") then
      result.totalParts+=1
      local mat=tostring(d.Material)
      result.materials[mat]=(result.materials[mat] or 0)+1
    elseif d:IsA("LuaSourceContainer") and #result.scripts<30 then
      table.insert(result.scripts,{name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""})
    end
  end
  asset:Destroy()
  return result
end
out.bigMap=inspectBigMap()


local function inspectBrookhavenMap()
  local result={id=106476929993683,loaded=false,top={},models={},materials={},scripts={},totalParts=0,totalModels=0}
  local ok,asset=pcall(function() return A:LoadAssetAsync(106476929993683) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  for _,child in ipairs(asset:GetChildren()) do
    table.insert(result.top,{name=child.Name,class=child.ClassName})
  end
  for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("Model") then
      result.totalModels+=1
      if #result.models<100 then
        local okb,cf,size=pcall(function() return d:GetBoundingBox() end)
        local pc=0
        for _,x in ipairs(d:GetDescendants()) do if x:IsA("BasePart") then pc+=1 end end
        table.insert(result.models,{
          name=d.Name,
          parent=d.Parent and d.Parent.Name or "",
          parts=pc,
          size=okb and {size.X,size.Y,size.Z} or nil
        })
      end
    elseif d:IsA("BasePart") then
      result.totalParts+=1
      local mat=tostring(d.Material)
      result.materials[mat]=(result.materials[mat] or 0)+1
    elseif d:IsA("LuaSourceContainer") and #result.scripts<40 then
      table.insert(result.scripts,{name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""})
    end
  end
  asset:Destroy()
  return result
end
out.brookhavenMap=inspectBrookhavenMap()


local function auditBrookhavenLayout()
  local result={id=106476929993683,loaded=false,greenCandidates={},named={},scriptCount=0}
  local ok,asset=pcall(function() return A:LoadAssetAsync(106476929993683) end)
  if not ok or not asset then result.error=tostring(asset) return result end
  result.loaded=true
  local map=asset:FindFirstChild("Brookhaven Map",true)
  if not map then asset:Destroy() return result end

  local keys={"house","home","plot","lot","estate","hill","mountain","grass","lawn","park","road","street","sidewalk","tree","bush","plant","spawn"}
  for _,d in ipairs(map:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then
      result.scriptCount+=1
    elseif d:IsA("BasePart") then
      local c=d.Color
      local green=(c.G>c.R*1.12 and c.G>c.B*1.05 and c.G>.18)
      local horizontal=d.CFrame.UpVector.Y>.82
      local area=d.Size.X*d.Size.Z
      if green and horizontal and area>80 and #result.greenCandidates<120 then
        table.insert(result.greenCandidates,{
          name=d.Name,
          parent=d.Parent and d.Parent.Name or "",
          size={d.Size.X,d.Size.Y,d.Size.Z},
          area=area,
          color={c.R,c.G,c.B},
          material=tostring(d.Material),
          pos={d.Position.X,d.Position.Y,d.Position.Z}
        })
      end
    end

    local lname=d.Name:lower()
    for _,k in ipairs(keys) do
      if string.find(lname,k,1,true) then
        result.named[k]=result.named[k] or {}
        if #result.named[k]<80 then
          local e={name=d.Name,class=d.ClassName,parent=d.Parent and d.Parent.Name or ""}
          if d:IsA("BasePart") then
            e.size={d.Size.X,d.Size.Y,d.Size.Z}
            e.pos={d.Position.X,d.Position.Y,d.Position.Z}
            e.color={d.Color.R,d.Color.G,d.Color.B}
            e.material=tostring(d.Material)
          elseif d:IsA("Model") then
            local okb,cf,size=pcall(function() return d:GetBoundingBox() end)
            local pc=0
            for _,x in ipairs(d:GetDescendants()) do if x:IsA("BasePart") then pc+=1 end end
            e.parts=pc
            if okb then
              e.size={size.X,size.Y,size.Z}
              e.pos={cf.Position.X,cf.Position.Y,cf.Position.Z}
            end
          end
          table.insert(result.named[k],e)
        end
        break
      end
    end
  end
  table.sort(result.greenCandidates,function(a,b) return a.area>b.area end)
  asset:Destroy()
  return result
end
out.brookhavenLayout=auditBrookhavenLayout()


local function inspectBrookhavenEntrances()
 local r={id=106476929993683,loaded=false,spawns={},named={},largeGround={},houseMarkers={}}
 local ok,asset=pcall(function() return A:LoadAssetAsync(106476929993683) end)
 if not ok or not asset then r.error=tostring(asset) return r end
 r.loaded=true
 local root=asset:FindFirstChild("Brookhaven Map",true)
 if not root then asset:Destroy(); r.error="Brookhaven Map missing"; return r end
 for _,d in ipairs(root:GetDescendants()) do
  if d:IsA("SpawnLocation") then
   table.insert(r.spawns,{name=d.Name,parent=d.Parent and d.Parent.Name or "",pos={d.Position.X,d.Position.Y,d.Position.Z},size={d.Size.X,d.Size.Y,d.Size.Z}})
  end
  if d:IsA("BasePart") then
   local n=d.Name:lower()
   if n:find("spawn",1,true) or n:find("start",1,true) or n:find("lobby",1,true) or n:find("road",1,true) or n:find("street",1,true) or n:find("sidewalk",1,true) then
    if #r.named<160 then table.insert(r.named,{name=d.Name,parent=d.Parent and d.Parent.Name or "",class=d.ClassName,pos={d.Position.X,d.Position.Y,d.Position.Z},size={d.Size.X,d.Size.Y,d.Size.Z},color={d.Color.R,d.Color.G,d.Color.B},material=tostring(d.Material)}) end
   end
   if d.CFrame.UpVector.Y>.96 and d.Size.X*d.Size.Z>12000 and #r.largeGround<100 then
    table.insert(r.largeGround,{name=d.Name,parent=d.Parent and d.Parent.Name or "",pos={d.Position.X,d.Position.Y,d.Position.Z},size={d.Size.X,d.Size.Y,d.Size.Z},color={d.Color.R,d.Color.G,d.Color.B},material=tostring(d.Material)})
   end
   if d.Name:match("^House%d+$") and #r.houseMarkers<40 then table.insert(r.houseMarkers,{name=d.Name,pos={d.Position.X,d.Position.Y,d.Position.Z}}) end
  end
 end
 asset:Destroy()
 return r
end
out.brookhavenEntrances=inspectBrookhavenEntrances()

return out
`);
console.log(JSON.stringify(result,null,2));
try{
  const universeMeta=await req('universes/9419478735');
  console.log(JSON.stringify({universeMeta},null,2));
}catch(e){
  console.log(JSON.stringify({universeMetaError:String(e)}));
}
