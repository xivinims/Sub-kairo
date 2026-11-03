assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==82,"Published version changed")
local world=workspace.IlhaSerena assert(world:GetAttribute("UpgradeVersion")==82,"Wrong island baseline")
local runtime=game.ReplicatedStorage.SerenaRuntime
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)local s=Instance.new(class)s.Name=name s.Source=code
 if old then for _,child in ipairs(old:GetChildren())do child.Parent=s end old:Destroy()end
 s.Parent=parent return s
end
local function run(code)
 local m=Instance.new("ModuleScript")m.Name="Stage83"m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage
 local result=require(m)()m:Destroy()return result
end
local function module(code)
 local m=Instance.new("ModuleScript")m.Name="Factory83"m.Source=code m.Parent=game.ServerStorage
 local result=require(m)m:Destroy()return result
end

source(runtime,"ModuleScript","Climate",[========[-- Four environment presets share these native lighting and wind effects.
local Climate={TransitionSeconds=.8}
function Climate.profile(hour,rain,clear,now)
 local sun=math.clamp((math.sin((hour-6)/24*math.pi*2)+.13)/1.13,0,1)
 local sunset=math.clamp(1-math.abs(hour-17.65)/1.8,0,1)
 local dawn=math.clamp(1-math.abs(hour-6.2)/1.5,0,1)
 local warm=math.max(sunset,dawn*.65)
 local gust=1+.17*math.sin(now*.39)+.09*math.sin(now*.91)
 local wind=Vector3.new(5+rain*10,0,2+rain*5)*gust
 local p={sun=sun,rain=rain,clear=clear,warm=warm,wind=wind}
 p.brightness=.85+sun*(1.7+clear*.75-rain*.25)
 p.ambient=Color3.fromRGB(52,63,83):Lerp(Color3.fromRGB(102,114,120),sun)
 p.outdoor=Color3.fromRGB(70,83,107):Lerp(Color3.fromRGB(148,162,166),sun)
 p.atmosphere=Color3.fromRGB(189,215,233):Lerp(Color3.fromRGB(245,186,134),warm*.75)
 p.decay=Color3.fromRGB(104,139,162):Lerp(Color3.fromRGB(163,100,73),warm*.7)
 p.density=.23+(1-clear)*.045+rain*.055
 p.haze=.9+(1-clear)*.45+rain*.9
 p.cover=.2+(1-clear)*.37+rain*.21
 p.cloudDensity=.32+rain*.28
 p.cloudColor=Color3.fromRGB(246,248,244):Lerp(Color3.fromRGB(145,161,176),rain):Lerp(Color3.fromRGB(255,208,169),warm*.25)
 p.rays=(.026+.065*clear)*math.max(sun,dawn*.9,sunset*.8)*(1-rain*.85)
 p.waterColor=Color3.fromRGB(36,138,153):Lerp(Color3.fromRGB(61,111,132),rain*.7)
 p.waveSize=.32+rain*.28 p.waveSpeed=12+rain*9
 return p
end
function Climate.apply(lighting,terrain,profile)
 local p=profile
 lighting.ClockTime=p.hour or lighting.ClockTime
 lighting.GlobalShadows=true lighting.Brightness=p.brightness lighting.ExposureCompensation=.08
 lighting.EnvironmentDiffuseScale=.75 lighting.EnvironmentSpecularScale=1 lighting.ShadowSoftness=.25
 lighting.Ambient=p.ambient lighting.OutdoorAmbient=p.outdoor
 lighting.ColorShift_Top=Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(98,44,19),p.warm)
 local atmosphere=lighting:FindFirstChild("SerenaAtmosphere")
 if atmosphere then atmosphere.Color=p.atmosphere atmosphere.Decay=p.decay atmosphere.Density=p.density atmosphere.Haze=p.haze atmosphere.Glare=p.clear*.22*p.sun end
 local grade=lighting:FindFirstChild("SerenaColor")
 if grade then grade.Contrast=.105 grade.Saturation=.16-p.rain*.12 grade.Brightness=.012 grade.TintColor=Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(255,224,200),p.warm*.25) end
 local bloom=lighting:FindFirstChild("SerenaBloom")
 if bloom then bloom.Enabled=true bloom.Intensity=.19 bloom.Threshold=1.05 bloom.Size=28 end
 local rays=lighting:FindFirstChild("SerenaSunRays")
 if rays then rays.Enabled=true rays.Intensity=p.rays rays.Spread=.78 end
 local clouds=terrain:FindFirstChild("SerenaClouds")
 if clouds then clouds.Cover=p.cover clouds.Density=p.cloudDensity clouds.Color=p.cloudColor end
 terrain.WaterColor=p.waterColor terrain.WaterTransparency=.44 terrain.WaterReflectance=.38
 terrain.WaterWaveSize=p.waveSize terrain.WaterWaveSpeed=p.waveSpeed
 workspace.GlobalWind=p.wind
end
function Climate.rendering(lighting)
 -- A renderer capability failure must not stop rain, grass, time or controls.
 local style=pcall(function()lighting.LightingStyle=Enum.LightingStyle.Realistic end)
 local quality=pcall(function()lighting.PrioritizeLightingQuality=true end)
 return style and quality
end
return Climate
]========])

source(runtime,"ModuleScript","PersonalClimate",[========[-- One local choice replaces the separate time/weather selectors.
local Personal={Default="Dia",Order={"Dia","Noite","Anoitecer","Chuva"},
 Modes={
  Dia={hour=12,rain=0,clear=1,label="Dia",description="Céu claro e brisa"},
  Noite={hour=23,rain=0,clear=1,label="Noite",description="Luzes acesas e brisa"},
  Anoitecer={hour=18.3,rain=0,clear=1,label="Anoitecer",description="Luz do fim do dia e brisa"},
  Chuva={hour=15.2,rain=1,clear=0,label="Chuva",description="Nuvens, chuva e vento"},
 }}
function Personal.resolve(choice)
 local key=Personal.Modes[choice]and choice or Personal.Default
 local mode=Personal.Modes[key]
 return mode.hour,mode.rain,mode.clear,key
end
return Personal
]========])

local grass=module([========[local function switch(world,runtime)
 local templates=runtime.SkinnedGrassTemplates
 local previous=templates.FineStudio
 local active=templates.AlternateGrassCard:Clone()active.Name="GrassCard"
 local mesh=active:FindFirstChildOfClass("MeshPart")
 assert(mesh and mesh.MeshId=="rbxassetid://117152506140384","Alternate GrassCard model missing")
 mesh.CFrame=CFrame.identity active.PrimaryPart=nil active.WorldPivot=CFrame.identity active:ScaleTo(.32)
 local oldMesh=previous:FindFirstChildOfClass("MeshPart")local oldBones={}local newBones={}
 for _,b in ipairs(oldMesh:GetChildren())do if b:IsA("Bone")then oldBones[b.Name]=b end end
 local count=0
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then
  local old=assert(oldBones[b.Name],"Grass root names changed")
  assert((b.CFrame.Position-old.CFrame.Position).Magnitude<.0001,"GrassCard roots require a new terrain mask")
  newBones[b.Name]=b count+=1
 end end
 assert(count==100,"GrassCard skeleton incomplete")
 local color=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
 mesh.Anchored=true mesh.CanCollide=false mesh.CanQuery=false mesh.CanTouch=false mesh.CastShadow=false mesh.Color=color
 local appearance=mesh:FindFirstChildOfClass("SurfaceAppearance")
 assert(appearance and appearance.AlphaMode==Enum.AlphaMode.Transparency,"Transparent grass-card appearance missing")
 appearance.Color=color
 for _,d in ipairs(active:GetDescendants())do
  if d:IsA("LuaSourceContainer")then d:Destroy()
  elseif d:IsA("Decal")or d:IsA("Texture")then d.Color3=color end
 end
 active:SetAttribute("SourceAssetId",87377915371959)active:SetAttribute("SourceVariant","GrassCard")
 active:SetAttribute("MatchesTerrainGrass",true)active:SetAttribute("RootSpan",previous:GetAttribute("RootSpan"))
 for _,m in ipairs(templates:GetChildren())do m:Destroy()end active.Parent=templates
 world:SetAttribute("GrassVariant","GrassCard")world:SetAttribute("GrassColor",color)
 world:SetAttribute("GrassMatchesTerrain",true)
 return {assetId=87377915371959,variant="GrassCard",meshId=mesh.MeshId,
 color={math.floor(color.R*255+.5),math.floor(color.G*255+.5),math.floor(color.B*255+.5)},
 rootLayoutPreserved=true,spacing=runtime.GrassCoverage:GetAttribute("Spacing"),
 patches=runtime.GrassCoverage:GetAttribute("PatchCount"),greenRoots=runtime.GrassCoverage:GetAttribute("RootCount"),
 transparentPBRPreserved=true}
end
return switch
]========])(world,runtime)

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaGrassClient",[========[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("SerenaRuntime")local player=Players.LocalPlayer
local Codec=require(runtime:WaitForChild("GrassCodec"))local Field=require(runtime:WaitForChild("GrassField"))
local SkinnedGrass=require(runtime:WaitForChild("SkinnedGrass"))
local coverage=runtime:WaitForChild("GrassCoverage")local field=Field.new(coverage)
local template=runtime:WaitForChild("SkinnedGrassTemplates"):WaitForChild("GrassCard")
local visible=Instance.new("Folder")visible.Name="SerenaInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="SerenaGrassLocalStorage"storage.Parent=RS
local radius=coverage:GetAttribute(UIS.TouchEnabled and"NearRadiusTouch"or"NearRadiusDesktop")
local maxActive=coverage:GetAttribute(UIS.TouchEnabled and"MaxActiveTouch"or"MaxActiveDesktop")
local keepRadius=radius+6
local grass=SkinnedGrass.new({RenderDistanceEnabled=false,MeshStorage=storage,
 CollisionDistance=30,CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionAngle=68,
 CollisionReturnDelay=.08,CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=UIS.TouchEnabled and 12 or 20,WindDistanceOuter=UIS.TouchEnabled and 32 or 48,
 WindFramerateInner=1,WindFramerateOuter=.25,UseGlobalWind=true})
local active={}local count=0 local queue={}local nextCell=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if h and h.Health>0 and r then return r,h end
end
local function add(cell)
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center))model.Parent=visible
 local mesh=model:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end
 table.sort(bones,function(a,b)return a.Name<b.Name end)
 local heights=Codec.decode(cell.encoded,#bones)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=Codec.height(heights,i,cell.base)
  local point=height and Vector3.new(original.X,height-.045,original.Z)or(original-Vector3.new(0,240,0))
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)
  b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 grass:AddMeshes({model})active[cell.key]={model=model,cell=cell}count+=1
end
local function remove(key)
 local entry=active[key]if not entry then return end
 grass:RemoveMeshes({entry.model})entry.model:Destroy()active[key]=nil count-=1
end
player:SetAttribute("SerenaGrassCoveragePatches",field.count)
player:SetAttribute("SerenaWholeMapGrassReady",true)
local heartbeat=RunService.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end
 refresh+=dt
 if refresh>=.15 then
  refresh=0
  for key,entry in pairs(active)do
   local dx,dz=entry.cell.center.X-root.Position.X,entry.cell.center.Z-root.Position.Z
   if dx*dx+dz*dz>keepRadius^2 then remove(key)end
  end
  queue={}nextCell=1
  for _,cell in ipairs(field:around(root.Position,radius))do if not active[cell.key]then queue[#queue+1]=cell end end
 end
 local budget=player:GetAttribute("SerenaGrassNearbyReady")and 4 or 8
 for _=1,budget do
  local cell=queue[nextCell]if not cell or count>=maxActive then break end nextCell+=1
  if not active[cell.key]then add(cell)end
 end
 player:SetAttribute("SerenaGrassLoadedPatches",count)
 player:SetAttribute("SerenaGrassNearbyReady",nextCell>#queue)
end)
local rendered=RunService.RenderStepped:Connect(function(dt)
 if destroyed then return end stepTime+=dt
 if stepTime<(UIS.TouchEnabled and 1/24 or 1/30)then return end local step=math.min(stepTime,.1)stepTime=0
 local root=rootOf(player)if not root then return end local actors={}
 for _,p in ipairs(Players:GetPlayers())do
  local r,h=rootOf(p)
  if r and(r.Position-root.Position).Magnitude<30 then
   local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)
   actors[#actors+1]=Vector3.new(r.Position.X,feet+.1,r.Position.Z)
  end
 end
 grass:Step(step,actors,root.Position)
end)
script.Destroying:Connect(function()
 destroyed=true heartbeat:Disconnect()rendered:Disconnect()
 grass:Destroy()visible:Destroy()storage:Destroy()table.clear(active)
end)
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaWeatherMenu",[========[local Players=game:GetService("Players")local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")local Personal=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("PersonalClimate"))
local player=Players.LocalPlayer local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild("SerenaWeatherUI")if old then old:Destroy()end
local gui=Instance.new("ScreenGui")gui.Name="SerenaWeatherUI"gui.ResetOnSpawn=false gui.DisplayOrder=16 gui.Parent=playerGui
local cream=Color3.fromRGB(243,239,219)local green=Color3.fromRGB(43,65,55)local accent=Color3.fromRGB(100,151,123)
local function round(p,r)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r or 12)c.Parent=p end
local open=Instance.new("TextButton")open.Name="OpenClimate"open.AnchorPoint=Vector2.new(1,0)open.Position=UDim2.new(1,-16,0,64)
open.Size=UDim2.fromOffset(156,42)open.BackgroundColor3=green open.TextColor3=cream open.Font=Enum.Font.GothamMedium open.TextSize=14 open.Parent=gui round(open)
local panel=Instance.new("Frame")panel.Name="ClimatePanel"panel.AnchorPoint=Vector2.new(1,0)panel.Position=UDim2.new(1,-16,0,114)
panel.Size=UDim2.fromOffset(286,350)panel.BackgroundColor3=Color3.fromRGB(26,42,36)panel.Visible=false panel.Parent=gui round(panel,16)
local title=Instance.new("TextLabel")title.BackgroundTransparency=1 title.Size=UDim2.new(1,-50,0,36)title.Position=UDim2.fromOffset(14,10)
title.Font=Enum.Font.GothamBold title.TextSize=18 title.TextColor3=cream title.Text="Escolha seu clima"title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=panel
local close=Instance.new("TextButton")close.Name="CloseClimate"close.Size=UDim2.fromOffset(36,36)close.Position=UDim2.new(1,-42,0,8)
close.Text="×"close.Font=Enum.Font.Gotham close.TextSize=26 close.TextColor3=cream close.BackgroundTransparency=1 close.Parent=panel
local note=Instance.new("TextLabel")note.Name="WindNote"note.BackgroundTransparency=1 note.Size=UDim2.new(1,-28,0,32)note.Position=UDim2.fromOffset(14,45)
note.Text="Vento em todos os modos. Só muda para você."note.Font=Enum.Font.Gotham note.TextSize=12 note.TextColor3=Color3.fromRGB(175,197,181)note.TextWrapped=true note.Parent=panel
local list=Instance.new("ScrollingFrame")list.Name="ClimateOptions"list.Position=UDim2.fromOffset(10,82)list.Size=UDim2.new(1,-20,1,-92)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=5 list.ScrollBarImageColor3=accent
list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.fromOffset(0,0)list.ScrollingDirection=Enum.ScrollingDirection.Y list.ClipsDescendants=true list.Parent=panel
local layout=Instance.new("UIListLayout")layout.Padding=UDim.new(0,8)layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=list
local padding=Instance.new("UIPadding")padding.PaddingLeft=UDim.new(0,3)padding.PaddingRight=UDim.new(0,9)padding.PaddingBottom=UDim.new(0,8)padding.Parent=list
local buttons={}local connections={}
for order,key in ipairs(Personal.Order)do
 local mode=Personal.Modes[key]
 local b=Instance.new("TextButton")b.Name="Mode_"..key b.Size=UDim2.new(1,0,0,55)b.BackgroundColor3=green b.TextColor3=cream
 b.Font=Enum.Font.GothamMedium b.TextSize=15 b.TextXAlignment=Enum.TextXAlignment.Left b.TextYAlignment=Enum.TextYAlignment.Top
 b.LayoutOrder=order b.Parent=list round(b,10)
 local inset=Instance.new("UIPadding")inset.PaddingLeft=UDim.new(0,13)inset.PaddingTop=UDim.new(0,8)inset.Parent=b
 local subtitle=Instance.new("TextLabel")subtitle.Name="Description"subtitle.BackgroundTransparency=1 subtitle.Size=UDim2.new(1,-20,0,18)
 subtitle.Position=UDim2.fromOffset(0,22)subtitle.TextXAlignment=Enum.TextXAlignment.Left subtitle.Font=Enum.Font.Gotham subtitle.TextSize=11
 subtitle.TextColor3=Color3.fromRGB(175,197,181)subtitle.Text=mode.description subtitle.Parent=b
 buttons[key]=b
 connections[#connections+1]=b.Activated:Connect(function()player:SetAttribute("SerenaEnvironmentChoice",key)end)
end
local function fit()
 local camera=workspace.CurrentCamera if not camera then return end local view=camera.ViewportSize
 panel.Size=UDim2.fromOffset(math.clamp(view.X-32,210,286),math.clamp(view.Y-170,130,350))
end
local function refresh()
 local _,_,_,selected=Personal.resolve(player:GetAttribute("SerenaEnvironmentChoice"))
 for key,b in pairs(buttons)do
  local on=key==selected b.BackgroundColor3=on and Color3.fromRGB(69,111,87)or green
  b.Text=(on and"✓  "or"")..Personal.Modes[key].label
 end
 open.Text="CLIMA · "..Personal.Modes[selected].label:upper()
end
connections[#connections+1]=open.Activated:Connect(function()fit()panel.Visible=not panel.Visible refresh()end)
connections[#connections+1]=close.Activated:Connect(function()panel.Visible=false end)
connections[#connections+1]=player:GetAttributeChangedSignal("SerenaEnvironmentChoice"):Connect(refresh)
player:SetAttribute("SerenaTimeChoice",nil)player:SetAttribute("SerenaWeatherChoice",nil)
local _,_,_,initial=Personal.resolve(player:GetAttribute("SerenaEnvironmentChoice"))player:SetAttribute("SerenaEnvironmentChoice",initial)
local timer=0
connections[#connections+1]=RunService.RenderStepped:Connect(function(dt)timer+=dt if timer>=.25 then timer=0 fit()end end)
script.Destroying:Connect(function()for _,c in ipairs(connections)do c:Disconnect()end gui:Destroy()end)
fit()refresh()
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaAmbienceClient",[========[local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local Climate=require(game.ReplicatedStorage:WaitForChild("SerenaRuntime"):WaitForChild("Climate"))
local Personal=require(game.ReplicatedStorage.SerenaRuntime:WaitForChild("PersonalClimate"))
local world=workspace:WaitForChild("IlhaSerena")
local player=Players.LocalPlayer
player:SetAttribute("SerenaRenderingApplied",Climate.rendering(Lighting))
-- Local copies prevent server weather from overwriting a personal sky profile.
local copies={}
for _,name in ipairs({"SerenaAtmosphere","SerenaColor","SerenaBloom","SerenaSunRays"})do
 local original=Lighting:WaitForChild(name) local clone=original:Clone()
 table.insert(copies,{original=original,clone=clone,parent=Lighting,name=name})
 original.Name=name.."ServerProfile" original.Parent=nil clone.Name=name clone.Parent=Lighting
end
local originalClouds=workspace.Terrain:WaitForChild("SerenaClouds")local localClouds=originalClouds:Clone()
table.insert(copies,{original=originalClouds,clone=localClouds,parent=workspace.Terrain,name="SerenaClouds"})
originalClouds.Name="SerenaCloudsServerProfile"originalClouds.Parent=nil localClouds.Name="SerenaClouds"localClouds.Parent=workspace.Terrain
local lamps={}local insects={}
local function light(d)
 if d:IsA("PointLight") and not d:GetAttribute("AlwaysOn")then lamps[d]=true
 elseif d:IsA("ParticleEmitter")and d.Name=="Vagalumes"then insects[d]=true end
end
for _,d in ipairs(world:GetDescendants())do light(d)end
world.DescendantAdded:Connect(light)
local renderedHour,renderedRain,renderedClear
local rain=Instance.new("Folder") rain.Name="SerenaLocalRain" rain.Parent=workspace
local rng=Random.new() local drops={}
local fountainDrops={}
for i=1,16 do
 local p=Instance.new("Part") p.Name="GotaDaFonte" p.Shape=Enum.PartType.Ball p.Size=Vector3.new(.13,.2,.13) p.Material=Enum.Material.Glass p.Color=Color3.fromRGB(167,222,223)
 p.Transparency=.35 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=rain
 fountainDrops[i]=p
end
for i=1,(UserInputService.TouchEnabled and 60 or 110) do
 local p=Instance.new("Part") p.Name="Chuva" p.Size=Vector3.new(.025,1.55,.025) p.Material=Enum.Material.Glass p.Color=Color3.fromRGB(203,223,235)
 p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=rain
 drops[i]={part=p,x=rng:NextNumber(-25,25),y=rng:NextNumber(-9,27),z=rng:NextNumber(-25,25)}
end
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Exclude ray.IgnoreWater=true
local nextRoofCheck=0 local outside=true local climateTime=0
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera if not camera then return end
 local now=workspace:GetServerTimeNow()
 local intensity=0
 do
  local hour,wet,clear,mode=Personal.resolve(player:GetAttribute("SerenaEnvironmentChoice"))
  local ease=1-math.exp(-math.min(dt,.1)*4)
  renderedHour=renderedHour and (renderedHour+((hour-renderedHour+12)%24-12)*ease)%24 or hour
  renderedRain=renderedRain and renderedRain+(wet-renderedRain)*ease or wet
  renderedClear=renderedClear and renderedClear+(clear-renderedClear)*ease or clear
  intensity=renderedRain
  local profile=Climate.profile(renderedHour,renderedRain,renderedClear,now)profile.hour=renderedHour
  Climate.apply(Lighting,workspace.Terrain,profile)
  player:SetAttribute("SerenaAppliedHour",renderedHour)player:SetAttribute("SerenaAppliedRain",renderedRain)
  player:SetAttribute("SerenaAppliedMode",mode)player:SetAttribute("SerenaAppliedWind",profile.wind.Magnitude)
  local night=profile.sun<.23
  for lamp in pairs(lamps)do if lamp.Parent then lamp.Enabled=night else lamps[lamp]=nil end end
  for insect in pairs(insects)do if insect.Parent then insect.Enabled=night else insects[insect]=nil end end
 end
 if intensity>.015 and os.clock()>nextRoofCheck then
  nextRoofCheck=os.clock()+.35
  local filters={rain} if player.Character then table.insert(filters,player.Character) end
  ray.FilterDescendantsInstances=filters
  local head=player.Character and player.Character:FindFirstChild("Head")
  outside=not workspace:Raycast(head and head.Position or camera.CFrame.Position,Vector3.new(0,140,0),ray)
 end
 local wind=workspace.GlobalWind local slant=math.atan2(wind.X,57)
 local waterY=world:GetAttribute("FountainWaterY")
 if waterY then
  for i,p in ipairs(fountainDrops) do
   if (camera.CFrame.Position-Vector3.new(104,waterY,108)).Magnitude<90 then
    local t=(now*.85+i/16)%1 local angle=i*2.39996 local spread=.15+math.sin(t*math.pi/2)*2.4
    p.CFrame=CFrame.new(104+math.cos(angle)*spread,waterY+3.05*(1-t)+math.sin(t*math.pi)*.3,108+math.sin(angle)*spread) p.Transparency=.35
   else p.Transparency=1 end
  end
 end
 for i,d in ipairs(drops) do
  if intensity>.015 and outside and i<=math.ceil(#drops*intensity) then
   d.y-=math.min(dt,.1)*57 d.x+=math.min(dt,.1)*wind.X*.45
   if d.y< -10 or d.x>29 then d.y=27 d.x=rng:NextNumber(-25,25) d.z=rng:NextNumber(-25,25) end
   d.part.CFrame=CFrame.new(camera.CFrame.Position+Vector3.new(d.x,d.y,d.z))*CFrame.Angles(0,0,-slant)
   d.part.Transparency=.48+(1-intensity)*.4
  elseif d.part.Transparency~=1 then d.part.Transparency=1 end
 end
end)
local function cameraFor(char)
 local hum=char:WaitForChild("Humanoid",10)
 if hum then local camera=workspace.CurrentCamera if camera then camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=hum camera.FieldOfView=70 end end
end
player.CharacterAdded:Connect(cameraFor)
if player.Character then task.spawn(cameraFor,player.Character) end
script.Destroying:Connect(function()
 rain:Destroy()
 for _,entry in ipairs(copies)do entry.clone:Destroy()entry.original.Name=entry.name entry.original.Parent=entry.parent end
end)
]========])

source(game.ServerScriptService,"Script","SerenaAmbienceServer",[========[local Lighting=game:GetService("Lighting")local Players=game:GetService("Players")
local runtime=game:GetService("ReplicatedStorage"):WaitForChild("SerenaRuntime")
local Climate=require(runtime:WaitForChild("Climate"))local Personal=require(runtime:WaitForChild("PersonalClimate"))
local world=workspace:WaitForChild("IlhaSerena")local terrain=workspace.Terrain
world:SetAttribute("RenderingServerApplied",Climate.rendering(Lighting))
world:SetAttribute("EnvironmentMode","Dia")world:SetAttribute("ClimateModeCount",4)
for _,key in ipairs({"ClockStart","DayLength","WeatherChanged","PreviousWeather","Weather"})do world:SetAttribute(key,nil)end
local lamps={}local insects={}
local function light(d)
 if d:IsA("PointLight")and not d:GetAttribute("AlwaysOn")then lamps[d]=true
 elseif d:IsA("ParticleEmitter")and d.Name=="Vagalumes"then insects[d]=true end
end
for _,d in ipairs(world:GetDescendants())do light(d)end world.DescendantAdded:Connect(light)
Players.CharacterAutoLoads=true Players.RespawnTime=3
local function ready(c)
 local h=c:WaitForChild("Humanoid",10)
 if h then h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true h.PlatformStand=false h.AutoRotate=true end
end
local function bind(p)p.CharacterAdded:Connect(ready)if p.Character then task.spawn(ready,p.Character)end end
Players.PlayerAdded:Connect(bind)for _,p in ipairs(Players:GetPlayers())do bind(p)end
while true do
 local hour,rain,clear,key=Personal.resolve(world:GetAttribute("EnvironmentMode"))
 local profile=Climate.profile(hour,rain,clear,workspace:GetServerTimeNow())profile.hour=hour
 Climate.apply(Lighting,terrain,profile)world:SetAttribute("TimePhase",key)world:SetAttribute("RainIntensity",rain)
 local night=profile.sun<.23
 for lamp in pairs(lamps)do if lamp.Parent then lamp.Enabled=night else lamps[lamp]=nil end end
 for insect in pairs(insects)do if insect.Parent then insect.Enabled=night else insects[insect]=nil end end
 task.wait(.5)
end
]========])

world:SetAttribute("EnvironmentMode","Dia")world:SetAttribute("ClimateModeCount",4)

for _,key in ipairs({"ClockStart","DayLength","WeatherChanged","PreviousWeather","Weather"})do world:SetAttribute(key,nil)end

local grassTests=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime
local Codec=require(runtime.GrassCodec)local Field=require(runtime.GrassField)
local coverage=runtime.GrassCoverage local field=Field.new(coverage)
local mesh=runtime.SkinnedGrassTemplates.GrassCard:FindFirstChildOfClass("MeshPart")
local bones={}for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end
table.sort(bones,function(a,b)return a.Name<b.Name end)
local offsets={Codec.Invalid,-32000,-1,0,1,32000}local encoded=Codec.encode(offsets)local decoded=Codec.decode(encoded,#offsets)
for i,n in ipairs(offsets)do assert(buffer.readi16(decoded,(i-1)*2)==n,"Terrain codec changed heights")end
-- Dense world-space samples detect uncovered ground, independently of mesh bounding boxes.
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,workspace.IlhaSerena}
ray.RespectCanCollide=true ray.IgnoreWater=false
local buffers={}local candidates={}
for rx=0,3 do for rz=0,3 do
 local list={}
 for dx=-1,1 do for dz=-1,1 do for i,b in ipairs(bones)do
  local x,z=dx*4+b.CFrame.X-rx,dz*4+b.CFrame.Z-rz local distance=x*x+z*z
  if distance<9 then list[#list+1]={dx=dx,dz=dz,index=i,distance=distance}end
 end end end
 table.sort(list,function(a,b)return a.distance<b.distance end)candidates[rx*4+rz]=list
end end
local greenSamples=0 local gaps=0 local maxDistance=0 local worst={}local denseNativeNear=0
for x=coverage:GetAttribute("Min")+1,coverage:GetAttribute("Max")-1,2 do
 for z=coverage:GetAttribute("Min")+1,coverage:GetAttribute("Max")-1,2 do
  local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-300,0),ray)
  if not(hit and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Grass and hit.Normal.Y>.2)then continue end
  greenSamples+=1
  local gx,gz=math.floor((x-field.minimum)/4),math.floor((z-field.minimum)/4)
  local rx,rz=x-(field.minimum+gx*4),z-(field.minimum+gz*4)
  local distance=math.huge
  for _,candidate in ipairs(candidates[rx*4+rz])do
   local cell=field:get(gx+candidate.dx,gz+candidate.dz)
   if cell then
    local data=buffers[cell.key]if not data then data=Codec.decode(cell.encoded,#bones)buffers[cell.key]=data end
    if Codec.height(data,candidate.index,cell.base)then distance=math.sqrt(candidate.distance)break end
   end
  end
  if distance>maxDistance then maxDistance=distance worst={x,z}end
  if distance>1.25 then gaps+=1 end
 end
end
assert(gaps==0,"Uncovered green ground: "..gaps.." worst "..table.concat(worst,",").." distance "..maxDistance)
assert(greenSamples>40000,"Coverage audit missed the island")
-- Execute the real client source on three adjacent full-green cells, with native meshes/bones.
local fixture=Instance.new("Folder")fixture.Name="GrassQA82"fixture.Parent=game.ServerStorage
local limited=Instance.new("Folder")limited.Parent=fixture
for name,value in pairs(coverage:GetAttributes())do limited:SetAttribute(name,value)end
local chosen
for _,cell in pairs(field.cells)do
 local a,b=field:get(cell.ix+1,cell.iz),field:get(cell.ix,cell.iz+1)
 if cell.roots==100 and a and b and a.roots==100 and b.roots==100 then chosen={cell,a,b}break end
end
assert(chosen,"No contiguous dense green area")
local data={}for _,c in ipairs(chosen)do data[#data+1]={c.ix,c.iz,c.base,c.encoded,c.roots}end
local chunk=Instance.new("StringValue")chunk.Value=game:GetService("HttpService"):JSONEncode(data)chunk.Parent=limited limited:SetAttribute("PatchCount",3)
local function signal()
 local callbacks={}local s={}
 function s:Connect(fn)local entry={fn=fn,live=true}callbacks[#callbacks+1]=entry return{Disconnect=function()entry.live=false end}end
 function s:Fire(...)for _,entry in ipairs(callbacks)do if entry.live then entry.fn(...)end end end
 return s
end
local root=Instance.new("Part")root.Name="HumanoidRootPart"root.Anchored=true root.Parent=fixture
local humanoid={Health=100,RigType=Enum.HumanoidRigType.R6}
local character={}
function character:FindFirstChild(name)return name=="HumanoidRootPart"and root end
function character:FindFirstChildOfClass(name)return name=="Humanoid"and humanoid end
local attrs={}local player={Character=character}
function player:GetAttribute(k)return attrs[k]end function player:SetAttribute(k,v)attrs[k]=v end
local players={LocalPlayer=player}function players:GetPlayers()return{player}end
local run={Heartbeat=signal(),RenderStepped=signal()}local mockScript={Destroying=signal()}
local fakeGame={}
function fakeGame:GetService(name)
 if name=="Players"then return players elseif name=="RunService"then return run elseif name=="UserInputService"then return{TouchEnabled=true}end
 return game:GetService(name)
end
local proxy={}
function proxy:WaitForChild(name)if name=="GrassCoverage"then return limited end return runtime:WaitForChild(name)end
local m=Instance.new("ModuleScript")m.Parent=fixture
local source=game.StarterPlayer.StarterPlayerScripts.SerenaGrassClient.Source:gsub('local runtime=RS:WaitForChild%("SerenaRuntime"%)',"local runtime=env.runtime\n")
m.Source="return function(env)\nlocal game=env.game local script=env.script\n"..source.."\nreturn {grass=grass,active=active,field=field}\nend"
root.CFrame=CFrame.new(chosen[1].center+Vector3.new(0,3,0))
local client=require(m)({game=fakeGame,script=mockScript,runtime=proxy})
for _=1,12 do run.Heartbeat:Fire(.05)run.RenderStepped:Fire(.05)end
assert(attrs.SerenaGrassLoadedPatches==3 and attrs.SerenaGrassNearbyReady,"Dense adjacent grass did not load")
local original=root.CFrame
for _,entry in pairs(client.active)do
 local part=entry.model:FindFirstChildOfClass("MeshPart")assert(part.MeshId==mesh.MeshId and not part.CanCollide and not part.CanQuery)
 for _,bone in ipairs(part:GetDescendants())do if bone:IsA("Bone")and bone:GetAttribute("SerenaGreenRoot")then
  denseNativeNear+=1 local point=bone:GetAttribute("SerenaGroundPoint")
  assert(math.abs(bone.TransformedWorldCFrame.Y-point.Y)<.02,"Dense grass root floated")
 end end
end
assert(denseNativeNear==300,"Adjacent volumes lost blades")
local displaced=0 for _ in pairs(client.grass.DisplaceBones)do displaced+=1 end assert(displaced>0,"Walking does not bend the dense grass")
for _=1,30 do
 root.CFrame=original+Vector3.new(120,0,0)
 run.Heartbeat:Fire(.2)run.RenderStepped:Fire(.05)
 assert(attrs.SerenaGrassLoadedPatches==0 and next(client.grass.MeshRecords)==nil,"Distant grass did not release")
 assert(#client.grass.BoneOctree:RadiusSearch(original.Position,1000)==0,"Unloaded grass leaked octree nodes")
 assert(next(client.grass.DisplaceBones)==nil and next(client.grass.ReturnBones)==nil,"Unloaded blades kept animation records")
 root.CFrame=original
 for _=1,3 do run.Heartbeat:Fire(.1)run.RenderStepped:Fire(.05)end
 assert(attrs.SerenaGrassLoadedPatches==3,"Walking back did not restore continuous grass")
end
local activePeak=0
for _,cell in pairs(field.cells)do
 if cell.key%17==0 then activePeak=math.max(activePeak,#field:around(cell.center,54))end
end
assert(activePeak<coverage:GetAttribute("MaxActiveTouch"),"Touch budget would create visible missing volumes")
mockScript.Destroying:Fire()
assert(not workspace:FindFirstChild("SerenaInteractiveGrass")and next(client.grass.MeshRecords)==nil,"Client cleanup leaked the field")
fixture:Destroy()
return {codecExact=true,greenSamples=greenSamples,uncoveredSamples=gaps,maxRootDistance=maxDistance,worstSample=worst,
 nativeContiguousRoots=denseNativeNear,actualTouchSource=true,walkBending=true,
 proximityUnloadAndReload=true,repeatTravelCycles=30,noBoneOrAnimationLeaks=true,maxTouchResidentPatches=activePeak}
]========])

local climateTests=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime
local Personal=require(runtime.PersonalClimate)local Climate=require(runtime.Climate)
assert(#Personal.Order==4 and Personal.Order[1]=="Dia" and Personal.Order[2]=="Noite"and Personal.Order[3]=="Anoitecer"and Personal.Order[4]=="Chuva","Extra or missing climate modes")
for _,key in ipairs(Personal.Order)do
 local hour,rain,clear,mode=Personal.resolve(key)assert(mode==key)
 for _,time in ipairs({0,1,5,20,60,1000})do
  local p=Climate.profile(hour,rain,clear,time)
  assert(p.wind.Magnitude>3,"A climate mode stops the wind")
  assert(p.rain==(key=="Chuva"and 1 or 0),"Wrong rain preset")
 end
end
local hour,wet,_,key=Personal.resolve("Madrugada")assert(hour==12 and wet==0 and key=="Dia","Retired mode survived")
assert(Personal.resolve("Noite")==23 and Personal.resolve("Dia")==12,"Personal profiles interfere")
local fixture=Instance.new("Folder")fixture.Name="ClimateQA83"fixture.Parent=game.ServerStorage
local playerGui=Instance.new("Folder")playerGui.Parent=fixture
local character=Instance.new("Model")character.Parent=fixture
local root=Instance.new("Part")root.Name="HumanoidRootPart"root.Anchored=true root.CFrame=CFrame.new(104,22,108)root.Parent=character
local humanoid=Instance.new("Humanoid")humanoid.Parent=character
local function signal()
 local list={}local s={}
 function s:Connect(fn)local entry={fn=fn,live=true}list[#list+1]=entry return {Disconnect=function()entry.live=false end}end
 function s:Fire(...)for _,entry in ipairs(list)do if entry.live then entry.fn(...)end end end
 return s
end
local attrs={SerenaTimeChoice="Noite",SerenaWeatherChoice="Chuva"}local events={}
local player={Character=character,CharacterAdded=signal()}
function player:WaitForChild(name)assert(name=="PlayerGui")return playerGui end
function player:GetAttribute(k)return attrs[k]end
function player:SetAttribute(k,v)attrs[k]=v if events[k]then events[k]:Fire()end end
function player:GetAttributeChangedSignal(k)events[k]=events[k]or signal()return events[k]end
local players={LocalPlayer=player}function players:GetPlayers()return{player}end
local run={RenderStepped=signal()}local fakeGame={ReplicatedStorage=game.ReplicatedStorage}
function fakeGame:GetService(name)if name=="Players"then return players elseif name=="RunService"then return run elseif name=="UserInputService"then return{TouchEnabled=true}end return game:GetService(name)end
local taskMock={}function taskMock.spawn(fn,...)fn(...)end
local bindings={}local mockScript={Destroying=signal()}
local function execute(name,source)
 local m=Instance.new("ModuleScript")m.Name=name m.Parent=fixture
 m.Source="return function(env)\nlocal game=env.game local script=env.script local task=env.task\n"..source.."\nend"
 require(m)({game=fakeGame,script=mockScript,task=taskMock,bind=function(b,fn)bindings[b]=fn return{Disconnect=function()bindings[b]=nil end}end})
end
local oldCamera=workspace.CurrentCamera local camera=Instance.new("Camera")camera.CFrame=CFrame.new(104,30,108)camera.Parent=workspace workspace.CurrentCamera=camera
local SPS=game.StarterPlayer.StarterPlayerScripts local source=SPS.SerenaWeatherMenu.Source
for _,name in ipairs({"b","open","close"})do source=source:gsub(name.."%.Activated:Connect%(","env.bind("..name..",")end
execute("ActualFourClimateMenu",source)
local gui=playerGui.SerenaWeatherUI local list=gui.ClimatePanel.ClimateOptions
assert(list:IsA("ScrollingFrame")and list.AutomaticCanvasSize==Enum.AutomaticSize.Y and list.ClipsDescendants,"Scrolling menu lost")
assert(attrs.SerenaTimeChoice==nil and attrs.SerenaWeatherChoice==nil,"Old selectors survived")
local options=0 for _,child in ipairs(list:GetChildren())do if child:IsA("TextButton")then options+=1 assert(child.Name:match("^Mode_"),"Legacy climate option")end end
assert(options==4,"More than four climate buttons")
bindings[gui.OpenClimate]()assert(gui.ClimatePanel.Visible)
local world=workspace.IlhaSerena local default=world:GetAttribute("EnvironmentMode")
local lamps={}for _,d in ipairs(world:GetDescendants())do if d:IsA("PointLight")or d:IsA("ParticleEmitter")then lamps[d]=d.Enabled end end
execute("ActualFourClimateRenderer",SPS.SerenaAmbienceClient.Source)
local results={}
for _,mode in ipairs(Personal.Order)do
 bindings[list["Mode_"..mode]]()
 for _=1,100 do run.RenderStepped:Fire(.05)end
 local hour,rain=Personal.resolve(mode)
 assert(math.abs(attrs.SerenaAppliedHour-hour)<.01 and math.abs(attrs.SerenaAppliedRain-rain)<.01,"Preset not applied: "..mode)
 assert(attrs.SerenaAppliedMode==mode and attrs.SerenaAppliedWind>3 and workspace.GlobalWind.Magnitude>3,"No wind in "..mode)
 assert(list["Mode_"..mode].Text:find("✓",1,true),"Selected mode not marked")
 assert(world:GetAttribute("EnvironmentMode")==default,"Personal mode changed the server")
 local visible=0
 for _,drop in ipairs(workspace.SerenaLocalRain:GetChildren())do if drop.Name=="Chuva"and drop.Transparency<1 then visible+=1 end end
 if mode=="Chuva"then assert(visible>0,"Rain preset has no rain")else assert(visible==0,"Rain stayed in a dry mode")end
 results[#results+1]={mode=mode,hour=attrs.SerenaAppliedHour,rain=attrs.SerenaAppliedRain,wind=attrs.SerenaAppliedWind}
end
bindings[list.Mode_Dia]()for _=1,100 do run.RenderStepped:Fire(.05)end
for _,drop in ipairs(workspace.SerenaLocalRain:GetChildren())do if drop.Name=="Chuva"then assert(drop.Transparency==1,"Rain did not stop when choosing day")end end
bindings[gui.ClimatePanel.CloseClimate]()assert(not gui.ClimatePanel.Visible)
mockScript.Destroying:Fire()
for d,enabled in pairs(lamps)do if d.Parent then d.Enabled=enabled end end
assert(not workspace:FindFirstChild("SerenaLocalRain"),"Old climate objects left behind")
workspace.CurrentCamera=oldCamera camera:Destroy()fixture:Destroy()
return {fourOptionsOnly=true,scrollingMenu=true,actualMenuAndClientSources=true,allModesHaveWind=true,
 personalSelectionPreserved=true,rainStopsOnDay=true,legacyChoicesRemoved=true,modes=results}
]========])

local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do
 if s:IsA("Script")or s:IsA("LocalScript")then
  local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
  local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
 end
end end
assert(compiled==15,"Runtime scripts incomplete")
local climate=require(runtime.Climate)local p=climate.profile(12,0,1,0)p.hour=12 climate.apply(game.Lighting,workspace.Terrain,p)
world:SetAttribute("TimePhase","Dia")world:SetAttribute("RainIntensity",0)
local count=0 for _,d in ipairs(world:GetDescendants())do if d:IsA("BasePart")then count+=1 end end
assert(count==4960,"Map geometry changed")
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834,"Requested wind was changed")
world:SetAttribute("UpgradeVersion",83)
game:GetService("AssetService"):SavePlaceAsync()
return {sourceVersion=game.PlaceVersion,published=true,grass=grass,grassTests=grassTests,climateTests=climateTests,compiledScripts=compiled,mapParts=count}
