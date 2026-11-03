local Workspace=game:GetService("Workspace")
local Terrain=Workspace.Terrain
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local StarterGui=game:GetService("StarterGui")
local StarterPack=game:GetService("StarterPack")
local StarterPlayer=game:GetService("StarterPlayer")
local ServerScriptService=game:GetService("ServerScriptService")
local SoundService=game:GetService("SoundService")
local InsertService=game:GetService("InsertService")
local AssetService=game:GetService("AssetService")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
local sourceVersion=game.PlaceVersion
local SERVER_SOURCE=__SERVER_SOURCE__
local CLIENT_SOURCE=__CLIENT_SOURCE__

local IDS={
 PrimaryCircle=115275786272862,
 MagicCircles=9132974153,
 PlayerStaff=3832698706,
 NPCStaff=84222065610676,
 NPC=106281505667193,
 BlackFlash=102185762902096,
 Gravity=126521784338665,
}

local function loadAsset(id)
 local ok,obj=pcall(function()return InsertService:LoadAsset(id)end)
 assert(ok and obj,"Failed loading requested asset "..tostring(id)..": "..tostring(obj))
 return obj
end
local function sanitize(root)
 for _,d in ipairs(root:GetDescendants())do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
   d:Destroy()
  elseif d:IsA("BasePart")then
   d.CanCollide=false;d.CanTouch=false;d.CanQuery=false
  end
 end
 return root
end
local function findModelWithHumanoid(root)
 for _,d in ipairs(root:GetDescendants())do
  if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid")then return d end
 end
end
local function findTool(root)
 for _,d in ipairs(root:GetDescendants())do if d:IsA("Tool")then return d end end
end
local function findPartByName(root,name)
 for _,d in ipairs(root:GetDescendants())do if d:IsA("BasePart") and d.Name==name then return d end end
end
local function firstParticleRoot(root)
 for _,d in ipairs(root:GetDescendants())do
  if d:IsA("BasePart") and d:FindFirstChildWhichIsA("Attachment")then
   for _,x in ipairs(d:GetDescendants())do if x:IsA("ParticleEmitter")then return d end end
  end
 end
end

-- Remove all old gameplay and all loading UI.
for _,obj in ipairs(Workspace:GetChildren())do
 if obj~=Terrain and not obj:IsA("Camera")then obj:Destroy()end
end
Terrain:Clear()
for _,obj in ipairs(ReplicatedFirst:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterGui:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterPack:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterPlayer.StarterCharacterScripts:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterPlayer.StarterPlayerScripts:GetChildren())do
 if obj.Name~="PlayerModule" and obj.Name~="RbxCharacterSounds" and obj.Name~="PlayerScriptsLoader" then obj:Destroy()end
end
for _,obj in ipairs(ServerScriptService:GetChildren())do
 if obj.Name~="OveryardUpdateMigrationServer" then obj:Destroy()end
end
for _,obj in ipairs(ReplicatedStorage:GetChildren())do
 if obj.Name~="OveryardUpdateEvent" then obj:Destroy()end
end
for _,obj in ipairs(SoundService:GetChildren())do obj:Destroy()end
for _,obj in ipairs(Lighting:GetChildren())do obj:Destroy()end

Workspace.StreamingEnabled=true
Workspace.GlobalWind=Vector3.new(0,0,0)

local world=Instance.new("Folder")
world.Name="MageDuelWorld"
world.Parent=Workspace

local floor=Instance.new("Part")
floor.Name="CleanFloor";floor.Anchored=true;floor.Size=Vector3.new(720,2,720);floor.Position=Vector3.new(0,-1,0)
floor.Material=Enum.Material.Slate;floor.Color=Color3.fromRGB(49,54,64);floor.TopSurface=Enum.SurfaceType.Smooth;floor.BottomSurface=Enum.SurfaceType.Smooth;floor.Parent=world

local inner=Instance.new("Part")
inner.Name="ArenaInlay";inner.Anchored=true;inner.Shape=Enum.PartType.Cylinder;inner.Size=Vector3.new(.3,210,210)
inner.CFrame=CFrame.new(0,.16,0)*CFrame.Angles(0,0,math.rad(90));inner.Material=Enum.Material.SmoothPlastic;inner.Color=Color3.fromRGB(64,70,84);inner.CanCollide=false;inner.Parent=world

local ring=Instance.new("Part")
ring.Name="ArenaRing";ring.Anchored=true;ring.Shape=Enum.PartType.Cylinder;ring.Size=Vector3.new(.10,226,226)
ring.CFrame=CFrame.new(0,.32,0)*CFrame.Angles(0,0,math.rad(90));ring.Material=Enum.Material.Neon;ring.Color=Color3.fromRGB(168,215,255);ring.Transparency=.58;ring.CanCollide=false;ring.Parent=world

local spawn=Instance.new("SpawnLocation")
spawn.Name="MageSpawn";spawn.Size=Vector3.new(7,1,7);spawn.Position=Vector3.new(0,.55,96);spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Parent=world

Lighting.ClockTime=21
Lighting.Brightness=2.1
Lighting.Ambient=Color3.fromRGB(53,61,82)
Lighting.OutdoorAmbient=Color3.fromRGB(72,84,112)
Lighting.EnvironmentDiffuseScale=.32
Lighting.EnvironmentSpecularScale=.78
Lighting.GlobalShadows=true
Lighting.FogColor=Color3.fromRGB(62,76,108)
Lighting.FogStart=390
Lighting.FogEnd=930
pcall(function()Lighting.Technology=Enum.Technology.Future end)
local atm=Instance.new("Atmosphere");atm.Name="MageAtmosphere";atm.Density=.27;atm.Offset=.18;atm.Color=Color3.fromRGB(137,172,222);atm.Decay=Color3.fromRGB(47,57,94);atm.Haze=1.5;atm.Glare=.08;atm.Parent=Lighting
local bloom=Instance.new("BloomEffect");bloom.Name="MageBloom";bloom.Intensity=.42;bloom.Size=30;bloom.Threshold=.68;bloom.Parent=Lighting
local rays=Instance.new("SunRaysEffect");rays.Name="MageRays";rays.Intensity=.05;rays.Spread=.92;rays.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect");cc.Name="MageGrade";cc.Brightness=.01;cc.Contrast=.09;cc.Saturation=.02;cc.TintColor=Color3.fromRGB(235,242,255);cc.Parent=Lighting

local remotes=Instance.new("Folder");remotes.Name="MageDuelRemotes";remotes.Parent=ReplicatedStorage
local cast=Instance.new("RemoteEvent");cast.Name="Cast";cast.Parent=remotes
local feedback=Instance.new("RemoteEvent");feedback.Name="Feedback";feedback.Parent=remotes

local templates=Instance.new("Folder");templates.Name="MageAssetTemplates";templates.Parent=ReplicatedStorage
local circles=Instance.new("Folder");circles.Name="MagicCircles";circles.Parent=templates

-- Exact requested base magic circle.
do
 local asset=loadAsset(IDS.PrimaryCircle)
 local source=asset:FindFirstChildWhichIsA("BasePart",true)
 assert(source,"Primary magic circle has no BasePart")
 local clone=source:Clone();clone.Name="PrimaryMagicCircle";sanitize(clone);clone.Anchored=true;clone.Parent=circles
 clone:SetAttribute("SourceAssetId",IDS.PrimaryCircle)
 asset:Destroy()
end

-- Exact requested magic-circle collection, scripts removed but decals/geometry preserved.
do
 local asset=loadAsset(IDS.MagicCircles)
 local source=asset:FindFirstChildWhichIsA("Model",true)
 assert(source,"Magic circles collection missing Model")
 local clone=source:Clone();clone.Name="RuneCircleCollection";sanitize(clone)
 for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true end end
 clone.Parent=circles;clone:SetAttribute("SourceAssetId",IDS.MagicCircles)
 asset:Destroy()
end

-- Exact Black Flash VFX template.
do
 local asset=loadAsset(IDS.BlackFlash)
 local source=firstParticleRoot(asset)
 assert(source,"Black Flash VFX missing particle root")
 local clone=source:Clone();clone.Name="BlackFlash";sanitize(clone);clone.Anchored=true;clone.Parent=templates
 clone:SetAttribute("SourceAssetId",IDS.BlackFlash)
 asset:Destroy()
end

-- Exact purple Gravity Field VFX template.
do
 local asset=loadAsset(IDS.Gravity)
 sanitize(asset)
 asset.Name="GravityField"
 for _,p in ipairs(asset:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true end end
 asset.Parent=templates;asset:SetAttribute("SourceAssetId",IDS.Gravity)
end

-- Exact requested NPC boss.
local npcAsset=loadAsset(IDS.NPC)
local boss=findModelWithHumanoid(npcAsset)
assert(boss,"NPC asset does not contain a Humanoid model")
boss.Parent=world
npcAsset:Destroy()
boss.Name="AstraVeyra"
sanitize(boss)
boss:SetAttribute("SourceAssetId",IDS.NPC)
boss:SetAttribute("BossVersion","mage-duel-v2")
boss:SetAttribute("Active",false)

local hum=assert(boss:FindFirstChildOfClass("Humanoid"))
hum.MaxHealth=2600;hum.Health=2600;hum.WalkSpeed=0;hum.AutoRotate=false;hum.DisplayName="Astra Veyra";hum.NameDisplayDistance=100
if not hum:FindFirstChildOfClass("Animator")then Instance.new("Animator",hum)end
local root=assert(boss:FindFirstChild("HumanoidRootPart"),"NPC missing HumanoidRootPart")
for _,p in ipairs(boss:GetDescendants())do
 if p:IsA("BasePart")then p.Anchored=(p==root);p.CanCollide=false;p.CanTouch=false;p.Massless=(p~=root) end
end

-- Elegant robe/cape enhancement while keeping exact NPC model.
local torso=boss:FindFirstChild("Torso")
if torso and torso:IsA("BasePart")then
 local function overlay(name,size,offset,color,material)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Material=material or Enum.Material.Fabric;p.CanCollide=false;p.CanTouch=false;p.Massless=true;p.Anchored=false
  p.CFrame=torso.CFrame*offset;p.Parent=boss
  local w=Instance.new("WeldConstraint");w.Part0=torso;w.Part1=p;w.Parent=p
  return p
 end
 overlay("BossRobeFront",Vector3.new(2.05,2.05,.16),CFrame.new(0,0,-.56),Color3.fromRGB(239,239,242))
 overlay("BossCapeBack",Vector3.new(2.25,3.65,.18),CFrame.new(0,-.78,.60),Color3.fromRGB(37,39,49))
 overlay("BossGoldTrim",Vector3.new(2.18,.14,.20),CFrame.new(0,.55,-.60),Color3.fromRGB(187,153,78),Enum.Material.Metal)
end

-- Ground exact NPC.
boss:PivotTo(CFrame.new(0,8,-30))
local cf,size=boss:GetBoundingBox()
local bottom=cf.Position.Y-size.Y/2
boss:PivotTo(boss:GetPivot()+Vector3.new(0,.08-bottom,0))

-- Exact Frieren staff attached to NPC.
do
 local asset=loadAsset(IDS.NPCStaff)
 sanitize(asset)
 local staff=asset:FindFirstChildWhichIsA("Model",true) or asset
 staff.Parent=boss
 asset:Destroy()
 staff.Name="FrierenStaff"
 staff:SetAttribute("SourceAssetId",IDS.NPCStaff)
 local scf,ss=staff:GetBoundingBox()
 local scale=ss.Y>0 and 7.4/ss.Y or 1
 pcall(function()staff:ScaleTo(scale)end)
 local arm=boss:FindFirstChild("Right Arm") or boss:FindFirstChild("RightHand")
 assert(arm and arm:IsA("BasePart"),"NPC has no right arm/hand for staff")
 staff:PivotTo(arm.CFrame*CFrame.new(0,-1.6,-.65)*CFrame.Angles(0,0,math.rad(-8)))
 local primary=staff:FindFirstChildWhichIsA("BasePart",true)
 assert(primary,"NPC staff has no BasePart")
 for _,p in ipairs(staff:GetDescendants())do
  if p:IsA("BasePart")then
   p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.Massless=true
   if p~=primary then local w=Instance.new("WeldConstraint");w.Part0=primary;w.Part1=p;w.Parent=p end
  end
 end
 local armWeld=Instance.new("WeldConstraint");armWeld.Part0=arm;armWeld.Part1=primary;armWeld.Parent=primary
 local bcf,bs=staff:GetBoundingBox()
 local tip=Instance.new("Part");tip.Name="StaffTip";tip.Size=Vector3.new(.18,.18,.18);tip.Transparency=1;tip.CanCollide=false;tip.CanTouch=false;tip.Massless=true;tip.Anchored=false
 tip.CFrame=CFrame.new(bcf.Position+Vector3.new(0,bs.Y/2,0));tip.Parent=boss
 local tw=Instance.new("WeldConstraint");tw.Part0=primary;tw.Part1=tip;tw.Parent=tip
end

-- Exact requested player staff, original legacy scripts removed and replaced.
do
 local asset=loadAsset(IDS.PlayerStaff)
 local tool=findTool(asset)
 assert(tool,"Player staff asset missing Tool")
 tool.Parent=StarterPack
 asset:Destroy()
 tool.Name="AstralStaff";tool.CanBeDropped=false;tool.RequiresHandle=true;tool.Enabled=true;tool.ManualActivationOnly=false;tool.ToolTip="Zoltraak • Barreira • Judradjim • Singularidade • Vida • Esquiva • Voo"
 sanitize(tool)
 tool:SetAttribute("SourceAssetId",IDS.PlayerStaff)
 local handle=assert(tool:FindFirstChild("Handle"),"Requested staff missing Handle")
 handle.Anchored=false;handle.CanCollide=false;handle.Massless=true
 for _,p in ipairs(tool:GetDescendants())do
  if p:IsA("BasePart")then
   p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.Massless=true
   if p~=handle then local w=Instance.new("WeldConstraint");w.Part0=handle;w.Part1=p;w.Parent=p end
  end
 end
 tool.Grip=CFrame.new(0,-1.25,0)*CFrame.Angles(0,0,math.rad(7))
 local client=Instance.new("LocalScript");client.Name="MageDuelClient";client.Source=CLIENT_SOURCE;client.Parent=tool
end

local server=Instance.new("Script");server.Name="MageDuelServer";server.Source=SERVER_SOURCE;server.Parent=ServerScriptService

Workspace:SetAttribute("BuildVersion","mage-duel-v2")
Workspace:SetAttribute("CleanRebuild",true)
Workspace:SetAttribute("BossReactiveOnly",true)
Workspace:SetAttribute("MagicBarrierLayers",3)
Workspace:SetAttribute("LoadingScreenRemoved",true)
Workspace:SetAttribute("RequestedAssetsExact",true)
Workspace:SetAttribute("MagicSystem","zoltraak+hex-barrier+judradjim+singularity+gravity+heal+dodge+flight")
Workspace:SetAttribute("StandardRobloxJump",true)

AssetService:SavePlaceAsync()

return {
 ok=true,sourceVersion=sourceVersion,buildVersion="mage-duel-v2",
 bossRig=tostring(hum.RigType),bossHealth=hum.MaxHealth,
 npcAsset=IDS.NPC,npcStaff=IDS.NPCStaff,playerStaff=IDS.PlayerStaff,
 primaryCircle=IDS.PrimaryCircle,magicCircles=IDS.MagicCircles,
 blackVFX=IDS.BlackFlash,gravityVFX=IDS.Gravity,
 loadingRemoved=#ReplicatedFirst:GetChildren()==0,
}
