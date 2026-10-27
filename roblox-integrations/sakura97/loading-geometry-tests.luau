local assets=assert(game.ReplicatedFirst:FindFirstChild("LoadingCinematicAssets"))
local world=Instance.new("WorldModel")
local camera=Instance.new("Camera") camera.FieldOfView=34
local viewport={AbsoluteSize=Vector2.new(1624,750)}
local function compose()
__LOADING_COMPOSITION__
return tv,tableModel,screen,fitLoadingCamera
end
local tv,mesa,screen,fit=compose()
assert(screen.CFrame.RightVector:Dot(Vector3.new(0,0,1))>.999,"TV must face viewer")
assert(screen.CFrame.LookVector:Dot(Vector3.new(0,1,0))>.999,"TV local -Z must point up, antenna upright")
local tested=0
for _,resolution in ipairs({Vector2.new(1624,750),Vector2.new(375,812),Vector2.new(812,375),Vector2.new(1920,1080),Vector2.new(768,1024)}) do
 viewport.AbsoluteSize=resolution fit(viewport,camera,tv,mesa)
 local tan=math.tan(math.rad(camera.FieldOfView*.5))
 local aspect=resolution.X/resolution.Y
 for _,model in ipairs({tv,mesa}) do
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then
    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
     local point=camera.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)*.5))
     assert(point.Z<0,"Loading part behind camera")
     assert(math.abs(point.X/(-point.Z*tan*aspect))<.99 and math.abs(point.Y/(-point.Z*tan))<.99,"Loading TV/table cropped at "..tostring(resolution))
    end end end
   end
  end
 end
 tested+=1
end
world:Destroy() camera:Destroy()
return {ok=true,upright=true,screenSizes=tested,noClipping=true}
