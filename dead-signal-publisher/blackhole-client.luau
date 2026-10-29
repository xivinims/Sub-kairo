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
local distance=450
model:ScaleTo(math.clamp(distance/reference,.12,.7))
model.Parent=W
local touch=UIS.TouchEnabled
local offset=Vector3.new(-.36,.49,-.79).Unit*distance
local base=model:GetPivot()
local orbit={};local flares={}
local function pivot(object,cf)
 if object:IsA('Model') then object:PivotTo(cf) else object.CFrame=cf end
end
local field=model:FindFirstChild('DebrisField')
if field then
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
    table.insert(orbit,{object=object,cf=localCF,speed=.012+(index%7)*.003,phase=angle,animated=index<=(touch and 24 or 48)})
   end
  end
 end
end
for _,d in ipairs(model:GetDescendants()) do
 if d:IsA('BasePart') then d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.CastShadow=false end
 if d:IsA('ParticleEmitter') then d.Rate=math.min(d.Rate,touch and 24 or 60) end
 if d:IsA('Light') then d.Shadows=false;d.Range=math.min(d.Range,30) end
 if d:IsA('BillboardGui') then table.insert(flares,{gui=d,enabled=d.Enabled}) end
end
local time,clock,occlusion=0,0,0
Run.RenderStepped:Connect(function(dt)
 clock+=dt;occlusion+=dt
 if clock<1/20 then return end
 local camera=W.CurrentCamera;if not camera then return end
 local step=math.min(clock,.2);clock=0;time+=step
 local center=camera.CFrame.Position+offset
 base=CFrame.lookAt(center,camera.CFrame.Position)
 model:PivotTo(base)
 for _,state in ipairs(orbit) do if state.animated then
  local spin=CFrame.Angles(0,time*state.speed,0)
  pivot(state.object,base*spin*state.cf*CFrame.Angles(time*.018,0,time*.012))
 end end
 if occlusion>.25 then
  occlusion=0
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.IgnoreWater=true
  local exclude={model};if player.Character then table.insert(exclude,player.Character) end;params.FilterDescendantsInstances=exclude
  local blocked=W:Raycast(camera.CFrame.Position,center-camera.CFrame.Position,params)~=nil
  for _,f in ipairs(flares) do if f.gui.Parent then f.gui.Enabled=f.enabled and not blocked end end
 end
end)
