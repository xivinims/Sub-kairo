local M={}
function M.start(runtime,world)
 local Players=game:GetService("Players")local remote=runtime:WaitForChild("MusicListening")
 local function label(player,character)
  local head=character:WaitForChild("Head",10)if not head or player.Character~=character then return end
  local old=head:FindFirstChild("TreeWorldMusicTag")if old then old:Destroy()end
  local tag=Instance.new("BillboardGui")tag.Name="TreeWorldMusicTag"tag.Size=UDim2.fromOffset(170,22)tag.StudsOffsetWorldSpace=Vector3.new(0,3.2,0)tag.MaxDistance=65 tag.AlwaysOnTop=false tag.Enabled=player:GetAttribute("ListeningToMusic")==true tag.Parent=head
  local text=Instance.new("TextLabel")text.Name="Status"text.Size=UDim2.fromScale(1,1)text.BackgroundTransparency=1 text.Text="♫ música ouvindo"text.Font=Enum.Font.GothamMedium text.TextSize=12 text.TextColor3=Color3.fromRGB(219,238,204)text.TextStrokeTransparency=.65 text.Parent=tag
 end
 local function apply(player,active)
  if type(active)~="boolean"then return false end
  player:SetAttribute("ListeningToMusic",active)
  local character=player.Character local head=character and character:FindFirstChild("Head")local tag=head and head:FindFirstChild("TreeWorldMusicTag")if tag then tag.Enabled=active end return true
 end
 local function added(player)
  player:SetAttribute("ListeningToMusic",false)
  player.CharacterAdded:Connect(function(character)task.spawn(label,player,character)end)
  if player.Character then task.spawn(label,player,player.Character)end
 end
 local rate={}
 remote.OnServerEvent:Connect(function(player,active)
  if type(active)~="boolean"then return end
  local now=os.clock()local record=rate[player]or{time=now,count=0}
  if now-record.time>1 then record.time=now record.count=0 end
  record.count+=1 rate[player]=record if active==false or record.count<=6 then apply(player,active)end
 end)
 Players.PlayerAdded:Connect(added)Players.PlayerRemoving:Connect(function(player)rate[player]=nil end)
 for _,player in ipairs(Players:GetPlayers())do added(player)end
 return{apply=apply,label=label}
end
return M
