-- Separate integration controls. Original imported scripts remain intact.
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui');gui.Name='R6TestControls';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.Parent=pg
local info=Instance.new('TextLabel');info.Size=UDim2.new(0,330,0,50);info.Position=UDim2.fromOffset(12,8);info.BackgroundColor3=Color3.fromRGB(22,29,43);info.BackgroundTransparency=.15;info.TextColor3=Color3.new(1,1,1);info.TextSize=13;info.Font=Enum.Font.GothamMedium;info.Text='ARENA R6  •  TESTE\nArco: mouse | Correr: W 2x | Lanterna: R';info.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=info
local aim=Instance.new('TextLabel');aim.Size=UDim2.fromOffset(22,22);aim.AnchorPoint=Vector2.new(.5,.5);aim.Position=UDim2.fromScale(.5,.5);aim.BackgroundTransparency=1;aim.Text='+';aim.TextSize=24;aim.TextColor3=Color3.new(1,1,1);aim.Parent=gui
local panel=Instance.new('Frame');panel.Name='Actions';panel.BackgroundTransparency=1;panel.AnchorPoint=Vector2.new(1,0);panel.Size=UDim2.fromOffset(116,116);panel.Parent=gui
local panelScale=Instance.new('UIScale');panelScale.Parent=panel
local buttons={}
local function button(name,label,x,y,fn)
 local b=Instance.new('TextButton');b.Name=name;b.Size=UDim2.fromOffset(52,52);b.Position=UDim2.fromOffset(x,y);b.Text=label;b.Font=Enum.Font.GothamBold;b.TextSize=10;b.TextColor3=Color3.new(1,1,1);b.BackgroundColor3=Color3.fromRGB(28,44,58);b.BackgroundTransparency=.12;b.Parent=panel
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(1,0);c.Parent=b
 local s=Instance.new('UIStroke');s.Color=Color3.fromRGB(100,211,185);s.Thickness=1.5;s.Parent=b
 b.Activated:Connect(fn);buttons[name]=b;return b
end
local lastShot=0
button('Shoot','ARCO',0,0,function()
 local char=player.Character;if not char or not char:FindFirstChild('HumanoidRootPart') then return end
 if os.clock()-lastShot<1 then return end;lastShot=os.clock()
 local camera=workspace.CurrentCamera
 require(RS.Assets.Modules.Packets).Shoot:Fire(camera.CFrame.LookVector)
 local sound=game:GetService('SoundService'):FindFirstChild('Bow Release');if sound then sound:Play() end
end)
button('Lantern','LUZ',60,0,function()
 local char=player.Character;if not char or not char:FindFirstChild('ClassicLantern') then return end
 require(RS.Modules.Network.Packets).ToggleLantern:Fire(char:GetAttribute('LanternToggled') and 'Off' or 'On')
end)
button('Sprint','CORRER',0,60,function()
 local char=player.Character;if not char or not char:FindFirstChild('Humanoid') then return end
 local running=char:GetAttribute('state')=='running';local run=require(RS.Modules.Run.RunClient)
 char:SetAttribute('state',running and 'neutral' or 'running');if running then run.stop(char) else run.begin(char) end
end)
button('Swap','TROCAR',60,60,function()
 local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');if not root then return end
 local camera=workspace.CurrentCamera;local best,score=nil,math.huge
 for _,bot in ipairs(workspace.TrainingBots:GetChildren()) do
  local r=bot:FindFirstChild('HumanoidRootPart');local h=bot:FindFirstChildOfClass('Humanoid')
  if r and h and h.Health>0 and (r.Position-root.Position).Magnitude<120 then
   local p,visible=camera:WorldToViewportPoint(r.Position)
   if visible then local distance=(Vector2.new(p.X,p.Y)-camera.ViewportSize/2).Magnitude;if distance<score then best=r;score=distance end end
  end
 end
 if best then RS.BoogieWoogie:FireServer(root,best) end
end)
local function layout()
 local size=gui.AbsoluteSize
 local top=math.max(66,size.Y*.32)
 local jump=pg:FindFirstChild('JumpButton',true)
 local limit=size.Y-12
 if jump and jump:IsA('GuiObject') and jump.Visible then limit=jump.AbsolutePosition.Y-gui.AbsolutePosition.Y-12 end
 top=math.max(12,math.min(top,limit-116))
 panelScale.Scale=math.min(1,math.max(.1,(limit-top)/116))
 panel.Position=UDim2.new(1,-14,0,top)
 info.Size=UDim2.fromOffset(math.min(330,math.max(200,size.X-160)),50)
end
gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout);pg.DescendantAdded:Connect(function(x) if x.Name=='JumpButton' then task.defer(layout) end end)
layout();task.spawn(function() while gui.Parent do task.wait(1);layout() end end)
