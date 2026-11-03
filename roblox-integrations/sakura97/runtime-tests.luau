-- Exercise the actual imported grass code, rather than checking text signatures.
local module=require(game.ReplicatedStorage.SkinnedGrassRuntimeModule)
local testFolder=Instance.new("Folder") testFolder.Name="GrassSimulationTest" testFolder.Parent=workspace
local model=game.ReplicatedStorage.GrassWindTemplate:Clone() model.Parent=testFolder
local sim=module.new()
sim:UpdateSettings({RenderDistanceEnabled=false,WindEnabled=true,CollisionsEnabled=true,
 WindDistanceInner=30,WindDistanceOuter=40,CollisionRadiusInner=1.5,CollisionRadiusOuter=4.5,CollisionAngle=75})
sim:AddMeshes({model})
sim:MovePooledMesh(model,CFrame.new(0,300,0),true)
local mesh=model:FindFirstChildWhichIsA("MeshPart")
local origin=mesh:FindFirstChild("SkinnedGrass_Origin")
local bone=assert(origin:FindFirstChildWhichIsA("Bone"),"Missing animated bone")
local point=bone.WorldPosition
for _=1,4 do sim:Step(1/20,{},point) end
local _,windAngle=bone.Transform:ToAxisAngle()
assert(math.abs(windAngle)>.01,"Original wind did not move grass")
sim:UpdateSettings({WindEnabled=false})
for _=1,4 do sim:Step(1/20,{point+Vector3.new(.4,0,.3)},point) end
local _,stepAngle=bone.Transform:ToAxisAngle()
assert(math.abs(stepAngle)>.1,"Foot collision did not bend grass")
sim:MovePooledMesh(model,CFrame.new(1000,300,0),true)
local oldNodes=sim.BoneOctree:RadiusSearch(point,20)
local newNodes=sim.BoneOctree:RadiusSearch(bone.WorldPosition,20)
assert(#oldNodes==0 and #newNodes==100,"Recycled grass simulation kept stale positions")
sim:MovePooledMesh(model,CFrame.new(0,-10000,0),false)
assert(model.Parent==nil,"Inactive grass retained in workspace")
model:Destroy() testFolder:Destroy()
local wind=game.StarterPlayer.StarterPlayerScripts.WindController
local shake=require(wind.WindShake)
local lines=require(wind.WindLines)
assert(type(shake.Init)=="function" and type(shake.Pause)=="function" and type(lines.Cleanup)=="function","Wind module dependencies fail")
return {ok=true,windBendsGrass=true,feetBendGrass=true,poolReindexed=true,windModulesLoaded=true}
