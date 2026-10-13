assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==85,"New city was not saved as version 85")
assert(workspace.IlhaSerena:GetAttribute("UpgradeVersion")==85)
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local v=require(m)()m:Destroy()return v end
local tests=run([============[local world=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime local Collection=game:GetService("CollectionService")
assert(world:GetAttribute("MapAssetId")==115377891476033 and world:GetAttribute("ThemeAssetId")==128071741625902)
assert(not world.Islands:FindFirstChild("IlhaDoFarol")and not world:FindFirstChild("TrilhasEMirante")and not world:GetAttribute("SecretSpawnCF"),"Old archipelago remains")
local parts,theme,seats,foreign,green=0,0,0,0,0
for _,p in ipairs(world:GetDescendants())do
 if p:IsA("BasePart")then parts+=1 if not p:IsDescendantOf(world.Viajante)then assert(p.Anchored,"Loose city geometry")end
  if p:GetAttribute("SerenaStudThemed")then theme+=1 assert(p.MaterialVariant=="SerenaStud_Studs")end
  if p:IsA("Seat")or p:IsA("VehicleSeat")then seats+=1 end if p:GetAttribute("SerenaGrassSurface")then green+=1 end
 elseif p:IsA("LuaSourceContainer")then foreign+=1 end
end
assert(parts>7000 and theme>5000 and seats>200 and foreign==0 and green>20,"City/template imports incomplete")
assert(game.MaterialService.SerenaStud_Studs and game.MaterialService.SerenaStud_StudsSmall)
assert(game.Lighting.LightingStyle==Enum.LightingStyle.Realistic and game.Lighting.PrioritizeLightingQuality and game.Lighting.GlobalShadows)
assert(game.Lighting.SerenaStudSky and game.Lighting.SerenaColor.Enabled and game.Lighting.SerenaBloom.Enabled and game.Lighting.SerenaSunRays.Enabled)
local Field=require(runtime.GrassField)local field=Field.new(runtime.GrassCoverage)
assert(field.spacing==4 and runtime.GrassCoverage:GetAttribute("SourceAssetId")==87377915371959)
local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={world.Islands,world.Props,workspace.Terrain}params.RespectCanCollide=true
local function hit(x,z)return workspace:Raycast(Vector3.new(x,450,z),Vector3.new(0,-700,0),params)end
local spawn=world:GetAttribute("MainSpawnCF")local floor=assert(hit(spawn.X,spawn.Z))
assert(floor.Material~=Enum.Material.Water and math.abs(spawn.Y-floor.Position.Y-3.3)<.06,"City spawn blocked or submerged")
local min,max=world:GetAttribute("CityBoundsMin"),world:GetAttribute("CityBoundsMax")local greenSamples=0 local gaps=0
for x=math.floor(min.X/16)*16,max.X,16 do
 for z=math.floor(min.Z/16)*16,max.Z,16 do
  local h=hit(x,z)
  if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Normal.Y>.2 then
   greenSamples+=1 local ix,iz=math.floor((x-field.minimum)/4+.5),math.floor((z-field.minimum)/4+.5)
   if not field:get(ix,iz)then gaps+=1 end
  end
 end
 if math.floor(x)%256==0 then task.wait()end
end
assert(greenSamples>1000 and gaps==0,"Grass index leaves green city areas uncovered")
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template:FindFirstChildOfClass("MeshPart")local bones={}local offsets={}
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
assert(#bones==100)for i,b in ipairs(bones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local sampler=require(runtime.GrassSampler).new(world)local tested=0 local validRoots=0 local rejectedRoadCells=0
for _,point in ipairs({Vector3.new(0,0,0),Vector3.new(-430,0,330),Vector3.new(500,0,450),Vector3.new(-1200,0,900)})do
 local candidates=field:around(point,40)local localCount=0
 for _,cell in ipairs(candidates)do
  local heights,anchor,valid=sampler:sample(cell,offsets)
  if anchor then
   tested+=1 localCount+=1 validRoots+=valid
   for i,y in pairs(heights)do local h=hit(cell.center.X+offsets[i].X,cell.center.Z+offsets[i].Z)
    assert(h and h.Instance:GetAttribute("SerenaGrassSurface")and math.abs(h.Position.Y-y)<.001,"Grass root floats or grows on road")
   end
  else rejectedRoadCells+=1 end
  if localCount>=8 then break end
 end
end
assert(tested>=12 and validRoots>800,"Dense grass roots unavailable around city")
local Tags=require(runtime.NametagCore)local tag=game.ReplicatedStorage.SerenaTemplates.SerenaNametagTemplate:Clone()
assert(tag:GetAttribute("SourceAssetId")==92018365421220 and not tag.AlwaysOnTop and tag.MaxDistance==65)
Tags.decorate(tag,{displayName="João",userId=1,plus=false,verified=false})
assert(tag.Username.Text=="João"and not tag.Title.Visible and not tag.Username.RichText)
Tags.decorate(tag,{displayName="ch_ckz2n",userId=8344738123,plus=false,verified=false})
assert(tag.Title.Text=="Dono"and tag.Title.Visible and not tag.Username.Text:find("",1,true),"Fake verified badge")tag:Destroy()
assert(world:GetAttribute("WindAnimationScale")==.9)
local Skinned=require(runtime.SkinnedGrass)local grass=Skinned.new({WindStrengthScale=.9})assert(grass.Settings.WindStrengthScale==.9)grass:Destroy()
assert(runtime.SkinnedGrass.Source:find("settingsTable.WindStrengthScale or 1",1,true))
local Admin=require(runtime.AdminCore)assert(Admin.allowed({UserId=8344738123})and not Admin.allowed({UserId=1}))
assert(not game.ServerScriptService:FindFirstChild("SerenaBridgeServer")and not game.ServerScriptService:FindFirstChild("SerenaBoatServer"))
assert(not game.StarterPlayer.StarterPlayerScripts.SerenaTraderClient.Source:find('id="Secret"',1,true))
local doors=0 for _,m in ipairs(Collection:GetTagged("SerenaCityDoor"))do if m:IsDescendantOf(world)then
 doors+=1 assert(m:GetAttribute("DoorClosed")and m:GetAttribute("DoorOpen")and m:FindFirstChild("CityDoorPrompt",true))
end end assert(doors>10)
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
return{parts=parts,themedParts=theme,seats=seats,foreignScripts=foreign,greenSurfaces=green,greenSamples=greenSamples,indexGaps=gaps,
 realGrassSampledCells=tested,validSampledRoots=validRoots,roadOrRoofCellsRejected=rejectedRoadCells,nametags=true,
 windStrengthScale=.9,ownerOnlyAdmin=true,cityDoors=doors,compiledScripts=compiled,realisticRendering=true,safeSpawn=true}
]============])
return {ok=true,version=game.PlaceVersion,upgrade=workspace.IlhaSerena:GetAttribute("UpgradeVersion"),map=workspace.IlhaSerena:GetAttribute("MapAssetId"),theme=workspace.IlhaSerena:GetAttribute("ThemeAssetId"),nametags=workspace.IlhaSerena:GetAttribute("NametagAssetId"),tests=tests,lighting=tostring(game.Lighting.LightingStyle)}