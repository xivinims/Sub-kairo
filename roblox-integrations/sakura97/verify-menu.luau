local ui=assert(game.StarterGui:FindFirstChild("TomiaszMenu"),"Menu missing")
assert(ui:GetAttribute("SourceAssetId")==84828163072141)
assert(ui.ResetOnSpawn==false and ui.Enabled)
local required={ui.MenuPrincipal.Play,ui.MenuPrincipal.Ajustes,ui.MenuPrincipal.Creditos,ui.Escenarios.MenuCreditos.Close,ui.Escenarios.MenuAjustes.Close,ui.Escenarios.MenuAjustes.AjustesFrame.QualityToggle,ui.ReturnToMenu}
for _,b in ipairs(required) do assert(b:IsA("GuiButton") and b.Active,"Inactive menu button") end
for _,d in ipairs(ui:GetDescendants()) do
 if d:IsA("GuiObject") then assert(d.Size.X.Scale>=0 and d.Size.Y.Scale>=0,"Negative GUI dimensions") end
end
local config=assert(game.ReplicatedStorage:FindFirstChild("SweanMenuConfig"))
for _,name in ipairs({"MainCamera","SettingsCamera","CreditsCamera"}) do assert(typeof(config:GetAttribute(name))=="CFrame") end
assert(ui:FindFirstChild("MenuController"))
assert(game.ReplicatedFirst:FindFirstChild("SweanLoadingController"))
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
return {ok=true,menuAsset=84828163072141,buttons=#required,loading=true,compiledScripts=compiled}
