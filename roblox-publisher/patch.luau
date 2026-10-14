assert(game.PlaceVersion==90)
local out={readOnly=true,audio={},seats={}}
for _,id in ipairs({9120552550,9083826864,135037154891351})do
 local s=Instance.new("Sound")s.SoundId="rbxassetid://"..id s.Parent=workspace
 pcall(function()game:GetService("ContentProvider"):PreloadAsync({s})end)
 out.audio[#out.audio+1]={id=id,loaded=s.IsLoaded,length=s.TimeLength}s:Destroy()
end
local seat=workspace.ForestWorld.Amenities.ForestRuins.TeaCorner:FindFirstChild("TeaSeat",true)
for _,rig in ipairs({Enum.HumanoidRigType.R6,Enum.HumanoidRigType.R15})do
 local d=Instance.new("HumanoidDescription")local m=game.Players:CreateHumanoidModelFromDescriptionAsync(d,rig)d:Destroy()
 m.Name="SeatProbe"m.Parent=workspace m:PivotTo(seat.CFrame+Vector3.yAxis*3)
 seat:Sit(m.Humanoid)task.wait(.7)
 local w=seat:FindFirstChild("SeatWeld")
 out.seats[#out.seats+1]={rig=rig.Name,sit=m.Humanoid.Sit,weld=w and w.Part1.Name or "",rootDot=m.HumanoidRootPart.CFrame.LookVector:Dot(seat.CFrame.LookVector),weldDot=w and (seat.CFrame*w.C0*w.C1:Inverse()).LookVector:Dot(seat.CFrame.LookVector)or 0}
 m:Destroy()task.wait(.1)
end return out