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
local distance=900
model:ScaleTo(math.clamp(500/reference,.12,.7))
model.Parent=W
local touch=UIS.TouchEnabled
-- In menus, reserve the visible center-right sky for the actual accretion disk.
-- This is a real mesh from the original asset, not a painted halo or a UI picture.
-- Right-side menus and the floating avatar are separate UI layers.
local offset=Vector3.new(-.36,.49,-.79).Unit*distance
local base=model:GetPivot()
local halo=assert(model:FindFirstChild('Halo',true),'Original black-hole singularity halo missing')
local haloToPivot=halo.CFrame:ToObjectSpace(base)
local orbit={};local flares={}
local function pivot(object,cf)
 if object:IsA('Model') then object:PivotTo(cf) else object.CFrame=cf end
end
local field=model:FindFirstChild('DebrisField')
local spinner;local shardBones={}
if field and field:FindFirstChildWhichIsA('Bone',true) then
 -- The original debris is one skinned mesh: retain its authored bones and shapes.
 local _,size=field:GetBoundingBox();local maximum=math.max(size.X,size.Y,size.Z)
 if maximum>420 then field:ScaleTo(field:GetScale()*420/maximum) end
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
    local radius=140+(index*37)%90
    local pos=Vector3.new(math.cos(angle)*radius,math.sin(index*1.7)*48,math.sin(angle)*radius)
    local localCF=CFrame.new(pos)*rotation
    pivot(object,base*localCF)
    table.insert(orbit,{object=object,cf=localCF,speed=(menu and .004 or .012)+(index%7)*(menu and .001 or .003),phase=angle,animated=index<=(touch and 24 or 48)})
   end
  end
 end
end

for _,d in ipairs(model:GetDescendants()) do
 if d:IsA('BasePart') then d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.CastShadow=false end
 if d:IsA('ParticleEmitter') then
  d.Rate=math.min(d.Rate,menu and 6 or (touch and 24 or 60))
  if menu then d.LightEmission=math.min(d.LightEmission,.15) end
 end
 if d:IsA('Light') then
  d.Shadows=false
  d.Range=math.min(d.Range,menu and 12 or 30)
  if menu then d.Brightness=math.min(d.Brightness,.3) end
 end
 if d:IsA('Beam') and menu then
  -- Keep the original rays, but stop them washing out the dark center.
  d.Brightness=math.min(d.Brightness,.35)
  d.LightEmission=math.min(d.LightEmission,.14)
 end
 if d:IsA('BillboardGui') then
  -- Original lens flares are much larger than the disk at menu camera distance.
  table.insert(flares,{gui=d,enabled=not menu and d.Enabled})
  if menu then d.Enabled=false end
 end
end
local time,clock,occlusion=0,0,0
Run.RenderStepped:Connect(function(dt)
 clock+=dt;occlusion+=dt
 if clock<1/20 then return end
 local camera=W.CurrentCamera;if not camera then return end
 local step=math.min(clock,.2);clock=0;time+=step
 local center
 if menu then
  local aspect=math.max(camera.ViewportSize.X,1)/math.max(camera.ViewportSize.Y,1)
  -- Target upper-left, above the player's torso, rather than directly behind it.
  -- Use camera axes so this composition is independent of the source asset's world coordinates.
  local fov=math.rad(camera.FieldOfView)
  local y=math.tan(fov*.5)*distance
  local x=y*aspect
  center=camera.CFrame.Position
   +camera.CFrame.LookVector*distance
   -camera.CFrame.RightVector*(x*.14)
   +camera.CFrame.UpVector*(y*.12)
  -- Force the original Halo mesh to face the menu camera so its dark
  -- singularity and accretion disc stay visible instead of edge-on glare.
  local targetHalo=CFrame.lookAt(center,camera.CFrame.Position,camera.CFrame.UpVector)
  base=targetHalo*haloToPivot
 else
  center=camera.CFrame.Position+offset
  base=CFrame.lookAt(center,camera.CFrame.Position)
 end
 model:PivotTo(base)
 if spinner and spinner:IsA('Bone') then spinner.Transform=CFrame.Angles(0,time*(menu and .005 or .018),0) end
 for i,bone in ipairs(shardBones) do bone.Transform=CFrame.Angles(time*((menu and .004 or .018)+i%4*(menu and .001 or .003)),time*(menu and .004 or .012),time*(menu and .003 or .009)) end
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
