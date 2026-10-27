-- User explicitly enabled GrabPack in revision 6. External scripts never ship.
local assets=Instance.new("Folder"); assets.Name="GrabPackGeometry"; assets.Parent=foundation
local function handAsset(selection,name,scale,color)
    local m=Importer.Select(10468403169,selection)
    m.Name=name; m:PivotTo(CFrame.new()); m:ScaleTo(scale)
    for _,p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false
            if color then p.Color=color end
        end
    end
    m.Parent=assets
end
handAsset("HandL2","BlueHand",0.55,C(44,83,173))
handAsset("HandL","RedHand",0.6,C(169,42,39))
handAsset("Gunl","RightLauncher",0.45,nil)
handAsset("Gunl2","LeftLauncher",0.45,nil)
Importer.ClearSelectionCache()
for _,p in ipairs(CollectionService:GetTagged("DeadSignalInteraction")) do
    local action=p:GetAttribute("ActionId")
    if ({CablePickup=true,CableSocket=true,Sequence=true,PowerSwitch=true,BatteryPickup=true,BatteryDock=true,ToggleDoor=true})[action] then
        CollectionService:AddTag(p.Parent,"DeadSignalGrabInteractable")
    end
end
-- A teachable, optional two-hand power bridge in reception; physical cables remain the chapter's main puzzle system.
local supply=box(map,"GrabSource",-18,4,15,2.7,3,1,C(66,91,116))
supply:SetAttribute("PowerNodeId","GRAB_SOURCE"); supply:SetAttribute("PowerNodeType","Source"); supply:SetAttribute("Output",30)
CollectionService:AddTag(supply,"DeadSignalPowerNode"); CollectionService:AddTag(supply,"DeadSignalGrabSource")
local receiver=box(map,"GrabReceiver",17,4,29,2.7,3,1,C(126,75,63))
receiver:SetAttribute("PowerNodeId","GRAB_RECEIVER"); receiver:SetAttribute("PowerNodeType","Consumer"); receiver:SetAttribute("Demand",30)
CollectionService:AddTag(receiver,"DeadSignalPowerNode"); CollectionService:AddTag(receiver,"DeadSignalGrabReceiver")
-- Palm markings are mounted on functional sockets, not floating tutorial boards.
addText(supply,"✋",Enum.NormalId.Front,C(79,143,228)); addText(receiver,"✋",Enum.NormalId.Front,C(209,83,69))
local locker=model("GrabPoweredLocker")
locker:SetAttribute("DoorId","GRAB_LOCKER"); locker:SetAttribute("PowerNodeId","GRAB_RECEIVER")
locker:SetAttribute("OpenOffset",V(0,7,0)); locker:SetAttribute("AutoOpenWhenPowered",true)
CollectionService:AddTag(locker,"DeadSignalDoor")
box(locker,"DoorPanel",17,3.5,31.3,5.4,7,0.5,C(73,89,79))
box(locker,"BackPanel",17,3.5,33.4,6,7,0.5,C(37,49,44))
for _,s in ipairs({-1,1}) do box(locker,"LockerSide",17+s*2.9,3.5,32.3,0.4,7,2,C(45,60,55)) end
local archive=box(locker,"MaintenanceRecord",17,1,32.2,2.4,0.5,1.4,C(122,104,63))
prompt(archive,"StartDialogue","Ler registro",{DialogueId="maintenanceRecording"})
local cart=model("GrabPullCart")
CollectionService:AddTag(cart,"DeadSignalPullable")
local cartBody=box(cart,"CartCollider",-10,1.7,181,4,3.4,3,C(94,77,51),Enum.Material.WoodPlanks)
cart.PrimaryPart=cartBody
for _,s in ipairs({-1,1}) do
    local wheel=box(cart,"Wheel",-10+s*1.8,0.5,181,0.3,1,1,C(31,38,35),Enum.Material.Rubber,false)
    wheel.Shape=Enum.PartType.Cylinder
end
Workspace:SetAttribute("GrabPackEnabled",true)
