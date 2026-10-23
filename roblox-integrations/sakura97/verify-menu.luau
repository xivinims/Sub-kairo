local ui=assert(game.StarterGui:FindFirstChild("TomiaszMenu"),"Menu missing")
assert(ui:GetAttribute("SourceAssetId")==84828163072141)
assert(ui.ResetOnSpawn==false and ui.Enabled)
local required={ui.MenuPrincipal.Play,ui.MenuPrincipal.Ajustes,ui.CreditsButton,ui.Escenarios.MenuCreditos.Close,ui.Escenarios.MenuAjustes.Close,ui.Escenarios.MenuAjustes.AjustesFrame.Controls.QualityToggle,ui.ReturnToMenu}
for _,b in ipairs(required) do assert(b:IsA("GuiButton") and b.Active,"Inactive menu button") end
for _,d in ipairs(ui:GetDescendants()) do
 if d:IsA("GuiObject") then assert(d.Size.X.Scale>=0 and d.Size.Y.Scale>=0,"Negative GUI dimensions") end
end
local config=assert(game.ReplicatedStorage:FindFirstChild("SweanMenuConfig"))
for _,name in ipairs({"MainCamera","SettingsCamera","CreditsCamera"}) do assert(typeof(config:GetAttribute(name))=="CFrame") end
assert(ui:FindFirstChild("MenuController"))
assert(game.ReplicatedFirst:FindFirstChild("SweanLoadingController"))
assert(not ui.MenuPrincipal:FindFirstChild("Frame"),"Menu background panel remains")
assert(config:GetAttribute("Version")==3)
assert(not ui.MenuPrincipal:FindFirstChild("Creditos"))
assert(not ui.MenuPrincipal:FindFirstChild("IslandTitle"))
assert(ui.MenuPrincipal.Logo.Image=="rbxassetid://89648072626653")
assert(ui.Sonidos.Click.SoundId=="rbxassetid://12221967")
assert(ui.Escenarios.MenuCreditos.CreditosFrame.TextCreditos.Text:find("ch_ckz2n",1,true))
local settingsCount=0
for _,b in ipairs(ui.Escenarios.MenuAjustes.AjustesFrame.Controls:GetChildren()) do
 if b:IsA("GuiButton") then settingsCount+=1 end
end
assert(settingsCount==8,"Menu settings missing")
local compiled=0
-- Parse stored LocalScript sources when the execution context exposes loadstring.
for _,root in ipairs({game.StarterGui,game.StarterPlayer.StarterPlayerScripts,game.ReplicatedFirst}) do
 for _,d in ipairs(root:GetDescendants()) do
  if d:IsA("LocalScript") and loadstring then
   local ok,fn,err=pcall(loadstring,d.Source)
   if ok then assert(fn,"Invalid script "..d.Name..": "..tostring(err)) compiled+=1 end
  end
 end
end
return {ok=true,menuAsset=84828163072141,buttons=#required,settings=settingsCount,loading=true,compiledScripts=compiled}
