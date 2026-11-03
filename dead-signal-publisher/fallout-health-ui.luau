-- Visual template: Creator Store asset 84860453909277, based on Roblox's 2014 Health GUI.
-- The asset's legacy scripts are removed; this controller scopes it to the FPS lobby.
local TweenService=game:GetService('TweenService')
local Health={}
local images={green='rbxassetid://35238053',red='rbxassetid://35238036',gold='rbxassetid://154646431'}
function Health.inLobby(phase)
 return phase=='Waiting' or phase=='Intermission'
end
function Health.create(parent,template)
 local screen=template:Clone();screen.Name='FalloutLobbyHealth';screen.ResetOnSpawn=false;screen.Enabled=false
 screen.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets;screen.SafeAreaCompatibility=Enum.SafeAreaCompatibility.None;screen.DisplayOrder=29
 local root=screen:WaitForChild('HealthGui');root.Size=UDim2.fromScale(1,1);root.Position=UDim2.new();root.BackgroundTransparency=1
 local frame=root:WaitForChild('HealthFrame');frame.AnchorPoint=Vector2.new(.5,1);frame.Position=UDim2.new(.5,0,1,-10)
 local overlay=root:WaitForChild('HurtOverlay');overlay.Visible=false
 screen.Parent=parent
 return {screen=screen,root=root,frame=frame,bar=frame:WaitForChild('HealthBar'),overlay=overlay}
end
local function cancel(view,key)
 if view[key] then view[key]:Cancel();view[key]=nil end
end
function Health.update(view,phase,humanoid)
 local enabled=Health.inLobby(phase) and humanoid~=nil
 view.screen.Enabled=enabled
 if not enabled then
  cancel(view,'barTween');cancel(view,'hurtTween');view.overlay.Visible=false;view.lastHealth=nil;view.humanoid=nil
  return
 end
 local health,maxHealth=humanoid.Health,humanoid.MaxHealth
 if view.humanoid==humanoid and view.lastHealth==health and view.lastMax==maxHealth then return end
 local previous=view.humanoid==humanoid and view.lastHealth or nil
 local ratio=maxHealth>0 and health/maxHealth or 0
 local infinite=ratio~=ratio
 ratio=infinite and 1 or math.clamp(ratio,0,1)
 view.bar.Image=infinite and images.gold or ratio>.25 and images.green or images.red
 cancel(view,'barTween')
 local size=UDim2.new(ratio,0,1,0)
 if previous and maxHealth>0 and maxHealth<math.huge then
  view.barTween=TweenService:Create(view.bar,TweenInfo.new(math.clamp(math.abs(previous-health)/maxHealth,0,1)*.3,Enum.EasingStyle.Linear),{Size=size});view.barTween:Play()
 else view.bar.Size=size end
 if previous and maxHealth>0 and maxHealth<math.huge and previous-health>=maxHealth*.05 then
  cancel(view,'hurtTween')
  view.overlay.Size=UDim2.fromScale(1,1);view.overlay.Position=UDim2.new();view.overlay.Visible=true
  view.hurtTween=TweenService:Create(view.overlay,TweenInfo.new(10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(20,20),Position=UDim2.fromScale(-10,-10)})
  view.hurtTween:Play()
 end
 view.humanoid=humanoid;view.lastHealth=health;view.lastMax=maxHealth
end
return Health
