assert(game.GameId==9419478735 and game.PlaceId==79738710219521)
local RS=game:GetService("ReplicatedStorage")
assert(RS.SweanRuntime:GetAttribute("Version")==115,"Publish compact map first")
local starter=game:GetService("StarterGui")
local first=game:GetService("ReplicatedFirst")
local asset=game:GetService("AssetService"):LoadAssetAsync(84828163072141)
local original=asset:FindFirstChildWhichIsA("ScreenGui",true)
assert(original and original.Name=="MenuPrincipal","Tomiasz menu unavailable")
local ui=original:Clone()
ui.Name="TomiaszMenu" ui.ResetOnSpawn=false ui.IgnoreGuiInset=false ui.DisplayOrder=20
ui:SetAttribute("SourceAssetId",84828163072141)
for _,d in ipairs(ui:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then d:Destroy()
 elseif d:IsA("GuiObject") then
  d.Visible=false
  if d.Size.X.Scale<0 or d.Size.Y.Scale<0 then
   d.Size=UDim2.new(math.abs(d.Size.X.Scale),math.abs(d.Size.X.Offset),math.abs(d.Size.Y.Scale),math.abs(d.Size.Y.Offset))
  end
  if d:IsA("TextLabel") or d:IsA("TextButton") then
   d.TextWrapped=true d.TextScaled=true
   local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=12 limit.MaxTextSize=24 limit.Parent=d
  end
 end
end
local main=ui.MenuPrincipal
main.Frame:Destroy()
main.Play.Text="Jogar" main.Ajustes.Text="Ajustes" main.Creditos.Text="Créditos"
main.Logo.Image="rbxassetid://"..tostring(__SURVIVERS_LOGO_ID__)
main.Logo.ImageColor3=Color3.new(1,1,1) main.Logo.ImageTransparency=0 main.Logo.BackgroundTransparency=1
main.Creditos.Name="CreditsButton"
main.CreditsButton.Parent=ui
ui.CreditsButton.Text="Créditos" ui.CreditsButton:SetAttribute("AccessibleLabel","Créditos")
local leftPanel=Instance.new("Frame")
leftPanel.Name="LeftPanel" leftPanel.BackgroundColor3=Color3.fromRGB(8,7,8) leftPanel.BackgroundTransparency=.32
leftPanel.BorderSizePixel=0 leftPanel.ZIndex=1 leftPanel.Parent=main
local panelCorner=Instance.new("UICorner",leftPanel) panelCorner.CornerRadius=UDim.new(0,22)
local panelGradient=Instance.new("UIGradient",leftPanel)
panelGradient.Rotation=90 panelGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,.62)})
local gameName=Instance.new("TextLabel")
gameName.Name="GameName" gameName.BackgroundTransparency=1 gameName.Text="SURVIVERS"
gameName.Font=Enum.Font.GothamBlack gameName.TextColor3=Color3.fromRGB(232,232,235)
gameName.TextScaled=true gameName.TextXAlignment=Enum.TextXAlignment.Left gameName.ZIndex=3 gameName.Parent=main
local sounds=ui:FindFirstChild("Sonidos")
if sounds then sounds:Destroy() end
sounds=Instance.new("Folder") sounds.Name="Sonidos" sounds.Parent=ui
local click=RS.XNMedia.MenuClick:Clone() click.Name="Click" click.Parent=sounds
local credits=ui.Escenarios.MenuCreditos
credits.Tittle.TittleText.Text="CRÉDITOS"
credits.CreditosFrame.TextCreditos.Text="Criado por\n\nch_ckz2n\n\nObrigado por jogar!"
credits.CreditosFrame.TextCreditos.ZIndex=4
local settings=ui.Escenarios.MenuAjustes
settings.Tittle.TittleText.Text="AJUSTES"
for _,scene in ipairs({settings,credits}) do
 scene.Close:Destroy()
 local close=Instance.new("TextButton") close.Name="Close" close.Text="×" close.Active=true close.Visible=false close.Parent=scene
 close.TextSize=26 close.TextScaled=false close.BorderSizePixel=0
end
local scroll=Instance.new("ScrollingFrame") scroll.Name="Controls" scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0
scroll.Position=UDim2.fromScale(.04,.04) scroll.Size=UDim2.fromScale(.92,.92) scroll.CanvasSize=UDim2.fromOffset(0,0)
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.ScrollBarThickness=4 scroll.ZIndex=4 scroll.Parent=settings.AjustesFrame
local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,8) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=scroll
for i,name in ipairs({"QualityToggle","WindToggle","GrassToggle","LeavesToggle","NametagsToggle","SoundToggle","MusicToggle","FriendsToggle"}) do
 local button=main.Play:Clone() button.Name=name button.Text=name button.LayoutOrder=i
 button.Position=UDim2.fromScale(0,0) button.Size=UDim2.new(1,-8,0,44) button.ZIndex=5 button.Parent=scroll
end
local back=main.Play:Clone() back.Name="ReturnToMenu" back.Text="Menu" back.Visible=false
back.AnchorPoint=Vector2.new(0,0) back.Position=UDim2.new(0,16,0,12) back.Size=UDim2.fromOffset(94,44) back.ZIndex=8 back.Parent=ui
local transition=ui.FrameDeTransicion
transition.Size=UDim2.fromScale(1,1) transition.Position=UDim2.fromScale(0,0)
transition.BackgroundTransparency=1 transition.ZIndex=100 transition.Visible=false
for _,b in ipairs(ui:GetDescendants()) do
 if b:IsA("TextButton") then
  b.AutoButtonColor=false b.BackgroundColor3=Color3.fromRGB(24,24,27) b.BackgroundTransparency=.28
  b.TextColor3=Color3.fromRGB(235,235,238) b.Font=Enum.Font.GothamMedium
  local corner=b:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner",b) corner.CornerRadius=UDim.new(0,14)
  local stroke=b:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke",b) stroke.Color=Color3.fromRGB(155,155,162) stroke.Transparency=.55 stroke.Thickness=1 stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 end
end
for _,panel in ipairs({settings.AjustesFrame,credits.CreditosFrame}) do
 panel.BackgroundColor3=Color3.fromRGB(20,20,23) panel.BackgroundTransparency=.22 panel.BorderSizePixel=0
 local corner=panel:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner",panel) corner.CornerRadius=UDim.new(0,18)
end
local controller=Instance.new("LocalScript") controller.Name="MenuController" controller.Source=__MENU_SOURCE__ controller.Parent=ui
local config=Instance.new("Folder") config.Name="SweanMenuConfig"
local runtime=RS.SweanRuntime
local menuOrigin=Vector3.new(10000,2500,10000)
config:SetAttribute("MenuOrigin",menuOrigin)
config:SetAttribute("MainCamera",CFrame.new(menuOrigin))
config:SetAttribute("SettingsCamera",CFrame.new(menuOrigin))
config:SetAttribute("CreditsCamera",CFrame.new(menuOrigin))
config:SetAttribute("Version",4)
config:SetAttribute("GameName","Survivers")
config:SetAttribute("MenuSceneAssetId",13327565335)
config:SetAttribute("LogoAssetId",__SURVIVERS_LOGO_ID__)
config:SetAttribute("SourceAssetId",84828163072141)
for _,e in ipairs(game:GetService("Lighting"):GetChildren()) do
 if e:IsA("PostEffect") and e:GetAttribute("SourceAssetId")==86563808574363 then e:SetAttribute("OriginalEnabled",e.Enabled) end
end
local loader=Instance.new("LocalScript") loader.Name="SweanLoadingController" loader.Source=__LOADING_SOURCE__
-- Replace only this feature, retaining the already verified map.
for _,pair in ipairs({{starter,"TomiaszMenu"},{first,"SweanLoadingController"},{RS,"SweanMenuConfig"}}) do
 local old=pair[1]:FindFirstChild(pair[2]) if old then old:Destroy() end
end
config.Parent=RS ui.Parent=starter loader.Parent=first
runtime:SetAttribute("MenuAssetId",84828163072141)
runtime:SetAttribute("MenuVersion",4)
runtime:SetAttribute("GameName","Survivers")
runtime:SetAttribute("SurviversLogoAssetId",__SURVIVERS_LOGO_ID__)
asset:Destroy()
