local W=workspace;local P=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local RF=game:GetService('ReplicatedFirst')
local p=P.LocalPlayer;local pg=p:WaitForChild('PlayerGui')
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' then return end
if W:GetAttribute('SelectedChapter')~=2 then
 for _,gui in ipairs(RS:WaitForChild('OriginalStarterGui'):GetChildren()) do gui:Clone().Parent=pg end
end
p.CameraMode=Enum.CameraMode.LockFirstPerson
if W:GetAttribute('SelectedChapter')==2 then p:SetAttribute('ArrivalReady',true);return end
local char=p.Character or p.CharacterAdded:Wait();local root=char:WaitForChild('HumanoidRootPart')
pcall(function() p:RequestStreamAroundAsync(root.Position,15) end)
local library=require(RS:WaitForChild('Library'));local untilTime=os.clock()+35
repeat task.wait(.2) until library.Loaded or os.clock()>untilTime
if not library.Loaded then warn('[OriginalFPS] Client library did not finish loading') end
p:SetAttribute('ArrivalReady',true)
-- Original mission events drive the original HUD. Quiet completion cue only.
RS.GameStateEvent.OnClientEvent:Connect(function(info)
 local cfg=require(RF.DemoConfig)
 if info[1]==cfg.GameEvents.GameState and info[2]==cfg.GameStates.CanGetSeal then
  local s=Instance.new('Sound');s.SoundId='rbxassetid://78259731630797';s.Volume=.16;s.Parent=game:GetService('SoundService');s:Play();game:GetService('Debris'):AddItem(s,8)
 end
end)
