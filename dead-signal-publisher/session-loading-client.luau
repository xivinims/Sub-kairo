local Players=game:GetService('Players');local RF=game:GetService('ReplicatedFirst');local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local experienceChapter=workspace:GetAttribute('ExperienceChapter')==2 and 2 or 1
local gui=Instance.new('ScreenGui');gui.Name='StillHereLoading';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10000;gui.Parent=pg
local background=Instance.new('Frame');background.Size=UDim2.fromScale(1,1);background.BackgroundColor3=Color3.fromRGB(4,5,6);background.BorderSizePixel=0;background.Parent=gui
local chapterArt=Instance.new('ImageLabel');chapterArt.Name='ChapterTwoLoadingArtwork';chapterArt.Size=UDim2.fromScale(1,1);chapterArt.BackgroundTransparency=1;chapterArt.Image='rbxassetid://__CHAPTER_TWO_ART_ASSET_ID__';chapterArt.ScaleType=Enum.ScaleType.Crop;chapterArt.ImageTransparency=experienceChapter==2 and 0 or 1;chapterArt.ZIndex=1;chapterArt.Parent=background
local artShade=Instance.new('Frame');artShade.Name='ChapterTwoLoadingShade';artShade.Size=UDim2.fromScale(1,1);artShade.BackgroundColor3=Color3.fromRGB(5,10,8);artShade.BackgroundTransparency=experienceChapter==2 and .73 or 0;artShade.BorderSizePixel=0;artShade.ZIndex=2;artShade.Parent=background
local chapterTitle=Instance.new('TextLabel');chapterTitle.Name='ChapterTwoLoadingTitle';chapterTitle.AnchorPoint=Vector2.new(0,1);chapterTitle.Position=UDim2.new(0,28,1,-104);chapterTitle.Size=UDim2.new(.82,0,0,50);chapterTitle.BackgroundTransparency=1;chapterTitle.Text='CHAPTER 2  ·  AQUELE QUE NÃO ENCONTRA';chapterTitle.TextXAlignment=Enum.TextXAlignment.Left;chapterTitle.Font=Enum.Font.Oswald;chapterTitle.TextSize=29;chapterTitle.TextColor3=Color3.fromRGB(246,239,213);chapterTitle.Visible=experienceChapter==2;chapterTitle.ZIndex=4;chapterTitle.Parent=background
local titleLimit=Instance.new('UITextSizeConstraint');titleLimit.MinTextSize=17;titleLimit.MaxTextSize=30;titleLimit.Parent=chapterTitle
local caption=Instance.new('TextLabel');caption.AnchorPoint=Vector2.new(1,1);caption.Position=UDim2.new(1,-28,1,-24);caption.Size=UDim2.new(.65,0,0,36);caption.BackgroundTransparency=1;caption.Text=experienceChapter==2 and 'Abrindo Chapter 2…' or 'Carregando…';caption.ZIndex=4;caption.TextXAlignment=Enum.TextXAlignment.Right;caption.Font=Enum.Font.Garamond;caption.TextSize=20;caption.TextColor3=Color3.fromRGB(239,236,220);caption.ZIndex=4;caption.Parent=background
local hint=caption:Clone();hint.AnchorPoint=Vector2.new(0,1);hint.Position=UDim2.new(0,28,1,-74);hint.TextXAlignment=Enum.TextXAlignment.Left;hint.TextTransparency=1;hint.Text='';hint.ZIndex=4;hint.Parent=background
local track=Instance.new('Frame');track.Name='LoadingProgressTrack';track.Position=UDim2.new(.04,0,1,-14);track.Size=UDim2.new(.92,0,0,2);track.BackgroundColor3=Color3.fromRGB(199,203,184);track.BackgroundTransparency=.62;track.BorderSizePixel=0;track.ZIndex=4;track.Parent=background
local fill=Instance.new('Frame');fill.Name='LoadingProgress';fill.Size=UDim2.fromScale(.28,1);fill.BackgroundColor3=Color3.fromRGB(230,205,136);fill.BorderSizePixel=0;fill.ZIndex=5;fill.Parent=track
local progressTween=Tween:Create(fill,TweenInfo.new(1.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=UDim2.new(.72,0,0,0)});progressTween:Play()
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
progressTween:Cancel();Tween:Create(background,TweenInfo.new(.25),{BackgroundTransparency=1}):Play();Tween:Create(chapterArt,TweenInfo.new(.25),{ImageTransparency=1}):Play();Tween:Create(artShade,TweenInfo.new(.25),{BackgroundTransparency=1}):Play();Tween:Create(chapterTitle,TweenInfo.new(.2),{TextTransparency=1}):Play();Tween:Create(caption,TweenInfo.new(.2),{TextTransparency=1}):Play();Tween:Create(hint,TweenInfo.new(.2),{TextTransparency=1}):Play();Tween:Create(fill,TweenInfo.new(.2),{BackgroundTransparency=1}):Play();task.wait(.3);gui:Destroy()
if workspace:GetAttribute('GameMode')=='Match' then
 local controls=Instance.new('ScreenGui');controls.Name='InGameSettings';controls.ResetOnSpawn=false;controls.IgnoreGuiInset=false;controls.DisplayOrder=100;controls.Parent=pg
 local button=ui.Button(controls,'⚙',ui.OpenSettings);button.AnchorPoint=Vector2.new(1,0);button.Position=UDim2.new(1,-10,0,6);button.Size=UDim2.fromOffset(44,44);button.TextSize=27;button.TextXAlignment=Enum.TextXAlignment.Center
end
