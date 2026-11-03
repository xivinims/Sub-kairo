local ui=assert(game.StarterGui:FindFirstChild("TomiaszMenu"),"Menu missing")
assert(ui:GetAttribute("SourceAssetId")==0)
assert(ui.ResetOnSpawn==false and ui.Enabled)
local required={ui.MenuPrincipal.Play,ui.MenuPrincipal.Ajustes,ui.CreditsButton,ui.Escenarios.MenuCreditos.Close,ui.Escenarios.MenuAjustes.Close,ui.Escenarios.MenuAjustes.AjustesFrame.Controls.QualityToggle,ui.ReturnToMenu}
for _,b in ipairs(required) do assert(b:IsA("GuiButton") and b.Active,"Inactive menu button") end
local config=assert(game.ReplicatedStorage:FindFirstChild("SweanMenuConfig"))
assert(config:GetAttribute("Version")==5)
assert(config:GetAttribute("GameName")=="Survivers")
assert(config:GetAttribute("MenuSceneAssetId")==13327565335)
assert(game.ReplicatedStorage:FindFirstChild("MenuSceneTemplate"),"Menu scene template missing")
assert(ui:FindFirstChild("MenuController"))
local loadingController=assert(game.ReplicatedFirst:FindFirstChild("SweanLoadingController"))
assert(loadingController:GetAttribute("LogoOnlyLoading")==true,"Loading screen must be logo-only")
assert(ui.MenuPrincipal:FindFirstChild("LeftPanel"))
assert(ui.MenuPrincipal:FindFirstChild("Logo"))
assert(ui.MenuPrincipal:FindFirstChild("GameName") and ui.MenuPrincipal.GameName.Text=="SURVIVERS")
local logoId=config:GetAttribute("LogoAssetId") or 0
if logoId>0 then assert(ui.MenuPrincipal.Logo.Image=="rbxassetid://"..tostring(logoId) and ui.MenuPrincipal.Logo.Visible)
else assert(ui.MenuPrincipal.GameName.Visible) end
assert(ui.Sonidos.Click.SoundId=="rbxassetid://12221967")
assert(ui.Escenarios.MenuCreditos.CreditosFrame.TextCreditos.Text:find("ch_ckz2n",1,true))
local settingsCount=0
for _,b in ipairs(ui.Escenarios.MenuAjustes.AjustesFrame.Controls:GetChildren()) do if b:IsA("GuiButton") then settingsCount+=1 end end
assert(settingsCount==8,"Menu settings missing")
return {ok=true,menuAsset=0,buttons=#required,settings=settingsCount,loading=true,customMenu=true,logoId=logoId}