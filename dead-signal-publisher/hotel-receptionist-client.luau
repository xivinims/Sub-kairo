local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local remote=RS:WaitForChild('MysteryUIAction')
local gui=Instance.new('ScreenGui');gui.Name='ReceptionistDialogue';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=1850;gui.Enabled=false;gui.Parent=player:WaitForChild('PlayerGui')
local card=Instance.new('Frame');card.AnchorPoint=Vector2.new(.5,1);card.Position=UDim2.new(.5,0,1,-112);card.Size=UDim2.new(.58,0,0,98);card.BackgroundColor3=Color3.fromRGB(11,13,13);card.BackgroundTransparency=.08;card.BorderSizePixel=0;card.Parent=gui;Instance.new('UICorner',card).CornerRadius=UDim.new(0,6)
local stroke=Instance.new('UIStroke',card);stroke.Color=Color3.fromRGB(183,159,120);stroke.Transparency=.62
local title=Instance.new('TextLabel');title.Position=UDim2.new(0,18,0,10);title.Size=UDim2.new(1,-36,0,20);title.BackgroundTransparency=1;title.Text='RECEPCIONISTA';title.Font=Enum.Font.RobotoCondensed;title.TextSize=11;title.TextColor3=Color3.fromRGB(213,184,128);title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=card
local divider=Instance.new('Frame');divider.Position=UDim2.new(0,18,0,36);divider.Size=UDim2.new(1,-36,0,1);divider.BackgroundColor3=Color3.fromRGB(129,115,93);divider.BackgroundTransparency=.5;divider.BorderSizePixel=0;divider.Parent=card
local line=Instance.new('TextLabel');line.Position=UDim2.new(0,18,0,44);line.Size=UDim2.new(1,-36,0,44);line.BackgroundTransparency=1;line.Text='Hola. Seja bem-vindo ao hotel.';line.Font=Enum.Font.Garamond;line.TextSize=21;line.TextColor3=Color3.fromRGB(235,226,207);line.TextWrapped=true;line.TextXAlignment=Enum.TextXAlignment.Left;line.Parent=card
local activeTween
remote.OnClientEvent:Connect(function(action,data)
 if action~='receptionist_dialogue' then return end
 if activeTween then activeTween:Cancel() end
 gui.Enabled=true;card.BackgroundTransparency=.08;card.Position=UDim2.new(.5,0,1,12);line.Text=typeof(data)=='table' and data.text or 'Hola. Seja bem-vindo ao hotel.'
 Tween:Create(card,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,1,-112)}):Play()
 task.delay(4.5,function()
  if not gui.Enabled then return end
  activeTween=Tween:Create(card,TweenInfo.new(.25,Enum.EasingStyle.Sine,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,1,12),BackgroundTransparency=1});activeTween:Play();activeTween.Completed:Once(function() gui.Enabled=false end)
 end)
end)
