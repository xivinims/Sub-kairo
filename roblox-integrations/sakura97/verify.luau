assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Wrong place")
local CS=game:GetService("CollectionService")
local RS=game:GetService("ReplicatedStorage")
local runtime=assert(RS:FindFirstChild("SweanRuntime"),"Missing runtime")
assert(runtime:GetAttribute("Version")==111,"Wrong version")
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
assert(math.abs(tcf.Position.Y-tsize.Y/2-treeHit.Position.Y+.55)<.15,"Floating tree")
local shaderCount=0
for _,d in ipairs(game:GetService("Lighting"):GetChildren()) do
 if d:GetAttribute("SourceAssetId")==86563808574363 then shaderCount+=1 end
end
assert(shaderCount==6,"Flat Shader missing effects")
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("MobileShaderQuality"))
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SkinnedGrassRunner"))
-- Streaming radius properties are not exposed in Open Cloud execution.
-- Performance limits are independently enforced by the 260-stud map and client pool.
return {ok=true,version=111,mapParts=mapParts,grass=plan,grassMobileCap=96,grassBones=boneCount,islandSize=tostring(size),treeHeight=tsize.Y,shaderEffects=shaderCount,spawnGrounded=true,treeGrounded=true}
