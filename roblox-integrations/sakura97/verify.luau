assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")
local CS=game:GetService("CollectionService")
local rt=game.ReplicatedStorage:FindFirstChild("XNRuntime")
assert(rt and rt:GetAttribute("Version")==103,"XNRuntime v103 missing")
assert(rt:GetAttribute("GameName")=="XN [VOICE]","game identity wrong")
assert(rt:GetAttribute("MapAssetId")==106476929993683,"map asset wrong")
assert(rt:GetAttribute("Design")=="FaithfulBrookhavenCleanup","wrong design build")

local map=workspace:FindFirstChild("BrookhavenMap")
assert(map and map:IsA("Model") and map:GetAttribute("AssetId")==106476929993683,"BrookhavenMap missing")

local parts,scripts=0,0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("BasePart") then parts+=1 elseif d:IsA("LuaSourceContainer") then scripts+=1 end
end
assert(parts>13000,"map lost too much geometry "..parts)
assert(scripts==0,"free-model scripts remain "..scripts)

assert(not workspace:FindFirstChild("ReworkedHouseLots"),"old fake parks remain")
assert(not workspace:FindFirstChild("GreenGrassDecor"),"old grass clones remain")
assert(not workspace:FindFirstChild("XN_Grass"),"procedural blade grass remains")

local green=CS:GetTagged("XNGreenGround")
assert(#green>=8,"green ground missing")
for _,p in ipairs(green) do assert(p:IsDescendantOf(map) and p.Material==Enum.Material.Grass,"grass escaped green map surfaces") end

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:GetAttribute("AssetId")==11946229834,"wind missing")
assert(workspace.GlobalWind.Magnitude>8 and workspace.GlobalWind.Magnitude<15,"wind too strong/weak")

local h=workspace:FindFirstChild("XN_Halloween")
assert(h and h:GetAttribute("OnlyPumpkins")==true,"Halloween folder wrong")
local pumpkins=0
for _,d in ipairs(h:GetDescendants()) do
 if d:IsA("BasePart") then assert(d.Name=="Pumpkin","non-pumpkin Halloween geometry"); pumpkins+=1 end
end
assert(pumpkins>=12 and pumpkins<=24,"pumpkin count unreasonable "..pumpkins)

local spawn=workspace:FindFirstChild("XNSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"spawn missing")
local st=spawn:GetAttribute("SourceType")
assert(st=="OriginalSpawnLocation" or st=="NamedSpawn" or st=="RoadFallback" or st=="FlatFallback","spawn source unknown")
assert(spawn:GetAttribute("SourcePosition")~=nil,"spawn lacks source position")

local loading=game.ReplicatedFirst:FindFirstChild("XNLoading")
assert(loading and loading:IsA("LocalScript"),"loading missing")
assert(loading.Source:find('txt.Text="acessando…"',1,true),"loading text wrong")
assert(loading.Source:find("CameraMode.Classic",1,true),"camera rotation blocked")

local _,size=map:GetBoundingBox()
assert(size.X>2900 and size.Z>2900,"map was scaled/cropped")
return {
 ok=true,
 version=103,
 mapParts=parts,
 scriptsRemoved=rt:GetAttribute("ScriptsRemoved"),
 greenGround=#green,
 windTagged=rt:GetAttribute("WindTagged"),
 pumpkins=pumpkins,
 spawnSourceType=st,
 spawnSourceName=spawn:GetAttribute("SourceName"),
 mapSize={size.X,size.Y,size.Z}
}
