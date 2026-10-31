local W=workspace
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' then return end
local sourceGui=RS:WaitForChild('OriginalStarterGui')
for _,screen in ipairs(sourceGui:GetChildren()) do
 local name=string.lower(screen.Name)
 if not name:find('menu',1,true) and not name:find('credit',1,true) then
  screen:Clone().Parent=pg
 end
end
player.CameraMode=Enum.CameraMode.Classic
player.CameraMinZoomDistance=8
player.CameraMaxZoomDistance=18
local character=player.Character or player.CharacterAdded:Wait()
local root=character:WaitForChild('HumanoidRootPart')
pcall(function() player:RequestStreamAroundAsync(root.Position,15) end)
local library=require(RS:WaitForChild('Library'))
local deadline=os.clock()+35
repeat task.wait(.2) until library.Loaded or os.clock()>deadline
if not library.Loaded then warn('[StillHere] Client interaction library did not finish loading') end
player:SetAttribute('ArrivalReady',true)
