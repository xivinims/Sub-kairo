assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Wrong place")
local CS=game:GetService("CollectionService")
local RS=game:GetService("ReplicatedStorage")
local runtime=assert(RS:FindFirstChild("SweanRuntime"),"Missing runtime")
assert(runtime:GetAttribute("Version")==115,"Wrong version")
local island=assert(workspace:FindFirstChild("FloatingIsland"),"Missing island")
local cf,size=island:GetBoundingBox()
assert(math.abs(math.max(size.X,size.Z)-260)<.1,"Island exceeds 260-stud budget")
assert(island:GetAttribute("AssetId")==10485490600,"Wrong island")
local mapParts=0
for _,d in ipairs(island:GetDescendants()) do
 assert(not d:IsA("LuaSourceContainer"),"Imported island script")
 if d:IsA("BasePart") then assert(d.Anchored,"Unanchored island") mapParts+=1 end
end
assert(mapParts>0)
local tree=assert(workspace:FindFirstChild("BigCenterTree"),"Missing tree")
assert(tree:GetAttribute("AssetId")==4617134997,"Wrong tree")
local tcf,tsize=tree:GetBoundingBox()
assert(tsize.Y>=63 and tsize.Y<=66,"Wrong tree height")
for _,d in ipairs(tree:GetDescendants()) do assert(not d:IsA("LuaSourceContainer"),"Imported tree script") end
local green=CS:GetTagged("IslandGreenGround")
assert(#green>0 and #green==runtime:GetAttribute("GreenSurfaceCount"))
local grass=assert(workspace:FindFirstChild("SkinnedGrassCoverage"))
assert(#grass:GetChildren()==0,"Dense grass saved on server")
assert(grass:GetAttribute("AssetId")==87377915371959)
assert(grass:GetAttribute("SingleMeshOnly")==true)
assert(grass:GetAttribute("MaxTouch")==96)
local template=assert(RS:FindFirstChild("GrassWindTemplate"))
local mesh=assert(template:FindFirstChild("SkinnedGrass"))
assert(mesh.MeshId=="rbxassetid://80159239673273","Wrong grass variant")
assert(mesh.Size==Vector3.new(100,4,100),"Grass was stretched")
local boneCount=0
for _,d in ipairs(mesh:GetDescendants()) do
 if d:IsA("Bone") then boneCount+=1 end
 assert(not d:IsA("LuaSourceContainer"),"Imported grass script")
end
assert(boneCount==100)
assert(runtime:GetAttribute("TreeSink")==6)
assert(grass:GetAttribute("TileOverlap")==1.65)
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("FriendPresence"))
for name,id in pairs({MenuClick=12221967,VoidMusic=110526913527016,FriendJoined=87437544236708,Regenerate=73292002268424}) do
 assert(RS.XNMedia[name].SoundId=="rbxassetid://"..id)
end
local stepX,stepZ=grass:GetAttribute("StepX"),grass:GetAttribute("StepZ")
assert(stepX>0 and stepX<grass:GetAttribute("FootprintX"))
assert(stepZ>0 and stepZ<grass:GetAttribute("FootprintZ"))
local plan=0
for _,p in ipairs(green) do
 assert(p:IsDescendantOf(island) and p:GetAttribute("GrassSurfaceId"))
 plan+=math.max(1,math.ceil((p.Size.X-grass:GetAttribute("FootprintX"))/stepX)+1)*math.max(1,math.ceil((p.Size.Z-grass:GetAttribute("FootprintZ"))/stepZ)+1)
end
assert(plan==runtime:GetAttribute("GrassPatchCount"),"Grid count mismatch")
local spawn=assert(workspace:FindFirstChild("IslandSpawn"))
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={island}
local hit=workspace:Raycast(spawn.Position+Vector3.new(0,2,0),Vector3.new(0,-10,0),ray)
assert(hit and CS:HasTag(hit.Instance,"IslandGreenGround"),"Spawn does not touch green ground")
local treeHit=workspace:Raycast(Vector3.new(runtime:GetAttribute("TreeGroundX"),runtime:GetAttribute("TreeGroundY")+2,runtime:GetAttribute("TreeGroundZ")),Vector3.new(0,-5,0),ray)
assert(treeHit and CS:HasTag(treeHit.Instance,"IslandGreenGround"),"Tree has no ground")
assert(math.abs(tcf.Position.Y-tsize.Y/2-treeHit.Position.Y+6)<.15,"Floating tree")
local shaderCount=0
for _,d in ipairs(game:GetService("Lighting"):GetChildren()) do
 if d:GetAttribute("SourceAssetId")==86563808574363 then shaderCount+=1 end
end
assert(shaderCount==6,"Flat Shader missing effects")
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("MobileShaderQuality"))
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SkinnedGrassRunner"))
-- Streaming radii are not exposed to Open Cloud; client pool and map size enforce budgets.
assert(workspace.StreamingEnabled==false,"Full map streaming setting failed")
assert(not workspace:FindFirstChild("MysticalSpawn"),"Decorative spawn was not removed")
assert(spawn.Transparency==1 and spawn.Enabled and spawn.Neutral)
assert(math.abs(spawn.Position.Y-hit.Position.Y-.2)<.1,"Invisible spawn not grounded")
local roads=assert(workspace:FindFirstChild("IslandRoads"))
assert(#roads:GetChildren()==2 and roads.TreeLoop and roads.EdgeLoop)
assert(#roads.TreeLoop:GetChildren()==72 and #roads.EdgeLoop:GetChildren()==144)
local center=roads:GetAttribute("Center") local width=roads:GetAttribute("Width")
for _,ring in ipairs(roads:GetChildren()) do
 local pieces=ring:GetChildren()
 for i,part in ipairs(pieces) do
  assert(part.Anchored and part.CanCollide and part.Material==Enum.Material.Asphalt)
  local nextPart=pieces[i%#pieces+1]
  assert((part:GetAttribute("End")-nextPart:GetAttribute("Start")).Magnitude<.01,"Road loop disconnected")
 end
end
local field=assert(workspace:FindFirstChild("FullIslandGrass"))
assert(#field:GetChildren()==field:GetAttribute("PatchCount") and #field:GetChildren()>100)
for _,patch in ipairs(field:GetChildren()) do
 assert(patch:IsA("MeshPart") and patch.MeshId==mesh.MeshId)
 assert(not patch:FindFirstChildWhichIsA("Bone",true),"Distant grass has unnecessary bones")
 local p=patch:GetAttribute("GroundPosition") local distance=Vector2.new(p.X-center.X,p.Z-center.Z).Magnitude
 local margin=field:GetAttribute("RoadClearance")*(patch:GetAttribute("GrassScale") or 1)
 for _,radius in ipairs({roads:GetAttribute("InnerRadius"),roads:GetAttribute("OuterRadius")}) do
  assert(math.abs(distance-radius)>width/2+margin-.01,"Grass overlaps road corridor")
 end
end
assert(game.ServerScriptService.NametagService.Nametag:IsA("BillboardGui"))
assert(game.ReplicatedStorage.SweanVoidEvent:IsA("RemoteEvent"))
assert(game.StarterPlayer.StarterPlayerScripts.VoidSequence:IsA("LocalScript"))
assert(runtime:GetAttribute("VoidThreshold")>workspace.FallenPartsDestroyHeight+100)
local wind=game.StarterPlayer.StarterPlayerScripts.WindController
assert(wind.WindShake:FindFirstChild("Settings") and wind.WindShake:FindFirstChild("Octree"),"Wind dependencies missing")
assert(not tree.FallingLeavesEmitter:FindFirstChildWhichIsA("ParticleEmitter"),"Obsolete leaf texture remains")
assert(tree.FallingLeavesEmitter.Transparency==1 and not tree.FallingLeavesEmitter.CanCollide)
return {ok=true,fullMap=true,nametags=true,invisibleSpawn=true,fullGrass=#field:GetChildren(),roadInner=roads:GetAttribute("InnerRadius"),roadOuter=roads:GetAttribute("OuterRadius"),voidSequence=true,version=115,mapParts=mapParts,grass=plan,grassMobileCap=96,grassBones=boneCount,islandSize=tostring(size),treeHeight=tsize.Y,shaderEffects=shaderCount,spawnGrounded=true,treeGrounded=true}
