local stage=Instance.new("Model"); stage.Name="MenuStage"; stage.Parent=Workspace
stage.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local function stagePart(name,x,y,z,sx,sy,sz,color,material)
    return box(stage,name,x,y,z,sx,sy,sz,color,material,false)
end
stagePart("StageFloor",184,-0.5,106,36,1,42,C(24,25,24),Enum.Material.DiamondPlate)
stagePart("StageBackWall",184,13,123,36,27,1,C(18,22,21),Enum.Material.Concrete)
for _,x in ipairs({167,201}) do stagePart("StageSideWall",x,13,106,1,27,34,C(19,21,20),Enum.Material.Brick) end
for _,x in ipairs({178,193}) do
    stagePart("RedPortalColumn",x,12,111,1.3,24,2,C(64,31,27),Enum.Material.Metal)
    local strip=stagePart("RedBacklight",x,10,114,0.35,20,0.35,C(174,32,19),Enum.Material.Neon)
    local light=Instance.new("PointLight"); light.Color=C(238,43,19); light.Range=30; light.Brightness=4; light.Shadows=true; light.Parent=strip
end
stagePart("StageHeader",185.5,24,111,17,2,2,C(49,29,25))
local pose=monster:Clone(); pose.Name="MenuThreadbare"; CollectionService:RemoveTag(pose,"DeadSignalStalker")
local humanoid=pose:FindFirstChildOfClass("Humanoid"); if humanoid then humanoid:Destroy() end
for _,p in ipairs(pose:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false end end
pose:ScaleTo(1.65); pose:PivotTo(CFrame.new(185,10,113)*CFrame.Angles(0,math.rad(12),0)); pose.Parent=stage
local camera=stagePart("CameraAnchor",174,8,84,1,1,1,C(0,0,0)); camera.Transparency=1
camera.CFrame=CFrame.lookAt(V(174,8,84),V(180,10,112))
local foreground=stagePart("ForegroundSpool",192,1,94,6,2,5,C(42,36,26),Enum.Material.Wood)
for i=1,4 do stagePart("StagePipe",169+i*0.6,17,104,0.25,0.25,35,C(42,47,41)) end
Workspace:SetAttribute("MenuRevision","chapter-three-layout-v6")
