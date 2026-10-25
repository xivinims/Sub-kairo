local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local Profile=require(game:GetService("ReplicatedStorage"):WaitForChild("Survival"):WaitForChild("PlayerProfile"))
local selected=nil local card=nil
local outline=Instance.new("Highlight") outline.Name="SelectedPlayerOutline" outline.FillTransparency=1 outline.OutlineColor=Color3.new(1,1,1) outline.OutlineTransparency=0 outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Enabled=false outline.Parent=game:GetService("Workspace")
local function close()
 local old=card card=nil selected=nil outline.Enabled=false outline.Adornee=nil
 player:SetAttribute("ProfileOpen",false)
 if old then old.close() end
end
local function blocked()
 if player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("ChoosingKiller") or player:GetAttribute("SweanLoadingDone")~=true then return true end
 local hud=player.PlayerGui:FindFirstChild("SurvivalHUD")
 if hud then
  for _,name in ipairs({"SettingsOverlay","MapVoting","KillerSelection","ArenaLoading","RoundResult"}) do local f=hud:FindFirstChild(name) if f and f.Visible then return true end end
 end
 return false
end
local function selectPlayer(target)
 if not target or target==player or blocked() then return end
 close() selected=target outline.Adornee=target.Character outline.Enabled=target.Character~=nil
 player:SetAttribute("ProfileOpen",true)
 card=Profile.open(player,target,function() card=nil selected=nil outline.Enabled=false outline.Adornee=nil player:SetAttribute("ProfileOpen",false) end)
end
local function pick(position)
 if blocked() or card then return end
 local camera=workspace.CurrentCamera if not camera then return end
 local ray=camera:ScreenPointToRay(position.X,position.Y)
 local filter=RaycastParams.new() filter.FilterType=Enum.RaycastFilterType.Exclude filter.FilterDescendantsInstances=player.Character and {player.Character} or {}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*120,filter)
 local node=hit and hit.Instance
 while node and node~=workspace do
  if node:IsA("Model") then local target=Players:GetPlayerFromCharacter(node) if target then selectPlayer(target) return end end
  node=node.Parent
 end
end
local down=nil
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then down=Vector2.new(input.Position.X,input.Position.Y) end
 if input.KeyCode==Enum.KeyCode.Escape and card then close() end
end)
UIS.InputEnded:Connect(function(input,processed)
 if input.UserInputType==Enum.UserInputType.MouseButton1 then
  local pos=Vector2.new(input.Position.X,input.Position.Y)
  if not processed and down and (pos-down).Magnitude<8 then pick(pos) end
  down=nil
 end
end)
UIS.TouchTapInWorld:Connect(function(position,processed) if not processed then pick(position) end end)
local elapsed=0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<.2 then return end elapsed=0
 if selected then
  if not selected.Parent or blocked() then close() else outline.Adornee=selected.Character outline.Enabled=selected.Character~=nil end
 end
end)
