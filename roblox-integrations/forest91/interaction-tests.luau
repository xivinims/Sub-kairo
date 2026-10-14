local runtime=game.ReplicatedStorage.ForestRuntime local W=require(runtime.GardenWeather)
runtime:SetAttribute("GardenTestMode",nil)W.start(runtime,workspace.ForestWorld)
local storage=Instance.new("Folder")storage.Name="InteractionTest"storage.Parent=game.ServerStorage
local mock={}
local report={seatRigs={},umbrellaRigs={}}
for i,rig in ipairs({Enum.HumanoidRigType.R6,Enum.HumanoidRigType.R15})do
 local desc=Instance.new("HumanoidDescription")local m=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,rig)desc:Destroy()
 m.Name="UmbrellaTest"m.Parent=workspace m:PivotTo(CFrame.new(i*3,130,0))m.HumanoidRootPart.Anchored=true
 local backpack=Instance.new("Backpack")backpack.Parent=storage
 local player={Character=m,Backpack=backpack,UserId=i+100}
 W.give(player)mock[#mock+1]=player
end
task.wait(.2)for _=1,20 do W.tick(.11)end
for _,player in ipairs(mock)do local m=player.Character local t=assert(m:FindFirstChildOfClass("Tool"))local motor=assert(m.HumanoidRootPart:FindFirstChild("UmbrellaHold"))
 assert(t:GetAttribute("SharingWith")and m.HumanoidRootPart.Anchored,"Sharing state: rig="..m.Humanoid.RigType.Name.." share="..tostring(t:GetAttribute("SharingWith")).." health="..m.Humanoid.Health.." sit="..tostring(m.Humanoid.Sit))
 assert(not m:FindFirstChild("RightGrip",true),"Umbrella fought the default hand grip")
 local expected=W.canopy(mock[1].Character,mock[2].Character)-Vector3.yAxis*3.2
 assert((m.HumanoidRootPart.CFrame:PointToWorldSpace(motor.C0.Position)-expected).Magnitude<.4,"Shared umbrella did not converge to the midpoint")
 if m.Humanoid.RigType==Enum.HumanoidRigType.R15 then assert(m.Humanoid:FindFirstChild("UmbrellaHandIK"),"R15 umbrella hand misses shaft")end
 report.umbrellaRigs[#report.umbrellaRigs+1]={rig=m.Humanoid.RigType.Name,shared=true,motor=true}
 m.Humanoid:UnequipTools()task.wait(.1)assert(not m.HumanoidRootPart:FindFirstChild("UmbrellaHold")and not m.Humanoid:FindFirstChild("UmbrellaHandIK"),"Unequip leaves character constrained")W.remove(player)m:Destroy()
end
storage:Destroy()
-- A fresh isolated seat for each rig avoids Roblox's seat cooldown during repeated tests.
local source=workspace.ForestWorld.Amenities.ForestRuins.TeaCorner:FindFirstChild("TeaSeat",true)
for _,rig in ipairs({Enum.HumanoidRigType.R6,Enum.HumanoidRigType.R15})do
 local seat=source:Clone()seat:ClearAllChildren()seat.Parent=workspace seat.CFrame=CFrame.new(0,140,0)*source.CFrame.Rotation seat.CanTouch=true
 local desc=Instance.new("HumanoidDescription")local m=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,rig)desc:Destroy()m.Parent=workspace m:PivotTo(seat.CFrame+Vector3.yAxis*3)
 seat:Sit(m.Humanoid)task.wait(.5)local weld=assert(seat:FindFirstChild("SeatWeld"))
 local facing=(seat.CFrame*weld.C0*weld.C1:Inverse()).LookVector:Dot(seat.CFrame.LookVector)assert(facing>.99,"Seated rig faces backwards")
 report.seatRigs[#report.seatRigs+1]={rig=rig.Name,seatWeldFacesTable=facing}
 m:Destroy()seat:Destroy()
end
return report
