assert(game.GameId==9419478735 and game.PlaceId==79738710219521)
local RS=game:GetService("ReplicatedStorage")
assert(RS.SweanRuntime:GetAttribute("Version")==112,"Publish compact map first")
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
local title=Instance.new("TextLabel") title.Name="IslandTitle" title.Text="Swean Island"
title.BackgroundTransparency=1 title.TextColor3=Color3.new(1,1,1) title.Font=Enum.Font.GothamBold title.TextSize=24 title.ZIndex=3 title.Parent=main
local credits=ui.Escenarios.MenuCreditos
credits.Tittle.TittleText.Text="CRÉDITOS"
credits.CreditosFrame.TextCreditos.Text="Swean Island\n\nMenu original: Tomiasz\nSkinnedGrass: xander22\n\nObrigado por jogar!"
credits.CreditosFrame.TextCreditos.ZIndex=4
local settings=ui.Escenarios.MenuAjustes
settings.Tittle.TittleText.Text="AJUSTES"
local scroll=Instance.new("ScrollingFrame") scroll.Name="Controls" scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0
scroll.Position=UDim2.fromScale(.04,.04) scroll.Size=UDim2.fromScale(.92,.92) scroll.CanvasSize=UDim2.fromOffset(0,0)
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.ScrollBarThickness=4 scroll.ZIndex=4 scroll.Parent=settings.AjustesFrame
local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,8) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=scroll
for i,name in ipairs({"QualityToggle","WindToggle","GrassToggle","LeavesToggle","NametagsToggle","SoundToggle"}) do
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
  b.AutoButtonColor=false b.BackgroundColor3=Color3.fromRGB(29,38,31) b.BackgroundTransparency=.08
  b.TextColor3=Color3.fromRGB(238,242,230) b.Font=Enum.Font.GothamMedium
  local corner=b:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner",b) corner.CornerRadius=UDim.new(0,9)
  local stroke=b:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke",b) stroke.Color=Color3.fromRGB(126,149,113) stroke.Transparency=.55 stroke.Thickness=1
 end
end
local controller=Instance.new("LocalScript") controller.Name="MenuController" controller.Source=__MENU_SOURCE__ controller.Parent=ui
local config=Instance.new("Folder") config.Name="SweanMenuConfig"
local runtime=RS.SweanRuntime
local base=Vector3.new(runtime:GetAttribute("TreeGroundX"),runtime:GetAttribute("TreeGroundY"),runtime:GetAttribute("TreeGroundZ"))
local target=base+Vector3.new(0,24,0)
config:SetAttribute("MainCamera",CFrame.lookAt(base+Vector3.new(80,48,100),target))
config:SetAttribute("SettingsCamera",CFrame.lookAt(base+Vector3.new(90,40,70),target))
config:SetAttribute("CreditsCamera",CFrame.lookAt(base+Vector3.new(65,54,95),target))
config:SetAttribute("Version",2)
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
runtime:SetAttribute("MenuVersion",2)
asset:Destroy()
