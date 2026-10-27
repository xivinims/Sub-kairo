local assets=assert(game.ReplicatedFirst:FindFirstChild("LoadingCinematicAssets"))
local world=Instance.new("WorldModel")
local camera=Instance.new("Camera") camera.FieldOfView=29
local RunService={RenderStepped={Connect=function(_,fn) return {Disconnect=function() end} end}}
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
 local screenCenter=camera.CFrame:PointToObjectSpace(screen.Position)
 assert(screenCenter.Z<0,"Loading TV screen is behind camera")
 local halfY=screen.Size.Y*.5
 local halfZ=screen.Size.Z*.5
 for sy=-1,1,2 do
  for sz=-1,1,2 do
   local worldPoint=screen.CFrame:PointToWorldSpace(Vector3.new(0,halfY*sy,halfZ*sz))
   local point=camera.CFrame:PointToObjectSpace(worldPoint)
   assert(point.Z<0,"Loading TV screen corner behind camera")
   assert(math.abs(point.X/(-point.Z*tan*aspect))<.96 and math.abs(point.Y/(-point.Z*tan))<.96,"Loading TV screen cropped at "..tostring(resolution))
  end
 end
 for _,part in ipairs(mesa:GetDescendants()) do
  if part:IsA("BasePart") then assert(part.Transparency==1,"Loading table must stay invisible") end
 end
 tested+=1
end
world:Destroy() camera:Destroy()
return {ok=true,upright=true,screenSizes=tested,noClipping=true,tableHidden=true,closeUp=true}
