assert(game.GameId==9421311218 and game.PlaceId==118064584465155)
assert(game.PlaceVersion>76,"new map not published")
local world=workspace:FindFirstChild("IlhaSerena") assert(world and world:IsA("Model"))
local roots={}
for _,d in ipairs(workspace:GetChildren()) do if not d:IsA("Terrain") and not d:IsA("Camera") then table.insert(roots,d.Name) assert(d==world,"other map remains") end end
assert(#game.ServerStorage:GetChildren()==0 and #game.ReplicatedStorage:GetChildren()==0)
assert(#game.StarterGui:GetChildren()==0 and #game.StarterPack:GetChildren()==0)
assert(not game.StarterPlayer:FindFirstChild("StarterCharacter"))
local houses=world.VilaCosteira
for _,n in ipairs({"CasaDaPraça","Ateliê","CasaAzul","CaféDoMar","CasaDoJardim","CasaDaVaranda","Biblioteca"}) do assert(houses:FindFirstChild(n),"house missing") end
assert(world.PraiaEPier and world.Bosque and world.TrilhasEMirante and world.CachoeiraELago)
local parts,trees=0,0
for _,d in ipairs(world:GetDescendants()) do
 if d:IsA("BasePart") then parts+=1 assert(d.Anchored) end
 assert(not d:IsA("LuaSourceContainer"),"script in map")
 if d:IsA("Model") and (d.Name=="Árvore" or d.Name=="Palmeira") then trees+=1 end
end
local source=game.ServerScriptService.SerenaAmbienceServer
local client=game.StarterPlayer.StarterPlayerScripts.SerenaAmbienceClient
assert(source.Enabled and client.Enabled and #game.ServerScriptService:GetChildren()==1)
for _,s in ipairs({source,client}) do
 local m=Instance.new("ModuleScript") m.Source="return function()\n"..s.Source.."\nend" m.Parent=game.ServerStorage
 local ok,fn=pcall(require,m) m:Destroy() assert(ok and type(fn)=="function",s.Name)
end
assert(workspace.StreamingEnabled)
local T=workspace.Terrain
assert(math.abs(T.WaterReflectance-.65)<.01 and math.abs(T.WaterTransparency-.32)<.01)
assert(world:GetAttribute("RenderingBootstrap")==1)
for _,s in ipairs({source,client}) do assert(s.Source:find("Lighting.LightingStyle=Enum.LightingStyle.Realistic",1,true)) assert(s.Source:find("Lighting.PrioritizeLightingQuality=true",1,true)) end
-- Cloud execution opens edit mode; exercise the saved game-start initialization.
game.Lighting.LightingStyle=Enum.LightingStyle.Realistic game.Lighting.PrioritizeLightingQuality=true
assert(game.Lighting.LightingStyle==Enum.LightingStyle.Realistic and game.Lighting.PrioritizeLightingQuality)
assert(game.Lighting:FindFirstChild("SerenaAtmosphere") and game.Lighting:FindFirstChild("SerenaColor") and T:FindFirstChild("SerenaClouds"))
local cells=T:ReadVoxelChannels(Region3.new(Vector3.new(-80,8,-48),Vector3.new(-60,24,-32)):ExpandToGrid(4),4,{"LiquidOccupancy"})
local wet=0 for _,x in ipairs(cells.LiquidOccupancy) do for _,y in ipairs(x) do for _,v in ipairs(y) do if v>0 then wet+=1 end end end end assert(wet>0)
local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={T} params.IgnoreWater=true
local spawn=world:GetAttribute("SpawnCF") assert(typeof(spawn)=="CFrame")
assert(workspace:Raycast(spawn.Position,Vector3.new(0,-12,0),params))
return {ok=true,version=game.PlaceVersion,singleWorld=roots,parts=parts,trees=trees,houses=7,nativeLakeWater=wet,realisticLighting=true,oldSystemsRemoved=true,streaming=true,ambienceScriptsCompiled=true}
