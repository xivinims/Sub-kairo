local Players=game:GetService('Players');local RF=game:GetService('ReplicatedFirst');local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui');gui.Name='StillHereLoading';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10000;gui.Parent=pg
local background=Instance.new('Frame');background.Size=UDim2.fromScale(1,1);background.BackgroundColor3=Color3.fromRGB(4,5,6);background.BorderSizePixel=0;background.Parent=gui
local caption=Instance.new('TextLabel');caption.AnchorPoint=Vector2.new(1,1);caption.Position=UDim2.new(1,-28,1,-24);caption.Size=UDim2.new(.65,0,0,36);caption.BackgroundTransparency=1;caption.Text='Carregando…';caption.TextXAlignment=Enum.TextXAlignment.Right;caption.Font=Enum.Font.Garamond;caption.TextSize=20;caption.TextColor3=Color3.fromRGB(190,193,185);caption.Parent=background
local hint=caption:Clone();hint.AnchorPoint=Vector2.new(0,1);hint.Position=UDim2.new(0,28,1,-74);hint.TextXAlignment=Enum.TextXAlignment.Left;hint.TextTransparency=1;hint.Text='';hint.Parent=background
RF:RemoveDefaultLoadingScreen()
local ui=require(RS:WaitForChild('SessionInterface'))
task.spawn(function() if not ui.Load() then warn('[Settings] Could not load preferences; defaults in use, retry in settings.') end end)
local active=true
local phrases={'Cuidado.','Não abra a porta.','Ele está te vendo.','Eu vejo você.'}
task.spawn(function()
 while active do
  task.wait(12)
  if not active then return end
  if workspace:GetAttribute('GameMode')=='Match' and player:GetAttribute('LoadingHints')~=false and math.random()<.35 then
   hint.Text=phrases[math.random(#phrases)];Tween:Create(hint,TweenInfo.new(2),{TextTransparency=.35}):Play();task.wait(4)
   if active then Tween:Create(hint,TweenInfo.new(2),{TextTransparency=1}):Play() end
  end
 end
end)
local started=os.clock()
while true do
 local mode=workspace:GetAttribute('GameMode')
 if mode=='Menu' and player:GetAttribute('MenuReady') or mode=='Match' and player:GetAttribute('ArrivalReady') then break end
 if os.clock()-started>45 then caption.Text='Carregando… conexão lenta.' end
 task.wait(.1)
end
active=false
-- No white flash or title animation. Reveal the already prepared scene from black.
Tween:Create(background,TweenInfo.new(.25),{BackgroundTransparency=1}):Play();Tween:Create(caption,TweenInfo.new(.2),{TextTransparency=1}):Play();Tween:Create(hint,TweenInfo.new(.2),{TextTransparency=1}):Play();task.wait(.3);gui:Destroy()
if workspace:GetAttribute('GameMode')=='Match' then
 local controls=Instance.new('ScreenGui');controls.Name='InGameSettings';controls.ResetOnSpawn=false;controls.IgnoreGuiInset=false;controls.DisplayOrder=100;controls.Parent=pg
 local button=ui.Button(controls,'⚙',ui.OpenSettings);button.AnchorPoint=Vector2.new(1,0);button.Position=UDim2.new(1,-10,0,6);button.Size=UDim2.fromOffset(44,44);button.TextSize=27;button.TextXAlignment=Enum.TextXAlignment.Center
end
