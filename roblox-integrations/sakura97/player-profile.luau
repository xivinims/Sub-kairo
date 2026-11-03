-- Compact profile. Currency is deliberately excluded from every public card.
local Profile={}
function Profile.open(viewer,target,onClose)
 local gui=Instance.new("ScreenGui") gui.Name="SelectedPlayerProfile" gui.DisplayOrder=65 gui.ResetOnSpawn=false gui.IgnoreGuiInset=true
 gui:SetAttribute("TargetUserId",target.UserId) gui:SetAttribute("CompactProfile",true) gui.Parent=viewer:WaitForChild("PlayerGui")
 local frame=Instance.new("Frame",gui) frame.Name="Card" frame.AnchorPoint=Vector2.new(.5,.5) frame.Position=UDim2.fromScale(.5,.5) frame.Size=UDim2.new(.78,0,0,198) frame.BackgroundColor3=Color3.new(0,0,0) frame.BackgroundTransparency=.16 frame.BorderSizePixel=0
 local limit=Instance.new("UISizeConstraint",frame) limit.MaxSize=Vector2.new(340,198)
 local photo=Instance.new("ImageLabel",frame) photo.Name="Photo" photo.Size=UDim2.fromOffset(72,72) photo.Position=UDim2.fromOffset(18,20) photo.BackgroundTransparency=1 photo.Image="rbxthumb://type=AvatarHeadShot&id="..target.UserId.."&w=150&h=150"
 local function label(name,value,y,size)
  local t=Instance.new("TextLabel",frame) t.Name=name t.Text=value t.Position=UDim2.fromOffset(104,y) t.Size=UDim2.new(1,-120,0,26) t.BackgroundTransparency=1 t.TextColor3=Color3.fromRGB(235,235,235) t.Font=Enum.Font.Gotham t.TextSize=size or 14 t.TextXAlignment=Enum.TextXAlignment.Left t.TextTruncate=Enum.TextTruncate.AtEnd return t
 end
 label("Name",target.DisplayName or target.Name,22,17)
 label("Username","@"..target.Name,48,12)
 local level=label("Level","NÍVEL 1",76,13)
 local xp=label("XP","0 XP",102,12)
 local close=Instance.new("TextButton",frame) close.Name="Close" close.Text="SAÍDA" close.BackgroundColor3=Color3.new(0,0,0) close.BackgroundTransparency=.2 close.BorderSizePixel=0 close.TextColor3=Color3.new(1,1,1) close.Font=Enum.Font.Gotham close.TextSize=13 close.Size=UDim2.new(1,-36,0,36) close.Position=UDim2.fromOffset(18,146)
 local connections={} local dead=false
 local function destroy()
  if dead then return end dead=true
  for _,c in ipairs(connections) do c:Disconnect() end
  gui:Destroy() if onClose then onClose() end
 end
 local function refresh()
  local stats=target:FindFirstChild("leaderstats")
  local l=stats and stats:FindFirstChild("Nível") local x=stats and stats:FindFirstChild("XP")
  level.Text="NÍVEL "..tostring(l and l.Value or 1) xp.Text=tostring(x and x.Value or 0).." XP"
 end
 refresh()
 task.spawn(function() while not dead and gui.Parent do refresh() task.wait(.5) end end)
 local stats=target:FindFirstChild("leaderstats")
 if stats then for _,n in ipairs({"Nível","XP"}) do local v=stats:FindFirstChild(n) if v then table.insert(connections,v.Changed:Connect(refresh)) end end end
 table.insert(connections,close.Activated:Connect(destroy))
 return {gui=gui,close=destroy,Destroy=destroy}
end
return Profile
