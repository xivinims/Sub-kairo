-- Exact DOORS room, stripped of third-party code before it enters the experience.
local RS=game:GetService("ReplicatedStorage")
local net=RS:WaitForChild("Survival")
local lobby=workspace:WaitForChild("JediLibrary")
local source=game:GetService("AssetService"):LoadAssetAsync(12467124775)
local room=assert(source:FindFirstChild("Jeff Shop"),"DOORS shop model missing")
room.Parent=nil source:Destroy()
room.Name="DoorsMerchantRoom"
for _,d in ipairs(room:GetDescendants()) do
 if d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("Sound") or d.Name=="ThumbnailCamera" then d:Destroy()
 elseif d:IsA("BasePart") then d.Anchored=true d.CanTouch=false
 end
end
local characters=room:FindFirstChild("Characters")
local ids={} -- Direct catalogue IDs required: Roblox share links require account authentication.
local oldKeeper=characters and characters:FindFirstChild("Shopkeeper")
local keeperCF=oldKeeper and oldKeeper:GetPivot()
if oldKeeper and #ids>0 then oldKeeper:Destroy() end
local floor=assert(room:FindFirstChild("Floor",true),"DOORS shop floor missing")
local floorCF=floor.CFrame
local floorTop=floor.Position.Y+floor.Size.Y/2
local focus=keeperCF and keeperCF.Position or floor.Position
local towards=Vector3.new(focus.X-floor.Position.X,0,focus.Z-floor.Position.Z)
if towards.Magnitude<1 then towards=Vector3.new(0,0,-1) else towards=towards.Unit end
local camPosition=floor.Position-towards*math.min(18,math.max(floor.Size.X,floor.Size.Z)*.3)+Vector3.new(0,6,0)
local cameraCF=CFrame.lookAt(camPosition,Vector3.new(focus.X,floorTop+4,focus.Z))
local scene=room:Clone() scene.Name="ShopScene"
-- Original model coordinates are retained for an exact, stable backdrop camera.
scene:SetAttribute("SourceAssetId",12467124775) scene:SetAttribute("PreviewCamera",cameraCF)
for _,d in ipairs(scene:GetDescendants()) do
 if d:IsA("BasePart") then d.CanCollide=false d.CanTouch=false d.CanQuery=false end
end
local oldScene=net:FindFirstChild("ShopScene") if oldScene then oldScene:Destroy() end
scene.Parent=net

local merchant,root
do
local description=Instance.new("HumanoidDescription")
description.HeadColor=Color3.fromRGB(198,180,160)
description.LeftArmColor=description.HeadColor description.RightArmColor=description.HeadColor
description.TorsoColor=Color3.fromRGB(51,47,43)
description.LeftLegColor=Color3.fromRGB(33,35,39) description.RightLegColor=description.LeftLegColor
local accessories={}
local accessoryTypes={ [8]=Enum.AccessoryType.Hat,[41]=Enum.AccessoryType.Hair,[42]=Enum.AccessoryType.Face,[43]=Enum.AccessoryType.Neck,[44]=Enum.AccessoryType.Shoulder,[45]=Enum.AccessoryType.Front,[46]=Enum.AccessoryType.Back,[47]=Enum.AccessoryType.Waist }
for _,id in ipairs(ids) do
 local info=game:GetService("MarketplaceService"):GetProductInfoAsync(id,Enum.InfoType.Asset)
 local kind=info.AssetTypeId
 if kind==11 then description.Shirt=id
 elseif kind==12 then description.Pants=id
 elseif kind==2 then description.GraphicTShirt=id
 elseif accessoryTypes[kind] then table.insert(accessories,{AssetId=id,AccessoryType=accessoryTypes[kind],IsLayered=false})
 else error("Merchant item type not supported: "..id.." / "..tostring(kind)) end
end
description:SetAccessories(accessories,true)
merchant=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
merchant.Name="ShopMerchant"
merchant:SetAttribute("Headless",#ids>0) merchant:SetAttribute("OutfitCount",#ids)
merchant:SetAttribute("SourceOutfitIds",game:GetService("HttpService"):JSONEncode(ids))
local head=merchant:FindFirstChild("Head")
if head and #ids>0 then head.Transparency=1 for _,d in ipairs(head:GetDescendants()) do if d:IsA("Decal") then d.Transparency=1 end end end
local hum=merchant:FindFirstChildOfClass("Humanoid") hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false hum.RequiresNeck=false
root=merchant:FindFirstChild("HumanoidRootPart") merchant.PrimaryPart=root
for _,d in ipairs(merchant:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then d:Destroy()
 elseif d:IsA("BasePart") then d.Anchored=d==root d.CanCollide=false d.CanTouch=false d.CanQuery=false end
end
local stand=room:FindFirstChild("ShopStand",true)
local standCF,standSize=stand and stand:GetBoundingBox()
local pos=keeperCF and keeperCF.Position or (standCF and standCF.Position) or (floor.Position+Vector3.new(0,0,-floor.Size.Z*.3))
pos=Vector3.new(pos.X,floorTop+3,pos.Z)
merchant:PivotTo(CFrame.lookAt(pos,Vector3.new(cameraCF.Position.X,pos.Y,cameraCF.Position.Z)))
merchant.Parent=room
end
assert(merchant.Humanoid.RigType==Enum.HumanoidRigType.R6,"Shop merchant must be R6")

local prompt=Instance.new("ProximityPrompt",root) prompt.Name="SuviversShopPrompt" prompt.ObjectText="Loja / Shop" prompt.ActionText="Abrir / Open"
prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=true prompt.HoldDuration=0
-- Keep the DOORS room only as the full-screen shop backdrop. The physical
-- monster room is removed from the lobby; only its shopkeeper remains in the house.
local priorRoom=lobby:FindFirstChild("DoorsMerchantRoom") if priorRoom then priorRoom:Destroy() end
local priorMerchant=lobby:FindFirstChild("ShopMerchant")
if priorMerchant and priorMerchant~=merchant then priorMerchant:Destroy() end
merchant.Name="ShopMerchant"
merchant.Parent=lobby
for _,d in ipairs(merchant:GetDescendants()) do
 if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") then d:Destroy()
 elseif d:IsA("BasePart") then d.Anchored=d==root d.CanCollide=false d.CanTouch=false d.CanQuery=false end
end

local house=assert(lobby:FindFirstChild("House"),"Lobby house missing for kitchen merchant placement")
local spawnPos=lobby:GetAttribute("VerifiedSpawn")
if typeof(spawnPos)~="Vector3" then spawnPos=house:GetPivot().Position end
local function ancestryText(part)
 local names={string.lower(part.Name)}
 local p=part.Parent
 for _=1,6 do
  if not p or p==lobby then break end
  table.insert(names,string.lower(p.Name))
  p=p.Parent
 end
 return table.concat(names," ")
end
local kitchenAnchor=nil
local best=math.huge
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") and p.Transparency<.98 then
  local t=ancestryText(p)
  local kitchen=string.find(t,"kitchen",1,true) or string.find(t,"cozinha",1,true)
  local fixture=string.find(t,"counter",1,true) or string.find(t,"cabinet",1,true)
   or string.find(t,"sink",1,true) or string.find(t,"stove",1,true)
   or string.find(t,"oven",1,true) or string.find(t,"fridge",1,true)
   or string.find(t,"refrigerator",1,true) or string.find(t,"island",1,true)
  local flat=(Vector3.new(p.Position.X,spawnPos.Y,p.Position.Z)-spawnPos).Magnitude
  if (kitchen or fixture) and flat<=90 then
   local score=flat-(kitchen and 36 or 0)-(fixture and 10 or 0)
   if score<best then best=score kitchenAnchor=p end
  end
 end
end
if not kitchenAnchor then
 for _,p in ipairs(house:GetDescendants()) do
  if p:IsA("BasePart") and p.Transparency<.98 then
   local t=ancestryText(p)
   local furniture=string.find(t,"furniture",1,true) or string.find(t,"table",1,true) or string.find(t,"desk",1,true)
   local flat=(Vector3.new(p.Position.X,spawnPos.Y,p.Position.Z)-spawnPos).Magnitude
   if furniture and flat<=45 and flat<best then best=flat kitchenAnchor=p end
  end
 end
end
assert(kitchenAnchor,"No kitchen/furniture anchor was found near the lobby spawn")

local toSpawn=Vector3.new(spawnPos.X-kitchenAnchor.Position.X,0,spawnPos.Z-kitchenAnchor.Position.Z)
if toSpawn.Magnitude<.1 then
 local ref=lobby:GetAttribute("FormerDoorCFrame")
 toSpawn=typeof(ref)=="CFrame" and -Vector3.new(ref.LookVector.X,0,ref.LookVector.Z) or Vector3.new(0,0,-1)
end
if toSpawn.Magnitude<.1 then toSpawn=Vector3.new(0,0,-1) else toSpawn=toSpawn.Unit end
local side=Vector3.new(-toSpawn.Z,0,toSpawn.X)
local edge=math.max(kitchenAnchor.Size.X,kitchenAnchor.Size.Z)*.5+3.5
local placementCandidates={
 kitchenAnchor.Position+toSpawn*edge,
 kitchenAnchor.Position-toSpawn*edge,
 kitchenAnchor.Position+side*edge,
 kitchenAnchor.Position-side*edge,
 spawnPos+side*8+toSpawn*5,
 spawnPos-side*8+toSpawn*5,
}
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances={lobby}
rayParams.RespectCanCollide=true
local kitchenFloor=nil
for _,candidate in ipairs(placementCandidates) do
 local hit=workspace:Raycast(Vector3.new(candidate.X,spawnPos.Y+14,candidate.Z),Vector3.new(0,-44,0),rayParams)
 if hit and hit.Normal.Y>.82 and not workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),rayParams) then
  kitchenFloor=hit.Position
  break
 end
end
assert(kitchenFloor,"Kitchen shopkeeper floor is blocked")

local merchantCF,merchantSize=merchant:GetBoundingBox()
local pivot=merchant:GetPivot()
local pivotToBottom=pivot.Position.Y-(merchantCF.Position.Y-merchantSize.Y/2)
local targetPos=Vector3.new(kitchenFloor.X,kitchenFloor.Y+pivotToBottom+.04,kitchenFloor.Z)
local face=Vector3.new(spawnPos.X,targetPos.Y,spawnPos.Z)
if (face-targetPos).Magnitude<.1 then face=targetPos+toSpawn end
merchant:PivotTo(CFrame.lookAt(targetPos,face))
merchant:SetAttribute("Placement","KitchenNearSpawn")
merchant:SetAttribute("KitchenAnchor",kitchenAnchor:GetFullName())
merchant:SetAttribute("PhysicalShopRemoved",true)
lobby:SetAttribute("PhysicalMonsterShopRemoved",true)
lobby:SetAttribute("ShopMerchantPlacement","KitchenNearSpawn")
lobby:SetAttribute("ShopMerchantKitchenAnchor",kitchenAnchor:GetFullName())
lobby:SetAttribute("ShopMerchantDistanceFromSpawn",(Vector3.new(targetPos.X,spawnPos.Y,targetPos.Z)-spawnPos).Magnitude)

room:Destroy()
local oldWall=lobby:FindFirstChild("UnderStairWallRepair")
if oldWall then oldWall:Destroy() end
lobby:SetAttribute("UnderStairWallRepaired",false)
lobby:SetAttribute("UnderStairWallRevision",3)
lobby:SetAttribute("InteriorWallRemoved",true)

local lamp=Instance.new("PointLight",root) lamp.Name="MerchantWarmLight" lamp.Color=Color3.fromRGB(255,198,132) lamp.Brightness=1.35 lamp.Range=20 lamp.Shadows=true
local clients=game.StarterPlayer.StarterPlayerScripts
local old=clients:FindFirstChild("MerchantIdle") if old then old:Destroy() end
do
local client=Instance.new("LocalScript") client.Name="MerchantIdle"
client.Source=[==[
local Run=game:GetService("RunService")
local p=game:GetService("Players").LocalPlayer
local npc=workspace:WaitForChild("JediLibrary"):WaitForChild("ShopMerchant")
local torso=npc:WaitForChild("Torso")
local root=npc:WaitForChild("HumanoidRootPart")
local joint=root:FindFirstChildWhichIsA("Motor6D")
local base=joint and joint.C0
Run.RenderStepped:Connect(function()
 local character=p.Character local hr=character and character:FindFirstChild("HumanoidRootPart")
 if not hr or not joint or not joint.Parent then return end
 local delta=root.CFrame:PointToObjectSpace(hr.Position)
 local yaw=delta.Magnitude<24 and math.clamp(math.atan2(-delta.X,-delta.Z),-.22,.22) or 0
 local target=base*CFrame.Angles(0,yaw,math.sin(os.clock()*1.3)*.012)
 joint.C0=joint.C0:Lerp(target,.08)
end)
]==]
client.Parent=clients
end
return {ok=true,asset=12467124775,rig="R6",outfitItems=#ids,headless=#ids>0,animatedShop=true,underStairWall=false,physicalMonsterShop=false,merchantPlacement="KitchenNearSpawn",merchantPosition=tostring(root.Position)}
