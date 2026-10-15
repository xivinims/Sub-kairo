assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==82,"Unexpected saved version")
local world=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime
assert(world:GetAttribute("UpgradeVersion")==82 and world:GetAttribute("DenseGrass"),"Grass correction was not saved")
local coverage=runtime.GrassCoverage
assert(coverage:GetAttribute("FormatVersion")==2 and coverage:GetAttribute("Spacing")==4,"Old sparse grass distribution")
assert(coverage:GetAttribute("AuditSamples")==54908 and coverage:GetAttribute("AuditGaps")==0,"Continuity audit was not saved")
assert(#coverage:GetChildren()==119,"Coverage chunk missing")
local Field=require(runtime.GrassField)local Codec=require(runtime.GrassCodec)local field=Field.new(coverage)
assert(field.count==15124 and coverage:GetAttribute("PatchCount")==field.count,"Dense volumes missing")
local roots=0 local checked=0
local mesh=runtime.SkinnedGrassTemplates.FineStudio:FindFirstChildOfClass("MeshPart")
assert(mesh.MeshId=="rbxassetid://80159239673273" and mesh.Color==Color3.fromRGB(104,171,65),"Fine vivid grass changed")
local bones={}for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end
table.sort(bones,function(a,b)return a.Name<b.Name end)assert(#bones==100)
local min=Vector3.new(math.huge,math.huge,math.huge)local max=-min
for _,b in ipairs(bones)do min=min:Min(b.CFrame.Position)max=max:Max(b.CFrame.Position)end
assert(max.X-min.X>4 and max.Z-min.Z>4,"Grass edges no longer overlap")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,world}
ray.RespectCanCollide=true ray.IgnoreWater=false
for _,cell in pairs(field.cells)do
 roots+=cell.roots
 if cell.key%41==0 then
  local data=Codec.decode(cell.encoded,#bones)
  for _,i in ipairs({1,25,50,75,100})do
   local height=Codec.height(data,i,cell.base)
   if height then
    local point=cell.center+bones[i].CFrame.Position
    local hit=workspace:Raycast(Vector3.new(point.X,180,point.Z),Vector3.new(0,-300,0),ray)
    assert(hit and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Grass,"Grass entered a non-green surface")
    assert(math.abs(hit.Position.Y-height)<.011,"Saved grass root height changed")checked+=1
   end
  end
 end
end
assert(roots==1372773 and coverage:GetAttribute("RootCount")==roots and checked>1000,"Grass roots missing")
assert(coverage:GetAttribute("NearRadiusTouch")==48 and coverage:GetAttribute("MaxActiveTouch")==640,"Touch streaming settings missing")
assert(runtime.SkinnedGrass.Source:find("function SkinnedGrass:RemoveMeshes",1,true),"Grass unload cleanup missing")
assert(game.StarterPlayer.StarterPlayerScripts.SerenaGrassClient.Source:find("keepRadius=radius+6",1,true),"Sparse old client restored")
local mapParts=0 for _,d in ipairs(world:GetDescendants())do if d:IsA("BasePart")then mapParts+=1 assert(d.Anchored)end end
assert(mapParts==4960 and runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834,"Other map features changed")
assert(not game.ServerStorage:FindFirstChild("GrassQA82")and not game.ServerStorage:FindFirstChild("GrassStage82"),"QA objects saved")
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
assert(compiled==15)
return {ok=true,publishedVersion=game.PlaceVersion,spacing=4,grassVolumes=field.count,greenRoots=roots,coverageChunks=119,
 overlapX=max.X-min.X-4,overlapZ=max.Z-min.Z-4,freshHeightChecks=checked,greenSamples=54908,uncoveredSamples=0,
 maxRootDistance=coverage:GetAttribute("AuditMaxRootDistance"),relativeDistributionDensity=30.25,
 touchRadius=48,touchMaxResidentVolumes=640,compiledScripts=compiled,mapParts=mapParts,fineRequestedGrassPreserved=true}
