local originalEffects={} for _,v in ipairs(game.Lighting:GetChildren()) do if v:IsA("PostEffect") then originalEffects[v]=v.Enabled end end
local originalShadows=game.Lighting.GlobalShadows
local realGame=game local RS=game:GetService("ReplicatedStorage")
local host=Instance.new("Folder",workspace) host.Name="MenuInterfaceTest"
local pg=Instance.new("Folder",host)
local ui=game.StarterGui.TomiaszMenu:Clone() ui:SetAttribute("HorrorDelaySeconds",.05) ui.Parent=pg
local added=Instance.new("BindableEvent",host) local attributeEvents={}
local p={attrs={SweanLoadingDone=true},CharacterAdded=added.Event}
p.Character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15) p.Character.Parent=host
local stats=Instance.new("Folder",host) stats.Name="leaderstats"
for _,name in ipairs({"XP","Nível","Pontos"}) do local v=Instance.new("IntValue",stats) v.Name=name v.Value=name=="Nível" and 2 or name=="XP" and 65 or 27 end
function p:GetAttribute(n) return self.attrs[n] end
function p:SetAttribute(n,v) if self.attrs[n]==v then return end self.attrs[n]=v if attributeEvents[n] then attributeEvents[n]:Fire() end end
function p:GetAttributeChangedSignal(n) if not attributeEvents[n] then attributeEvents[n]=Instance.new("BindableEvent",host) end return attributeEvents[n].Event end
function p:FindFirstChild(n) return n=="leaderstats" and stats or nil end
function p:WaitForChild(n) if n=="PlayerGui" then return pg elseif n=="leaderstats" then return stats end return nil end
local settingsModule=RS.Survival.SettingsPanel:Clone() settingsModule.Parent=host
local net=setmetatable({WaitForChild=function(_,name) if name=="SettingsPanel" then return settingsModule end return RS.Survival:WaitForChild(name) end},{__index=function(_,n) local v=RS.Survival[n] if type(v)=="function" then return function(_,...) return v(RS.Survival,...) end end return v end})
local fakeRS=setmetatable({Survival=net,WaitForChild=function(_,n) if n=="Survival" then return net end return RS:WaitForChild(n) end},{__index=function(_,n) return RS[n] end})
local bound={}
local proxy={}
function proxy:GetService(name)
 if name=="Players" then return {LocalPlayer=p}
 elseif name=="ReplicatedStorage" then return fakeRS
 elseif name=="RunService" then return {BindToRenderStep=function(_,name,_,fn) bound[name]=fn end,UnbindFromRenderStep=function(_,name) bound[name]=nil end} end
 return realGame:GetService(name)
end
local originalSounds={} for _,v in ipairs(game:GetService("SoundService"):GetChildren()) do originalSounds[v]=true end
local previousCamera=workspace.CurrentCamera local camera=Instance.new("Camera",host) workspace.CurrentCamera=camera
local api
local function controller()
 local game=proxy local script={Parent=ui} local TEST_VIEWPORT=Vector2.new(812,375)
__MENU_TEST_SOURCE__
 return {open=open,close=close,show=show,settings=settingsControl,layout=layout}
end
local ok,err=xpcall(function()
 api=controller() task.wait()
 assert(ui.MenuPrincipal.Visible,"Main menu did not open")
 assert(not ui.MenuPrincipal.Play:FindFirstChild("Preview"),"Large menu preview must not cover the background")
 assert(not ui.MenuPrincipal:FindFirstChild("Shop"),"Shop button object returned")
 assert(not ui.MenuPrincipal:FindFirstChild("Inventory"),"Inventory button object returned")
 assert(not ui.Escenarios:FindFirstChild("MenuShop"),"Shop modal returned")
 assert(not ui.Escenarios:FindFirstChild("MenuInventory"),"Inventory modal returned")
 assert(not ui:FindFirstChild("ReturnToMenu"),"Obsolete return-to-menu object returned")
 assert(ui.MenuPrincipal.Play.Position.X.Scale==0 and ui.MenuPrincipal.Ajustes.Position.X.Scale==0 and ui.MenuPrincipal.Updates.Position.X.Scale==0,"Main navigation did not move to the left")
 assert(ui.MenuPrincipal.Play.Position.X.Offset>0 and ui.MenuPrincipal.Play.TextXAlignment==Enum.TextXAlignment.Left,"Left navigation alignment is incorrect")
 assert(not ui.MenuPrincipal.Play.UIStroke.Enabled and not ui.MenuPrincipal.Ajustes.UIStroke.Enabled,"Menu buttons must stay clean/text-only")
 assert(ui.MenuPrincipal.Play.BackgroundTransparency==1 and ui.MenuPrincipal.Play.UIStroke.Thickness<=1.5,"Main buttons are not clean reference-style outlines")
 assert(ui:GetAttribute("MenuIntroAnimated")==true,"Logo-to-top intro animation was not armed")
 local closeAvatar=workspace:FindFirstChild("LocalMenuAvatar")
 assert(closeAvatar and closeAvatar:GetAttribute("ClosePortrait")==true,"Menu avatar is not a close portrait")
 assert(ui:GetAttribute("HorrorMenuEffect")==true,"Menu light/avatar horror beat missing")
 local revealDeadline=os.clock()+3.5
 while ui:GetAttribute("MenuJasonVisible")~=true and os.clock()<revealDeadline do task.wait(.05) end
 local horrorJason=workspace:FindFirstChild("LocalMenuJason")
 assert(horrorJason and horrorJason:GetAttribute("MenuHorrorJason")==true,"Jason was not revealed after menu flicker")
 assert(ui:GetAttribute("HorrorJasonReveal")==true and ui:GetAttribute("MenuJasonVisible")==true,"Jason reveal state missing")
 assert(closeAvatar:GetAttribute("HorrorVisible")==false,"Player avatar did not disappear before Jason reveal")
 assert(game.Lighting:FindFirstChild("SuviversMenuHorrorDark"),"Menu background did not darken during horror beat")
 assert(ui.MenuPrincipal.Profile.XPBar.Value.Text:find("NÍVEL 2",1,true),"Level header missing")
 assert(ui.MenuPrincipal.Play.Size.X.Offset>=168 and ui.MenuPrincipal.Play.Size.Y.Offset>=28,"Centered phone menu target too small")
 assert(ui.MenuPrincipal.Play.Position.Y.Scale<ui.MenuPrincipal.Ajustes.Position.Y.Scale and ui.MenuPrincipal.Ajustes.Position.Y.Scale<ui.MenuPrincipal.Updates.Position.Y.Scale,"Main menu is not a clean vertical stack")
 api.show("settings") api.settings.select("audio")
 assert(api.settings.frame:GetAttribute("SourceAssetId")==93583640955196,"Exact settings asset missing")
 assert(api.settings.frame:FindFirstChild("EffectsVolume",true),"Functional audio slider missing")
 api.settings.select("visual")
 assert(api.settings.frame:FindFirstChild("CameraFOV",true) and api.settings.frame:FindFirstChild("MapShadows",true),"Functional visual controls missing")
 assert(p:GetAttribute("CameraFOV")==48,"Camera FOV default must match reference")
 assert(p:GetAttribute("VisualSaturation")==-.65,"Saturation default must match reference")
 assert(p:GetAttribute("VisualContrast")==0,"Contrast default must match reference")
 assert(p:GetAttribute("VisualExposure")==1.5,"Exposure default must match reference")
 assert(p:GetAttribute("VisualTime")==8.25,"Time default must be 08:15")
 assert(p:GetAttribute("MapShadows")==true,"Shadows must default on")
 api.settings.setValue("VisualSaturation",-.62) assert(p:GetAttribute("VisualSaturation")==-.6,"Saturation step rounding failed")
 api.settings.setValue("VisualContrast",.17) assert(p:GetAttribute("VisualContrast")==.15,"Contrast step rounding failed")
 api.settings.setValue("VisualExposure",1.46) assert(p:GetAttribute("VisualExposure")==1.5,"Exposure step rounding failed")
 api.settings.setValue("VisualTime",8.22) assert(p:GetAttribute("VisualTime")==8.25,"Time quarter-hour rounding failed")
 api.settings.setValue("CameraFOV",500) assert(p:GetAttribute("CameraFOV")==100,"FOV bounds failed")
 api.settings.setValue("LowGraphics",true) task.wait()
 assert(not game.Lighting.SuviversMenuBloom.Enabled,"Lightweight mode failed to disable menu bloom")
 api.settings.select("gameplay") assert(api.settings.frame:FindFirstChild("ControlScale",true) and api.settings.frame:FindFirstChild("AFK",true),"Gameplay settings missing")
 assert(ui.Sonidos.PlayClick.SoundId=="rbxassetid://87437544236708","Requested play click sound missing")
 assert(ui.Sonidos.LightFlicker.SoundId=="rbxassetid://137413271824429","Requested light flicker sound missing")
 api.close() assert(not p:GetAttribute("InMenu") and not workspace:FindFirstChild("LocalMenuScene"),"Menu did not release private scene")
 assert(not game.Lighting:FindFirstChild("SuviversMenuGrade"),"Menu grade leaked into gameplay")
end,debug.traceback)
if api then api.close() end
local localScene=workspace:FindFirstChild("LocalMenuScene") if localScene then localScene:Destroy() end
local avatar=workspace:FindFirstChild("LocalMenuAvatar") if avatar then avatar:Destroy() end
workspace.CurrentCamera=previousCamera host:Destroy()
for _,v in ipairs(game:GetService("SoundService"):GetChildren()) do if not originalSounds[v] then v:Destroy() end end
for effect,enabled in pairs(originalEffects) do if effect.Parent then effect.Enabled=enabled end end
game.Lighting.GlobalShadows=originalShadows
assert(ok,err)
return {ok=true,leftReferenceMenu=true,logoIntro=true,horrorAvatarCloseup=true,jasonAfterFlicker=true,twelveSecondHorrorBeat=true,phoneLayout=true,levelProgress=true,effectsOnlyAudio=true,referenceVisualControls=true,decimalVisualSliders=true,time0815=true,reflectionToggle=true,visualToggles=true,gameplaySettings=true,menuCleanup=true,shopInventoryObjectsRemoved=true,noReturnToMenuObject=true,noResetButton=true,requestedMenuSounds=true}
