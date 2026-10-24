assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==79,"Published version changed")
local world=workspace.IlhaSerena assert(world:GetAttribute("UpgradeVersion")==79,"Wrong island version")
local runtime=game.ReplicatedStorage.SerenaRuntime local SSS=game.ServerScriptService local SPS=game.StarterPlayer.StarterPlayerScripts
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)if old then old:Destroy()end
 local s=Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
local function run(code)
 local m=source(game.ServerStorage,"ModuleScript","Stage80","return function()\n"..code.."\nend")local result=require(m)()m:Destroy()return result
end

source(runtime,"ModuleScript","Climate",[========[-- Shared climate profile: the same native effects run on server and client.
local Climate={DayLength=600,InitialHour=9.25,TransitionSeconds=8}
function Climate.hour(now,start)
 return (Climate.InitialHour+(now-start)*24/Climate.DayLength)%24
end
function Climate.phase(hour)
 if hour<5 then return "Madrugada" elseif hour<6.5 then return "Amanhecer" elseif hour<12 then return "Manhã"
 elseif hour<17 then return "Tarde" elseif hour<18.5 then return "Pôr do sol" elseif hour<20 then return "Anoitecer" else return "Noite" end
end
function Climate.weights(now,changed,from,to)
 local t=math.clamp((now-changed)/Climate.TransitionSeconds,0,1) t=t*t*(3-2*t)
 local function amount(state,key) return state==key and 1 or 0 end
 return amount(from,"Chuva")*(1-t)+amount(to,"Chuva")*t,
  amount(from,"Sol")*(1-t)+amount(to,"Sol")*t
end
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
 p.rays=(.018+.045*clear)*sun*(1-rain*.8)
 p.waterColor=Color3.fromRGB(39,141,151):Lerp(Color3.fromRGB(61,111,132),rain*.7)
 p.waveSize=.22+rain*.17 p.waveSpeed=8+rain*7
 return p
end
function Climate.apply(lighting,terrain,profile)
 local p=profile
 lighting.ClockTime=p.hour or lighting.ClockTime
 lighting.GlobalShadows=true lighting.Brightness=p.brightness lighting.ExposureCompensation=.08
 lighting.EnvironmentDiffuseScale=.55 lighting.EnvironmentSpecularScale=.9 lighting.ShadowSoftness=.25
 lighting.Ambient=p.ambient lighting.OutdoorAmbient=p.outdoor
 lighting.ColorShift_Top=Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(98,44,19),p.warm)
 local atmosphere=lighting:FindFirstChild("SerenaAtmosphere")
 if atmosphere then atmosphere.Color=p.atmosphere atmosphere.Decay=p.decay atmosphere.Density=p.density atmosphere.Haze=p.haze atmosphere.Glare=p.clear*.22*p.sun end
 local grade=lighting:FindFirstChild("SerenaColor")
 if grade then grade.Contrast=.065 grade.Saturation=.045-p.rain*.09 grade.Brightness=0 grade.TintColor=Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(255,224,200),p.warm*.25) end
 local bloom=lighting:FindFirstChild("SerenaBloom")
 if bloom then bloom.Enabled=true bloom.Intensity=.19 bloom.Threshold=1.05 bloom.Size=28 end
 local rays=lighting:FindFirstChild("SerenaSunRays")
 if rays then rays.Enabled=true rays.Intensity=p.rays rays.Spread=.78 end
 local clouds=terrain:FindFirstChild("SerenaClouds")
 if clouds then clouds.Cover=p.cover clouds.Density=p.cloudDensity clouds.Color=p.cloudColor end
 terrain.WaterColor=p.waterColor terrain.WaterTransparency=.37 terrain.WaterReflectance=.55
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

source(runtime,"ModuleScript","PersonalClimate",[========[local Personal={Times={Automatico=false,Dia=12,Noite=23,Amanhecer=6.2,Manha=9,Tarde=15,PorDoSol=17.7,Madrugada=3},Weather={Automatico=false,Sol={0,1},Nublado={0,0},Chuva={1,0}}}
function Personal.resolve(timeChoice,weatherChoice,hour,rain,clear)
 local selectedHour=Personal.Times[timeChoice]local selectedWeather=Personal.Weather[weatherChoice]
 return selectedHour or hour,selectedWeather and selectedWeather[1] or rain,selectedWeather and selectedWeather[2] or clear
end
return Personal
]========])

source(runtime,"ModuleScript","SuspensionBridge",[========[-- Adapted from the user's arched cyan/gold suspension bridge.
local Bridge={}
function Bridge.build(old,terrain)
 local parent=old.Parent local name=old.Name
 local left,right=old:GetAttribute("SpanLeft"),old:GetAttribute("SpanRight")
 local ly,ry=old:GetAttribute("BankLeftY"),old:GetAttribute("BankRightY")
 local _,box=old:GetBoundingBox() local z=tonumber(name:match("%d+")) assert(z,"Bridge location missing")
 local L=right-left local half=L/2 local cx=(left+right)/2 local base=(ly+ry)/2
 local CFG={Length=L,Width=9,ArchHeight=L*16/120,Segments=40,TowerHeight=L*55/120,TowerSize=1.8,TowerX=.6,CableSag=L*28/120,HangerStep=2.6,Animate=true,StepDelay=.04,DropHeight=12}
 local STONE=Color3.fromRGB(200,208,220) local CYAN=Color3.fromRGB(0,229,255)
 local GOLD=Color3.fromRGB(212,175,55) local CABLE=Color3.fromRGB(170,150,60)
 local model=Instance.new("Model") model.Name=name model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local time=0 local groupTime=0
 local function group(delay)groupTime=time time+=delay end
 local function P(x,y,dz)return Vector3.new(cx+x,base+y,z+dz)end
 local function deckY(x)
  local t=(x+half)/L return (ly-base)+(ry-ly)*t+CFG.ArchHeight*(1-(x/half)^2)
 end
 local function part(cf,size,color,material,alpha,collide,physical)
  local p=Instance.new("Part") p.Name=physical and "PisoFixo" or "Estrutura" p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.SmoothPlastic
  p.Transparency=alpha or 0 p.Anchored=true p.CanCollide=collide==true p.CanTouch=false p.CanQuery=p.CanCollide p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  if not physical then p:SetAttribute("BridgeRestCF",cf) p:SetAttribute("BridgeAlpha",p.Transparency) p:SetAttribute("BridgeRevealAt",groupTime) end
  p.Parent=model return p
 end
 local function line(a,b,thick,color)
  local p=part(CFrame.lookAt((a+b)/2,b),Vector3.new(thick,thick,(b-a).Magnitude),color,Enum.Material.Metal,0,false)
  p.Name="Cabo" return p
 end
 local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={terrain} ray.IgnoreWater=true
 local function floor(x,dz)
  local hit=workspace:Raycast(P(x,160,dz),Vector3.new(0,-260,0),ray) assert(hit,"Missing bridge footing") return hit.Position.Y-base
 end
 group(0)
 for i=0,CFG.Segments-1 do
  local x0=-half+i*L/CFG.Segments local x1=x0+L/CFG.Segments
  local a,b=P(x0,deckY(x0),0),P(x1,deckY(x1),0)
  local cf=CFrame.lookAt((a+b)/2,b) local len=(b-a).Magnitude+.035
  group(CFG.StepDelay)
  local deckCF=cf-cf.UpVector*.3
  local visual=part(deckCF,Vector3.new(CFG.Width,.6,len),STONE,Enum.Material.Concrete,0,false) visual.Name="DeckVisual"
  part(deckCF,visual.Size,STONE,Enum.Material.Concrete,1,true,true)
  for _,s in ipairs({-1,1})do
   local neon=part(cf*CFrame.new(s*(CFG.Width/2-.17),.13,0),Vector3.new(.28,.23,len),CYAN,Enum.Material.Neon,0,false) neon.Name="NeonCiano"
   local rail=part(cf*CFrame.new(s*(CFG.Width/2-.13),2.7,0),Vector3.new(.22,.22,len),GOLD,Enum.Material.Metal,0,false) rail.Name="CorrimãoDourado"
   local blocker=part(rail.CFrame,Vector3.new(.22,2.8,len),GOLD,Enum.Material.Metal,1,true,true) blocker.Name="ProteçãoFixa"
   if i%2==0 then part(cf*CFrame.new(s*(CFG.Width/2-.13),1.35,0),Vector3.new(.27,2.7,.27),GOLD,Enum.Material.Metal,0,false).Name="PosteDourado"end
  end
 end
 local xt=half*CFG.TowerX local zt=CFG.Width/2+CFG.TowerSize/2+.5 local top=CFG.TowerHeight local anchorX=half+4
 local function cableY(x)return top-CFG.CableSag*(1-(x/xt)^2)end
 local function backCableY(d,s)
  local t=(d-xt)/(anchorX-xt) return top+(floor(s*anchorX,zt)+.7-top)*t
 end
 for _,sx in ipairs({-1,1})do
  group(.35)
  for _,sz in ipairs({-1,1})do
   local bottom=floor(sx*xt,sz*zt)-.8 local height=top+.4-bottom
   local tower=part(CFrame.new(P(sx*xt,(bottom+top+.4)/2,sz*zt)),Vector3.new(CFG.TowerSize,height,CFG.TowerSize),STONE,Enum.Material.Concrete,0,false) tower.Name="Torre"
   part(tower.CFrame,tower.Size,STONE,Enum.Material.Concrete,1,true,true).Name="TorreFixa"
   part(CFrame.new(P(sx*xt,bottom+.4,sz*zt)),Vector3.new(3.2,1.5,3.2),STONE,Enum.Material.Concrete,0,false).Name="FundaçãoEnterrada"
   part(CFrame.new(P(sx*xt,top*.52,sz*(zt-CFG.TowerSize/2-.08))),Vector3.new(.2,top*.77,.2),CYAN,Enum.Material.Neon,0,false).Name="NeonDaTorre"
   for _,fraction in ipairs({.18,.45,.73})do part(CFrame.new(P(sx*xt,top*fraction,sz*zt)),Vector3.new(CFG.TowerSize+.35,.4,CFG.TowerSize+.35),GOLD,Enum.Material.Metal,0,false).Name="AnelDourado"end
   part(CFrame.new(P(sx*xt,top+.5,sz*zt)),Vector3.new(CFG.TowerSize+.55,.7,CFG.TowerSize+.55),GOLD,Enum.Material.Metal,0,false).Name="TopoDourado"
  end
  part(CFrame.new(P(sx*xt,top-1.5,0)),Vector3.new(CFG.TowerSize,1.8,2*zt+CFG.TowerSize),STONE,Enum.Material.Concrete,0,false).Name="VigaDasTorres"
  part(CFrame.new(P(sx*xt,top-2.5,0)),Vector3.new(.25,.25,2*zt),CYAN,Enum.Material.Neon,0,false).Name="NeonDaViga"
 end
 for _,sz in ipairs({-1,1})do
  for i=0,23 do
   local x0=-xt+2*xt*i/24 local x1=-xt+2*xt*(i+1)/24 group(.02)
   line(P(x0,cableY(x0),sz*zt),P(x1,cableY(x1),sz*zt),.23,CABLE)
  end
  for _,sx in ipairs({-1,1})do
   group(.1) line(P(sx*xt,top,sz*zt),P(sx*anchorX,floor(sx*anchorX,sz*zt)+.7,sz*zt),.23,CABLE)
   part(CFrame.new(P(sx*anchorX,floor(sx*anchorX,sz*zt)+.1,sz*zt)),Vector3.new(2.2,1.3,2.2),STONE,Enum.Material.Concrete,0,false).Name="Ancoragem"
  end
  local x=-xt+CFG.HangerStep
  while x<xt-.5 do
   group(.03) line(P(x,cableY(x),sz*zt),P(x,deckY(x)+1.1,sz*(CFG.Width/2-.3)),.09,GOLD) x+=CFG.HangerStep
  end
  for _,sx in ipairs({-1,1})do
   local d=xt+CFG.HangerStep
   while d<half-.5 do
    group(.03) line(P(sx*d,backCableY(d,sx),sz*zt),P(sx*d,deckY(sx*d)+1.1,sz*(CFG.Width/2-.3)),.09,GOLD) d+=CFG.HangerStep
   end
  end
 end
 group(.3)
 for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
  local orb=part(CFrame.new(P(sx*xt,top+2,sz*zt)),Vector3.new(1.8,1.8,1.8),CYAN,Enum.Material.Neon,.1,false)
  orb.Name="EsferaPulsante" orb.Shape=Enum.PartType.Ball orb:SetAttribute("BridgeOrb",true)
  local light=Instance.new("PointLight") light.Color=CYAN light.Range=18 light.Brightness=1.4 light.Shadows=false light:SetAttribute("AlwaysOn",true)light.Parent=orb
 end end
 -- Retain the measured shore ramps, with stationary transparent collision copies.
 group(0)
 for _,p in ipairs(old:GetChildren())do if p:IsA("BasePart") and p.Name=="RampaDeEntrada"then
  local visual=part(p.CFrame,p.Size,STONE,Enum.Material.Concrete,0,false)visual.Name="RampaVisual"
  part(p.CFrame,p.Size,STONE,Enum.Material.Concrete,1,true,true).Name="RampaFixa"
 end end
 model:SetAttribute("SpanLeft",left)model:SetAttribute("SpanRight",right)model:SetAttribute("BankLeftY",ly)model:SetAttribute("BankRightY",ry)
 model:SetAttribute("ArchRise",CFG.ArchHeight)model:SetAttribute("SuspensionBridge",true)model:SetAttribute("ConstructionDuration",time+.6)model:SetAttribute("DropHeight",CFG.DropHeight)
 model:SetAttribute("BridgeCenter",Vector3.new(cx,base,z))
 model:SetAttribute("AnimateConstruction",CFG.Animate)
 old:Destroy()model.Parent=parent
 game:GetService("CollectionService"):AddTag(model,"SerenaSuspensionBridge")
 return model
end
return Bridge
]========])

local factory=require(runtime.SuspensionBridge)
for _,z in ipairs({70,124})do factory.build(world.TrilhasEMirante["Ponte"..z],workspace.Terrain)end

source(SSS,"Script","SerenaAmbienceServer",[========[local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local Climate=require(game:GetService("ReplicatedStorage"):WaitForChild("SerenaRuntime"):WaitForChild("Climate"))
local world=workspace:WaitForChild("IlhaSerena")
local terrain=workspace.Terrain
world:SetAttribute("RenderingServerApplied",Climate.rendering(Lighting))
local lamps={}
for _,d in ipairs(world:GetDescendants()) do if d:IsA("PointLight") and not d:GetAttribute("AlwaysOn") then table.insert(lamps,d) end end
local start=workspace:GetServerTimeNow()
world:SetAttribute("ClockStart",start) world:SetAttribute("DayLength",Climate.DayLength)
local sequence={{"Sol",100},{"Nublado",20},{"Chuva",55},{"Nublado",20},{"Sol",120},{"Nublado",25},{"Chuva",70},{"Nublado",20}}
local index=1 local nextWeather=start+sequence[1][2] local changed=start local previous="Sol"
world:SetAttribute("WeatherChanged",changed) world:SetAttribute("PreviousWeather",previous) world:SetAttribute("Weather","Sol")
local lastNight
Players.CharacterAutoLoads=true Players.RespawnTime=3
local function ready(c)
 local h=c:WaitForChild("Humanoid",10)
 if h then h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true h.PlatformStand=false h.AutoRotate=true end
end
local function bind(p)
 p.CharacterAdded:Connect(ready)
 if p.Character then task.spawn(ready,p.Character) end
end
Players.PlayerAdded:Connect(bind) for _,p in ipairs(Players:GetPlayers()) do bind(p) end
while true do
 local now=workspace:GetServerTimeNow()
 if now>=nextWeather then
  previous=sequence[index][1] index=index%#sequence+1 changed=now nextWeather=now+sequence[index][2]
  world:SetAttribute("PreviousWeather",previous) world:SetAttribute("Weather",sequence[index][1]) world:SetAttribute("WeatherChanged",changed)
 end
 local hour=Climate.hour(now,start)
 local rain,clear=Climate.weights(now,changed,previous,sequence[index][1])
 local p=Climate.profile(hour,rain,clear,now) p.hour=hour
 Climate.apply(Lighting,terrain,p)
 world:SetAttribute("TimePhase",Climate.phase(hour)) world:SetAttribute("RainIntensity",rain)
 local night=p.sun<.23
 if night~=lastNight then
  for _,light in ipairs(lamps) do if light.Parent then light.Enabled=night end end
  for _,d in ipairs(world:GetDescendants()) do
   if d:IsA("ParticleEmitter") and d.Name=="Vagalumes" then d.Enabled=night end
  end
  lastNight=night
 end
 task.wait(.5)
end
]========])

source(SPS,"LocalScript","SerenaAmbienceClient",[========[local RunService=game:GetService("RunService")
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
 local now=workspace:GetServerTimeNow() local start=world:GetAttribute("ClockStart")
 local intensity=0
 if start then
  local hour=Climate.hour(now,start)
  local wet,clear=Climate.weights(now,world:GetAttribute("WeatherChanged") or start,world:GetAttribute("PreviousWeather") or "Sol",world:GetAttribute("Weather") or "Sol")
  hour,wet,clear=Personal.resolve(player:GetAttribute("SerenaTimeChoice") or "Automatico",player:GetAttribute("SerenaWeatherChoice") or "Automatico",hour,wet,clear)
  local ease=1-math.exp(-math.min(dt,.1)*4)
  renderedHour=renderedHour and (renderedHour+((hour-renderedHour+12)%24-12)*ease)%24 or hour
  renderedRain=renderedRain and renderedRain+(wet-renderedRain)*ease or wet
  renderedClear=renderedClear and renderedClear+(clear-renderedClear)*ease or clear
  intensity=renderedRain
  local profile=Climate.profile(renderedHour,renderedRain,renderedClear,now)profile.hour=renderedHour
  Climate.apply(Lighting,workspace.Terrain,profile)
  player:SetAttribute("SerenaAppliedHour",renderedHour)player:SetAttribute("SerenaAppliedRain",renderedRain)
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

source(SPS,"LocalScript","SerenaBridgeAnimation",[========[local TweenService=game:GetService("TweenService")
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local player=Players.LocalPlayer local bridges={} local played={} local tweens={}
local function track(m)if m:IsA("Model") then bridges[m]=true end end
for _,m in ipairs(CollectionService:GetTagged("SerenaSuspensionBridge"))do track(m)end
CollectionService:GetInstanceAddedSignal("SerenaSuspensionBridge"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SerenaSuspensionBridge"):Connect(function(m)bridges[m]=nil end)
local function animate(model)
 played[model.Name]=true local now=os.clock() local duration=model:GetAttribute("ConstructionDuration") or 6
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart") and p:GetAttribute("BridgeRestCF")then
  local rest=p:GetAttribute("BridgeRestCF")local alpha=p:GetAttribute("BridgeAlpha") or 0
  local construction=model:GetAttribute("AnimateConstruction")~=false
  if construction then p.CFrame=rest+Vector3.new(0,model:GetAttribute("DropHeight") or 12,0)p.Transparency=1 end
  task.delay(construction and (p:GetAttribute("BridgeRevealAt") or 0) or 0,function()
   if not p.Parent then return end
   local tween=TweenService:Create(p,TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=rest,Transparency=alpha})
   table.insert(tweens,tween)tween:Play()
   if p:GetAttribute("BridgeOrb")then
    task.delay(.55,function()if not p.Parent then return end
     local pulse=TweenService:Create(p,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Size=Vector3.new(2.5,2.5,2.5)})table.insert(tweens,pulse)pulse:Play()
    end)
   end
  end)
 end end
 model:SetAttribute("LocalConstructionEnds",now+duration)
end
local timer=0
RunService.Heartbeat:Connect(function(dt)
 timer+=dt if timer<.3 then return end timer=0
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")if not root then return end
 for m in pairs(bridges)do if m.Parent and not played[m.Name] and (root.Position-m:GetAttribute("BridgeCenter")).Magnitude<130 then animate(m)end end
end)
script.Destroying:Connect(function()for _,t in ipairs(tweens)do t:Cancel()end end)
]========])

source(SPS,"LocalScript","SerenaWeatherMenu",[========[local Players=game:GetService("Players")local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")gui.Name="SerenaWeatherUI"gui.ResetOnSpawn=false gui.DisplayOrder=16 gui.Parent=player:WaitForChild("PlayerGui")
local cream=Color3.fromRGB(243,239,219)local green=Color3.fromRGB(43,65,55)local accent=Color3.fromRGB(100,151,123)
local function round(p,r)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r or 12)c.Parent=p end
local open=Instance.new("TextButton")open.Name="OpenClimate"open.AnchorPoint=Vector2.new(1,0)open.Position=UDim2.new(1,-16,0,64)open.Size=UDim2.fromOffset(156,42)
open.BackgroundColor3=green open.TextColor3=cream open.Font=Enum.Font.GothamMedium open.TextSize=14 open.Text="CLIMA  ☀"open.Parent=gui round(open)
local panel=Instance.new("Frame")panel.Name="ClimatePanel"panel.AnchorPoint=Vector2.new(1,0)panel.Position=UDim2.new(1,-16,0,114)panel.Size=UDim2.fromOffset(286,420)panel.BackgroundColor3=Color3.fromRGB(26,42,36)panel.Visible=false panel.Parent=gui round(panel,16)
local title=Instance.new("TextLabel")title.BackgroundTransparency=1 title.Size=UDim2.new(1,-50,0,36)title.Position=UDim2.fromOffset(14,10)title.Font=Enum.Font.GothamBold title.TextSize=18 title.TextColor3=cream title.Text="Seu céu, seu clima"title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=panel
local close=Instance.new("TextButton")close.Name="CloseClimate"close.Size=UDim2.fromOffset(36,36)close.Position=UDim2.new(1,-42,0,8)close.Text="×"close.Font=Enum.Font.Gotham close.TextSize=26 close.TextColor3=cream close.BackgroundTransparency=1 close.Parent=panel
local note=Instance.new("TextLabel")note.BackgroundTransparency=1 note.Size=UDim2.new(1,-28,0,30)note.Position=UDim2.fromOffset(14,44)note.Text="As escolhas mudam só a sua visão."note.Font=Enum.Font.Gotham note.TextSize=12 note.TextColor3=Color3.fromRGB(175,197,181)note.TextWrapped=true note.Parent=panel
local list=Instance.new("ScrollingFrame")list.Name="ClimateOptions"list.Position=UDim2.fromOffset(10,80)list.Size=UDim2.new(1,-20,1,-90)list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=5 list.ScrollBarImageColor3=accent
list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.fromOffset(0,0)list.ScrollingDirection=Enum.ScrollingDirection.Y list.ClipsDescendants=true list.Parent=panel
local layout=Instance.new("UIListLayout")layout.Padding=UDim.new(0,7)layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=list
local padding=Instance.new("UIPadding")padding.PaddingLeft=UDim.new(0,3)padding.PaddingRight=UDim.new(0,9)padding.PaddingBottom=UDim.new(0,10)padding.Parent=list
local order=0 local buttons={}
local function heading(label)
 order+=1 local l=Instance.new("TextLabel")l.Size=UDim2.new(1,0,0,27)l.BackgroundTransparency=1 l.Text=label l.Font=Enum.Font.GothamBold l.TextSize=12 l.TextColor3=accent l.TextXAlignment=Enum.TextXAlignment.Left l.LayoutOrder=order l.Parent=list
end
local function option(label,kind,value)
 order+=1 local b=Instance.new("TextButton")b.Name=kind.."_"..value b.Size=UDim2.new(1,0,0,42)b.BackgroundColor3=green b.TextColor3=cream b.Font=Enum.Font.GothamMedium b.TextSize=14 b.Text=label b.TextXAlignment=Enum.TextXAlignment.Left b.LayoutOrder=order b.Parent=list round(b,9)
 local inset=Instance.new("UIPadding")inset.PaddingLeft=UDim.new(0,13)inset.Parent=b
 table.insert(buttons,{part=b,kind=kind,value=value,label=label})
 b.Activated:Connect(function()player:SetAttribute(kind,value)end)
end
heading("HORÁRIO")
for _,o in ipairs({{"Acompanhar a ilha","Automatico"},{"Dia","Dia"},{"Noite","Noite"},{"Amanhecer","Amanhecer"},{"Manhã","Manha"},{"Tarde","Tarde"},{"Pôr do sol","PorDoSol"},{"Madrugada","Madrugada"}})do option(o[1],"SerenaTimeChoice",o[2])end
heading("TEMPO")
for _,o in ipairs({{"Clima automático","Automatico"},{"Sol e céu aberto","Sol"},{"Nublado","Nublado"},{"Chuva","Chuva"}})do option(o[1],"SerenaWeatherChoice",o[2])end
local function fit()
 local camera=workspace.CurrentCamera if not camera then return end local view=camera.ViewportSize
 panel.Size=UDim2.fromOffset(math.clamp(view.X-32,210,286),math.clamp(view.Y-170,150,420))
end
local function refresh()
 for _,o in ipairs(buttons)do local selected=(player:GetAttribute(o.kind) or "Automatico")==o.value o.part.BackgroundColor3=selected and Color3.fromRGB(69,111,87) or green o.part.Text=(selected and "✓  " or "")..o.label end
end
open.Activated:Connect(function()fit()panel.Visible=not panel.Visible refresh()end)
close.Activated:Connect(function()panel.Visible=false end)
player:GetAttributeChangedSignal("SerenaTimeChoice"):Connect(refresh)player:GetAttributeChangedSignal("SerenaWeatherChoice"):Connect(refresh)
local timer=0
RunService.RenderStepped:Connect(function(dt)
 timer+=dt if timer<.25 then return end timer=0 fit()
end)
fit()refresh()
]========])

world:SetAttribute("DayLength",600)world:SetAttribute("ClockStart",nil)world:SetAttribute("WeatherChanged",nil)

local geometry=run([========[local w=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime
local Climate=require(runtime.Climate)local Personal=require(runtime.PersonalClimate)
assert(Climate.DayLength==600 and Climate.TransitionSeconds==8,"Cycle speed incorrect")
for _,hour in ipairs({0,6.2,12,17.7,23})do for _,weather in ipairs({"Sol","Nublado","Chuva"})do
 local rain,clear=Climate.weights(8,0,weather,weather)local profile=Climate.profile(hour,rain,clear,1)profile.hour=hour Climate.apply(game.Lighting,workspace.Terrain,profile)
 assert(profile.brightness>.5 and profile.brightness<4,"Bad lighting")
end end
local h,r,c=Personal.resolve("Noite","Chuva",12,0,1)assert(h==23 and r==1 and c==0,"Combined selection")
local h2,r2,c2=Personal.resolve("Automatico","Automatico",9.5,.3,.7)assert(h2==9.5 and r2==.3 and c2==.7,"Automatic mode")
local hd,rd,cd=Personal.resolve("Dia","Sol",23,1,0)assert(hd==12 and rd==0 and cd==1,"Day override")
local ra=RaycastParams.new()ra.FilterType=Enum.RaycastFilterType.Include ra.FilterDescendantsInstances={workspace.Terrain,w}ra.IgnoreWater=true ra.RespectCanCollide=true
local overlap=OverlapParams.new()overlap.FilterType=Enum.RaycastFilterType.Include overlap.FilterDescendantsInstances={w}overlap.RespectCanCollide=true
local samples=0 local maximum=0 local bridgeParts=0
for _,z in ipairs({70,124})do
 local m=w.TrilhasEMirante["Ponte"..z]assert(m:GetAttribute("SuspensionBridge"),"Bridge missing")
 local left,right=m:GetAttribute("SpanLeft"),m:GetAttribute("SpanRight")local last
 local towers,orbs,neon,fixed=0,0,0,0
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
  bridgeParts+=1 assert(p.Anchored,"Unanchored bridge")
  if p.Name=="Torre"then towers+=1 end if p:GetAttribute("BridgeOrb")then orbs+=1 end if p.Material==Enum.Material.Neon then neon+=1 end
  if p:GetAttribute("BridgeRestCF")then assert(not p.CanCollide,"Animated collision moves")elseif p.CanCollide then fixed+=1 assert(p.Transparency==1,"Fixed collider visible")end
 end end
 assert(towers==4 and orbs==4 and neon>80 and fixed>=80,"Suspension geometry incomplete")
 for x=left-6,right+6,.75 do
  local hit=workspace:Raycast(Vector3.new(x,100,z),Vector3.new(0,-140,0),ra)assert(hit,"Missing bridge floor")
  if last then local grade=math.abs(hit.Position.Y-last)/.75 maximum=math.max(maximum,grade)assert(grade<.65,"Steep lip at "..z..","..x..":"..grade)end last=hit.Position.Y
  assert(hit.Normal.Y>.84,"Unsafe walking slope")
  -- Leave space for the feet to follow the slope; test torso/head clearance above it.
  local blockers=workspace:GetPartBoundsInBox(CFrame.new(x,hit.Position.Y+3.7,z),Vector3.new(3,4,3),overlap)
  assert(#blockers==0,"Blocked bridge path at "..x..","..z..":"..(#blockers>0 and blockers[1]:GetFullName()or "")) samples+=1
 end
end
local parts=0 for _,d in ipairs(w:GetDescendants())do if d:IsA("BasePart")then parts+=1 assert(d.Anchored,"Unanchored scenery")end assert(not d:IsA("LuaSourceContainer"),"World script")end assert(parts<6500,"Scene budget exceeded")
local compiled=0
for _,container in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(container:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
local profile=Climate.profile(9.25,0,1,0)profile.hour=9.25 Climate.apply(game.Lighting,workspace.Terrain,profile)
return {parts=parts,bridgeParts=bridgeParts,walkSamples=samples,maxGrade=maximum,cyanGoldSuspension=true,fixedCollision=true,compiledScripts=compiled,daySeconds=600,transitionSeconds=8,personalNightAndRain=true}
]========])

local clients=run([========[-- Execute real client sources with simulated input and time on native Roblox objects.
local function signal()
 local callbacks={}local s={}
 function s:Connect(fn)table.insert(callbacks,fn)return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in ipairs(callbacks)do fn(...)end end
 return s
end
local sandbox=Instance.new("Folder")sandbox.Name="QA80"sandbox.Parent=game.ServerStorage
local playerGui=Instance.new("Folder")playerGui.Parent=sandbox
local char=Instance.new("Model")char.Parent=sandbox
local root=Instance.new("Part")root.Name="HumanoidRootPart"root.Anchored=true root.CanCollide=false root.Parent=char
local h=Instance.new("Humanoid")h.Parent=char
local attrs={}local events={}local bindings={}
local player={Character=char,CharacterAdded=signal()}
function player:WaitForChild(name)assert(name=="PlayerGui")return playerGui end
function player:GetAttribute(k)return attrs[k]end
function player:SetAttribute(k,v)attrs[k]=v if events[k]then events[k]:Fire()end end
function player:GetAttributeChangedSignal(k)events[k]=events[k]or signal()return events[k]end
local players={LocalPlayer=player}function players:GetPlayers()return {player}end
local run={RenderStepped=signal(),Heartbeat=signal()}
local now=0 local delays={}local fakeTask={}
function fakeTask.delay(time,fn)table.insert(delays,{at=now+time,fn=fn})end
function fakeTask.spawn(fn,...)fn(...)end
local function advance(seconds)
 local untilTime=now+seconds
 while true do
  local index local earliest=math.huge
  for i,t in ipairs(delays)do if t.at<earliest then earliest=t.at index=i end end
  if earliest>untilTime then break end now=earliest local callback=table.remove(delays,index)callback.fn()
 end now=untilTime
end
local tweenCount=0 local pulses=0 local fakeTweens={}
function fakeTweens:Create(part,info,goal)
 tweenCount+=1 if info.RepeatCount==-1 then pulses+=1 end
 return {Play=function()for k,v in pairs(goal)do part[k]=v end end,Cancel=function()end}
end
local services={Players=players,RunService=run,UserInputService={TouchEnabled=true}}
local fakeGame={ReplicatedStorage=game.ReplicatedStorage}
function fakeGame:GetService(name)return services[name] or game:GetService(name)end
local scriptMock={Destroying=signal()}
local function execute(name,src)
 local m=Instance.new("ModuleScript")m.Name=name m.Source="return function(env)\nlocal game=env.game local script=env.script local task=env.task\n"..src.."\nend"m.Parent=sandbox
 require(m)({game=fakeGame,script=scriptMock,task=fakeTask,bind=function(b,fn)bindings[b]=fn end})
end
local SPS=game.StarterPlayer.StarterPlayerScripts
local source=SPS.SerenaWeatherMenu.Source
for _,name in ipairs({"b","open","close"})do source=source:gsub(name.."%.Activated:Connect%(","env.bind("..name..",")end
execute("Menu",source)
local gui=playerGui.SerenaWeatherUI local panel=gui.ClimatePanel local options=panel.ClimateOptions
assert(options:IsA("ScrollingFrame") and options.AutomaticCanvasSize==Enum.AutomaticSize.Y and options.ClipsDescendants,"Scrolling menu missing")
bindings[gui.OpenClimate]()assert(panel.Visible,"Menu does not open")
bindings[options.SerenaTimeChoice_Noite]()bindings[options.SerenaWeatherChoice_Chuva]()
assert(attrs.SerenaTimeChoice=="Noite"and attrs.SerenaWeatherChoice=="Chuva","Menu selections incorrect")
assert(options.SerenaTimeChoice_Noite.Text:find("✓",1,true),"Selected state missing")
bindings[panel.CloseClimate]()assert(not panel.Visible,"Menu does not close")
-- Real ambience script must use personal choices without changing shared world attributes.
run.RenderStepped=signal()scriptMock={Destroying=signal()}
local w=workspace.IlhaSerena local snapshot={clock=w:GetAttribute("ClockStart"),changed=w:GetAttribute("WeatherChanged"),weather=w:GetAttribute("Weather"),previous=w:GetAttribute("PreviousWeather")}
w:SetAttribute("ClockStart",workspace:GetServerTimeNow())w:SetAttribute("WeatherChanged",workspace:GetServerTimeNow()-8)w:SetAttribute("Weather","Sol")w:SetAttribute("PreviousWeather","Sol")
local oldCamera=workspace.CurrentCamera local testCamera=Instance.new("Camera")testCamera.CFrame=CFrame.new(104,28,87)testCamera.Parent=workspace workspace.CurrentCamera=testCamera
local lights={}
for _,d in ipairs(w:GetDescendants())do if d:IsA("PointLight")or d:IsA("ParticleEmitter")then lights[d]=d.Enabled end end
execute("ActualPersonalAmbience",SPS.SerenaAmbienceClient.Source)
for _=1,100 do run.RenderStepped:Fire(.05)end
assert(math.abs(attrs.SerenaAppliedHour-23)<.01 and attrs.SerenaAppliedRain>.99,"Night/rain not applied")
assert(w:GetAttribute("Weather")=="Sol","Personal weather changed server state")
local rain=workspace.SerenaLocalRain local visible=0
for _,p in ipairs(rain:GetChildren())do if p.Name=="Chuva"and p.Transparency<1 then visible+=1 end end assert(visible>0,"Personal rain invisible")
player:SetAttribute("SerenaTimeChoice","Dia")player:SetAttribute("SerenaWeatherChoice","Sol")
for _=1,100 do run.RenderStepped:Fire(.05)end
assert(math.abs(attrs.SerenaAppliedHour-12)<.01 and attrs.SerenaAppliedRain<.01,"Day/sun not applied")
for _,p in ipairs(rain:GetChildren())do if p.Name=="Chuva"then assert(p.Transparency==1,"Rain remains after choosing sun")end end
player:SetAttribute("SerenaTimeChoice","Amanhecer")player:SetAttribute("SerenaWeatherChoice","Nublado")
for _=1,100 do run.RenderStepped:Fire(.05)end
assert(math.abs(attrs.SerenaAppliedHour-6.2)<.01,"Dawn not applied")
scriptMock.Destroying:Fire()
for d,value in pairs(lights)do if d.Parent then d.Enabled=value end end
workspace.CurrentCamera=oldCamera testCamera:Destroy()
w:SetAttribute("ClockStart",snapshot.clock)w:SetAttribute("WeatherChanged",snapshot.changed)w:SetAttribute("Weather",snapshot.weather)w:SetAttribute("PreviousWeather",snapshot.previous)
-- Actual bridge scheduler: raised visual pieces settle; fixed floors never move.
services.TweenService=fakeTweens run.Heartbeat=signal()scriptMock={Destroying=signal()}
local m=w.TrilhasEMirante.Ponte70 root.CFrame=CFrame.new(m:GetAttribute("BridgeCenter")+Vector3.new(0,4,0))
local originals={}local fixed={}
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then originals[p]={cf=p.CFrame,size=p.Size,alpha=p.Transparency}if p.CanCollide then fixed[p]=p.CFrame end end end
execute("ActualBridgeAnimation",SPS.SerenaBridgeAnimation.Source)
run.Heartbeat:Fire(.31)
local raised=0
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")then
 assert(p.Transparency==1,"Construction not hidden initially")assert(p.Position.Y>p:GetAttribute("BridgeRestCF").Y+11,"Construction does not drop")raised+=1
end end assert(raised>200,"Construction did not start")
for p,cf in pairs(fixed)do assert(p.CFrame==cf,"Floor moved during construction")end
advance(8)
for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")then assert((p.Position-p:GetAttribute("BridgeRestCF").Position).Magnitude<.01 and p.Transparency<1,"Construction does not finish")end end
assert(pulses>=4 and tweenCount>raised,"Orb pulse missing")
for p,cf in pairs(fixed)do assert(p.CFrame==cf,"Collision moved after tween")end
scriptMock.Destroying:Fire()
-- Both tagged bridges are within range, so restore all visuals touched by the test.
for _,bridge in ipairs({w.TrilhasEMirante.Ponte70,w.TrilhasEMirante.Ponte124})do for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("BridgeRestCF")then p.CFrame=p:GetAttribute("BridgeRestCF")p.Transparency=p:GetAttribute("BridgeAlpha")or 0 if p:GetAttribute("BridgeOrb")then p.Size=Vector3.new(1.8,1.8,1.8)end end end bridge:SetAttribute("LocalConstructionEnds",nil)end
local Climate=require(game.ReplicatedStorage.SerenaRuntime.Climate)local profile=Climate.profile(9.25,0,1,0)profile.hour=9.25 Climate.apply(game.Lighting,workspace.Terrain,profile)
sandbox:Destroy()
return {actualClientSources=true,scrollingMenu=true,combinedNightRain=true,dayAndDawn=true,worldWeatherUnchanged=true,constructionRaisedAndSettled=true,stationaryFloor=true,orbPulses=pulses,scheduledTweens=tweenCount}
]========])

world:SetAttribute("UpgradeVersion",80)world:SetAttribute("DesignVersion",3)
game:GetService("AssetService"):SavePlaceAsync()
return {geometry=geometry,clients=clients,published=true,sourceVersion=game.PlaceVersion}
