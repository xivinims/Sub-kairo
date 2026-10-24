local realGame=game local RS=game:GetService("ReplicatedStorage")
local host=Instance.new("Folder",workspace) host.Name="SurvivalClientTest"
local render=Instance.new("BindableEvent",host) local input=Instance.new("BindableEvent",host) local ended=Instance.new("BindableEvent",host) local update=Instance.new("BindableEvent",host)
local attrs={InRound=true,SweanLoadingDone=true,HasMedkit=true,HasBoost=true,RoundStatus="alive"}
local p={attrs=attrs,Character=nil,UserId=991,DisplayName="Tester"}
local description=Instance.new("HumanoidDescription")
local char=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) char.Parent=host p.Character=char
local introJason=game.ServerStorage.SurvivalAssets.Killers.Jason:Clone() introJason.Name="IntroJasonTest" introJason.Parent=host
local guiHost=Instance.new("Folder",host) guiHost.Name="PlayerGui"
function p:GetAttribute(n) return attrs[n] end
function p:WaitForChild(n) if n=="PlayerGui" then return guiHost end end
function p:FindFirstChild() return nil end
function p:FindFirstChildWhichIsA() return nil end
local survivor={Character=char,UserId=992,DisplayName="Sobrevivente",GetAttribute=function(_,n) return n=="InRound" end}
local fakePlayers={LocalPlayer=p,GetPlayers=function() return {p,survivor} end,GetPlayerByUserId=function(_,id) if id==991 then return p elseif id==992 then return survivor end end}
local requests={}
local fakeAction={FireServer=function(_,action) table.insert(requests,action) end}
local fakeNet=setmetatable({Action=fakeAction,Update={OnClientEvent=update.Event},Config=RS.Survival.Config},{__index=function(_,k)
 local v=RS.Survival[k] if type(v)=="function" then return function(_,...) return v(RS.Survival,...) end end return v
end})
local fakeRS={XNMedia=RS.XNMedia,WaitForChild=function(_,n) if n=="Survival" then return fakeNet end return RS:WaitForChild(n) end}
local proxy={}
function proxy:GetService(n)
 if n=="Players" then return fakePlayers elseif n=="ReplicatedStorage" then return fakeRS elseif n=="RunService" then return {RenderStepped=render.Event}
 elseif n=="UserInputService" then return {InputBegan=input.Event,InputEnded=ended.Event} end return realGame:GetService(n)
end
local oldCamera=workspace.CurrentCamera local camera=Instance.new("Camera",host) workspace.CurrentCamera=camera
local function controller()
 local game=proxy
__SURVIVAL_CLIENT_TEST_SOURCE__
end
local function step() render:Fire(.2) task.wait() end
local ok,result=xpcall(function()
 controller() step()
 local gui=assert(guiHost:FindFirstChild("SurvivalHUD")) assert(gui.Actions.Visible and not gui:FindFirstChild("Join"))
 local introData={duration=4,runDuration=3.15,startCF=CFrame.new(0,1000,0),endCF=CFrame.new(0,1000,-18),cameraCF=CFrame.lookAt(Vector3.new(8,1005,-10),Vector3.new(0,1002,-10))}
 update:Fire("jasonIntro",introData,introJason) task.wait()
 assert(gui:GetAttribute("CinematicActive")==true,"Jason intro did not activate")
 assert(camera.CameraType==Enum.CameraType.Scriptable,"Jason intro did not take camera")
 assert(workspace:FindFirstChild("LocalJasonIntro"),"Local Jason cinematic clone missing")
 update:Fire("reset") task.wait()
 assert(gui:GetAttribute("CinematicActive")==false and not workspace:FindFirstChild("LocalJasonIntro"),"Jason intro did not clean up")
 update:Fire("caught","Jason",CFrame.new(0,0,-3)) task.wait()
 update:Fire("reset") task.wait()
 attrs.VoidActive=true camera.CameraType=Enum.CameraType.Scriptable
 task.wait(.7)
 assert(camera.CameraType==Enum.CameraType.Scriptable and not gui.Capture.Visible,"Old hit callback reclaimed death camera")
 attrs.VoidActive=false
 update:Fire("roundResult",{jasonWon=true,map="Base Abandonada",xp=50,board={{name="Tester",userId=991,time=125,hits=2,falls=1,level=4}}}) task.wait()
 assert(gui.RoundResult.Ranking:IsA("ScrollingFrame") and gui.RoundResult.Ranking.Rank1,"Scrollable result ranking missing")
 assert(gui.RoundResult.WinnerPortrait:FindFirstChildOfClass("WorldModel"):FindFirstChild("WinnerJason"),"Winning Jason portrait missing")
 assert(gui.RoundResult.Subtitle.Text:find("50 XP",1,true),"Earned XP not shown")
 assert(not gui.RoundResult.Winner.Text:find("\\n",1,true),"Result contains literal newline escape")
 local flash=assert(gui:FindFirstChild("EntryFlash"),"Entry glow flash missing")
 local before=flash:GetAttribute("PulseCount") or 0
 update:Fire("lobbyDoorGlow") task.wait()
 assert((flash:GetAttribute("PulseCount") or 0)==before+1,"Lobby door glow event did not pulse")
 assert(gui.Actions.Run.UICorner.CornerRadius.Scale==1 and gui.Actions.Run.Size.X.Offset==gui.Actions.Run.Size.Y.Offset,"Sprint must be circular")
 assert(gui.Actions.Run.InnerRing and gui.Round.BackgroundTransparency==1 and gui.Countdown.BackgroundTransparency==1,"Circular rings and transparent timer")
 assert(gui.Actions:FindFirstChild("Flashlight") and gui.Actions.Flashlight.UICorner.CornerRadius.Scale==1,"Circular flashlight button missing")
 input:Fire({KeyCode=Enum.KeyCode.F},false) task.wait() assert(requests[#requests]=="flashlight")
 input:Fire({KeyCode=Enum.KeyCode.E},false) task.wait() assert(requests[#requests]=="kit")
 attrs.MusicEnabled=false attrs.IsJason=true step()
 assert(not game:GetService("SoundService").LocalJasonTheme.IsPlaying,"Music toggle ignored by Jason theme")
 attrs.IsJason=false
 attrs.Downed=true attrs.BleedoutAt=workspace:GetServerTimeNow()+25 step()
 assert(not gui.Actions.Run.Visible and not gui.Actions.Slow.Visible and gui.Actions.Medkit.Text=="+")
 attrs.ReviveAt=workspace:GetServerTimeNow()+3 step()
 assert(gui.Notice.Text:find("Reanimando",1,true),"Self-revive progress hidden by downed message")
 attrs.ReviveAt=0
 attrs.InRound=false attrs.Downed=false attrs.RoundStatus="eliminated" attrs.Spectating=true step()
 assert(gui.Spectate.Visible and not gui.Actions.Visible and not gui:FindFirstChild("Join"))
 assert(camera.CameraSubject==char.Humanoid and gui.Spectate.Player.Text=="Sobrevivente")
 survivor.GetAttribute=function() return false end step()
 assert(gui.Spectate.Player.Text=="Nenhum sobrevivente disponível","Stale spectator target")
 attrs.IsJason=true attrs.InRound=true attrs.Spectating=false step()
 assert(gui.Actions.Attack.Visible and not gui.Actions.Run.Visible,"Player Jason attack controls")
 assert(camera.FieldOfView>70,"Jason FOV boost did not activate")
 attrs.IsJason=false attrs.InRound=false attrs.Spectating=true
 attrs.VoidActive=true step() assert(not gui.Spectate.Visible and not gui.Round.Visible)
 attrs.VoidActive=false attrs.Spectating=false attrs.RoundStatus="lobby"
 fakeNet:SetAttribute("Phase","Intervalo") fakeNet:SetAttribute("EndsAt",workspace:GetServerTimeNow()+30)
 fakeNet:SetAttribute("Waiting",1) fakeNet:SetAttribute("MaxPlayers",8) step()
 assert(gui.Countdown.Visible and not gui:FindFirstChild("Join") and gui.Actions.Visible,"Intermission HUD mismatch")
 assert(gui.Actions.Run.Visible and gui.Actions.Slow.Visible and gui.Actions.Boost.Visible,"Movement controls must remain visible in lobby")
 fakeNet:SetAttribute("Phase","Partida") step()
 assert(not gui:FindFirstChild("Join") and gui.Actions.Visible,"Portal admission must keep movement controls visible")
 assert(gui.Actions.Run.Visible and gui.Actions.Slow.Visible and gui.Actions.Boost.Visible,"Run/slow/boost controls disappeared outside round")
 attrs.InMenu=true step() assert(not gui:FindFirstChild("Join") and not gui.Round.Visible and not gui.Countdown.Visible)
 return {ok=true,scrollableResults=true,winningPortrait=true,musicPreference=true,selfReviveProgress=true,staleCameraCallbackCancelled=true,jasonIntroCinematic=true,smoothCameraReturn=true,flashlightButton=true,persistentMovementControls=true,lobbyDoorGlow=true,jasonFovBoost=true,selfReviveButton=true,spectatorCamera=true,targetMarker=true,menuAndDeathHideHUD=true,keyboardMedkit=true}
end,debug.traceback)
workspace.CurrentCamera=oldCamera host:Destroy() description:Destroy()
assert(ok,result) return result


