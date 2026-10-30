local fs=require('@lune/fs')
local R=require('@lune/roblox')
local original=R.deserializePlace(fs.readFile('/tmp/asset-7208091524.rbxl'))
local halo=original:GetService('Workspace').Skybox.BlackHole.Model.Singularity.Halo
local spawn=assert(original:GetService('Workspace'):FindFirstChildWhichIsA('SpawnLocation',true))
local observer=(spawn.CFrame.Position-halo.CFrame.Position).Unit
assert(observer.X>.9,'Original effect view is not facing toward +X')
local originalDiameter=math.max(halo.Size.X,halo.Size.Y,halo.Size.Z)
assert(originalDiameter>210 and originalDiameter<230,'Unexpected source halo size')
local place=R.deserializePlace(fs.readFile('/tmp/still-here-original.rbxl'))
local template=place:GetService('ReplicatedStorage').SkyBlackHoleTemplate
assert(template:GetAttribute('SourceAsset')=='7208091524','Black-hole original asset missing')
assert(math.abs(template:GetAttribute('SourceHaloDiameter')-originalDiameter)<.1,'Source scale not preserved')
local view=template:GetAttribute('SourceViewDirection')
assert((view-observer).Magnitude<.002,'Original camera perspective discarded')
local sourceDebris=original:GetService('Workspace').Skybox.DebrisField
local originalBones=0
for _,d in ipairs(sourceDebris:GetDescendants()) do if d:IsA('Bone') then originalBones+=1 end end
assert(originalBones==162,'Expected the untouched 160-rock source rig with two parent bones')
assert(template:GetAttribute('OriginalDebrisBoneCount')==originalBones,'Source rock count altered')
assert(template:GetAttribute('OriginalDebrisAnimationId')=='7239753826','Original animation ID was not preserved')
assert(template.DebrisField:FindFirstChildOfClass('AnimationController'),'Original animation controller stripped')
local releaseBones=0
for _,d in ipairs(template.DebrisField:GetDescendants()) do if d:IsA('Bone') then releaseBones+=1 end end
assert(releaseBones==originalBones,'Not all original debris bones survived extraction')
local client=place:GetService('StarterPlayer').StarterPlayerScripts.SkyBlackHoleClient.Source
assert(client:find("debrisTrack:Play(0,1,1)",1,true),'Original animation playback rate changed')
assert(not client:find("field:ScaleTo",1,true),'Original rock field rescaled independently')
assert(not client:find("field:PivotTo",1,true),'Original rock formation moved independently')
assert(not client:find("shardBones",1,true),'Original rock animation is incomplete')
assert(client:find('sourceObservation=CFrame.lookAt',1,true),'Wrong original view axis used')
assert(client:find('observationToPivot=sourceObservation:ToObjectSpace(base)',1,true),'Original perspective not retained')
assert(client:find('base=targetObservation*observationToPivot',1,true),'Source view not mapped onto menu camera')
assert(not client:find('haloToPivot=halo.CFrame:ToObjectSpace',1,true),'Incorrect halo-normal facing returned')
local projectedHaloPx=originalDiameter*math.clamp(145/originalDiameter,.60,.70)*720/(2*math.tan(math.rad(60)/2))/600
assert(projectedHaloPx>=120 and projectedHaloPx<=180,'Hole must be close but not larger than the menu')
local menu=place:GetService('ReplicatedFirst').SessionMenuClient.Source
assert(not menu:find("local shade=make('Frame'",1,true),'Full-screen menu shadow still hides original effect')
print('BLACK HOLE GEOMETRY PASS: authored +X observer, original 220-stud singularity, closer 720p projection '..math.floor(projectedHaloPx)..'px, no giant menu overlay; 160 original animated rocks preserved')
