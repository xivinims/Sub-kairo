-- Exact map requested by the user. Imported detached; no source code, audio or interactions survive.
local testMap,mapReport=Importer.Load({id=18509954401,importMode="static",stripScripts=true})
testMap.Name="PoppyTestMap"
for _,d in ipairs(testMap:GetDescendants()) do
    if d:IsA("Sound") or d:IsA("Animation") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("PackageLink") or d:IsA("Humanoid") or d:IsA("AnimationController") then d:Destroy()
    elseif d:IsA("BasePart") then
        d.Anchored=true; d.CanTouch=false
        if d:IsA("MeshPart") then d.RenderFidelity=Enum.RenderFidelity.Performance end
        if d:IsA("TriangleMeshPart") then pcall(function() d.CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition end) end
    elseif d:IsA("Light") then d:SetAttribute("PowerBrightness",d.Brightness); d.Enabled=false; d.Shadows=false
    elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=false end
end
-- Preserve authored orientation; move the audited main floor down to the world origin.
local anchor=Vector3.new(24.8521824,141.9106909,1.5578613)
testMap:PivotTo(CFrame.new(-anchor)*testMap:GetPivot())
testMap:SetAttribute("SourceAssetId",18509954401)
testMap:SetAttribute("RemovedExternalScripts",mapReport.removedScripts)
testMap.Parent=W
local mapParams=RaycastParams.new(); mapParams.FilterType=Enum.RaycastFilterType.Include; mapParams.FilterDescendantsInstances={testMap}; mapParams.RespectCanCollide=true
local candidates={}
for x=-64,64,16 do
    for z=-80,80,16 do
        local hit=W:Raycast(Vector3.new(x,12,z),Vector3.new(0,-25,0),mapParams)
        if hit and hit.Normal.Y>0.85 and math.abs(hit.Position.Y)<5 then
            local up=W:Blockcast(CFrame.new(hit.Position+Vector3.new(0,0.4,0)),Vector3.new(3.6,0.2,3.6),Vector3.new(0,17,0),mapParams)
            if not up then table.insert(candidates,hit.Position) end
        end
    end
end
assert(#candidates>=8,"No safe, tall test area in requested map")
local spawnPoint,monsterPoint
for _,a in ipairs(candidates) do
    for _,b in ipairs(candidates) do
        local delta=b-a
        if delta.Magnitude>28 and delta.Magnitude<42 and math.abs(delta.Y)<1 then
            local block=W:Blockcast(CFrame.new(a+Vector3.new(0,8.5,0)),Vector3.new(3.6,15,3.6),delta,mapParams)
            if not block then spawnPoint=a; monsterPoint=b; break end
        end
    end
    if spawnPoint then break end
end
assert(spawnPoint and monsterPoint,"No connected spawn/monster corridor")
local markers=Instance.new("Folder"); markers.Name="TestNavigation"; markers.Parent=W
local function marker(name,pos)
 local p=part(name,Vector3.new(0.2,0.2,0.2),CFrame.new(pos)); p.CanCollide=false; p.CanQuery=false; p.Transparency=1; p.Parent=markers; return p
end
marker("SpawnGround",spawnPoint); marker("MonsterGround",monsterPoint)
local count=0
for _,point in ipairs(candidates) do
 if (point-monsterPoint).Magnitude>10 and (point-monsterPoint).Magnitude<50 then
  local delta=point-monsterPoint
  if not W:Blockcast(CFrame.new(monsterPoint+Vector3.new(0,8.5,0)),Vector3.new(3.6,15,3.6),delta,mapParams) then count+=1; marker("Patrol"..count,point) end
 end
 if count>=6 then break end
end
assert(count>=1,"No usable patrol route")
-- Add only functional lighting to the audited open test area; nearby lamps activate locally.
local lightFolder=Instance.new("Folder"); lightFolder.Name="TestPowerLights"; lightFolder.Parent=W
local lightPoints={spawnPoint,monsterPoint}
for _,point in ipairs(candidates) do
 local separated=true
 for _,existing in ipairs(lightPoints) do if (existing-point).Magnitude<27 then separated=false; break end end
 if separated and #lightPoints<14 then table.insert(lightPoints,point) end
end
for i,point in ipairs(lightPoints) do
 local ceiling=W:Raycast(point+Vector3.new(0,2,0),Vector3.new(0,35,0),mapParams)
 local h=ceiling and ceiling.Position.Y-0.3 or point.Y+16
 local housing=part("PowerLuminaire"..i,Vector3.new(3,0.3,1),CFrame.new(point.X,h,point.Z)); housing.CanCollide=false; housing.CanQuery=false; housing.Parent=lightFolder
 housing.Color=Color3.fromRGB(214,203,168)
 local light=Instance.new("PointLight"); light.Name="PowerLight"; light.Brightness=1.8; light.Range=35; light.Color=Color3.fromRGB(238,222,180); light.Enabled=false; light.Shadows=false; light.Parent=housing
end
local delta=monsterPoint-spawnPoint
local side=Vector3.new(-delta.Z,0,delta.X).Unit
local switchPosition=spawnPoint+side*5
if W:Blockcast(CFrame.new(spawnPoint+Vector3.new(0,2,0)),Vector3.new(1,3,1),side*5,mapParams) then switchPosition=spawnPoint-side*5 end
local pedestal=part("PowerSwitchBase",Vector3.new(2,2.2,1.4),CFrame.new(switchPosition+Vector3.new(0,1.1,0)))
pedestal.Color=Color3.fromRGB(52,65,65)
local switch=part("TestPowerSwitch",Vector3.new(1.6,1,1.2),CFrame.new(switchPosition+Vector3.new(0,2.7,0)))
switch.Color=Color3.fromRGB(139,107,44); switch:SetAttribute("Powered",false)
local prompt=Instance.new("ProximityPrompt"); prompt.Name="PowerPrompt"; prompt.ActionText="Ligar energia"; prompt.ObjectText="Quadro elétrico"; prompt.KeyboardKeyCode=Enum.KeyCode.F; prompt.HoldDuration=0.35; prompt.MaxActivationDistance=9; prompt.RequiresLineOfSight=true; prompt.Parent=switch
W:SetAttribute("PowerOn",false); W:SetAttribute("PowerFlickering",false); W:SetAttribute("TestMapAssetId",18509954401)
