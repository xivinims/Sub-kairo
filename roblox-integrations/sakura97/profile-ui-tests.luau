local realGame=game
local host=Instance.new("Folder",workspace) host.Name="ProfileUITest"
local gui=Instance.new("Folder",host) gui.Name="PlayerGui"
local attrs={SweanLoadingDone=true}
local p={PlayerGui=gui,UserId=991}
function p:GetAttribute(k) return attrs[k] end
function p:SetAttribute(k,v) attrs[k]=v end
function p:WaitForChild(k) return gui end
local char=Instance.new("Model",host) local root=Instance.new("Part",char) root.Name="HumanoidRootPart" root.Anchored=true
local humanoid=Instance.new("Humanoid",char) humanoid.Health=75
local target={Character=char,UserId=8344738123,Name="ch_ckz2n",DisplayName="Perfil Teste",Parent=host}
function target:GetAttribute(k) if k=="SessionJoinedAt" then return workspace:GetServerTimeNow()-100 end return nil end
local stats=Instance.new("Folder",host) stats.Name="leaderstats"
for name,value in pairs({XP=150,["Nível"]=3,Pontos=20}) do local v=Instance.new("IntValue",stats) v.Name=name v.Value=value end
function target:FindFirstChild(k) if k=="leaderstats" then return stats end end
local signals={} for _,name in ipairs({"InputBegan","InputEnded","TouchTapInWorld","RenderStepped"}) do signals[name]=Instance.new("BindableEvent",host) end
local function run()
 local game={}
 function game:GetService(name)
  if name=="Players" then return {LocalPlayer=p,GetPlayerFromCharacter=function(_,m) return m==char and target or nil end}
  elseif name=="UserInputService" then return {InputBegan=signals.InputBegan.Event,InputEnded=signals.InputEnded.Event,TouchTapInWorld=signals.TouchTapInWorld.Event}
  elseif name=="RunService" then return {RenderStepped=signals.RenderStepped.Event} end
  return realGame:GetService(name)
 end
 local workspace=setmetatable({Raycast=function() return {Instance=root} end},{__index=function(_,key) return realGame.Workspace[key] end})
__PROFILE_CLIENT_TEST_SOURCE__
end
local ok,result=xpcall(function()
 run()
 signals.TouchTapInWorld:Fire(Vector2.new(200,200),false) task.wait(.1)
 local card=assert(gui:FindFirstChild("SelectedPlayerProfile"),"Tap did not open profile in lobby")
 assert(card:GetAttribute("SourceAssetId")==124873348702500 and card:GetAttribute("TargetUserId")==target.UserId,"Wrong profile asset or selected user")
 local highlight=assert(gui:FindFirstChild("SelectedPlayerOutline"))
 assert(highlight.Enabled and highlight.Adornee==char and highlight.FillTransparency==1 and highlight.OutlineColor==Color3.new(1,1,1),"White player outline missing")
 signals.InputBegan:Fire({KeyCode=Enum.KeyCode.Escape},false) task.wait(.1)
 assert(not highlight.Enabled and not gui:FindFirstChild("SelectedPlayerProfile"),"Profile close left an outline or UI")
 signals.TouchTapInWorld:Fire(Vector2.new(200,200),true) task.wait(.1)
 assert(not gui:FindFirstChild("SelectedPlayerProfile"),"UI-consumed touch opened profile")
 signals.TouchTapInWorld:Fire(Vector2.new(200,200),false) task.wait(.1)
 target.Parent=nil signals.RenderStepped:Fire(.3) task.wait(.1)
 assert(not gui:FindFirstChild("SelectedPlayerProfile") and not highlight.Enabled,"Player departure did not clear profile")
 return {ok=true,lobbyTap=true,exactAsset=true,selectedIdentity=true,whiteOutline=true,closeCleanup=true,processedTouchIgnored=true,departureCleanup=true}
end,debug.traceback)
host:Destroy()
assert(ok,result)
return result
