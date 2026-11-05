local Players=game:GetService('Players');local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer;local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local controls
pcall(function()controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls()end)
local mode='';local time=0;local offset=Vector3.zero
local viewState='';local viewCharacter;local zoomGeneration=0
local function setView(first,emoting)
 zoomGeneration+=1;local token=zoomGeneration
 player.CameraMode=Enum.CameraMode.Classic
 if first then
  player.CameraMinZoomDistance=.5;player.CameraMaxZoomDistance=16
  player.CameraMode=Enum.CameraMode.LockFirstPerson
 else
  -- Force a real zoom distance when leaving first person; Classic alone keeps the old distance.
  player.CameraMaxZoomDistance=16;player.CameraMinZoomDistance=8;player.CameraMaxZoomDistance=8
  task.delay(.15,function()
   if token~=zoomGeneration then return end
   player.CameraMaxZoomDistance=16;player.CameraMinZoomDistance=emoting and 4 or .5
  end)
 end
end
Run:BindToRenderStep('ExactRunCamera',Enum.RenderPriority.Camera.Value+1,function(dt)
 local camera=workspace.CurrentCamera;if not camera then return end
 local char=player.Character;local h=char and char:FindFirstChildOfClass('Humanoid');local root=char and char:FindFirstChild('HumanoidRootPart')
 local spectating=player:GetAttribute('NBSpectating')==true
 local menu=not player:GetAttribute('NBInArena')and not spectating
 local newMode=menu and 'Menu'or spectating and 'Spectate'or 'Play'
 local changed=newMode~=mode
 if newMode~=mode then
  mode=newMode
  offset=Vector3.zero;if h then h.CameraOffset=Vector3.zero end
  if menu then if h then h.AutoRotate=true end;viewState='';if controls then controls:Disable()end;UIS.MouseBehavior=Enum.MouseBehavior.Default
  else camera.CameraType=Enum.CameraType.Custom;if h then camera.CameraSubject=h end;if controls then controls:Enable()end end
 end
 if menu then
  camera.CameraType=Enum.CameraType.Scriptable;UIS.MouseBehavior=Enum.MouseBehavior.Default
  local anchors=workspace:FindFirstChild('MenuCameras');local page=player:GetAttribute('NBMenuPage')or 'Home'
  local anchor=anchors and (anchors:FindFirstChild(page)or anchors:FindFirstChild('Home'))
  if anchor then
   local mouse=UIS:GetMouseLocation();local v=camera.ViewportSize
   local x=UIS.MouseEnabled and math.clamp(mouse.X/math.max(v.X,1)-.5,-.5,.5)or 0
   local y=UIS.MouseEnabled and math.clamp(mouse.Y/math.max(v.Y,1)-.5,-.5,.5)or 0
   local view=anchor.CFrame*CFrame.Angles(-y*.025,-x*.04,0)
   camera.CFrame=changed and view or camera.CFrame:Lerp(view,1-math.exp(-dt*5))
  end
 elseif spectating then
  local target=Players:GetPlayerByUserId(player:GetAttribute('NBSpectateTarget')or 0)
  if not target or not target:GetAttribute('NBInRound')then target=nil;for _,p in ipairs(Players:GetPlayers())do if p~=player and p:GetAttribute('NBInRound')then target=p;break end end end
  local th=target and target.Character and target.Character:FindFirstChildOfClass('Humanoid')
  if th then camera.CameraSubject=th elseif h then camera.CameraSubject=h end
 elseif h and root then
  camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=h
  local emoting=(player:GetAttribute('NBPlayingEmote')or '')~=''
  local firstRequested=player:GetAttribute('NBFirstPerson')==true and not emoting
  local state=emoting and 'Emote'or firstRequested and 'First'or 'Third'
  if viewState~=state or viewCharacter~=char or changed then
   viewState=state;viewCharacter=char;setView(firstRequested,emoting)
  end
  local down=player:GetAttribute('NBDowned')==true
  h.AutoRotate=emoting or down
  if not emoting and not down and h.Health>0 and not root.Anchored then
   local facing=camera.CFrame.LookVector;local flat=Vector3.new(facing.X,0,facing.Z)
   if flat.Magnitude>.001 then root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit)end
  end
  local crouch=player:GetAttribute('NBMobility')=='Crouch'or player:GetAttribute('NBMobility')=='Slide'or player:GetAttribute('NBDowned')
  time+=dt*math.clamp(h.WalkSpeed*.45,5,16)
  local moving=h.MoveDirection.Magnitude>.1 and h.FloorMaterial~=Enum.Material.Air
  local legacy=player:GetAttribute('NBSetting_LegacyCamera')==true
  local bob=moving and not legacy and player:GetAttribute('NBSetting_Viewbob')~=false and .07 or 0
  local target=Vector3.new(math.cos(time)*bob,(crouch and -.65 or 0)+math.abs(math.sin(time))*bob,0)
  offset=offset:Lerp(target,1-math.exp(-dt*12));h.CameraOffset=offset
  local first=(camera.CFrame.Position-camera.Focus.Position).Magnitude<1
  for _,name in ipairs({'Left Arm','Right Arm'})do local arm=char:FindFirstChild(name);if arm then arm.LocalTransparencyModifier=first and player:GetAttribute('NBSetting_RunningViewmodel')~=false and moving and 0 or first and 1 or 0 end end
  local fov=player:GetAttribute('NBSetting_FOV')or 70
  camera.FieldOfView=camera.FieldOfView+(fov+(not legacy and player:GetAttribute('NBMobility')=='Sprint'and 5 or 0)-camera.FieldOfView)*math.min(dt*8,1)
 end
end)
script.Destroying:Connect(function()Run:UnbindFromRenderStep('ExactRunCamera');if controls then controls:Enable()end end)
