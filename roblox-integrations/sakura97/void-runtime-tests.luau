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
local attrs={VoidActive=true,MusicEnabled=false,InMenu=false,RoundStatus="eliminated",InRound=false}
local fakePlayer={Character=character,CharacterAdded=characterEvent.Event}
function fakePlayer:GetAttribute(name) return attrs[name] end
function fakePlayer:WaitForChild(name) if name=="PlayerGui" then return guiHost end return nil end
local remote={OnClientEvent=remoteEvent.Event}
local returns=0
function remote:FireServer(action) assert(action=="return","Invalid recovery request") returns+=1 end
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
 attrs.InMenu=true
 remoteEvent:Fire("start","Jason","spectate") task.wait(.2)
 assert(not guiHost:FindFirstChild("BeyondTheIsland"),"Death screen opened while player was in menu")
 attrs.InMenu=false attrs.RoundStatus="lobby"
 remoteEvent:Fire("start","Jason","spectate") task.wait(.2)
 assert(not guiHost:FindFirstChild("BeyondTheIsland"),"Death screen opened without elimination")
 attrs.RoundStatus="eliminated"
 remoteEvent:Fire("start","Figure","spectate") task.wait(.3)
 local spectateScreen=assert(guiHost:FindFirstChild("BeyondTheIsland"))
 local figureMessages={} local fc=spectateScreen.Darkness.DeathMessage:GetPropertyChangedSignal("Text"):Connect(function() table.insert(figureMessages,spectateScreen.Darkness.DeathMessage.Text) end)
 local spectateDeadline=os.clock()+25
 local previousReturns=returns
 while returns==previousReturns and os.clock()<spectateDeadline do task.wait(.1) end
 fc:Disconnect()
 assert(returns==previousReturns+1,"Spectator transition was not automatic")
 assert(not spectateScreen.Darkness.Regenerate.Visible,"Eliminated player saw respawn button")
 assert(#figureMessages>=1 and figureMessages[1]=="ele ouve seus passos","Wrong Figure messages")
 remoteEvent:Fire("finish") task.wait(.7)
 attrs.RoundStatus="eliminated" attrs.InMenu=false
 remoteEvent:Fire("start","Figure","spectate") task.wait(.2) remoteEvent:Fire("start","Figure","spectate") task.wait(.2)
 assert(#guiHost:GetChildren()==1,"Repeated real-death start duplicated scene")
 characterEvent:Fire(character) task.wait(.2)
 assert(#guiHost:GetChildren()==0,"Respawn left death UI behind")
 return {ok=true,menuSuppression=true,nonDeathSuppression=true,spectatorTransition=true,figureMessages=true,recoveryCleanup=true,repeatedStartSafe=true}
end,debug.traceback)
characterEvent:Fire(character) task.wait()
heartbeat:Disconnect() characterEvent:Destroy() remoteEvent:Destroy() renderEvent:Destroy() host:Destroy() description:Destroy()
assert(ok,result)
return result
