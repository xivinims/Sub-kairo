-- Exercise the actual client controller with real UI/character instances and local event adapters.
local realGame=game
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local host=Instance.new("Folder") host.Name="VoidControllerTest" host.Parent=workspace
local characterEvent=Instance.new("BindableEvent")
local remoteEvent=Instance.new("BindableEvent")
local renderEvent=Instance.new("BindableEvent")
local description=Instance.new("HumanoidDescription")
local character=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
character.Name="TestPlayer" character.Parent=host
local guiHost=Instance.new("Folder") guiHost.Name="PlayerGui" guiHost.Parent=host
local attrs={VoidActive=true,MusicEnabled=false}
local fakePlayer={Character=character,CharacterAdded=characterEvent.Event}
function fakePlayer:GetAttribute(name) return attrs[name] end
function fakePlayer:WaitForChild(name) if name=="PlayerGui" then return guiHost end return nil end
local remote={OnClientEvent=remoteEvent.Event}
function remote:FireServer(action) assert(action=="return","Invalid recovery request") end
local proxyRS=setmetatable({}, {__index=function(_,key)
 if key=="WaitForChild" then return function(_,name) if name=="SweanVoidEvent" then return remote end return RS:WaitForChild(name) end end
 return RS[key]
end})
local proxyGame={}
function proxyGame:GetService(name)
 if name=="Players" then return {LocalPlayer=fakePlayer} end
 if name=="ReplicatedStorage" then return proxyRS end
 if name=="RunService" then return {RenderStepped=renderEvent.Event} end
 return realGame:GetService(name)
end
local heartbeat=realGame:GetService("RunService").Heartbeat:Connect(function(dt) renderEvent:Fire(dt) end)
local function runController()
 local game=proxyGame
__VOID_CLIENT_TEST_SOURCE__
end
local ok,result=xpcall(function()
 runController()
 remoteEvent:Fire("start") task.wait(.3)
 local screen=assert(guiHost:FindFirstChild("BeyondTheIsland"),"Death screen did not open")
 local bg=screen.Darkness local view=bg.PlayerSwimming local label=bg.DeathMessage local button=bg.Regenerate
 assert(view.ZIndex>label.ZIndex,"Avatar must cover message")
 assert(math.abs(view.Position.Y.Scale-.30)<.001 and math.abs(view.Size.Y.Scale-1.12)<.001,"Initial lower framing missing")
 assert(not button.Visible and not button.Active,"Regenerate exposed before messages")
 local messages={} local changed=label:GetPropertyChangedSignal("Text"):Connect(function() messages[#messages+1]=label.Text end)
 local deadline=os.clock()+25
 while screen.Parent and (screen:GetAttribute("Phase")~="regenerate" or not button.Active) and os.clock()<deadline do task.wait(.1) end
 changed:Disconnect()
 assert(screen:GetAttribute("Phase")=="regenerate" and button.Visible and button.Active,"Sequence did not reach regeneration")
 assert(button.Text=="Regenerar")
 assert(not label.Visible and not bg.SubtleAtmosphere.Visible,"Text/effects did not disappear")
 assert(math.abs(view.Position.Y.Scale-.16)<.001 and math.abs(view.Size.Y.Scale-.58)<.001,"Final framing missing")
 assert(#messages==4 and messages[1]=="cuidado" and messages[2]=="não pule mais no void" and messages[3]=="já pensou como é a vida pós morte?" and messages[4]=="Volte…","Wrong message order")
 assert(view:FindFirstChildOfClass("WorldModel"):FindFirstChild("TestPlayer"),"Player avatar missing")
 remoteEvent:Fire("finish") task.wait(.7)
 assert(not guiHost:FindFirstChild("BeyondTheIsland"),"Recovery left screen behind")
 remoteEvent:Fire("start") task.wait(.2) remoteEvent:Fire("start") task.wait(.2)
 assert(#guiHost:GetChildren()==1,"Repeated start duplicated scene")
 characterEvent:Fire(character) task.wait(.2)
 assert(#guiHost:GetChildren()==0,"Respawn left death UI behind")
 return {ok=true,messageOrder=true,avatarAboveText=true,regenerateAfterTransition=true,effectsFade=true,recoveryCleanup=true,repeatedStartSafe=true}
end,debug.traceback)
characterEvent:Fire(character) task.wait()
heartbeat:Disconnect() characterEvent:Destroy() remoteEvent:Destroy() renderEvent:Destroy() host:Destroy() description:Destroy()
assert(ok,result)
return result
