assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==79,"Unexpected published version")
local world=workspace:FindFirstChild("IlhaSerena") assert(world and world:GetAttribute("UpgradeVersion")==79 and world:GetAttribute("DesignVersion")==2,"Upgrade missing")
local RS=game.ReplicatedStorage local SSS=game.ServerScriptService local SPS=game.StarterPlayer.StarterPlayerScripts
assert(RS.SerenaShop:IsA("RemoteEvent") and RS.SerenaRuntime:FindFirstChild("ApplePreview"),"Shop assets not saved")
for _,name in ipairs({"Climate","GrassMotion","ItemRules","Routes"})do assert(RS.SerenaRuntime[name]:IsA("ModuleScript"),"Runtime module missing")end
assert(SSS.SerenaAmbienceServer and SSS.SerenaShopServer and SSS.SerenaInvisibility,"Server sources not saved")
assert(SPS.SerenaAmbienceClient and SPS.SerenaGrassClient and SPS.SerenaShopClient,"Client sources not saved")
assert(#game.StarterGui:GetChildren()==0 and #game.StarterPack:GetChildren()==0,"Legacy UI or tools returned")
assert(not game.StarterPlayer:FindFirstChild("StarterCharacter"),"Custom character returned")
local scenes={}
for _,child in ipairs(workspace:GetChildren())do if child~=world and child~=workspace.Terrain and not child:IsA("Camera")then error("Unexpected scene: "..child.Name)end table.insert(scenes,child.Name)end
assert(workspace.StreamingEnabled,"Streaming disabled")
local parts=0 local trees=0
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain} ray.IgnoreWater=true
local maxGap=-math.huge
for _,d in ipairs(world:GetDescendants())do
 if d:IsA("BasePart")then assert(d.Anchored,"Unanchored scene") parts+=1 end
 assert(not d:IsA("LuaSourceContainer"),"World script returned")
 if d:IsA("Model") and d:GetAttribute("SerenaRootCF")then
  local root=d:GetAttribute("SerenaRootCF") local low
  for _,p in ipairs(d:GetChildren())do if p:IsA("BasePart")and(p.Name=="Tronco"or p.Name=="TroncoCurvo")then
   local a=p.CFrame:PointToWorldSpace(Vector3.new(-p.Size.X/2,0,0)) local b=p.CFrame:PointToWorldSpace(Vector3.new(p.Size.X/2,0,0)) local q=a.Y<b.Y and a or b if not low or q.Y<low.Y then low=q end
  end end
  local floor=workspace:Raycast(Vector3.new(root.X,200,root.Z),Vector3.new(0,-300,0),ray) assert(low and floor,"Ground contact missing")
  local gap=low.Y-floor.Position.Y assert(gap<-.5 and gap> -1.1,"Tree contact lost after save")maxGap=math.max(maxGap,gap)trees+=1
 end
end
assert(parts==5340 and trees==111,"Scene size changed after save")
local tool=game.ServerStorage.SerenaItems["Maçã da Névoa"] assert(tool:IsA("Tool")and not tool.Handle.Anchored and not tool.CanBeDropped,"Physical item lost")
local Rules=require(RS.SerenaRuntime.ItemRules) assert(Rules.Duration==3 and Rules.Cooldown==60 and Rules.Price==30,"Item rules changed")
local sky=game.Lighting.SerenaSky
assert(world:GetAttribute("SkyPackAsset")==11808837483 and sky.SkyboxBk=="rbxassetid://1084532042" and sky.SkyboxUp=="rbxassetid://1084532776","HD sky not saved")
assert(game.Lighting.SerenaSunRays.Enabled and game.Lighting.SerenaBloom.Enabled and game.Lighting.SerenaAtmosphere and workspace.Terrain.SerenaClouds,"Sky effects not saved")
assert(workspace.Terrain.WaterWaveSize>=.21 and workspace.Terrain.WaterWaveSpeed>=8,"Water motion lost")
assert(world:GetAttribute("InteractiveGrass")==true and world:GetAttribute("RenderingBootstrap")==2,"Runtime configuration lost")
local Climate=require(RS.SerenaRuntime.Climate)
local savedStyle=game.Lighting.LightingStyle.Name
local bootstrap=Climate.rendering(game.Lighting) assert(bootstrap,"Rendering startup failed")
assert(game.Lighting.LightingStyle==Enum.LightingStyle.Realistic and game.Lighting.PrioritizeLightingQuality,"Rendering startup mismatch")
local compiled=0 local scriptNames={}
for _,parent in ipairs({SSS,SPS})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,result=pcall(require,m)m:Destroy()assert(ok,tostring(result))compiled+=1 table.insert(scriptNames,s.Name)
end end end
local water=workspace.Terrain:ReadVoxelChannels(Region3.new(Vector3.new(-80,8,-48),Vector3.new(-60,24,-32)):ExpandToGrid(4),4,{"LiquidOccupancy"})local cells=0
for _,x in ipairs(water.LiquidOccupancy)do for _,y in ipairs(x)do for _,v in ipairs(y)do if v>0 then cells+=1 end end end end assert(cells>0,"Lake water lost")
return {ok=true,version=game.PlaceVersion,parts=parts,trees=trees,maxTrunkGap=maxGap,savedRenderingStyle=savedStyle,renderingStartupChecked=bootstrap,hdSky=true,interactiveGrass=true,nativeWaterCells=cells,item={price=Rules.Price,invisibleSeconds=Rules.Duration,cooldownSeconds=Rules.Cooldown},compiledScripts=compiled,scriptNames=scriptNames,singleScene=scenes}
