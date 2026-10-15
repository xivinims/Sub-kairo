assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==83,"Unexpected saved version")
local world=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime
assert(world:GetAttribute("UpgradeVersion")==83 and world:GetAttribute("GrassVariant")=="GrassCard","Grass variant not saved")
local templates=runtime.SkinnedGrassTemplates
assert(#templates:GetChildren()==1 and templates:FindFirstChild("GrassCard")and not templates:FindFirstChild("FineStudio"),"Old grass template still active")
local model=templates.GrassCard local mesh=model:FindFirstChildOfClass("MeshPart")
assert(mesh.MeshId=="rbxassetid://117152506140384"and model:GetAttribute("SourceAssetId")==87377915371959,"Wrong alternate model")
local color=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
local appearance=mesh:FindFirstChildOfClass("SurfaceAppearance")
assert(mesh.Color==color and appearance.Color==color and appearance.AlphaMode==Enum.AlphaMode.Transparency,"Grass tint differs from ground")
local bones=0 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones+=1 end end assert(bones==100)
local coverage=runtime.GrassCoverage local field=require(runtime.GrassField).new(coverage)
assert(field.count==15124 and coverage:GetAttribute("RootCount")==1372773 and coverage:GetAttribute("Spacing")==4,"Dense coverage changed")
assert(coverage:GetAttribute("AuditGaps")==0 and coverage:GetAttribute("AuditSamples")==54908,"Coverage audit lost")
local personal=require(runtime.PersonalClimate)local climate=require(runtime.Climate)
assert(#personal.Order==4,"Extra climate choices")
local modes={}
for i,key in ipairs({"Dia","Noite","Anoitecer","Chuva"})do
 assert(personal.Order[i]==key,"Mode order changed")
 local hour,rain,clear,choice=personal.resolve(key)
 assert(choice==key and rain==(key=="Chuva"and 1 or 0))
 local p=climate.profile(hour,rain,clear,0)assert(p.wind.Magnitude>3,"A preset lost wind")
 modes[#modes+1]={mode=key,hour=hour,rain=rain,wind=p.wind.Magnitude}
end
assert(not personal.Times and not personal.Weather and not climate.hour and not climate.weights,"Legacy cycle remains")
assert(world:GetAttribute("EnvironmentMode")=="Dia"and world:GetAttribute("ClimateModeCount")==4,"Default climate changed")
for _,key in ipairs({"ClockStart","DayLength","WeatherChanged","PreviousWeather","Weather"})do assert(world:GetAttribute(key)==nil,"Old cycle state survived")end
local SPS=game.StarterPlayer.StarterPlayerScripts
assert(SPS.SerenaGrassClient.Source:find('WaitForChild("GrassCard")',1,true),"Client still uses fine Studio grass")
assert(SPS.SerenaWeatherMenu.Source:find('ipairs(Personal.Order)',1,true)and not SPS.SerenaWeatherMenu.Source:find('Automatico',1,true),"Menu not replaced")
assert(SPS.SerenaWeatherMenu.Source:find("AutomaticCanvasSize=Enum.AutomaticSize.Y",1,true),"Scrolling menu lost")
assert(SPS.SerenaAmbienceClient.Source:find('Personal.resolve(player:GetAttribute("SerenaEnvironmentChoice"))',1,true),"Renderer still uses old time/weather choices")
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834,"Requested wind removed")
local compiled=0
for _,parent in ipairs({game.ServerScriptService,SPS})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
assert(compiled==15)
local parts=0 for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then parts+=1 end end assert(parts==4960)
for _,name in ipairs({"Stage83","Factory83","GrassQA82","ClimateQA83"})do assert(not game.ServerStorage:FindFirstChild(name),"QA object saved")end
return {ok=true,publishedVersion=game.PlaceVersion,grassVariant="GrassCard",meshId=mesh.MeshId,
 terrainMatchedColor={math.floor(color.R*255+.5),math.floor(color.G*255+.5),math.floor(color.B*255+.5)},
 grassVolumes=field.count,greenRoots=1372773,spacing=4,transparentPBR=true,
 climates=modes,allModesHaveWind=true,personalSelection=true,scrollingMenu=true,legacyCycleRemoved=true,
 compiledScripts=compiled,mapParts=parts}
