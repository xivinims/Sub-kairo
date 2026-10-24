assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==81,"Unexpected saved version")
local w=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime
assert(w:GetAttribute("UpgradeVersion")==81,"Upgrade not saved")
assert(w:GetAttribute("WindEffectsAssetId")==11946229834 and runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834,"Exact wind model missing")
assert(w:GetAttribute("SkinnedGrassAssetId")==87377915371959 and w:GetAttribute("GrassVariant")=="StudioFine"and w:GetAttribute("WholeMapGrass"),"Exact fine grass missing")
local template=runtime.SkinnedGrassTemplates.FineStudio local mesh=template:FindFirstChildOfClass("MeshPart")
assert(mesh.MeshId=="rbxassetid://80159239673273"and mesh.Color==Color3.fromRGB(104,171,65),"Fine grass mesh or vivid color changed")
local patches=#runtime.GrassCoverage:GetChildren()local roots=0
for _,cell in ipairs(runtime.GrassCoverage:GetChildren())do roots+=cell:GetAttribute("GreenRoots")end
assert(patches==503 and roots==44994 and w:GetAttribute("GrassCoverageRoots")==roots,"Coverage was not saved")
local parts=0 local meshes=0 local foreignScripts=0
for _,d in ipairs(w:GetDescendants())do if d:IsA("BasePart")then parts+=1 assert(d.Anchored,"Loose map geometry")if d:IsA("MeshPart")then meshes+=1 end elseif d:IsA("LuaSourceContainer")then foreignScripts+=1 end end
assert(parts==4960 and foreignScripts==0,"Map changed after staging")
local houses=0 local cabins=0 local cottages=0
for _,home in ipairs(w.VilaCosteira:GetChildren())do if home:IsA("Model")and home:GetAttribute("SerenaHouse")then
 assert(home:GetAttribute("Furnished"),"Empty house")houses+=1
 if home:GetAttribute("SourceAssetId")==2109355142 then cabins+=1
 elseif home:GetAttribute("SourceAssetId")==12346232595 then assert(home.InteriorDaLoja:GetAttribute("SourceAssetId")==6319697240)cottages+=1 end
end end
assert(houses==7 and cabins==4 and cottages==3,"Furnished houses not saved")
local bridge=require(runtime.BridgeLifecycle)assert(bridge.GraceSeconds==60 and bridge.AppearRadius==130,"Bridge presence settings lost")
for _,z in ipairs({70,124})do
 local m=w.TrilhasEMirante["Ponte"..z]assert(m:GetAttribute("BridgeVisible")==false and m:GetAttribute("EmptyGraceSeconds")==60,"Bridge idle state wrong")
 local fixed=0
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
  if p:GetAttribute("BridgeCollider")then assert(not p.CanCollide and not p.CanQuery)fixed+=1
  elseif p:GetAttribute("BridgeRestCF")then assert(p.Transparency==1 and not p.CanCollide and p.CFrame==p:GetAttribute("BridgeRestCF"),"Hidden bridge visual moved")end
 end end assert(fixed>=80,"Stable bridge floor lost")
end
local rules=require(runtime.ItemRules)assert(rules.Price==30 and rules.Duration==3 and rules.Cooldown==60,"Apple behavior changed")
for _,name in ipairs({"Maçã da Névoa","Vara de Pesca","Carpa"})do
 local tool=game.ServerStorage.SerenaItems[name]assert(tool.Handle:IsA("MeshPart")and tool:GetAttribute("SourceAssetId"))
 for _,p in ipairs(tool:GetDescendants())do if p:IsA("BasePart")then assert(not p.Anchored and p.Massless and not p.CanCollide,"Item can freeze avatar")end end
end
local boat=w.PraiaEPier.BarcoDePesca assert(boat:GetAttribute("SourceAssetId")==9617142471 and boat.DriverSeat:IsA("VehicleSeat")and boat.PassengerSeat:IsA("Seat"),"Boat not saved")
assert(game.ReplicatedStorage.SerenaBoat and game.ReplicatedStorage.SerenaFishing and game.ServerScriptService.SerenaCurrency:IsA("BindableFunction"),"Gameplay endpoints missing")
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
assert(compiled==15,"Runtime scripts incomplete")
local climate=require(runtime.Climate)local dawn=climate.profile(6.2,0,1,0)assert(dawn.rays>.06,"Sunrise rays lost")
assert(game.Lighting.SerenaColor.Saturation>.1 and workspace.Terrain.WaterWaveSize>=.3 and workspace.Terrain.WaterReflectance<.5,"Color/water enhancements lost")
local personal=require(runtime.PersonalClimate)local hour,rain=personal.resolve("Noite","Chuva",12,0,1)assert(hour==23 and rain==1,"Personal weather lost")
assert(game.StarterPlayer.StarterPlayerScripts.SerenaWeatherMenu.Source:find("AutomaticCanvasSize=Enum.AutomaticSize.Y",1,true),"Scrolling menu lost")
assert(game.Lighting.SerenaSky.SkyboxBk=="rbxassetid://1084532042"and workspace.StreamingEnabled,"Sky or streaming lost")
for _,m in ipairs(workspace:GetChildren())do assert(m==w or m==workspace.Terrain or m:IsA("Camera"),"Extra world or QA object")end
assert(not game.ServerStorage:FindFirstChild("QA81")and not game.ServerStorage:FindFirstChild("Stage81"),"Test objects saved")
return {ok=true,publishedVersion=game.PlaceVersion,mapParts=parts,realMeshParts=meshes,furnishedHouses=houses,readyCabins=cabins,cottagesWithStoreInterior=cottages,grassAsset=87377915371959,grassVariant="StudioFine",grassPatches=patches,greenRoots=roots,windAsset=11946229834,bridgeEmptyGraceSeconds=60,boatAndFishing=true,appleInvisibilitySeconds=3,appleCooldownSeconds=60,compiledScripts=compiled,singleMap=true,personalWeatherAndScroll=true,vividColorSunriseAndWaves=true}
