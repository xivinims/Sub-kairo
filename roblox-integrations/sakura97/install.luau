-- XN [VOICE] v102 — Brookhaven clean Halloween build
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")
local A=game:GetService("AssetService")
local CS=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local RF=game:GetService("ReplicatedFirst")
local SP=game:GetService("StarterPlayer")
local SSS=game:GetService("ServerScriptService")
local Terrain=workspace.Terrain
local MAP=106476929993683
local WIND=11946229834
local HALLOWEEN=12489961338
local function load(id)
 local ok,x=pcall(A.LoadAssetAsync,A,id); assert(ok and x,"asset "..id.." failed "..tostring(x)); return x
end

-- clean previous build
for _,x in ipairs(workspace:GetChildren()) do if x~=Terrain and not x:IsA("Camera") then x:Destroy() end end
Terrain:Clear()
for _,c in ipairs({SSS,RF,SP.StarterPlayerScripts,game:GetService("StarterGui")}) do for _,x in ipairs(c:GetChildren()) do x:Destroy() end end
for _,x in ipairs(RS:GetChildren()) do if x.Name=="SweanRuntime" or x.Name=="SakuraRuntime" then x:Destroy() end end
for _,x in ipairs(Lighting:GetChildren()) do x:Destroy() end

local rt=Instance.new("Folder"); rt.Name="SweanRuntime"; rt.Parent=RS
rt:SetAttribute("Version",102); rt:SetAttribute("ExperienceName","XN [VOICE]"); rt:SetAttribute("MapAssetId",MAP)

pcall(function()
 workspace.StreamingEnabled=true
 workspace.StreamingMinRadius=96
 workspace.StreamingTargetRadius=360
end)
workspace.FallenPartsDestroyHeight=-700

-- exact Brookhaven visual map, but strip all embedded code
local asset=load(MAP)
local source=asset:FindFirstChild("Brookhaven Map",true); assert(source and source:IsA("Model"),"Brookhaven Map missing")
local map=source:Clone(); map.Name="XN_City"; map:SetAttribute("AssetId",MAP); map.Parent=workspace
local scripts,parts,models,vehicles=0,0,0,0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then scripts+=1; d:Destroy()
 elseif d:IsA("BasePart") then parts+=1; d.Anchored=true; d.CanTouch=false
 elseif d:IsA("Model") then models+=1 end
end
-- remove vehicle collection: large static clutter + scripts already stripped
local veh=map:FindFirstChild("Vehicles",true)
if veh then vehicles=#veh:GetChildren(); veh:Destroy() end
local cf,size=map:GetBoundingBox()
map:PivotTo(map:GetPivot()+Vector3.new(-cf.Position.X,size.Y/2-cf.Position.Y,-cf.Position.Z))
rt:SetAttribute("OriginalScriptsRemoved",scripts); rt:SetAttribute("VehiclesRemoved",vehicles)
asset:Destroy()

-- lighting / Halloween atmosphere
Lighting.ClockTime=17.55; Lighting.Brightness=2.1; Lighting.ExposureCompensation=-.12
Lighting.Ambient=Color3.fromRGB(76,72,78); Lighting.OutdoorAmbient=Color3.fromRGB(112,102,106)
Lighting.GlobalShadows=true
local at=Instance.new("Atmosphere"); at.Name="XNAtmosphere"; at.Density=.22; at.Offset=.05
at.Color=Color3.fromRGB(184,174,177); at.Decay=Color3.fromRGB(84,72,79); at.Haze=1.15; at.Glare=.03; at.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect"); cc.Name="XNColor"; cc.Contrast=.1; cc.Saturation=-.08
cc.TintColor=Color3.fromRGB(235,218,207); cc.Parent=Lighting

-- wind
workspace.GlobalWind=Vector3.new(15,0,5)
local wa=load(WIND); local wc=wa:FindFirstChild("WindController",true)
assert(wc and wc:IsA("LocalScript") and wc:FindFirstChild("WindLines") and wc:FindFirstChild("WindShake"),"wind asset incomplete")
local w=wc:Clone(); w.Name="WindController"; w:SetAttribute("AssetId",WIND); w.Parent=SP.StarterPlayerScripts; wa:Destroy()

-- identify actual green horizontal map surfaces, tag them, and add sparse grass only there
local green={}
for _,p in ipairs(map:GetDescendants()) do
 if p:IsA("BasePart") and p.CFrame.UpVector.Y>.92 and p.Size.X>=5 and p.Size.Z>=5 then
  local c=p.Color
  local greenish=(c.G>c.R*1.08 and c.G>c.B*1.04) or p.Material==Enum.Material.Grass
  local n=p.Name:lower()
  if greenish and not n:find("tree",1,true) and not n:find("leaf",1,true) then
   table.insert(green,p); CS:AddTag(p,"XNGreenGround")
  end
 end
end
assert(#green>20,"too few green ground surfaces "..#green)

local grass=Instance.new("Folder"); grass.Name="XN_Grass"; grass.Parent=workspace
local gp=RaycastParams.new(); gp.FilterType=Enum.RaycastFilterType.Include; gp.FilterDescendantsInstances=green; gp.IgnoreWater=true
local rng=Random.new(10222); local grassCount=0
for i=1,math.min(420,#green*4) do
 local s=green[rng:NextInteger(1,#green)]
 local x=rng:NextNumber(-s.Size.X*.45,s.Size.X*.45); local z=rng:NextNumber(-s.Size.Z*.45,s.Size.Z*.45)
 local origin=s.CFrame:PointToWorldSpace(Vector3.new(x,8,z))
 local hit=workspace:Raycast(origin,Vector3.new(0,-18,0),gp)
 if hit and hit.Instance==s then
  local blade=Instance.new("Part"); blade.Name="GrassPatch"; blade.Anchored=true; blade.CanCollide=false; blade.CanTouch=false; blade.CanQuery=false
  blade.Material=Enum.Material.Grass; blade.Color=s.Color; blade.Size=Vector3.new(rng:NextNumber(.12,.22),rng:NextNumber(.9,1.5),rng:NextNumber(.12,.22))
  blade.CFrame=CFrame.new(hit.Position+Vector3.new(0,blade.Size.Y*.5,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),rng:NextNumber(-.08,.08))
  blade.Parent=grass; grassCount+=1
 end
end
rt:SetAttribute("GreenSurfaces",#green); rt:SetAttribute("GrassBlades",grassCount)

-- tag foliage for WindShake, never trunks
local windTagged=0
for _,p in ipairs(map:GetDescendants()) do
 if p:IsA("BasePart") then
  local n=p.Name:lower(); local c=p.Color
  if (n:find("leaf",1,true) or n:find("leaves",1,true) or (c.G>c.R*1.18 and p.Size.Y>2 and p.Size.X<80)) and p.Material~=Enum.Material.Wood and p.Material~=Enum.Material.WoodPlanks then
   CS:AddTag(p,"WindShake"); p:SetAttribute("WindPower",.28); p:SetAttribute("WindSpeed",15); windTagged+=1
  end
 end
end
rt:SetAttribute("WindTagged",windTagged)

-- Halloween: pumpkins only, arranged in small groups on green ground
local ha=load(HALLOWEEN); local templates={}
for _,d in ipairs(ha:GetDescendants()) do if d:IsA("BasePart") and d.Name=="Pumpkin" then table.insert(templates,d:Clone()) end end
ha:Destroy(); assert(#templates>0,"pumpkins missing")
local deco=Instance.new("Folder"); deco.Name="XN_Halloween"; deco:SetAttribute("OnlyPumpkins",true); deco.Parent=workspace
local pumpkinCount=0
for cluster=1,10 do
 local s=green[((cluster-1)%#green)+1]
 local folder=Instance.new("Folder"); folder.Name=string.format("PumpkinCluster_%02d",cluster); folder.Parent=deco
 for j=1,3 do
  local lx=(j-2)*3.2; local lz=(j%2==0) and 1.8 or -1.2
  local o=s.CFrame:PointToWorldSpace(Vector3.new(lx,10,lz))
  local hit=workspace:Raycast(o,Vector3.new(0,-22,0),gp)
  if hit and hit.Instance==s then
   local p=templates[((pumpkinCount)%#templates)+1]:Clone(); p.Name="Pumpkin"; p.Anchored=true; p.CanCollide=false; p.CanTouch=false
   p.CFrame=CFrame.new(hit.Position+Vector3.new(0,p.Size.Y*.45,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0); p.Parent=folder; pumpkinCount+=1
  end
 end
end
for _,p in ipairs(templates) do p:Destroy() end
rt:SetAttribute("Pumpkins",pumpkinCount)

-- safe spawn near center
local mp=RaycastParams.new(); mp.FilterType=Enum.RaycastFilterType.Include; mp.FilterDescendantsInstances={map}; mp.IgnoreWater=true
local spawnPos
for r=0,1000,50 do for k=1,30 do local a=k/30*math.pi*2; local hit=workspace:Raycast(Vector3.new(math.cos(a)*r,size.Y+300,math.sin(a)*r),Vector3.new(0,-(size.Y+800),0),mp); if hit and hit.Normal.Y>.75 then spawnPos=hit.Position break end end if spawnPos then break end end
assert(spawnPos,"spawn not found")
local sp=Instance.new("SpawnLocation"); sp.Name="XNSpawn"; sp.Size=Vector3.new(8,.5,8); sp.Transparency=1; sp.CanCollide=false; sp.Anchored=true; sp.Neutral=true; sp.Enabled=true; sp.CFrame=CFrame.new(spawnPos+Vector3.new(0,.25,0)); sp.Parent=workspace

-- fullscreen loading + glitch + first-person-to-third-person zoom, camera rotation remains player controlled
local loader=Instance.new("LocalScript"); loader.Name="XNLoading"; loader.Source=[[
local RF=game:GetService("ReplicatedFirst")
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
RF:RemoveDefaultLoadingScreen()
local p=Players.LocalPlayer
local gui=Instance.new("ScreenGui"); gui.Name="XNLoading"; gui.IgnoreGuiInset=true; gui.DisplayOrder=10000; gui.ResetOnSpawn=false
local bg=Instance.new("Frame"); bg.Size=UDim2.fromScale(1,1); bg.BackgroundColor3=Color3.fromRGB(7,7,9); bg.BorderSizePixel=0; bg.Parent=gui
local txt=Instance.new("TextLabel"); txt.AnchorPoint=Vector2.new(.5,.5); txt.Position=UDim2.fromScale(.5,.5); txt.Size=UDim2.fromScale(.72,.12); txt.BackgroundTransparency=1
txt.Text="acessando…"; txt.TextColor3=Color3.fromRGB(238,238,242); txt.TextScaled=true; txt.Font=Enum.Font.BuilderSans; txt.Parent=bg
local constraint=Instance.new("UITextSizeConstraint"); constraint.MaxTextSize=42; constraint.MinTextSize=20; constraint.Parent=txt
gui.Parent=p:WaitForChild("PlayerGui")
for i=1,16 do
 txt.Position=UDim2.fromScale(.5+((i%3)-1)*.003,.5+((i%2)*2-1)*.002)
 txt.TextTransparency=(i%5==0) and .28 or 0
 if i%4==0 then bg.BackgroundColor3=Color3.fromRGB(13,10,15) else bg.BackgroundColor3=Color3.fromRGB(7,7,9) end
 task.wait(.055)
end
txt.Position=UDim2.fromScale(.5,.5); txt.TextTransparency=0
if not game:IsLoaded() then game.Loaded:Wait() end
local char=p.Character or p.CharacterAdded:Wait(); char:WaitForChild("HumanoidRootPart")
p.CameraMode=Enum.CameraMode.Classic
local oldMin,oldMax=p.CameraMinZoomDistance,p.CameraMaxZoomDistance
p.CameraMinZoomDistance=.5; p.CameraMaxZoomDistance=.55
task.wait(.12)
TweenService:Create(bg,TweenInfo.new(.45,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
TweenService:Create(txt,TweenInfo.new(.28),{TextTransparency=1}):Play()
for z=.55,10,.45 do p.CameraMinZoomDistance=z; p.CameraMaxZoomDistance=z+.08; RunService.RenderStepped:Wait() end
p.CameraMinZoomDistance=oldMin; p.CameraMaxZoomDistance=oldMax
task.wait(.1); gui:Destroy()
]]; loader.Parent=RF

local guard=Instance.new("Script"); guard.Name="XNServer"; guard.Source=[[
local Players=game:GetService("Players"); local sp=workspace:WaitForChild("XNSpawn")
local function hook(p)
 p.RespawnLocation=sp
 p.CharacterAdded:Connect(function(c) task.spawn(function() while c.Parent do local r=c:FindFirstChild("HumanoidRootPart"); if r and r.Position.Y<-650 then c:PivotTo(sp.CFrame*CFrame.new(0,4,0)) end task.wait(.5) end end) end)
end
Players.PlayerAdded:Connect(hook); for _,p in ipairs(Players:GetPlayers()) do hook(p) end
]]; guard.Parent=SSS

return {version=102,map="Brookhaven Map",scriptsRemoved=scripts,greenSurfaces=#green,grass=grassCount,windTagged=windTagged,pumpkins=pumpkinCount}
