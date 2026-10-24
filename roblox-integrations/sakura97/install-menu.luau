assert(game.GameId==9419478735 and game.PlaceId==79738710219521)
local RS=game:GetService("ReplicatedStorage")
local starter=game:GetService("StarterGui")
local first=game:GetService("ReplicatedFirst")
local runtime=assert(RS:FindFirstChild("SweanRuntime"),"Runtime missing")

for _,pair in ipairs({{starter,"TomiaszMenu"},{first,"SweanLoadingController"},{RS,"SweanMenuConfig"}}) do
 local old=pair[1]:FindFirstChild(pair[2]) if old then old:Destroy() end
end

local function corner(parent,r)
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=parent return c
end
local function stroke(parent,t)
 local s=Instance.new("UIStroke") s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 s.Color=Color3.fromRGB(143,66,70) s.Transparency=t or .7 s.Thickness=1 s.Parent=parent return s
end
local function label(parent,name,textValue)
 local t=Instance.new("TextLabel") t.Name=name t.BackgroundTransparency=1 t.Text=textValue
 t.Font=Enum.Font.GothamMedium t.TextColor3=Color3.fromRGB(235,235,239)
 t.TextWrapped=true t.Parent=parent return t
end
local function button(parent,name,textValue)
 local b=Instance.new("TextButton") b.Name=name b.Text=textValue b.Active=true b.AutoButtonColor=false
 b.BackgroundColor3=Color3.fromRGB(26,16,18) b.BackgroundTransparency=.18
 b.TextColor3=Color3.fromRGB(242,242,245) b.Font=Enum.Font.GothamSemibold
 b.TextSize=16 b.BorderSizePixel=0 b.Parent=parent corner(b,14) stroke(b,.68) return b
end

local ui=Instance.new("ScreenGui")
ui.Name="TomiaszMenu" ui.ResetOnSpawn=false ui.IgnoreGuiInset=true ui.DisplayOrder=20
ui:SetAttribute("SourceAssetId",0)

local main=Instance.new("Frame") main.Name="MenuPrincipal" main.Size=UDim2.fromScale(1,1)
main.BackgroundTransparency=1 main.Parent=ui

local vignette=Instance.new("Frame") vignette.Name="Vignette" vignette.Size=UDim2.fromScale(1,1)
vignette.BackgroundColor3=Color3.fromRGB(0,0,0) vignette.BackgroundTransparency=.72 vignette.BorderSizePixel=0 vignette.Parent=main
local vg=Instance.new("UIGradient") vg.Rotation=0
vg.Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.36,.45),NumberSequenceKeypoint.new(1,1)
}) vg.Parent=vignette

local left=Instance.new("Frame") left.Name="LeftPanel" left.BackgroundColor3=Color3.fromRGB(10,9,12)
left.BackgroundTransparency=1 left.BorderSizePixel=0 left.Parent=main corner(left,22)

local logo=Instance.new("ImageLabel") logo.Name="Logo" logo.BackgroundTransparency=1 logo.ScaleType=Enum.ScaleType.Fit
local logoId=__SURVIVERS_LOGO_ID__
assert(logoId and logoId>0,"Exact logo is required")
if logoId and logoId>0 then logo.Image="rbxassetid://"..tostring(logoId) logo.Visible=true else logo.Image="" logo.Visible=false end
local logoAsset=game:GetService("AssetService"):LoadAssetAsync(logoId)
local decal=logoAsset:FindFirstChildWhichIsA("Decal",true)
assert(decal and decal.Texture~="","Exact logo texture unavailable")
logo.Image=decal.Texture logo:SetAttribute("SourceAssetId",logoId) logoAsset:Destroy()
logo.Parent=main

local gameName=label(main,"GameName","SUVIVERS [ALFA]")
gameName.Font=Enum.Font.GothamBlack gameName.TextColor3=Color3.fromRGB(231,225,226)
gameName.TextXAlignment=Enum.TextXAlignment.Center gameName.TextStrokeColor3=Color3.fromRGB(126,12,20) gameName.TextStrokeTransparency=.25 gameName.Visible=true

local play=button(main,"Play","ENTRAR NO LOBBY")
local settingsButton=button(main,"Ajustes","AJUSTES")
local creditsButton=button(ui,"CreditsButton","CRÉDITOS")

local guide=label(main,"Guide","ATRAVESSE A PORTA PARA JOGAR")
guide.TextSize=11 guide.TextColor3=Color3.fromRGB(177,157,160) guide.TextXAlignment=Enum.TextXAlignment.Left
local edition=label(main,"Edition","3 CENÁRIOS  •  ATÉ 8 JOGADORES")
edition.Font=Enum.Font.GothamSemibold edition.TextSize=10 edition.TextColor3=Color3.fromRGB(178,118,125) edition.TextXAlignment=Enum.TextXAlignment.Left
local help=label(main,"QuickHelp","Correr faz barulho. Agache para se esconder.\nUm kit pode salvar você ou um aliado caído.")
help.TextSize=12 help.TextColor3=Color3.fromRGB(190,182,188) help.TextXAlignment=Enum.TextXAlignment.Left
local scenes=Instance.new("Frame") scenes.Name="Escenarios" scenes.Size=UDim2.fromScale(1,1)
scenes.BackgroundTransparency=1 scenes.Parent=ui

local function modal(name,titleText)
 local scene=Instance.new("Frame") scene.Name=name scene.Size=UDim2.fromScale(1,1)
 scene.BackgroundColor3=Color3.fromRGB(0,0,0) scene.BackgroundTransparency=.35 scene.Visible=false scene.Parent=scenes
 local title=Instance.new("Frame") title.Name="Tittle" title.BackgroundTransparency=1 title.Parent=scene
 local titleTextObj=label(title,"TittleText",titleText) titleTextObj.Font=Enum.Font.GothamBold titleTextObj.TextSize=24 titleTextObj.TextXAlignment=Enum.TextXAlignment.Left
 local body=Instance.new("Frame") body.Name=name=="MenuAjustes" and "AjustesFrame" or "CreditosFrame"
 body.BackgroundColor3=Color3.fromRGB(14,14,18) body.BackgroundTransparency=.12 body.BorderSizePixel=0 body.Parent=scene corner(body,20) stroke(body,.72)
 local close=button(scene,"Close","×") close.TextSize=26
 return scene,title,body,close
end

local settings,settingsTitle,settingsBody,settingsClose=modal("MenuAjustes","AJUSTES")
local credits,creditsTitle,creditsBody,creditsClose=modal("MenuCreditos","CRÉDITOS")

local controls=Instance.new("ScrollingFrame") controls.Name="Controls" controls.BackgroundTransparency=1 controls.BorderSizePixel=0
controls.AutomaticCanvasSize=Enum.AutomaticSize.Y controls.CanvasSize=UDim2.new() controls.ScrollBarThickness=3 controls.Parent=settingsBody
local list=Instance.new("UIListLayout") list.Padding=UDim.new(0,8) list.SortOrder=Enum.SortOrder.LayoutOrder list.Parent=controls
for i,name in ipairs({"QualityToggle","NametagsToggle","SoundToggle","MusicToggle","FriendsToggle"}) do
 local b=button(controls,name,name) b.LayoutOrder=i b.Size=UDim2.new(1,-4,0,44)
end

local creditsText=label(creditsBody,"TextCreditos","Criado por\n\nch_ckz2n\n\nSurvivers")
creditsText.TextSize=18 creditsText.TextXAlignment=Enum.TextXAlignment.Center creditsText.TextYAlignment=Enum.TextYAlignment.Center

local back=button(ui,"ReturnToMenu","☰") back.Visible=false
local transition=Instance.new("Frame") transition.Name="FrameDeTransicion" transition.Size=UDim2.fromScale(1,1)
transition.BackgroundColor3=Color3.new(0,0,0) transition.BackgroundTransparency=1 transition.Visible=false transition.ZIndex=100 transition.Parent=ui

local sounds=Instance.new("Folder") sounds.Name="Sonidos" sounds.Parent=ui
local media=RS:FindFirstChild("XNMedia")
if media and media:FindFirstChild("MenuClick") then
 local click=media.MenuClick:Clone() click.Name="Click" click.Parent=sounds
else
 local click=Instance.new("Sound") click.Name="Click" click.SoundId="rbxassetid://12221967" click.Volume=.35 click.Parent=sounds
end

local controller=Instance.new("LocalScript") controller.Name="MenuController" controller.Source=__MENU_SOURCE__ controller.Parent=ui

local config=Instance.new("Folder") config.Name="SweanMenuConfig"
config:SetAttribute("MenuOrigin",Vector3.new(10000,2500,10000))
config:SetAttribute("MainCamera",CFrame.new(10000,2505,10010))
config:SetAttribute("SettingsCamera",CFrame.new(10000,2505,10010))
config:SetAttribute("CreditsCamera",CFrame.new(10000,2505,10010))
config:SetAttribute("Version",121)
config:SetAttribute("GameName","Suvivers [ALFA]")
config:SetAttribute("MenuSceneAssetId",13327565335)
config:SetAttribute("LogoAssetId",logoId or 0)
config:SetAttribute("SourceAssetId",0)
config.Parent=RS

local loader=Instance.new("LocalScript") loader.Name="SweanLoadingController" loader.Source=__LOADING_SOURCE__ loader.Parent=first
ui.Parent=starter

runtime:SetAttribute("MenuAssetId",0)
runtime:SetAttribute("MenuVersion",121)
runtime:SetAttribute("GameName","Suvivers [ALFA]")
runtime:SetAttribute("SurviversLogoAssetId",logoId or 0)

