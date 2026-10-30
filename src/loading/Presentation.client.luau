local RF=game:GetService("ReplicatedFirst")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")
pcall(function() RF:RemoveDefaultLoadingScreen() end)
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="BramblePresentation";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=1000;gui.Parent=player:WaitForChild("PlayerGui")
local black=Instance.new("Frame");black.Size=UDim2.fromScale(1,1);black.BackgroundColor3=Color3.new(0,0,0);black.BorderSizePixel=0;black.Parent=gui
local function text(value,y,size)
 local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.AnchorPoint=Vector2.new(.5,.5);t.Position=UDim2.fromScale(.5,y);t.Size=UDim2.fromScale(.86,.2);t.Text=value;t.Font=Enum.Font.GothamBold;t.TextSize=size;t.TextScaled=true;t.TextColor3=Color3.fromRGB(236,232,218);t.TextTransparency=1;t.Parent=black
 local cap=Instance.new("UITextSizeConstraint");cap.MaxTextSize=size;cap.Parent=t;return t
end
local status=text("CARREGANDO RECURSOS…",.85,18);status.TextTransparency=0
local shared=RS:WaitForChild("Shared",20)
if not shared then status.Text="Não foi possível carregar. Entre novamente na experiência.";return end
local Config=require(shared:WaitForChild("Config"))
local studio=text("AURIVANE\nWORKS",.47,70)
local title=text(Config.Title,.47,64)
local chapter=text("CAPÍTULO 1 / DEAD SIGNAL",.60,22);chapter.TextColor3=Color3.fromRGB(172,56,32)
if Config.Assets.StudioLogo>0 then
 studio:Destroy();studio=Instance.new("ImageLabel");studio.Size=UDim2.fromScale(.75,.75);studio.AnchorPoint=Vector2.new(.5,.5);studio.Position=UDim2.fromScale(.5,.47);studio.BackgroundTransparency=1;studio.Image="rbxassetid://"..Config.Assets.StudioLogo;studio.ScaleType=Enum.ScaleType.Fit;studio.ImageTransparency=1;studio.Parent=black
end
if Config.Assets.ChapterLogo>0 then
 title.Position=UDim2.fromScale(.5,.32);chapter:Destroy();chapter=Instance.new("ImageLabel");chapter.Size=UDim2.fromScale(.84,.25);chapter.AnchorPoint=Vector2.new(.5,.5);chapter.Position=UDim2.fromScale(.5,.62);chapter.BackgroundTransparency=1;chapter.Image="rbxassetid://"..Config.Assets.ChapterLogo;chapter.ScaleType=Enum.ScaleType.Fit;chapter.ImageTransparency=1;chapter.Parent=black
end
local function chapterAlpha(alpha) if chapter:IsA("ImageLabel") then chapter.ImageTransparency=alpha else chapter.TextTransparency=alpha end end
local function fade(item,alpha,duration)
 local goal=if item:IsA("ImageLabel") then {ImageTransparency=alpha} else {TextTransparency=alpha}
 local t=TweenService:Create(item,TweenInfo.new(duration),goal);t:Play();t.Completed:Wait()
end
local preloadDone=false
local assets={};for _,key in ipairs({"StudioLogo","ChapterLogo","MenuLogo","Ambient","Pursuit","Radio","Relay","OpeningVoice"}) do local id=Config.Assets[key];if id and id>0 then table.insert(assets,"rbxassetid://"..id) end end
for _,id in pairs(Config.Assets.Cassettes or {}) do if type(id)=="number" and id>0 then table.insert(assets,"rbxassetid://"..id) end end
for _,id in pairs(Config.Assets.Voices) do if id>0 then table.insert(assets,"rbxassetid://"..id) end end
task.spawn(function()
 local n=0
 local templates=RS:WaitForChild("BrambleAssets",30)
 if templates then local untilTime=os.clock()+30;while not templates:GetAttribute("Ready") and os.clock()<untilTime do task.wait(.1) end;table.insert(assets,templates) end
 local ok=pcall(function() ContentProvider:PreloadAsync(assets,function() n+=1;status.Text="CARREGANDO RECURSOS / "..math.min(n,#assets).." / "..#assets end) end)
 preloadDone=true;if not ok then status.Text="Alguns recursos estão indisponíveis. Continuando com texto." end
end)
status.Visible=false
task.wait(.9);fade(studio,0,.8);task.wait(2)
local flash=Instance.new("Frame");flash.Size=UDim2.fromScale(1,1);flash.BackgroundColor3=Color3.new(1,1,1);flash.BackgroundTransparency=1;flash.BorderSizePixel=0;flash.ZIndex=10;flash.Parent=black
local flashIn=TweenService:Create(flash,TweenInfo.new(.12),{BackgroundTransparency=.12});flashIn:Play();flashIn.Completed:Wait();local flashOut=TweenService:Create(flash,TweenInfo.new(.4),{BackgroundTransparency=1});flashOut:Play()
local whiten=TweenService:Create(studio,TweenInfo.new(.35),if studio:IsA("ImageLabel") then {ImageColor3=Color3.new(1,1,1)} else {TextColor3=Color3.new(1,1,1)});whiten:Play();whiten.Completed:Wait();fade(studio,1,.7)
chapterAlpha(0);fade(title,0,.8);task.wait(2);fade(title,1,.7);chapterAlpha(1)
status.Visible=true
local deadline=os.clock()+40
while not preloadDone or not workspace:GetAttribute("BrambleWorldReady") do
 if os.clock()>deadline then status.Text="O servidor não terminou o carregamento. Saia e tente entrar novamente.";return end
 if not workspace:GetAttribute("BrambleWorldReady") then status.Text="PREPARANDO O CONSERVATÓRIO…" end
 task.wait(.1)
end
player:SetAttribute("BrambleBootDone",true)
fade(status,1,.25);gui:Destroy()
