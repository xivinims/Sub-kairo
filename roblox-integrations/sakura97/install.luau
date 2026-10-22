-- XN [VOICE] v110 giant nature world
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")
local A=game:GetService("AssetService")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local RF=game:GetService("ReplicatedFirst")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local SG=game:GetService("StarterGui")
local Terrain=workspace.Terrain
local IDS={PBR=13536410655,HD=18242663106,ROCKS=8248445118,BIGTREE=86013526879602,WIND=11946229834,BUTTERFLY=5287371738,LEAVES=14463654629}
local function load(id) local ok,x=pcall(A.LoadAssetAsync,A,id); assert(ok and x,"asset "..id.." failed"); return x end
local function clear(c) for _,x in ipairs(c:GetChildren()) do x:Destroy() end end
local function strip(x) for _,d in ipairs(x:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored=true; d.CanCollide=false; d.CanTouch=false end end end

for _,x in ipairs(workspace:GetChildren()) do if x~=Terrain and not x:IsA("Camera") then x:Destroy() end end
Terrain:Clear(); clear(SSS); clear(RF); clear(SS); clear(SP.StarterPlayerScripts); clear(SG); clear(Lighting)
for _,x in ipairs(RS:GetChildren()) do if x.Name=="XNRuntime" or x.Name=="SweanRuntime" or x.Name=="SakuraRuntime" then x:Destroy() end end

local rt=Instance.new("Folder"); rt.Name="XNRuntime"; rt.Parent=RS
rt:SetAttribute("Version",110); rt:SetAttribute("GameName","XN [VOICE]"); rt:SetAttribute("WorldWidth",270000); rt:SetAttribute("WorldDepth",270000); rt:SetAttribute("ChunkSize",512)
for k,v in pairs(IDS) do rt:SetAttribute(k.."AssetId",v) end
workspace.FallenPartsDestroyHeight=-500
pcall(function() workspace.StreamingEnabled=true; workspace.StreamingMinRadius=96; workspace.StreamingTargetRadius=384 end)

Terrain.WaterColor=Color3.fromRGB(54,113,105); Terrain.WaterTransparency=.34; Terrain.WaterReflectance=.12; Terrain.WaterWaveSize=.08; Terrain.WaterWaveSpeed=7
Lighting.ClockTime=13.7; Lighting.Brightness=2.45; Lighting.ExposureCompensation=.03; Lighting.Ambient=Color3.fromRGB(125,129,120); Lighting.OutdoorAmbient=Color3.fromRGB(154,158,148); Lighting.GlobalShadows=true
local at=Instance.new("Atmosphere"); at.Name="NatureAtmosphere"; at.Density=.12; at.Offset=.08; at.Color=Color3.fromRGB(205,218,207); at.Decay=Color3.fromRGB(132,153,142); at.Haze=.5; at.Glare=.04; at.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect"); cc.Name="NatureColor"; cc.Contrast=.035; cc.Saturation=.055; cc.Brightness=.01; cc.Parent=Lighting

local templates=Instance.new("Folder"); templates.Name="NatureTemplates"; templates.Parent=SS
local function pack(id,name)
 local a=load(id); local f=Instance.new("Folder"); f.Name=name; f:SetAttribute("AssetId",id); f.Parent=templates
 for _,x in ipairs(a:GetChildren()) do local q=x:Clone(); strip(q); q.Parent=f end
 a:Destroy(); assert(#f:GetChildren()>0,name.." pack empty")
end
pack(IDS.PBR,"PBR"); pack(IDS.HD,"HD"); pack(IDS.ROCKS,"Rocks"); pack(IDS.BIGTREE,"BigTree"); pack(IDS.BUTTERFLY,"Butterfly"); pack(IDS.LEAVES,"LeafFX")

workspace.GlobalWind=Vector3.new(13,0,4)
local wa=load(IDS.WIND); local wc=wa:FindFirstChild("WindController",true)
assert(wc and wc:IsA("LocalScript") and wc:FindFirstChild("WindLines") and wc:FindFirstChild("WindShake"),"wind invalid")
local w=wc:Clone(); w.Name="WindController"; w:SetAttribute("AssetId",IDS.WIND); w.Parent=SP.StarterPlayerScripts; wa:Destroy()

local chunks=Instance.new("Folder"); chunks.Name="NatureChunks"; chunks.Parent=workspace
local spawn=Instance.new("SpawnLocation"); spawn.Name="NatureSpawn"; spawn.Size=Vector3.new(8,.5,8); spawn.Transparency=1; spawn.Anchored=true; spawn.CanCollide=false; spawn.Neutral=true; spawn.Enabled=true; spawn.CFrame=CFrame.new(0,15,0); spawn.Parent=workspace

local gen=Instance.new("Script"); gen.Name="NatureWorldGenerator"; gen.Source=__RUNTIME_SOURCE__; gen.Parent=SSS

local loader=Instance.new("LocalScript"); loader.Name="XNLoading"; loader.Source=[[
local RF=game:GetService("ReplicatedFirst"); local P=game:GetService("Players"); local T=game:GetService("TweenService")
RF:RemoveDefaultLoadingScreen(); local p=P.LocalPlayer; p.CameraMode=Enum.CameraMode.Classic
local g=Instance.new("ScreenGui"); g.IgnoreGuiInset=true; g.DisplayOrder=10000; g.ResetOnSpawn=false
local b=Instance.new("Frame"); b.Size=UDim2.fromScale(1,1); b.BackgroundColor3=Color3.fromRGB(8,9,8); b.BorderSizePixel=0; b.Parent=g
local t=Instance.new("TextLabel"); t.AnchorPoint=Vector2.new(.5,.5); t.Position=UDim2.fromScale(.5,.5); t.Size=UDim2.new(.7,0,0,50); t.BackgroundTransparency=1; t.Text="acessando…"; t.TextColor3=Color3.fromRGB(240,242,239); t.TextSize=25; t.Font=Enum.Font.BuilderSans; t.Parent=b; g.Parent=p:WaitForChild("PlayerGui")
if not game:IsLoaded() then game.Loaded:Wait() end; task.wait(.35); T:Create(t,TweenInfo.new(.2),{TextTransparency=1}):Play(); local f=T:Create(b,TweenInfo.new(.35),{BackgroundTransparency=1}); f:Play(); f.Completed:Wait(); g:Destroy()
]]; loader.Parent=RF
return {ok=true,version=110,worldWidth=270000}
