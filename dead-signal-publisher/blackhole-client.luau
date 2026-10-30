while not workspace:GetAttribute('GameMode') do task.wait(.1) end
local menu=workspace:GetAttribute('GameMode')=='Menu'
-- Original visual data from Roblox asset 7208091524; all runtime code here is ours.
local W=workspace
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local template=RS:WaitForChild('SkyBlackHoleTemplate',30)
if not template then warn('[SkyBlackHole] Visual template missing');return end
local previous=W:FindFirstChild('LocalSkyBlackHole');if previous then previous:Destroy() end
local model=template:Clone();model.Name='LocalSkyBlackHole'
local origin=template:GetAttribute('SourceOrigin')
local reference=template:GetAttribute('ReferenceDistance') or 1028
model.WorldPivot=CFrame.lookAt(origin,origin+Vector3.new(1,0,0))
local distance=menu and 600 or 900
-- Source halo diameter is 220 studs and the beam lattice extends much farther.
-- Scale according to the actual halo, NOT the spawn distance or the full sky.
local haloDiameter=template:GetAttribute('SourceHaloDiameter') or 220
local scale=menu and math.clamp(145/haloDiameter,.60,.70) or math.clamp(500/reference,.12,.7)
model:ScaleTo(scale)
model.Parent=W
local touch=UIS.TouchEnabled
-- The player requested a near-black void, not the original asset's bright
-- orange skybox. Only replace the local menu background; keep the authored
-- BlackHole/AccretionDisc, beams and source-space geometry unmodified.
local voidBackdrop
if menu then
 local previousBackdrop=W:FindFirstChild('LocalBlackVoidBackdrop')
 if previousBackdrop then previousBackdrop:Destroy() end
 voidBackdrop=Instance.new('Part')
 voidBackdrop.Name='LocalBlackVoidBackdrop'
 voidBackdrop.Anchored=true
 voidBackdrop.CanCollide=false;voidBackdrop.CanTouch=false;voidBackdrop.CanQuery=false
 voidBackdrop.CastShadow=false
 voidBackdrop.Material=Enum.Material.Neon
 voidBackdrop.Color=Color3.fromRGB(0,0,2)
 voidBackdrop.Size=Vector3.new(16000,12000,5)
 -- Beyond the entire local singularity and close foreground, but before the skybox.
 voidBackdrop.CFrame=CFrame.new(0,5000,-3200)
 voidBackdrop.Parent=W
end
-- View the original singularity from its AUTHORED observer direction (+X with
-- a slight downward angle). The previous code aimed Halo.LookVector (-Z) at
-- the camera, which turned the accretion disc into a giant edge-on stripe.
local offset=Vector3.new(-.36,.49,-.79).Unit*distance
local base=model:GetPivot()
local halo=assert(model:FindFirstChild('Halo',true),'Original black-hole singularity halo missing')
local sourceDirection=template:GetAttribute('SourceViewDirection') or Vector3.new(1,-.09,0)
local sourceObservation=CFrame.lookAt(halo.CFrame.Position,halo.CFrame.Position+sourceDirection)
local observationToPivot=sourceObservation:ToObjectSpace(base)
local orbit={};local flares={}
local function pivot(object,cf)
 if object:IsA('Model') then object:PivotTo(cf) else object.CFrame=cf end
end
local field=model:FindFirstChild('DebrisField')
local spinner;local shardBones={}
if field and field:FindFirstChildWhichIsA('Bone',true) then
 -- The original debris is one skinned mesh: retain its authored bones and shapes.
 local _,size=field:GetBoundingBox();local maximum=math.max(size.X,size.Y,size.Z)
 local maxDebris=menu and 85 or 420
 if maximum>maxDebris then field:ScaleTo(field:GetScale()*maxDebris/maximum) end
 local orientation=base:ToObjectSpace(field:GetPivot()).Rotation
 field:PivotTo(base*orientation)
 spinner=field:FindFirstChild('spinner',true)
 for _,d in ipairs(field:GetDescendants()) do
  if d:IsA('Bone') and d.Name:match('^%d+$') and #shardBones<(touch and 12 or 32) then table.insert(shardBones,d) end
 end
elseif field then
 local index=0
 for _,object in ipairs(field:GetChildren()) do
  if object:IsA('Model') or object:IsA('BasePart') then
   local part=object:IsA('BasePart') and object or object:FindFirstChildWhichIsA('BasePart',true)
   if part then
    index+=1
    local original=object:IsA('Model') and object:GetPivot() or object.CFrame
    local rotation=base:ToObjectSpace(original).Rotation
    local angle=index*2.399963
    local radius=(menu and 35 or 140)+(index*37)%(menu and 30 or 90)
    local pos=Vector3.new(math.cos(angle)*radius,math.sin(index*1.7)*48,math.sin(angle)*radius)
    local localCF=CFrame.new(pos)*rotation
    pivot(object,base*localCF)
    table.insert(orbit,{object=object,cf=localCF,speed=(menu and .009 or .012)+(index%7)*(menu and .002 or .003),phase=angle,animated=index<=(touch and 24 or 48)})
   end
  end
 end
end

for _,d in ipairs(model:GetDescendants()) do
 if d:IsA('BasePart') then d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.CastShadow=false end
 if d:IsA('ParticleEmitter') then
  d.Rate=math.min(d.Rate,menu and 26 or (touch and 24 or 60))
 end
 if d:IsA('Light') then
  d.Shadows=false
  d.Range=math.min(d.Range,menu and 100 or 30)
 end
 -- Preserve the original Beams and BillboardGui elements of the singularity.
 -- Disabling all world GUIs removed part of the authored accretion glow.
 if d:IsA('BillboardGui') then table.insert(flares,{gui=d,enabled=d.Enabled}) end
end
local time,clock,occlusion=0,0,0
local blastStarted
local blastBall
local blastRings={}
local function localBurst()
 if blastStarted then return end
 blastStarted=os.clock()
 blastBall=Instance.new('Part')
 blastBall.Name='LocalSingularityBurst'
 blastBall.Shape=Enum.PartType.Ball
 blastBall.Material=Enum.Material.Neon
 blastBall.Color=Color3.fromRGB(187,213,244)
 blastBall.Transparency=.42
 blastBall.Anchored=true
 blastBall.CanCollide=false;blastBall.CanQuery=false;blastBall.CanTouch=false
 blastBall.Size=Vector3.new(2,2,2)
 blastBall.Parent=W
 for i=1,2 do
  local ring=Instance.new('Part')
  ring.Name='LocalBlackHoleShockwave'
  ring.Shape=Enum.PartType.Cylinder
  ring.Material=Enum.Material.Neon
  ring.Color=i==1 and Color3.fromRGB(157,189,233) or Color3.fromRGB(247,217,160)
  ring.Transparency=.25
  ring.Anchored=true;ring.CanCollide=false;ring.CanQuery=false;ring.CanTouch=false
  ring.Parent=W
  table.insert(blastRings,ring)
 end
end
player:GetAttributeChangedSignal('MenuCameraMode'):Connect(function()
 if menu and player:GetAttribute('MenuCameraMode')=='starting' then localBurst() end
end)
if menu and player:GetAttribute('MenuCameraMode')=='starting' then localBurst() end
Run.RenderStepped:Connect(function(dt)
 clock+=dt;occlusion+=dt;time+=math.min(dt,.12)
 local camera=W.CurrentCamera;if not camera then return end
 local center
 if menu then
  local aspect=math.max(camera.ViewportSize.X,1)/math.max(camera.ViewportSize.Y,1)
  -- Compose the original hole just left of the swimmer. Keep its beams/disk
  -- at their original angles relative to the viewer from the source place.
  local fov=math.rad(camera.FieldOfView)
  local y=math.tan(fov*.5)*distance
  local x=y*aspect
  center=camera.CFrame.Position
   +camera.CFrame.LookVector*distance
   -camera.CFrame.RightVector*(x*.20)
   +camera.CFrame.UpVector*(y*.10)
  local targetObservation=CFrame.lookAt(center,camera.CFrame.Position,camera.CFrame.UpVector)
  base=targetObservation*observationToPivot
 else
  center=camera.CFrame.Position+offset
  base=CFrame.lookAt(center,camera.CFrame.Position)
 end
 model:PivotTo(base)
 if menu and blastStarted then
  local progress=math.clamp((os.clock()-blastStarted)/1.25,0,1)
  if blastBall then
   blastBall.CFrame=CFrame.new(center)
   local size=5+progress*220
   blastBall.Size=Vector3.new(size,size,size)
   blastBall.Transparency=math.clamp(.52+progress*.48,0,1)
  end
  for i,ring in ipairs(blastRings) do
   local t=math.clamp((progress-(i-1)*.18)/.82,0,1)
   local width=10+t*250
   ring.Size=Vector3.new(1.2,width,width)
   ring.CFrame=CFrame.lookAt(center,camera.CFrame.Position)*CFrame.Angles(0,0,t*1.5)
   ring.Transparency=.28+t*.72
  end
  if progress>=1 then
   if blastBall then blastBall:Destroy();blastBall=nil end
   for _,ring in ipairs(blastRings) do ring:Destroy() end
   table.clear(blastRings)
  end
 end
 if clock<1/24 then return end
 clock=0
 if spinner and spinner:IsA('Bone') then spinner.Transform=CFrame.Angles(0,time*(menu and .018 or .018),0) end
 for i,bone in ipairs(shardBones) do bone.Transform=CFrame.Angles(time*((menu and .015 or .018)+i%4*(menu and .003 or .003)),time*(menu and .010 or .012),time*(menu and .008 or .009)) end
 for _,state in ipairs(orbit) do if state.animated then
  local spin=CFrame.Angles(0,time*state.speed,0)
  pivot(state.object,base*spin*state.cf*CFrame.Angles(time*(menu and .006 or .018),0,time*(menu and .004 or .012)))
 end end
 if occlusion>.25 then
  occlusion=0
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.IgnoreWater=true
  local exclude={model};if player.Character then table.insert(exclude,player.Character) end;params.FilterDescendantsInstances=exclude
  local blocked=not menu and W:Raycast(camera.CFrame.Position,center-camera.CFrame.Position,params)~=nil
  for _,f in ipairs(flares) do if f.gui.Parent then f.gui.Enabled=f.enabled and not blocked end end
 end
end)
