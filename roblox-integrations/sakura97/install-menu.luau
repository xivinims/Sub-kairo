assert(game.GameId==9419478735 and game.PlaceId==79738710219521)
local RS=game:GetService("ReplicatedStorage")
local starter=game:GetService("StarterGui")
local first=game:GetService("ReplicatedFirst")
local runtime=assert(RS:FindFirstChild("SweanRuntime"),"Runtime missing")

for _,pair in ipairs({{starter,"TomiaszMenu"},{first,"SweanLoadingController"},{first,"LoadingCinematicAssets"},{RS,"SweanMenuConfig"}}) do
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
 b.BackgroundColor3=Color3.fromRGB(26,23,28) b.BackgroundTransparency=.18
 b.TextColor3=Color3.fromRGB(242,242,245) b.Font=Enum.Font.GothamSemibold
 b.TextSize=16 b.TextStrokeColor3=Color3.new(0,0,0) b.TextStrokeTransparency=.25 b.BorderSizePixel=0 b.Parent=parent corner(b,10) local outer=stroke(b,.25) outer.Thickness=2
 local inset=Instance.new("Frame",b) inset.Name="Inset" inset.BackgroundTransparency=1 inset.Size=UDim2.new(1,-8,1,-8) inset.Position=UDim2.fromOffset(4,4) corner(inset,7) stroke(inset,.65)
 return b
end

local ui=Instance.new("ScreenGui")
ui.Name="TomiaszMenu" ui.ResetOnSpawn=false ui.IgnoreGuiInset=true ui.DisplayOrder=20 ui.Enabled=false
ui:SetAttribute("MenuRemoved",true)
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
local updatesButton=button(main,"Updates","NOVIDADES")
for _,b in ipairs({play,settingsButton,updatesButton}) do
 b.BackgroundTransparency=1
 b.UICorner.CornerRadius=UDim.new(0,3)
 b.UIStroke.Thickness=1.4
 b.UIStroke.Transparency=.68
 local inset=b:FindFirstChild("Inset") if inset then inset.Visible=false end
end
local profile=Instance.new("Frame",main) profile.Name="Profile" profile.BackgroundTransparency=1
local xpBar=Instance.new("Frame",profile) xpBar.Name="XPBar" xpBar.Size=UDim2.new(1,0,0,26) xpBar.BackgroundColor3=Color3.fromRGB(18,18,25) xpBar.BackgroundTransparency=.3 xpBar.BorderSizePixel=0 corner(xpBar,5)
local fill=Instance.new("Frame",xpBar) fill.Name="Fill" fill.Size=UDim2.fromScale(0,1) fill.BackgroundColor3=Color3.fromRGB(94,116,204) fill.BorderSizePixel=0 corner(fill,5)
local xp=label(xpBar,"Value","NÍVEL 1") xp.Size=UDim2.new(1,-14,1,0) xp.Position=UDim2.fromOffset(7,0) xp.TextSize=12 xp.Font=Enum.Font.GothamBold xp.TextXAlignment=Enum.TextXAlignment.Left
local coins=label(profile,"Coins","◉  0") coins.Position=UDim2.fromOffset(0,32) coins.Size=UDim2.fromOffset(150,30) coins.TextSize=20 coins.TextColor3=Color3.fromRGB(164,214,114) coins.TextXAlignment=Enum.TextXAlignment.Left

local creditsButton=button(ui,"CreditsButton","CRÉDITOS")
creditsButton.BackgroundTransparency=1 creditsButton.UICorner.CornerRadius=UDim.new(0,3) creditsButton.UIStroke.Thickness=1.4 creditsButton.UIStroke.Transparency=.68
local creditsInset=creditsButton:FindFirstChild("Inset") if creditsInset then creditsInset.Visible=false end

local guide=label(main,"Guide","") guide.Visible=false
guide.TextSize=11 guide.TextColor3=Color3.fromRGB(177,157,160) guide.TextXAlignment=Enum.TextXAlignment.Left
local edition=label(main,"Edition","3 CENÁRIOS  •  ATÉ 8 JOGADORES")
edition.Font=Enum.Font.GothamSemibold edition.TextSize=10 edition.TextColor3=Color3.fromRGB(178,118,125) edition.TextXAlignment=Enum.TextXAlignment.Left
local help=label(main,"QuickHelp","") help.Visible=false
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
local updates,_,updatesBody=modal("MenuUpdates","NOVIDADES • ALFA 123")
local news=label(updatesBody,"Info","TRÊS CENÁRIOS\nBosque do Silêncio • Base Abandonada • Fortaleza da Névoa\n\nPERSEGUIDORES\nSpawns protegidos, movimentação por personagem e animações revisadas.\n\nVISUAL\nIluminação adaptativa, reflexos opcionais e nova tela de carregamento.\n\nINTERFACE\nHUD limpa, corrida por toque segurado e revive contextual.") news.Position=UDim2.fromOffset(20,12) news.Size=UDim2.new(1,-40,1,-24) news.TextSize=15 news.TextXAlignment=Enum.TextXAlignment.Left


local controls=Instance.new("ScrollingFrame") controls.Name="Controls" controls.BackgroundTransparency=1 controls.BorderSizePixel=0
controls.AutomaticCanvasSize=Enum.AutomaticSize.Y controls.CanvasSize=UDim2.new() controls.ScrollBarThickness=3 controls.Parent=settingsBody
local list=Instance.new("UIListLayout") list.Padding=UDim.new(0,8) list.SortOrder=Enum.SortOrder.LayoutOrder list.Parent=controls
for i,name in ipairs({"QualityToggle","NametagsToggle","SoundToggle","MusicToggle","FriendsToggle"}) do
 local b=button(controls,name,name) b.LayoutOrder=i b.Size=UDim2.new(1,-4,0,44)
end

local creditsText=label(creditsBody,"TextCreditos","Criado por\n\nch_ckz2n\n\nSurvivers")
creditsText.TextSize=18 creditsText.TextXAlignment=Enum.TextXAlignment.Center creditsText.TextYAlignment=Enum.TextYAlignment.Center

local transition=Instance.new("Frame") transition.Name="FrameDeTransicion" transition.Size=UDim2.fromScale(1,1)
transition.BackgroundColor3=Color3.new(0,0,0) transition.BackgroundTransparency=1 transition.Visible=false transition.ZIndex=100 transition.Parent=ui

local sounds=Instance.new("Folder") sounds.Name="Sonidos" sounds.Parent=ui
local media=RS:FindFirstChild("XNMedia")
if media and media:FindFirstChild("MenuClick") then
 local click=media.MenuClick:Clone() click.Name="Click" click.Parent=sounds
else
 local click=Instance.new("Sound") click.Name="Click" click.SoundId="rbxassetid://12221967" click.Volume=.28 click.Parent=sounds
end
local playClick=Instance.new("Sound") playClick.Name="PlayClick" playClick.SoundId="rbxassetid://87437544236708" playClick.Volume=.55 playClick.Parent=sounds
local flicker=Instance.new("Sound") flicker.Name="LightFlicker" flicker.SoundId="rbxassetid://137413271824429" flicker.Volume=.52 flicker.Parent=sounds

local controller=Instance.new("LocalScript") controller.Name="MenuController" controller.Source=__MENU_SOURCE__ controller.Parent=ui

local config=Instance.new("Folder") config.Name="SweanMenuConfig"
config:SetAttribute("MenuOrigin",Vector3.new(10000,2500,10000))
config:SetAttribute("MainCamera",CFrame.new(10000,2505,10010))
config:SetAttribute("SettingsCamera",CFrame.new(10000,2505,10010))
config:SetAttribute("CreditsCamera",CFrame.new(10000,2505,10010))
config:SetAttribute("Version",123)
config:SetAttribute("GameName","Suvivers [ALFA]")
config:SetAttribute("MenuSceneAssetId",13327565335)
do
 local oldTemplate=RS:FindFirstChild("MenuSceneTemplate")
 if oldTemplate then oldTemplate:Destroy() end
 local ok,asset=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(13327565335) end)
 if ok and asset then
  local best=nil local bestParts=-1
  for _,obj in ipairs(asset:GetDescendants()) do
   if obj:IsA("Model") then
    local n=0 for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
    if n>bestParts then bestParts=n best=obj end
   end
  end
  local source=best or asset
  local template=Instance.new("Model") template.Name="MenuSceneTemplate"
  if source:IsA("Model") then
   for _,child in ipairs(source:GetChildren()) do child:Clone().Parent=template end
  else
   for _,child in ipairs(asset:GetChildren()) do child:Clone().Parent=template end
  end
  for _,d in ipairs(template:GetDescendants()) do
   if d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then d:Destroy()
   elseif d:IsA("BasePart") then d.CanTouch=false end
  end
  template:SetAttribute("SourceAssetId",13327565335)
  template:SetAttribute("WinnerSceneOnly",true)
  template.Parent=RS
  asset:Destroy()
 end
end
config:SetAttribute("LogoAssetId",logoId or 0)
config:SetAttribute("SourceAssetId",0)
config.Parent=RS

-- Ten-second cinematic loading set. Keep the requested Toolbox assets in
-- ReplicatedFirst so the TV, table and horror hand exist before the rest of the place finishes replicating.
local cinematic=Instance.new("Folder")
cinematic.Name="LoadingCinematicAssets"
cinematic:SetAttribute("TVAssetId",421148437)
cinematic:SetAttribute("TableAssetId",397786287)
cinematic:SetAttribute("HandAssetId",8091676187)
cinematic:SetAttribute("Duration",10)

local function importLoadingModel(id,expectedName)
 local asset=game:GetService("AssetService"):LoadAssetAsync(id)
 local source=asset:FindFirstChild(expectedName,true) or asset:FindFirstChildWhichIsA("Model",true)
 local model
 if source and source:IsA("Model") then
  model=source:Clone()
 else
  model=Instance.new("Model")
  for _,child in ipairs(asset:GetChildren()) do
   if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Folder") or child:IsA("Accessory") then
    child:Clone().Parent=model
   end
  end
  assert(model:FindFirstChildWhichIsA("BasePart",true),"Loading asset "..id.." missing renderable geometry "..expectedName)
 end
 model.Name=expectedName
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
   d.Enabled=false
  elseif d:IsA("Sound") then
   d:Destroy()
  end
 end
 model:SetAttribute("SourceAssetId",id)
 model.Parent=cinematic
 asset:Destroy()
 return model
end

local loadingTV=importLoadingModel(421148437,"TV")
local loadingTable=importLoadingModel(397786287,"Mesa")
local loadingHand=importLoadingModel(8091676187,"BloodHand")
assert(loadingTV:FindFirstChild("Screen",true),"Old Television screen surface missing")
assert(loadingHand:FindFirstChildWhichIsA("BasePart",true),"Blood hand geometry missing")
cinematic.Parent=first

local loader=Instance.new("LocalScript")
loader.Name="SweanLoadingController"
loader.Source=__LOADING_SOURCE__
loader:SetAttribute("CinematicInitialLoading",true)
loader:SetAttribute("CinematicDuration",10)
loader:SetAttribute("TVAssetId",421148437)
loader:SetAttribute("TableAssetId",397786287)
loader:SetAttribute("MapLoadingOwnsGoodLuck",true)
loader.Parent=first

-- The old menu no longer exists in gameplay. Keep only its disabled controller stub;
-- MenuSceneTemplate above is retained exclusively for the winner presentation.
for _,child in ipairs(ui:GetChildren()) do
 if child~=controller then child:Destroy() end
end
ui:SetAttribute("LegacyMenuWidgetsPurged",true)
ui:SetAttribute("WinnerSceneOnly",true)
ui.Parent=starter

runtime:SetAttribute("MenuAssetId",0)
runtime:SetAttribute("MenuVersion",123)
runtime:SetAttribute("GameName","Suvivers [ALFA]")
runtime:SetAttribute("SurviversLogoAssetId",logoId or 0)

