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
if #ids>0 then
local description=Instance.new("HumanoidDescription")
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
merchant:SetAttribute("Headless",true) merchant:SetAttribute("OutfitCount",#ids)
merchant:SetAttribute("SourceOutfitIds",game:GetService("HttpService"):JSONEncode(ids))
local head=merchant:FindFirstChild("Head")
if head then head.Transparency=1 for _,d in ipairs(head:GetDescendants()) do if d:IsA("Decal") then d.Transparency=1 end end end
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
else
 merchant=assert(oldKeeper,"Existing shopkeeper missing")
 root=assert(merchant:FindFirstChildWhichIsA("BasePart",true),"Shopkeeper interaction anchor missing")
 merchant:SetAttribute("OutfitPending",true)
end
local prompt=Instance.new("ProximityPrompt",root) prompt.Name="SuviversShopPrompt" prompt.ObjectText="Loja / Shop" prompt.ActionText="Abrir / Open"
prompt.MaxActivationDistance=16 prompt.RequiresLineOfSight=false prompt.HoldDuration=0
-- The room is outdoors beside the house, facing its front entrance. No duplicate
-- doors or collision sheets are placed in the lobby's existing passages.
local reference=lobby:GetAttribute("FormerDoorCFrame")
local yard=assert(lobby:FindFirstChild("OutdoorGround"))
local target=reference.Position-reference.LookVector*58+reference.RightVector*48
local y=yard.Position.Y+yard.Size.Y/2
local destination=CFrame.lookAt(Vector3.new(target.X,y+.5,target.Z),Vector3.new(reference.Position.X,y+.5,reference.Position.Z))
local relative=floorCF:ToObjectSpace(room:GetPivot())
room:PivotTo(destination*relative)
local prior=lobby:FindFirstChild("DoorsMerchantRoom") if prior then prior:Destroy() end
room:SetAttribute("SourceAssetId",12467124775) room:SetAttribute("MerchantReady",#ids>0) room.Parent=lobby
-- Doors at the two ends stay open; imported hollow decorative meshes are noncolliding.
local doors=room:FindFirstChild("Doors")
if doors then for _,d in ipairs(doors:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide=false d.Transparency=1 end end end
for _,d in ipairs(room:GetDescendants()) do
 if d:IsA("BasePart") and (d.Transparency>=.98 or d.Name:lower():find("doorframe",1,true)) then d.CanCollide=false end
 if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then d.Enabled=true d.Brightness=math.clamp(d.Brightness,.5,2) end
end
local lamp=Instance.new("PointLight",root) lamp.Name="MerchantWarmLight" lamp.Color=Color3.fromRGB(255,198,132) lamp.Brightness=1.2 lamp.Range=18 lamp.Shadows=true
local clients=game.StarterPlayer.StarterPlayerScripts
local old=clients:FindFirstChild("MerchantIdle") if old then old:Destroy() end
if #ids>0 then
local client=Instance.new("LocalScript") client.Name="MerchantIdle"
client.Source=[==[
local Run=game:GetService("RunService")
local p=game:GetService("Players").LocalPlayer
local room=workspace:WaitForChild("JediLibrary"):WaitForChild("DoorsMerchantRoom")
local npc=room:WaitForChild("ShopMerchant")
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
return {ok=true,asset=12467124775,outfitItems=#ids,headless=#ids>0,animatedShop=true,merchantPosition=tostring(root.Position)}
