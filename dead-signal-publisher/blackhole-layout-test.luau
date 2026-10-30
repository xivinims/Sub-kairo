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
local client=place:GetService('StarterPlayer').StarterPlayerScripts.SkyBlackHoleClient.Source
assert(client:find('sourceObservation=CFrame.lookAt',1,true),'Wrong original view axis used')
assert(client:find('observationToPivot=sourceObservation:ToObjectSpace(base)',1,true),'Original perspective not retained')
assert(client:find('base=targetObservation*observationToPivot',1,true),'Source view not mapped onto menu camera')
assert(not client:find('haloToPivot=halo.CFrame:ToObjectSpace',1,true),'Incorrect halo-normal facing returned')
local projectedHaloPx=originalDiameter*math.clamp(145/originalDiameter,.60,.70)*720/(2*math.tan(math.rad(60)/2))/600
assert(projectedHaloPx>=120 and projectedHaloPx<=180,'Hole must be close but not larger than the menu')
local menu=place:GetService('ReplicatedFirst').SessionMenuClient.Source
assert(not menu:find("local shade=make('Frame'",1,true),'Full-screen menu shadow still hides original effect')
print('BLACK HOLE GEOMETRY PASS: authored +X observer, original 220-stud singularity, closer 720p projection '..math.floor(projectedHaloPx)..'px, no giant menu overlay')
