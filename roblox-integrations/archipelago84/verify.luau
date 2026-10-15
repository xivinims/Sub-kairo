assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==84,"Expected published version 84")
local world=workspace:WaitForChild("IlhaSerena")local RS=game.ReplicatedStorage local runtime=RS.SerenaRuntime
assert(world:GetAttribute("UpgradeVersion")==84 and world:GetAttribute("WorldLayout")=="ThreeCreatorIslands")
assert(world:GetAttribute("PublicIslandCount")==2 and #world.Islands:GetChildren()==3)
local wanted={IlhaDoFarol=13138901447,IlhaVerde=8143419396,IlhaDoSol=139196111}local assets={}
for name,id in pairs(wanted)do local island=world.Islands:FindFirstChild(name)assert(island and island:GetAttribute("SourceAssetId")==id)
 assert(island:GetAttribute("ShoreAlignedY")==.4)assets[#assets+1]={name=name,id=id,hidden=island:GetAttribute("HiddenIsland")}
end
assert(not world:FindFirstChild("VilaCosteira")and not world:FindFirstChild("Bosque"))
local parts,foreign,seats,benches=0,0,0,0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then parts+=1 if p:IsA("Seat")then seats+=1 end
 if not p:IsDescendantOf(world.Viajante)then assert(p.Anchored,"Loose scenery")end
 elseif p:IsA("LuaSourceContainer")then foreign+=1 end
end
for _,p in ipairs(world.Props:GetChildren())do if p:GetAttribute("SourceAssetId")==741384218 then benches+=1 end end
assert(foreign==0 and parts==6130 and benches==6 and seats>=12)
assert(world.Viajante:GetAttribute("SourceAssetId")==80608769509945 and world.Viajante.ViajanteClick.MaxActivationDistance==12)
assert(world.Viajante.Humanoid.RigType==Enum.HumanoidRigType.R6)
local secret=world:GetAttribute("SecretSpawnCF")assert((secret.Position-world:GetAttribute("MainSpawnCF").Position).Magnitude>1700)
local bridge=world.TrilhasEMirante.PonteDePedra assert(bridge:GetAttribute("AllStone")and bridge:GetAttribute("BridgeActivation")=="StandingOnMysticalStone")
local floors,visuals,guards=0,0,0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")then
 assert(p.Material==Enum.Material.Limestone and not p.CanCollide and p.Transparency==1,"Bridge saved in wrong initial state")
 if p:GetAttribute("BridgeCollider")then if p:GetAttribute("BridgeGuard")then guards+=1 else floors+=1 end else visuals+=1 assert(p:GetAttribute("BridgeRestCF")and p:GetAttribute("BridgeRevealAt"))end
end end assert(floors==102 and guards==204 and visuals>250)
for _,name in ipairs({"PedraMistica1","PedraMistica2"})do local pad=world.Props[name]assert(pad:GetAttribute("SourceAssetId")==110144096035671 and pad:GetAttribute("BridgeActivator"))end
local coverage=runtime.GrassCoverage assert(coverage:GetAttribute("PatchCount")==969 and coverage:GetAttribute("RootCount")==79892 and coverage:GetAttribute("Spacing")==4)
assert(coverage:GetAttribute("SourceAssetId")==87377915371959 and #coverage:GetChildren()==8)
assert(coverage:GetAttribute("NearRadiusTouch")==48 and coverage:GetAttribute("MaxActiveTouch")==640)
local color=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)local mesh=runtime.SkinnedGrassTemplates.GrassCard:FindFirstChildOfClass("MeshPart")assert((Vector3.new(mesh.Color.R,mesh.Color.G,mesh.Color.B)-Vector3.new(color.R,color.G,color.B)).Magnitude<.01)
local Admin=require(runtime.AdminCore)assert(Admin.UserId==8344738123 and world:GetAttribute("AdminUserId")==8344738123)
assert(Admin.allowed({UserId=8344738123})and not Admin.allowed({UserId=1}))
assert(RS.SerenaTemplates.SerenaAdminTemplate:GetAttribute("SourceAssetId")==111176085924966)
assert(game.StarterPlayer.StarterPlayerScripts.SerenaAdminChat.Source:find("message.TextSource.UserId==AdminId",1,true))
assert(game.StarterPlayer.StarterPlayerScripts.SerenaAdminClient.Source:find("channel:SendAsync(text)",1,true))
local Rules=require(runtime.ItemRules)assert(Rules.Price==30 and Rules.RodPrice==20 and Rules.Duration==3 and Rules.Cooldown==60)
local rod=game.ServerStorage.SerenaItems["Vara de Pesca"]assert(rod:GetAttribute("SourceAssetId")==11316383656 and not rod.Handle.Anchored and not rod.Handle.CanCollide)
local fishClient=game.StarterPlayer.StarterPlayerScripts.SerenaFishingClient.Source
assert(fishClient:find('world:GetAttribute("TraderPosition")',1,true)and not fishClient:find("grátis",1,true))
assert(game.ServerScriptService.SerenaBoatServer.Source:find("workspace.Terrain,world.Islands",1,true)and not game.ServerScriptService.SerenaBoatServer.Source:find("Vector3.new(100",1,true))
local Personal=require(runtime.PersonalClimate)local hours={Dia=12,Noite=23,Anoitecer=18.3,Chuva=15.2}
for mode,hour in pairs(hours)do local h,wet,clear,selected=Personal.resolve(mode)assert(math.abs(h-hour)<.01 and selected==mode)
 local p=require(runtime.Climate).profile(h,wet,clear,0)assert(p.wind.Magnitude>.1)
end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
 for line in s.Source:gmatch("[^\n]+")do assert(not line:find("VilaCosteira",1,true)and not line:find("Bosque",1,true),"Runtime still waits for old island")end
end end end assert(compiled==20)
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local v=require(m)()m:Destroy()return v end
local navigation=run([========[local world=workspace.IlhaSerena
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={world.Islands,workspace.Terrain}ray.RespectCanCollide=true
local function ground(point)return workspace:Raycast(Vector3.new(point.X,180,point.Z),Vector3.new(0,-260,0),ray)end
local deck=world.PraiaEPier.PierDeMadeira.Deck
local below=ground(deck.Position)
local boat=world.PraiaEPier.BarcoDePesca local water=ground(boat:GetPivot().Position)
assert(water and water.Material==Enum.Material.Water,"Boat starts under land")
assert(below and below.Position.Y<deck.Position.Y-deck.Size.Y/2,"Pier buried")
local bp=world.PraiaEPier.PierDeMadeira.Embarque.Position assert((bp-boat:GetPivot().Position).Magnitude<12,"Boarding outside reach")
local exit=world:GetAttribute("DockExitCF").Position local exitHit=ground(exit)assert(exitHit and exitHit.Material~=Enum.Material.Water and math.abs(exit.Y-exitHit.Position.Y-3.3)<.05,"Boat exit unsafe")
local bridge=world.TrilhasEMirante.PonteDePedra local samples=0 local maxGrade=0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")and not p:GetAttribute("BridgeGuard")then
 local f=p.CFrame.LookVector local grade=math.abs(f.Y)/math.sqrt(f.X*f.X+f.Z*f.Z)maxGrade=math.max(maxGrade,grade) samples+=1
end end assert(maxGrade<.6,"Stone bridge too steep")
return{boatOnOpenWater=true,bridgeFloorSamples=samples,maxGrade=maxGrade,pierTop=deck.Position.Y+deck.Size.Y/2,underPier=below and below.Position.Y or nil,pierUnderMaterial=below and tostring(below.Material)or nil}]========])
local bridgeSurfaceAudit=run([========[local world=workspace.IlhaSerena local bridge=world.TrilhasEMirante.PonteDePedra
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={world.Islands}ray.RespectCanCollide=true
local bad={}local checked=0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")and not p:GetAttribute("BridgeGuard")then
 for _,x in ipairs({-5,0,5})do for _,z in ipairs({-p.Size.Z*.45,0,p.Size.Z*.45})do
  local pt=p.CFrame:PointToWorldSpace(Vector3.new(x,p.Size.Y/2,z))
  local h=workspace:Raycast(Vector3.new(pt.X,180,pt.Z),Vector3.new(0,-260,0),ray)checked+=1
  if h and h.Position.Y>pt.Y+.15 then bad[#bad+1]={bridge={pt.X,pt.Y,pt.Z},ground=h.Position.Y}end
 end end
end end
assert(#bad==0,"Bridge width intersects island")
return{checked=checked,blocked=#bad,examples={bad[1],bad[2],bad[3]},stoneY=world.Props.PedraMistica1:GetPivot().Position.Y}]========])
local coverageAudit=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime local world=workspace.IlhaSerena
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template:FindFirstChildOfClass("MeshPart")local bones={}
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
local Codec=require(runtime.GrassCodec)local bins={}local minimum=runtime.GrassCoverage:GetAttribute("Min")local spacing=4 local total=0
local function key(x,z)return math.floor(x*2)..":"..math.floor(z*2)end
for _,chunk in ipairs(runtime.GrassCoverage:GetChildren())do if chunk:IsA("StringValue")then for _,cell in ipairs(game.HttpService:JSONDecode(chunk.Value))do
 local raw=Codec.decode(cell[4],#bones)
 for index,b in ipairs(bones)do local y=Codec.height(raw,index,cell[3])if y then
  local x,z=minimum+cell[1]*spacing+b.CFrame.X,minimum+cell[2]*spacing+b.CFrame.Z
  local k=key(x,z)bins[k]=bins[k]or{}table.insert(bins[k],Vector3.new(x,y,z))total+=1
 end end
end end end
local results={}local samples=0 local gaps=0 local maxDistance=0
for _,island in ipairs(world.Islands:GetChildren())do
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={island}params.RespectCanCollide=true
 local lo,hi=island:GetBoundingBox()local position=lo.Position local size=hi
 local tested=0 local missed=0 local farthest=0
 for x=math.floor(position.X-size.X/2)+1,position.X+size.X/2,2 do for z=math.floor(position.Z-size.Z/2)+1,position.Z+size.Z/2,2 do
  local h=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),params)
  if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Position.Y>.15 and h.Normal.Y>.55 then
   tested+=1 local nearest=math.huge
   for bx=math.floor(x*2)-2,math.floor(x*2)+2 do for bz=math.floor(z*2)-2,math.floor(z*2)+2 do
    for _,p in ipairs(bins[bx..":"..bz]or{})do local d=Vector2.new(p.X-x,p.Z-z).Magnitude if d<nearest then nearest=d end end
   end end
   if nearest>.9 then missed+=1 end farthest=math.max(farthest,nearest)
  end
 end end
 samples+=tested gaps+=missed maxDistance=math.max(maxDistance,farthest)results[#results+1]={name=island.Name,samples=tested,gaps=missed,maxRootDistance=farthest}
end
assert(gaps==0,"Grass coverage has interior gaps")
return{samples=samples,gaps=gaps,maxRootDistance=maxDistance,roots=total,islands=results}
]========])
return {ok=true,version=game.PlaceVersion,universe=game.GameId,place=game.PlaceId,assets=assets,
 oldIslandRemoved=true,parts=parts,foreignScripts=foreign,benches=benches,seats=seats,bridgeFloorSegments=floors,
 stoneTrigger=true,bridgeHiddenInitially=true,adminUserId=Admin.UserId,ownerOnly=true,compiledScripts=compiled,
 personalWeatherCount=4,windEveryMode=true,navigation=navigation,coverageAudit=coverageAudit,bridgeSurfaceAudit=bridgeSurfaceAudit,guardSegments=guards}