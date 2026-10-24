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
local Players=game:GetService("Players")
local AssetService=game:GetService("AssetService")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
local sourceVersion=game.PlaceVersion

local SERVER_SOURCE=__SERVER_SOURCE__
local CLIENT_SOURCE=__CLIENT_SOURCE__

-- Clean rebuild: remove the old map, NPCs and gameplay, keep only update/loading infrastructure.
for _,obj in ipairs(Workspace:GetChildren())do
 if obj~=Terrain and not obj:IsA("Camera") then obj:Destroy()end
end
Terrain:Clear()

for _,obj in ipairs(StarterGui:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterPack:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterPlayer.StarterPlayerScripts:GetChildren())do obj:Destroy()end
for _,obj in ipairs(StarterPlayer.StarterCharacterScripts:GetChildren())do obj:Destroy()end
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

-- Clean neutral arena.
local world=Instance.new("Folder")
world.Name="MageDuelWorld"
world.Parent=Workspace

local floor=Instance.new("Part")
floor.Name="CleanFloor"
floor.Anchored=true
floor.Size=Vector3.new(640,2,640)
floor.Position=Vector3.new(0,-1,0)
floor.Material=Enum.Material.Slate
floor.Color=Color3.fromRGB(57,62,72)
floor.TopSurface=Enum.SurfaceType.Smooth
floor.BottomSurface=Enum.SurfaceType.Smooth
floor.Parent=world

local inner=Instance.new("Part")
inner.Name="ArenaInlay"
inner.Anchored=true
inner.Shape=Enum.PartType.Cylinder
inner.Size=Vector3.new(.35,170,170)
inner.CFrame=CFrame.new(0,.18,0)*CFrame.Angles(0,0,math.rad(90))
inner.Material=Enum.Material.SmoothPlastic
inner.Color=Color3.fromRGB(69,75,88)
inner.CanCollide=false
inner.Parent=world

local ring=Instance.new("Part")
ring.Name="ArenaRing"
ring.Anchored=true
ring.Shape=Enum.PartType.Cylinder
ring.Size=Vector3.new(.12,188,188)
ring.CFrame=CFrame.new(0,.38,0)*CFrame.Angles(0,0,math.rad(90))
ring.Material=Enum.Material.Neon
ring.Color=Color3.fromRGB(128,169,220)
ring.Transparency=.65
ring.CanCollide=false
ring.Parent=world

local spawn=Instance.new("SpawnLocation")
spawn.Name="MageSpawn"
spawn.Size=Vector3.new(7,1,7)
spawn.Position=Vector3.new(0,.55,92)
spawn.Anchored=true
spawn.Transparency=1
spawn.CanCollide=false
spawn.Neutral=true
spawn.Parent=world

-- Lighting optimized for bright spell readability.
Lighting.ClockTime=21.25
Lighting.Brightness=2.2
Lighting.Ambient=Color3.fromRGB(64,70,90)
Lighting.OutdoorAmbient=Color3.fromRGB(80,92,120)
Lighting.EnvironmentDiffuseScale=.35
Lighting.EnvironmentSpecularScale=.7
Lighting.GlobalShadows=true
Lighting.FogColor=Color3.fromRGB(75,87,112)
Lighting.FogStart=430
Lighting.FogEnd=900
pcall(function()Lighting.Technology=Enum.Technology.Future end)

local atm=Instance.new("Atmosphere")
atm.Name="MageAtmosphere";atm.Density=.24;atm.Offset=.2;atm.Color=Color3.fromRGB(147,178,225);atm.Decay=Color3.fromRGB(55,65,105);atm.Haze=1.3;atm.Glare=.1;atm.Parent=Lighting
local bloom=Instance.new("BloomEffect")
bloom.Name="MageBloom";bloom.Intensity=.36;bloom.Size=30;bloom.Threshold=.72;bloom.Parent=Lighting
local rays=Instance.new("SunRaysEffect")
rays.Name="MageRays";rays.Intensity=.055;rays.Spread=.9;rays.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect")
cc.Name="MageGrade";cc.Brightness=.015;cc.Contrast=.07;cc.Saturation=.04;cc.TintColor=Color3.fromRGB(238,243,255);cc.Parent=Lighting

-- Remotes
local remotes=Instance.new("Folder");remotes.Name="MageDuelRemotes";remotes.Parent=ReplicatedStorage
local cast=Instance.new("RemoteEvent");cast.Name="Cast";cast.Parent=remotes
local feedback=Instance.new("RemoteEvent");feedback.Name="Feedback";feedback.Parent=remotes

-- R15 boss
local desc=Instance.new("HumanoidDescription")
desc.HeightScale=1.04
desc.WidthScale=.78
desc.DepthScale=.80
desc.HeadScale=.96
desc.BodyTypeScale=.35
desc.ProportionScale=.78
local boss=Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)
desc:Destroy()
boss.Name="AstraVeyra"
boss.Parent=world

for _,d in ipairs(boss:GetDescendants())do
 if d:IsA("LuaSourceContainer")or d:IsA("Accessory")or d:IsA("Shirt")or d:IsA("Pants")or d:IsA("ShirtGraphic")or d:IsA("Decal")or d:IsA("Motor6D") then d:Destroy()
 elseif d:IsA("BasePart")then
  d.CanCollide=false;d.CanTouch=false;d.Massless=true
  d.Anchored=d.Name=="HumanoidRootPart"
  d.Color=Color3.fromRGB(234,221,215)
 end
end

local function motor(name,p0Name,p1Name,attachmentName)
 local p0=assert(boss:FindFirstChild(p0Name),p0Name)
 local p1=assert(boss:FindFirstChild(p1Name),p1Name)
 local a0=assert(p0:FindFirstChild(attachmentName),p0Name.."."..attachmentName)
 local a1=assert(p1:FindFirstChild(attachmentName),p1Name.."."..attachmentName)
 p1.CFrame=p0.CFrame*a0.CFrame*a1.CFrame:Inverse()
 local m=Instance.new("Motor6D")
 m.Name=name;m.Part0=p0;m.Part1=p1;m.C0=a0.CFrame;m.C1=a1.CFrame;m.Parent=p0
 return m
end
motor("Root","HumanoidRootPart","LowerTorso","RootRigAttachment")
motor("Waist","LowerTorso","UpperTorso","WaistRigAttachment")
motor("Neck","UpperTorso","Head","NeckRigAttachment")
motor("LeftShoulder","UpperTorso","LeftUpperArm","LeftShoulderRigAttachment")
motor("LeftElbow","LeftUpperArm","LeftLowerArm","LeftElbowRigAttachment")
motor("LeftWrist","LeftLowerArm","LeftHand","LeftWristRigAttachment")
motor("RightShoulder","UpperTorso","RightUpperArm","RightShoulderRigAttachment")
motor("RightElbow","RightUpperArm","RightLowerArm","RightElbowRigAttachment")
motor("RightWrist","RightLowerArm","RightHand","RightWristRigAttachment")
motor("LeftHip","LowerTorso","LeftUpperLeg","LeftHipRigAttachment")
motor("LeftKnee","LeftUpperLeg","LeftLowerLeg","LeftKneeRigAttachment")
motor("LeftAnkle","LeftLowerLeg","LeftFoot","LeftAnkleRigAttachment")
motor("RightHip","LowerTorso","RightUpperLeg","RightHipRigAttachment")
motor("RightKnee","RightUpperLeg","RightLowerLeg","RightKneeRigAttachment")
motor("RightAnkle","RightLowerLeg","RightFoot","RightAnkleRigAttachment")

local hum=assert(boss:FindFirstChildOfClass("Humanoid"))
hum.MaxHealth=2200;hum.Health=2200;hum.WalkSpeed=0;hum.AutoRotate=false;hum.DisplayName="Astra Veyra";hum.NameDisplayDistance=95
if not hum:FindFirstChildOfClass("Animator")then Instance.new("Animator",hum)end

local function weldPart(name,parentPart,size,offset,color,material,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Shape=shape or Enum.PartType.Block;p.CanCollide=false;p.CanTouch=false;p.Massless=true;p.Anchored=false;p.CastShadow=true
 p.CFrame=parentPart.CFrame*offset;p.Parent=boss
 local w=Instance.new("WeldConstraint");w.Part0=parentPart;w.Part1=p;w.Parent=p
 return p
end

local head=assert(boss:FindFirstChild("Head"))
local upper=assert(boss:FindFirstChild("UpperTorso"))
local lower=assert(boss:FindFirstChild("LowerTorso"))
local leftArm=assert(boss:FindFirstChild("LeftUpperArm"))
local rightArm=assert(boss:FindFirstChild("RightUpperArm"))
local rightHand=assert(boss:FindFirstChild("RightHand"))

-- White hair with layered locks.
weldPart("HairCap",head,Vector3.new(2.15,1.35,1.9),CFrame.new(0,.28,.10),Color3.fromRGB(235,239,248),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
for i=-2,2 do
 weldPart("HairFront"..i,head,Vector3.new(.32,1.35,.25),CFrame.new(i*.28,-.05,-.92)*CFrame.Angles(math.rad(5),0,math.rad(i*3)),Color3.fromRGB(239,242,250))
end
for i=-2,2 do
 weldPart("HairBack"..i,head,Vector3.new(.42,3.2,.34),CFrame.new(i*.31,-1.55,.78)*CFrame.Angles(math.rad(5),0,math.rad(i*4)),Color3.fromRGB(232,237,247))
end
-- Pointed ears.
weldPart("ElfEarL",head,Vector3.new(.25,1.25,.5),CFrame.new(-.72,.03,0)*CFrame.Angles(0,0,math.rad(33)),Color3.fromRGB(235,215,208))
weldPart("ElfEarR",head,Vector3.new(.25,1.25,.5),CFrame.new(.72,.03,0)*CFrame.Angles(0,0,math.rad(-33)),Color3.fromRGB(235,215,208))

-- Eyes.
local eyeL=weldPart("EyeL",head,Vector3.new(.20,.28,.06),CFrame.new(-.25,.08,-.96),Color3.fromRGB(77,156,120),Enum.Material.Neon,Enum.PartType.Ball)
local eyeR=weldPart("EyeR",head,Vector3.new(.20,.28,.06),CFrame.new(.25,.08,-.96),Color3.fromRGB(77,156,120),Enum.Material.Neon,Enum.PartType.Ball)

-- Robe/cape.
weldPart("RobeChest",upper,Vector3.new(2.25,2.35,.24),CFrame.new(0,-.05,-.56),Color3.fromRGB(242,241,238))
weldPart("GoldChestTrim",upper,Vector3.new(2.42,.16,.28),CFrame.new(0,.58,-.60),Color3.fromRGB(191,158,79),Enum.Material.Metal)
weldPart("Cape",upper,Vector3.new(2.72,4.4,.28),CFrame.new(0,-1.05,.67),Color3.fromRGB(41,43,53),Enum.Material.Fabric)
weldPart("RobeLower",lower,Vector3.new(2.15,2.55,.25),CFrame.new(0,-1.25,-.54),Color3.fromRGB(242,241,238),Enum.Material.Fabric)
weldPart("SleeveL",leftArm,Vector3.new(.95,1.75,.95),CFrame.new(0,-.15,0),Color3.fromRGB(242,241,238),Enum.Material.Fabric)
weldPart("SleeveR",rightArm,Vector3.new(.95,1.75,.95),CFrame.new(0,-.15,0),Color3.fromRGB(242,241,238),Enum.Material.Fabric)

-- Boss staff.
local shaft=weldPart("MageStaff",rightHand,Vector3.new(.25,5.8,.25),CFrame.new(0,-1.95,.15)*CFrame.Angles(0,0,math.rad(9)),Color3.fromRGB(114,75,53),Enum.Material.Wood)
local staffTip=weldPart("StaffTip",shaft,Vector3.new(.76,.76,.76),CFrame.new(0,2.95,0),Color3.fromRGB(200,235,255),Enum.Material.Neon,Enum.PartType.Ball)
local light=Instance.new("PointLight");light.Color=staffTip.Color;light.Brightness=2;light.Range=16;light.Parent=staffTip

-- Ground boss by actual feet after accessories/joints.
boss.PrimaryPart=boss.HumanoidRootPart
boss:PivotTo(CFrame.new(0,8,-28))
local boxCF,boxSize=boss:GetBoundingBox()
local lowest=math.min(
 boss.LeftFoot.Position.Y-boss.LeftFoot.Size.Y/2,
 boss.RightFoot.Position.Y-boss.RightFoot.Size.Y/2
)
boss:PivotTo(boss:GetPivot()+Vector3.new(0,.08-lowest,0))
boss:SetAttribute("Active",false)
boss:SetAttribute("BossVersion","mage-duel-v1")

-- Server runtime
local server=Instance.new("Script");server.Name="MageDuelServer";server.Source=SERVER_SOURCE;server.Parent=ServerScriptService

-- Player staff tool.
local tool=Instance.new("Tool")
tool.Name="AstralStaff";tool.RequiresHandle=true;tool.CanBeDropped=false;tool.ToolTip="Ataque • Barreira • Vida • Esquiva • Pulo • Voo"
local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.28,5.2,.28);handle.Color=Color3.fromRGB(112,73,52);handle.Material=Enum.Material.Wood;handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
local grip=Instance.new("Part");grip.Name="GripRing";grip.Size=Vector3.new(.52,.18,.52);grip.Shape=Enum.PartType.Cylinder;grip.Color=Color3.fromRGB(184,151,78);grip.Material=Enum.Material.Metal;grip.CanCollide=false;grip.Massless=true;grip.CFrame=handle.CFrame*CFrame.new(0,1.6,0)*CFrame.Angles(0,0,math.rad(90));grip.Parent=tool
local gw=Instance.new("WeldConstraint");gw.Part0=handle;gw.Part1=grip;gw.Parent=grip
local gem=Instance.new("Part");gem.Name="StaffGem";gem.Size=Vector3.new(.72,.72,.72);gem.Shape=Enum.PartType.Ball;gem.Color=Color3.fromRGB(200,235,255);gem.Material=Enum.Material.Neon;gem.CanCollide=false;gem.Massless=true;gem.CFrame=handle.CFrame*CFrame.new(0,2.65,0);gem.Parent=tool
local jw=Instance.new("WeldConstraint");jw.Part0=handle;jw.Part1=gem;jw.Parent=gem
local gl=Instance.new("PointLight");gl.Color=gem.Color;gl.Brightness=1.7;gl.Range=14;gl.Parent=gem
local client=Instance.new("LocalScript");client.Name="MageDuelClient";client.Source=CLIENT_SOURCE;client.Parent=tool
tool.Parent=StarterPack

Workspace:SetAttribute("BuildVersion","mage-duel-v1")
Workspace:SetAttribute("CleanRebuild",true)
Workspace:SetAttribute("BossReactiveOnly",true)
Workspace:SetAttribute("MagicBarrierLayers",3)
Workspace:SetAttribute("MagicSystem","beam+hex+storm+singularity+heal+dodge+jump+flight")

AssetService:SavePlaceAsync()

return {
 ok=true,
 sourceVersion=sourceVersion,
 buildVersion="mage-duel-v1",
 bossMotors=15,
 bossHealth=hum.MaxHealth,
 clean=true,
 tool=tool.Name,
}
