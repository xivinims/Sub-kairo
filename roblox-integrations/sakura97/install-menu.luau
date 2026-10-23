assert(game.GameId==9419478735 and game.PlaceId==79738710219521)
local RS=game:GetService("ReplicatedStorage")
assert(RS.SweanRuntime:GetAttribute("Version")==111,"Publish compact map first")
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
main.Play.Text="Jogar" main.Ajustes.Text="Ajustes" main.Creditos.Text="Créditos"
local title=Instance.new("TextLabel") title.Name="IslandTitle" title.Text="Swean Island"
title.BackgroundTransparency=1 title.TextColor3=Color3.new(1,1,1) title.Font=Enum.Font.GothamBold title.TextSize=24 title.ZIndex=3 title.Parent=main
local credits=ui.Escenarios.MenuCreditos
credits.Tittle.TittleText.Text="CRÉDITOS"
credits.CreditosFrame.TextCreditos.Text="Swean Island\n\nMenu original: Tomiasz\nSkinnedGrass: xander22\n\nObrigado por jogar!"
credits.CreditosFrame.TextCreditos.ZIndex=4
local settings=ui.Escenarios.MenuAjustes
settings.Tittle.TittleText.Text="AJUSTES"
local quality=main.Play:Clone() quality.Name="QualityToggle" quality.Text="Gráficos: leve"
quality.Position=UDim2.new(.05,0,.12,0) quality.Size=UDim2.new(.9,0,0,48) quality.ZIndex=4 quality.Parent=settings.AjustesFrame
local info=Instance.new("TextLabel") info.Name="QualityInfo" info.Text="O modo leve desativa desfoque e raios de sol. A grama continua limitada para poupar memória."
info.BackgroundTransparency=1 info.TextColor3=Color3.new(1,1,1) info.Font=Enum.Font.Gotham info.TextSize=16 info.TextWrapped=true
info.Position=UDim2.new(.05,0,.12,64) info.Size=UDim2.new(.9,0,.72,-64) info.ZIndex=4 info.Parent=settings.AjustesFrame
local back=main.Play:Clone() back.Name="ReturnToMenu" back.Text="Menu" back.Visible=false
back.AnchorPoint=Vector2.new(1,0) back.Position=UDim2.new(1,-16,0,12) back.Size=UDim2.fromOffset(94,44) back.ZIndex=8 back.Parent=ui
local transition=ui.FrameDeTransicion
transition.Size=UDim2.fromScale(1,1) transition.Position=UDim2.fromScale(0,0)
transition.BackgroundTransparency=1 transition.ZIndex=100 transition.Visible=false
local controller=Instance.new("LocalScript") controller.Name="MenuController" controller.Source=__MENU_SOURCE__ controller.Parent=ui
local config=Instance.new("Folder") config.Name="SweanMenuConfig"
local runtime=RS.SweanRuntime
local base=Vector3.new(runtime:GetAttribute("TreeGroundX"),runtime:GetAttribute("TreeGroundY"),runtime:GetAttribute("TreeGroundZ"))
local target=base+Vector3.new(0,24,0)
config:SetAttribute("MainCamera",CFrame.lookAt(base+Vector3.new(80,48,100),target))
config:SetAttribute("SettingsCamera",CFrame.lookAt(base+Vector3.new(90,40,70),target))
config:SetAttribute("CreditsCamera",CFrame.lookAt(base+Vector3.new(65,54,95),target))
config:SetAttribute("Version",1)
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
runtime:SetAttribute("MenuVersion",1)
asset:Destroy()
