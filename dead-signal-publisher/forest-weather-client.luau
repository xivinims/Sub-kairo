local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local SoundService=game:GetService("SoundService")
local Workspace=game:GetService("Workspace")
local rng=Random.new()

local effects=Instance.new("Folder");effects.Name="ForestWeatherLocal"
effects.Parent=Workspace.CurrentCamera or Workspace
local drops={}
local swayTrees={}
local swayClock=0
local function trackTree(tree)
 if not tree:IsA("Model") or swayTrees[tree] then return end
 local trunk=tree:FindFirstChild("TreeCollisionTrunk")
 if not trunk then return end
 local pivot=tree:GetPivot()
 local bottom=Vector3.new(trunk.Position.X,trunk.Position.Y-trunk.Size.Y*.5,trunk.Position.Z)
 local base=CFrame.new(bottom)
 swayTrees[tree]={pivot=pivot,base=base,relative=base:ToObjectSpace(pivot),phase=rng:NextNumber(0,math.pi*2),moving=false}
end
task.spawn(function()
 local map=Workspace:WaitForChild("OvergrownAtrium",45)
 local pines=map and map:WaitForChild("Pines",15)
 if not pines then return end
 for _,tree in ipairs(pines:GetChildren()) do trackTree(tree) end
 pines.ChildAdded:Connect(function(tree) task.defer(trackTree,tree) end)
end)
local raining=false
local lastCamera=Workspace.CurrentCamera
local dropCount=560
local atmosphere=Lighting:FindFirstChild("ForestAerialPerspective")
local grade=Lighting:FindFirstChild("ForestGoldenGrade")
local clouds=Workspace.Terrain:FindFirstChild("WoodlandCloudDeck")
local flash=Instance.new("ColorCorrectionEffect");flash.Name="ForestLightningFlash";flash.Brightness=0;flash.Contrast=.08;flash.TintColor=Color3.fromRGB(229,239,255);flash.Parent=Lighting

local rainBed=Instance.new("Sound");rainBed.Name="ForestRainAndThunder";rainBed.SoundId="rbxassetid://9120020741"
rainBed.Volume=.27;rainBed.Looped=true;rainBed.Parent=SoundService
local thunder=Instance.new("Sound");thunder.Name="ForestDistantThunder";thunder.SoundId="rbxassetid://3627353508"
thunder.Volume=.65;thunder.RollOffMode=Enum.RollOffMode.InverseTapered;thunder.Parent=SoundService
local sfx=SoundService:FindFirstChild("SFX")
if sfx and sfx:IsA("SoundGroup") then rainBed.SoundGroup=sfx;thunder.SoundGroup=sfx end

local function randomOffset()
 return Vector3.new(rng:NextNumber(-100,100),rng:NextNumber(18,94),rng:NextNumber(-100,100))
end

local function addDrop()
 local p=Instance.new("Part");p.Name="RainStreak";p.Size=Vector3.new(.025,rng:NextNumber(2.4,4.4),.025)
 p.Color=Color3.fromRGB(202,215,229);p.Material=Enum.Material.SmoothPlastic;p.Transparency=.38
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=effects
 table.insert(drops,{part=p,offset=randomOffset(),length=p.Size.Y})
end

local function positionDrop(drop,camera,dt)
 local wind=Workspace.GlobalWind
 local velocity=Vector3.new(-wind.X*.38,-118,-wind.Z*.38)
 drop.offset+=velocity*dt
 if drop.offset.Y < -26 then drop.offset=randomOffset() end
 if math.abs(drop.offset.X)>112 or math.abs(drop.offset.Z)>112 then
  drop.offset=Vector3.new(rng:NextNumber(-100,100),rng:NextNumber(28,92),rng:NextNumber(-100,100))
 end
 local center=camera.CFrame.Position+drop.offset
 drop.part.CFrame=CFrame.lookAt(center,center+velocity)*CFrame.Angles(-math.pi/2,0,0)
end

local function startRain()
 if raining then return end
 raining=true
 effects.Parent=Workspace.CurrentCamera or Workspace
 for i=1,dropCount do addDrop() end
 if not rainBed.IsPlaying then rainBed:Play() end
 local info=TweenInfo.new(7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
 if atmosphere then TweenService:Create(atmosphere,info,{Density=.36,Haze=3.1,Color=Color3.fromRGB(185,198,211),Decay=Color3.fromRGB(103,117,130)}):Play() end
 if clouds then TweenService:Create(clouds,info,{Cover=.76,Density=.82,Color=Color3.fromRGB(169,180,192)}):Play() end
 if grade then TweenService:Create(grade,info,{Saturation=-.17,Contrast=.11,TintColor=Color3.fromRGB(211,220,232)}):Play() end
end

local function stopRain()
 if not raining then return end
 raining=false
 for _,drop in ipairs(drops) do drop.part:Destroy() end
 table.clear(drops)
 rainBed:Stop()
 local info=TweenInfo.new(10,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
 if atmosphere then TweenService:Create(atmosphere,info,{Density=.29,Haze=2.25,Color=Color3.fromRGB(220,207,172),Decay=Color3.fromRGB(140,148,111)}):Play() end
 if clouds then TweenService:Create(clouds,info,{Cover=.43,Density=.62,Color=Color3.fromRGB(241,229,202)}):Play() end
 if grade then TweenService:Create(grade,info,{Saturation=-.045,Contrast=.09,TintColor=Color3.fromRGB(255,245,218)}):Play() end
end

local function makeBolt(a,b)
 local direction=b-a
 local length=direction.Magnitude
 if length<.1 then return end
 local dir=direction.Unit
 local reference=math.abs(dir:Dot(Vector3.new(0,1,0)))>.94 and Vector3.new(1,0,0) or Vector3.new(0,1,0)
 local yAxis=(reference-dir*reference:Dot(dir)).Unit
 local zAxis=dir:Cross(yAxis).Unit
 local segment=Instance.new("Part");segment.Name="DistantLightning";segment.Shape=Enum.PartType.Cylinder
 segment.Size=Vector3.new(length,.16,.16);segment.Material=Enum.Material.Neon;segment.Color=Color3.fromRGB(226,239,255)
 segment.Anchored=true;segment.CanCollide=false;segment.CanTouch=false;segment.CanQuery=false;segment.CastShadow=false
 segment.CFrame=CFrame.fromMatrix((a+b)*.5,dir,yAxis,zAxis);segment.Parent=effects
 return segment
end

local function lightningStrike()
 if not raining then return end
 local camera=Workspace.CurrentCamera
 if not camera then return end
 local lateral=rng:NextNumber(-110,110)
 local distance=rng:NextNumber(205,390)
 local aim=camera.CFrame.Position+camera.CFrame.LookVector*distance+camera.CFrame.RightVector*lateral
 local x=math.clamp(aim.X,-940,940);local z=math.clamp(aim.Z,-940,940)
 local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Include;rayParams.FilterDescendantsInstances={Workspace.Terrain}
 local hit=Workspace:Raycast(Vector3.new(x,150,z),Vector3.new(0,-280,0),rayParams)
 if not hit then return end
 local top=hit.Position+Vector3.new(0,rng:NextNumber(115,165),0)
 local points={top}
 for i=1,7 do
  local t=i/8
  table.insert(points,top:Lerp(hit.Position+Vector3.new(0,3,0),t)+Vector3.new(rng:NextNumber(-15,15),0,rng:NextNumber(-13,13)))
 end
 table.insert(points,hit.Position+Vector3.new(0,3,0))
 local bolts={}
 for i=1,#points-1 do table.insert(bolts,makeBolt(points[i],points[i+1])) end
 flash.Brightness=.9
 task.delay(.075,function() if flash.Parent then flash.Brightness=.14 end end)
 task.delay(.14,function() if flash.Parent then flash.Brightness=.72 end end)
 task.delay(.23,function() if flash.Parent then flash.Brightness=0 end end)
 task.delay(math.clamp(distance/343,.35,1.65),function()
  if raining and thunder.Parent then thunder.Volume=math.clamp(1.05-distance/560,.22,.7);thunder:Play() end
 end)
 task.delay(.48,function() for _,p in ipairs(bolts) do if p and p.Parent then p:Destroy() end end end)
end

local function applyWeather()
 local state=Workspace:GetAttribute("ForestWeather")
 if state=="Storm" then startRain() else stopRain() end
end
Workspace:GetAttributeChangedSignal("ForestWeather"):Connect(applyWeather)
local lastLightning=Workspace:GetAttribute("ForestLightningCue") or 0
Workspace:GetAttributeChangedSignal("ForestLightningCue"):Connect(function()
  local cue=Workspace:GetAttribute("ForestLightningCue") or 0
  if cue~=lastLightning then lastLightning=cue;lightningStrike() end
end)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 lastCamera=Workspace.CurrentCamera
 effects.Parent=lastCamera or Workspace
end)
RunService.Heartbeat:Connect(function(dt)
 if raining then
  local camera=Workspace.CurrentCamera
  if camera~=lastCamera then lastCamera=camera;effects.Parent=camera or Workspace end
  if camera then
   local step=math.min(dt,.05)
   for _,drop in ipairs(drops) do positionDrop(drop,camera,step) end
  end
 end
 swayClock+=dt
 if swayClock>=.2 then
  local camera=Workspace.CurrentCamera
  if camera then
   local wind=Workspace.GlobalWind
   local horizontal=Vector3.new(wind.X,0,wind.Z)
   local axis=horizontal.Magnitude>.05 and Vector3.new(-horizontal.Z,0,horizontal.X).Unit or Vector3.new(1,0,0)
   local strength=.004+math.clamp(horizontal.Magnitude/10,0,1.4)*.008
   local time=os.clock()
   for tree,state in pairs(swayTrees) do
    if not tree.Parent then swayTrees[tree]=nil
    elseif (tree:GetPivot().Position-camera.CFrame.Position).Magnitude<460 then
     local angle=math.sin(time*.72+state.phase)*strength
     tree:PivotTo(state.base*CFrame.fromAxisAngle(axis,angle)*state.relative)
     state.moving=true
    elseif state.moving then
     tree:PivotTo(state.pivot);state.moving=false
    end
   end
  end
  swayClock=0
 end
end)
applyWeather()
