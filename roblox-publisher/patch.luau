assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155 and game.PlaceVersion == 87, "Unexpected forest version")
local Asset = game:GetService("AssetService")
local Marketplace = game:GetService("MarketplaceService")
local function vector(v) return {v.X, v.Y, v.Z} end
local function inspect(d)
 local r = {name=d.Name,class=d.ClassName,path=d:GetFullName()}
 if d:IsA("Model") then local cf,s=d:GetBoundingBox() r.pivot={d:GetPivot():GetComponents()} r.position=vector(cf.Position) r.size=vector(s) end
 if d:IsA("BasePart") then r.cf={d.CFrame:GetComponents()} r.size=vector(d.Size) r.material=d.Material.Name r.color={d.Color.R,d.Color.G,d.Color.B} r.collide=d.CanCollide end
 if d:IsA("MeshPart") then r.meshId=d.MeshId r.textureId=d.TextureID end
 if d:IsA("LuaSourceContainer") then r.source=d.Source end
 if d:IsA("Sound") then r.soundId=d.SoundId r.volume=d.Volume end
 for _,key in ipairs(d:IsA("Lighting") and {"ClockTime","Brightness","ExposureCompensation","Ambient","OutdoorAmbient"} or d:IsA("ColorCorrectionEffect") and {"Brightness","Contrast","Saturation","TintColor"} or d:IsA("BloomEffect") and {"Intensity","Size","Threshold"} or d:IsA("SunRaysEffect") and {"Intensity","Spread"} or d:IsA("DepthOfFieldEffect") and {"FarIntensity","NearIntensity","FocusDistance","InFocusRadius"} or d:IsA("Sky") and {"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"} or d:IsA("Atmosphere") and {"Density","Offset","Haze","Glare","Color","Decay"} or {}) do
  local ok,v=pcall(function() return d[key] end) if ok then r[key]=typeof(v)=="Color3" and {v.R,v.G,v.B} or v end
 end
 return r
end
local output={readOnly=true,version=game.PlaceVersion,assets={}}
for _,id in ipairs({3070634312,8490242417,13478419902,1352279393,13557849262,12974780941}) do
 local ok,raw=pcall(function() return Asset:LoadAssetAsync(id) end)
 if ok then
  local info={root=inspect(raw),items={},classes={}}
  for _,d in ipairs(raw:GetDescendants()) do
   info.classes[d.ClassName]=(info.classes[d.ClassName] or 0)+1
   if d:IsA("LuaSourceContainer") or d:IsA("Model") or d:IsA("BasePart") or d:IsA("PostEffect") or d:IsA("Sky") or d:IsA("Atmosphere") or d:IsA("Sound") then info.items[#info.items+1]=inspect(d) end
  end
  output.assets[tostring(id)]=info raw:Destroy()
 else output.assets[tostring(id)]={error=tostring(raw)} end
end
local audioOk,audio=pcall(function() return Marketplace:GetProductInfoAsync(9059051593,Enum.InfoType.Asset) end)
output.audio=audioOk and {id=9059051593,name=audio.Name,type=audio.AssetTypeId,creator=audio.Creator.Name,description=audio.Description} or {error=tostring(audio)}
local ownerId=game.Players:GetUserIdFromNameAsync("ch_ckz2n") assert(ownerId==8344738123,"Owner mismatch")
local description=game.Players:GetHumanoidDescriptionFromUserIdAsync(ownerId)
local rig=game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
local parts,motors={},{}
for _,d in ipairs(rig:GetDescendants()) do if d:IsA("Motor6D") then motors[#motors+1]={name=d.Name,c0={d.C0:GetComponents()},c1={d.C1:GetComponents()}} elseif d:IsA("BasePart") then parts[#parts+1]=inspect(d) end end
output.owner={id=ownerId,shirt=description.Shirt,pants=description.Pants,face=description.Face,parts=parts,motors=motors}
rig:Destroy() description:Destroy()
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
output.floors={}
for _,folder in ipairs({workspace.ForestWorld.Decor.Trees,workspace.ForestWorld.Decor.Plants}) do
 local checked,maxLift,maxSlope=0,0,0 local examples={}
 for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") then
  local p=m:GetPivot().Position
  local h=workspace:Raycast(Vector3.new(p.X,210,p.Z),Vector3.new(0,-310,0),ray)
  if h then
   checked+=1 maxLift=math.max(maxLift,p.Y-h.Position.Y)
   local lo,hi=math.huge,-math.huge
   for _,off in ipairs({Vector3.new(-2,0,0),Vector3.new(2,0,0),Vector3.new(0,0,-2),Vector3.new(0,0,2)}) do local s=workspace:Raycast(Vector3.new(p.X+off.X,210,p.Z+off.Z),Vector3.new(0,-310,0),ray) if s then lo=math.min(lo,s.Position.Y) hi=math.max(hi,s.Position.Y) end end
   maxSlope=math.max(maxSlope,hi-lo)
   if #examples<10 then local a=inspect(m) a.floor=vector(h.Position) a.normal=vector(h.Normal) a.parts={} for _,d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and d.Name~="TrunkCollision" then a.parts[#a.parts+1]=inspect(d) end end examples[#examples+1]=a end
  end
 end end
 output.floors[folder.Name]={checked=checked,maxPivotLift=maxLift,maxFootVariation=maxSlope,examples=examples}
end
local card=game.ReplicatedStorage.ForestRuntime.SkinnedGrassTemplates.GrassCard
output.grass=inspect(card) output.grass.bones={}
for _,d in ipairs(card:GetDescendants()) do if d:IsA("Bone") and #output.grass.bones<15 then output.grass.bones[#output.grass.bones+1]={name=d.Name,cf={d.CFrame:GetComponents()},world=vector(d.WorldPosition)} end end
return output
