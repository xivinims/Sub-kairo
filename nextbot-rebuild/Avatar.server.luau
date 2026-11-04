local Players=game:GetService('Players')
local function setup(p)
 local function appearance(c)
  local h=c:WaitForChild('Humanoid',12);if not h then return end
  h.MaxHealth=100;h.Health=100;h.UseJumpPower=true;h.JumpPower=45;h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
  if not h:FindFirstChildOfClass('Animator')then local animator=Instance.new('Animator');animator.Parent=h end
  local ok,description=pcall(function()return Players:GetHumanoidDescriptionFromUserIdAsync(p.UserId)end)
  if ok and p.Character==c and c.Parent then
   pcall(function()h:ApplyDescriptionResetAsync(description)end)
   p:SetAttribute('NBAppearanceRevision',(p:GetAttribute('NBAppearanceRevision')or 0)+1)
  end
 end
 p.CharacterAdded:Connect(appearance);if p.Character then task.spawn(appearance,p.Character)end
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
