local originalSounds={} for _,v in ipairs(game:GetService("SoundService"):GetChildren()) do originalSounds[v]=true end
local realGame=game local RS=game:GetService("ReplicatedStorage")
local host=Instance.new("Folder",workspace) host.Name="SurvivalClientTest"
local render=Instance.new("BindableEvent",host) local input=Instance.new("BindableEvent",host) local ended=Instance.new("BindableEvent",host) local update=Instance.new("BindableEvent",host)
local attrs={InRound=true,SweanLoadingDone=true,RoundStatus="alive",GameLanguage="pt-BR"}
local p={attrs=attrs,Character=nil,UserId=991,DisplayName="Tester",Parent=host}
local description=Instance.new("HumanoidDescription")
local char=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6) char.Parent=host p.Character=char
local introJason=game.ServerStorage.SurvivalAssets.Killers.Jason:Clone() introJason.Name="IntroJasonTest" introJason.Parent=host
local guiHost=Instance.new("Folder",host) guiHost.Name="PlayerGui"
function p:GetAttribute(n) return attrs[n] end
local attributeEvents={}
function p:GetAttributeChangedSignal(n) if not attributeEvents[n] then attributeEvents[n]=Instance.new("BindableEvent",host) end return attributeEvents[n].Event end
function p:SetAttribute(n,v) attrs[n]=v if attributeEvents[n] then attributeEvents[n]:Fire() end end

function p:WaitForChild(n) if n=="PlayerGui" then return guiHost end end
function p:FindFirstChild() return nil end
function p:FindFirstChildWhichIsA() return nil end
local survivorAttrs={InRound=true,Downed=false,IsJason=false,VoidActive=false}
local survivor={Character=char,UserId=992,DisplayName="Sobrevivente",Parent=host,GetAttribute=function(_,n) return survivorAttrs[n] end}
local fakePlayers={LocalPlayer=p,GetPlayers=function() return {p,survivor} end,GetPlayerByUserId=function(_,id) if id==991 then return p elseif id==992 then return survivor end end}
local requests={}
local fakeAction={FireServer=function(_,action) table.insert(requests,action) end}
local fakeNet=setmetatable({Action=fakeAction,Update={OnClientEvent=update.Event},Config=RS.Survival.Config},{__index=function(_,k)
 local v=RS.Survival[k] if type(v)=="function" then return function(_,...) return v(RS.Survival,...) end end return v
end})
local fakeRS=setmetatable({XNMedia=RS.XNMedia,WaitForChild=function(_,n) if n=="Survival" then return fakeNet end return RS:WaitForChild(n) end},{__index=function(_,k) local v=RS[k] if type(v)=="function" then return function(_,...) return v(RS,...) end end return v end})
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
 local artGui=assert(guiHost:FindFirstChild("SurvivalHUD"))
 local runArt=assert(artGui.TopActions.Run:FindFirstChild("ReferenceActionArt"),"Reference artwork missing")
 assert(runArt.Image~="" and runArt.ImageRectOffset==Vector2.new(373,78),"Idle run crop incorrect")
 attrs.MoveMode="run" step()
 assert(runArt.ImageRectOffset==Vector2.new(658,71),"Active sprint crop missing")
 attrs.MoveMode="walk" step()
 assert(runArt.UICorner.CornerRadius.Scale==1,"Square panel rule broke circular action art")

 local gui=assert(guiHost:FindFirstChild("SurvivalHUD")) assert(gui.TopActions.Run.Visible and not gui:FindFirstChild("Join"))
 local mapLoading=assert(gui:FindFirstChild("ArenaLoading"),"Map loading screen missing")
 assert(mapLoading:FindFirstChild("MapProgress") and mapLoading.MapProgress:FindFirstChild("Fill"),"Bottom map loading progress bar missing")
 assert(mapLoading:FindFirstChild("GoodLuck") and mapLoading.GoodLuck.Text=="GOOD LUCK","Good Luck loading text missing")
 assert(mapLoading.Size==UDim2.fromScale(1,1) and mapLoading:FindFirstChild("ArenaAvatar") and mapLoading.ArenaAvatar.Visible==false,"Map loading must use the real full-screen workspace camera, not a visible avatar viewport")
 update:Fire("jasonIntro",{duration=4},introJason) task.wait()
 assert(gui:GetAttribute("CinematicActive")~=true and not workspace:FindFirstChild("LocalJasonIntro"),"Removed killer intro cinematic returned")
 update:Fire("caught","Jason",CFrame.new(0,0,-3)) task.wait()
 update:Fire("reset") task.wait()
 attrs.VoidActive=true camera.CameraType=Enum.CameraType.Scriptable
 task.wait(.7)
 assert(camera.CameraType==Enum.CameraType.Scriptable and not gui:FindFirstChild("Capture"),"Hit reaction must never restore removed capture UI or steal death/menu camera")
 attrs.VoidActive=false
 local beforeResultType=camera.CameraType
 local beforeResultSubject=camera.CameraSubject
 update:Fire("roundResult",{jasonWon=true,killer="JohnDoe",killerPlayer=false,killerWinnerName="JohnDoe",winnerText="JohnDoe venceu a partida",lastVictimUserId=992,lastVictimName="Sobrevivente",map="Base Abandonada",xp=50,board={{name="Tester",userId=991,time=125,hits=2,falls=1,level=4},{name="Sobrevivente",userId=992,time=111,hits=3,falls=2,level=2}}}) task.wait()
 assert(camera.CameraType==Enum.CameraType.Scriptable,"Fullscreen result did not own the gameplay camera")
 assert(gui.RoundResult.Ranking:IsA("ScrollingFrame") and gui.RoundResult.Ranking.Rank1,"Scrollable result ranking missing")
 assert(gui.RoundResult.Size==UDim2.fromScale(1,1) and gui.RoundResult.WinnerPortrait.Visible==false and gui.RoundResult.Ranking.Visible,"Killer victory must use the real full-screen workspace camera with ranking overlay")
 assert(gui.RoundResult.Close.Text=="SAÍDA" and gui.RoundResult.Close.Position.Y.Scale>=gui.RoundResult.Ranking.Position.Y.Scale+gui.RoundResult.Ranking.Size.Y.Scale,"Exit must be under ranking")
 assert(not gui:FindFirstChild("AdminReset"),"Removed reset/test button returned")
  assert(gui:FindFirstChild("KillerShop") and gui:FindFirstChild("ShopButton"),"Killer shop HUD missing")
 assert(gui.ShopButton.Text=="" and gui.ShopButton:FindFirstChild("CartIcon"),"Cart icon missing")
 assert(gui.Countdown.Icon:FindFirstChild("ClockFace") and gui.Countdown.Icon:FindFirstChild("MinuteHand"),"Native clock icon missing")
 assert(gui.SettingsOverlay.BackgroundTransparency>=.75,"Settings overlay is still darkening the controls")
 assert(gui.SettingsOverlay.ReferenceSettings.ZIndex>gui.SettingsOverlay.ZIndex,"Settings panel is rendered behind its dark overlay")
 assert(gui.SettingsOverlay.ReferenceSettings:FindFirstChild("language"),"Game language tab missing")
 attrs.GameLanguage="en" if attributeEvents.GameLanguage then attributeEvents.GameLanguage:Fire() end task.wait()
 assert(gui.KillerShop.ShopPanel.Title.Text=="KILLERS","HUD text did not switch to English from settings")
 assert(gui.SettingsOverlay.ReferenceSettings.language.Text=="LANGUAGE","Settings language tab did not translate")
 attrs.GameLanguage="pt-BR" if attributeEvents.GameLanguage then attributeEvents.GameLanguage:Fire() end task.wait()
 assert(gui.KillerShop.ShopPanel.Title.Text=="PERSEGUIDORES","HUD text did not switch back to Portuguese")
 assert(gui.HackPanel and gui.Profile.Coin,"Hack UI or requested coin missing")
 local winnerActor=workspace:FindFirstChild("WinnerPursuer")
 if winnerActor then
  assert(winnerActor:GetAttribute("PresentationState")=="RoundVictory" and winnerActor:GetAttribute("PresentationFrozen")==false,"Winner actor is frozen")
  assert(winnerActor:GetAttribute("PresentationPursuer")==true,"Winner animation driver missing")
  for _,part in ipairs(winnerActor:GetDescendants()) do if part:IsA("BasePart") and part~=winnerActor.PrimaryPart then assert(not part.Anchored,"Winner limb is anchored") end end
 end
 assert(gui.RoundResult.BackgroundTransparency==1,"Result overlay is still blocking the real workspace camera")
 assert(camera.CameraType==Enum.CameraType.Scriptable,"Real result camera did not stay scriptable during the cinematic")
 assert(gui.RoundResult.Header.Text:find("JOHNDOE",1,true) and gui.RoundResult.Header.Text:find("GANHADOR",1,true),"Winner wording is not using the pursuer name")
 assert(not gui:FindFirstChild("MusicButton") and not gui:FindFirstChild("MusicPanel"),"Music icon/panel returned to gameplay HUD")
 assert(gui.RoundResult.Subtitle.Text:find("50 XP",1,true),"Earned XP not shown")
 assert(not gui.RoundResult.Winner.Text:find("\\n",1,true),"Result contains literal newline escape")
 gui.RoundResult.Visible=false task.wait()
 assert(camera.CameraType==beforeResultType,"Gameplay camera type was not restored after result closed")
 if beforeResultSubject then assert(camera.CameraSubject==beforeResultSubject,"Gameplay camera subject was not restored after result closed") end
 assert(gui.TopActions and gui.TopActions:FindFirstChild("Run"),"Hold-to-run control missing")
 assert(not gui.TopActions:FindFirstChild("Flashlight") and not gui.TopActions:FindFirstChild("Boost") and not gui.TopActions:FindFirstChild("Medkit"),"Extra persistent top buttons returned")
 assert(not gui:FindFirstChild("Leave"),"Return-to-menu button returned to gameplay")
 assert(gui.Actions:FindFirstChild("ReviveNearby"),"Contextual proximity revive button missing")
 assert(gui.Actions:FindFirstChild("CarryNearby") and gui.Actions:FindFirstChild("Attack"),"Carry/killer attack controls missing")
 assert(gui.TopActions:FindFirstChild("Crouch"),"Crouch HUD control missing")
 assert(not gui.Actions:FindFirstChild("Slow") and not gui.Actions:FindFirstChild("Jump"),"Removed legacy bottom action buttons returned")
 assert(gui.TopActions.Run.BackgroundTransparency<1 and gui.TopActions.Position.Y.Scale==1,"Run needs visible background and lower-screen placement")
 assert(gui.Round.BackgroundTransparency==1 and not gui.Round.Detail.Visible,"Round HUD must show only the top timer")
 assert(gui.Countdown.Visible==(fakeNet:GetAttribute("Phase")=="Intervalo" or fakeNet:GetAttribute("Phase")=="Escolha" or fakeNet:GetAttribute("Phase")=="Aguardando"),"Timer visibility must follow non-voting pre-round phases")
 assert(gui.PlayerRoster and gui.PlayerRoster:FindFirstChild("Player_991") and gui.PlayerRoster:FindFirstChild("Player_992"),"Reference-style player roster missing")
 local rosterRow=gui.PlayerRoster.Player_991
 local rosterName=assert(rosterRow:FindFirstChild("Name"),"Roster name label missing")
 local rosterAvatar=assert(rosterRow:FindFirstChild("Avatar"),"Roster avatar missing")
 local rosterHealth=assert(rosterRow:FindFirstChild("Health"),"Roster health bar missing")
 assert(rosterRow.Size.X.Offset<=184 and rosterRow.Size.Y.Offset<=40,"Roster card is too large/stretched")
 assert(rosterAvatar.Position.X.Offset<rosterName.Position.X.Offset,"Avatar must stay left of player name")
 assert(rosterHealth.Position.X.Offset>=rosterName.Position.X.Offset,"Health bar must sit under/right of the name")
 input:Fire({KeyCode=Enum.KeyCode.F},false) task.wait() assert(requests[#requests]=="flashlight")
 local beforeCarryHotkey=#requests
 input:Fire({KeyCode=Enum.KeyCode.E},false) task.wait()
 assert(#requests==beforeCarryHotkey+1 and requests[#requests]=="carry","Carry hotkey did not fire server-owned carry action")
 local beforeRemovedHotkey=#requests
 input:Fire({KeyCode=Enum.KeyCode.Q},false) task.wait()
 assert(#requests==beforeRemovedHotkey,"Removed kit/boost hotkey still fires actions")
 attrs.IsJason=true step()
 assert(not game:GetService("SoundService"):FindFirstChild("LocalJasonTheme"),"Automatic Jason theme was recreated")
 local roundMusic=assert(game:GetService("SoundService"):FindFirstChild("SuviversMatchMusic"),"Match soundtrack missing")
 assert(roundMusic.SoundId=="rbxassetid://108879410219148","Wrong match soundtrack asset")
 assert(roundMusic.Volume<.5 and math.abs(roundMusic.Volume-.35)<.001,"Match soundtrack must stay below half volume")
 assert(roundMusic.Looped,"Match soundtrack must loop")
 attrs.IsJason=false
 attrs.Downed=true attrs.BleedoutAt=workspace:GetServerTimeNow()+30 step()
 assert(not gui.TopActions.Run.Visible and not gui.Actions.ReviveNearby.Visible,"Downed player must not see run/self-revive buttons")
 assert(gui.Notice.Text:find("30",1,true) or gui.Notice.Text:find("29",1,true),"30-second downed countdown missing")
 attrs.Downed=false survivorAttrs.Downed=true step()
 assert(gui.Actions.ReviveNearby.Visible,"Nearby downed teammate did not expose + revive button")
 attrs.ReviveAt=workspace:GetServerTimeNow()+2 step()
 assert(gui.Notice.Text:find("Reanimando",1,true),"Teammate revive progress hidden")
 attrs.ReviveAt=0 survivorAttrs.Downed=false
 attrs.InRound=false attrs.Downed=false attrs.RoundStatus="eliminated" attrs.Spectating=true step()
 assert(gui.Spectate.Visible and not gui.Actions.Visible and not gui:FindFirstChild("Join"))
 assert(camera.CameraSubject==char.Humanoid and gui.Spectate.Player.Text=="Sobrevivente")
 survivor.GetAttribute=function() return false end step()
 assert(not gui.Spectate.Visible,"Spectator UI must disappear when no living target remains")
 attrs.IsJason=true attrs.InRound=true attrs.Spectating=false step()
 assert(gui.TopActions.Run.Visible and gui.TopActions.Run:FindFirstChild("ReferenceActionArt")~=nil,"Player killer sprint control missing")
 assert(gui.Actions.Visible and gui.Actions.Attack.Visible and not gui.Actions.ReviveNearby.Visible and not gui.Actions.CarryNearby.Visible,"Player killer attack/context controls are wrong")
 assert(camera.FieldOfView>(attrs.CameraFOV or 48),"Killer FOV boost did not increase above the configured base FOV")
 attrs.IsJason=false attrs.InRound=false attrs.Spectating=true
 attrs.VoidActive=true step() assert(not gui.Spectate.Visible and not gui.Round.Visible)
 attrs.VoidActive=false attrs.Spectating=false attrs.RoundStatus="lobby"
 fakeNet:SetAttribute("Phase","Votação") fakeNet:SetAttribute("EndsAt",workspace:GetServerTimeNow()+6)
 fakeNet:SetAttribute("MapVoteOptions",'["DoomspireBrickbattle","RocketArena","PiggySewers","PiggyMappleDonut"]')
 fakeNet:SetAttribute("MapVotes",'{"DoomspireBrickbattle":1,"RocketArena":0,"PiggySewers":0,"PiggyMappleDonut":0,"RANDOM":0}')
 fakeNet:SetAttribute("Waiting",1) fakeNet:SetAttribute("MaxPlayers",8) step()
 assert(not gui.Countdown.Visible and gui.MapVoting.Visible and not gui.Round.Visible and not gui.Actions.Visible,"Dedicated voting overlay must replace intermission countdown during voting")
 camera.CameraType=Enum.CameraType.Scriptable camera.CameraSubject=nil
 char.Humanoid.Health=37 step()
 assert(camera.CameraType==Enum.CameraType.Custom and camera.CameraSubject==char.Humanoid,"Camera did not recover the living lobby character")
 assert(p.CameraMinZoomDistance==4 and p.CameraMaxZoomDistance==24,"Lobby zoom remains locked")
 assert(gui.Condition.Value.Text=="♥  37","Heart must show real health")
 assert(gui.Profile.XP.Size.Y.Offset==8 and gui.Profile.XP.Level.Size.Y.Offset>=18,"Thin XP bar clipped the level label")
 assert(gui.MapVoting.Visible,"Map voting missing in dedicated six-second voting phase")
 attrs.MapVote="RocketArena" step()
 assert(not gui.MapVoting.Visible,"Accepted vote must dismiss map voting")
 attrs.MapVote=nil step()
 fakeNet:SetAttribute("Phase","Escolha") attrs.ChoosingKiller=false step()
 assert(not gui.MapVoting.Visible and not gui.KillerSelection.Visible,"Selection leaked to survivor")
 attrs.ChoosingKiller=true step()
 assert(gui.KillerSelection.Visible,"Chosen player did not see killer selection")
 attrs.ChoosingKiller=false fakeNet:SetAttribute("Phase","Votação") step()
 local expected={"DoomspireBrickbattle","RocketArena","PiggySewers","PiggyMappleDonut","RANDOM"}
 for i,value in ipairs(expected) do
  local card=assert(gui.MapVoting:FindFirstChild("VoteCard"..i),"Voting card "..i.." missing")
  assert(card:GetAttribute("VoteValue")==value,"Voting card value mismatch")
  if value=="RANDOM" then assert(card.RandomMark.Visible and not card.Preview.Visible,"Random voting card is wrong")
  else
   local id=nil for _,map in ipairs(require(RS.Survival.Config).Maps) do if map.name==value then id=map.id break end end
   assert(id and card.Preview.Image:find(tostring(id),1,true),"Map thumbnail uses wrong asset")
  end
 end
 assert(gui.MapVoting.Hint.Text:find("7 MAPAS TOTAIS",1,true),"Seven-map voting hint missing")
 char.Humanoid.Health=100
 fakeNet:SetAttribute("Phase","Partida") step()
 assert(not gui:FindFirstChild("Join") and not gui.Actions.Visible and not gui.Round.Visible,"Active round HUD leaked to a lobby player")
 attrs.InMenu=true step() assert(not gui:FindFirstChild("Join") and not gui.Round.Visible and not gui.Countdown.Visible)
 return {ok=true,fullScreenKillResult=true,realWorkspaceResultCamera=true,realWorkspaceLoadingCamera=true,resultCameraRestored=true,dynamicKillerWinnerName=true,musicHudRemoved=true,buckshotRoundMusic=true,lowVolumeRoundMusic=true,mapLoadingBottomBar=true,goodLuckLoadingText=true,r6ClientRig=true,singleHoldRunControl=true,compactReferenceRoster=true,topTimerOnly=true,transparentActionButtons=true,scrollableResults=true,winnerMenuScene=true,killerShop=true,noResetButton=true,automaticGameMusicRemoved=true,teammateReviveProgress=true,noHitCinematic=true,noKillerIntro=true,smoothCameraReturn=true,flashlightKeyboardOnly=true,persistentMovementControls=true,jasonFovBoost=true,proximityReviveButton=true,spectatorCamera=true,targetMarker=true,menuAndDeathHideHUD=true,noBoostOrKitButtons=true,noReturnButton=true}
end,debug.traceback)
workspace.CurrentCamera=oldCamera host:Destroy() description:Destroy()
for _,v in ipairs(game:GetService("SoundService"):GetChildren()) do if not originalSounds[v] then v:Destroy() end end
assert(ok,result) return result


