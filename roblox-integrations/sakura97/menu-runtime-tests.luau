local realGame=game
local host=Instance.new("Folder",workspace) host.Name="MenuRemovedTest"
local pg=Instance.new("Folder",host)
local ui=game.StarterGui.TomiaszMenu:Clone() ui.Enabled=true ui.Parent=pg
local added=Instance.new("BindableEvent",host)
local attrs={SweanLoadingDone=true,InMenu=true}
local p={CharacterAdded=added.Event}
p.Character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15) p.Character.Parent=host
function p:GetAttribute(n) return attrs[n] end
function p:SetAttribute(n,v) attrs[n]=v end
local proxy={}
function proxy:GetService(name)
 if name=="Players" then return {LocalPlayer=p} end
 return realGame:GetService(name)
end
local previousCamera=workspace.CurrentCamera
local camera=Instance.new("Camera",host) workspace.CurrentCamera=camera
local function controller()
 local game=proxy
 local script={Parent=ui}
__MENU_TEST_SOURCE__
end
local ok,err=xpcall(function()
 controller()
 task.wait()
 assert(attrs.InMenu==false,"Removed menu left player InMenu")
 assert(ui.Enabled==false,"Removed main menu is still visible")
 assert(ui:GetAttribute("MenuRemoved")==true,"Removed menu marker missing")
 assert(not workspace:FindFirstChild("LocalMenuScene"),"Legacy local menu scene returned")
 assert(not game:GetService("SoundService"):FindFirstChild("SuviversMenuMusic"),"Legacy menu music returned")
end,debug.traceback)
workspace.CurrentCamera=previousCamera
host:Destroy()
assert(ok,err)
return {ok=true,noMainMenu=true,directLobby=true,noMenuMusic=true,noLegacyMenuScene=true}