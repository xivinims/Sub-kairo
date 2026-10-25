local host=Instance.new("Folder",workspace) host.Name="GuideClientTest"
local npc=workspace.LobbyGuide:Clone() npc.Name="GuideTestNPC" npc.Parent=host
npc.GuideInteraction:Destroy()
local attrs={}
local gui=Instance.new("Folder",host) gui.Name="PlayerGui"
local p={Name="GuideTester",PlayerGui=gui}
function p:GetAttribute(name) return attrs[name] end
function p:SetAttribute(name,value) attrs[name]=value end
function p:WaitForChild(name) if name=="PlayerGui" then return gui end end
function p:Destroy() gui:Destroy() end
local description=Instance.new("HumanoidDescription")
local character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
character.Parent=host p.Character=character
local position=npc.HumanoidRootPart.Position+npc.HumanoidRootPart.CFrame.LookVector*6+npc.HumanoidRootPart.CFrame.RightVector*2
character:PivotTo(CFrame.new(position))
for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.Anchored=true end end
local render=Instance.new("BindableEvent",host)
local input=Instance.new("BindableEvent",host)
local triggered=Instance.new("BindableEvent",host)
local TEST_PROMPT={Triggered=triggered.Event}
local realGame=game
local proxy={}
function proxy:GetService(name)
 if name=="Players" then return {LocalPlayer=p}
 elseif name=="RunService" then return {RenderStepped=render.Event}
 elseif name=="UserInputService" then return {InputBegan=input.Event}
 else return realGame:GetService(name) end
end
local resources=game:GetService("ReplicatedStorage"):WaitForChild("LobbyGuideResources")
local savedVoiceIds={}
for i=1,6 do
 savedVoiceIds[i]=resources:GetAttribute("Voice"..i)
 resources:SetAttribute("Voice"..i,0)
end
local function start()
 local game=proxy
 local script={Parent=npc}
__GUIDE_CLIENT_TEST_SOURCE__
end
local ok,result=xpcall(function()
 local neck=npc.Torso.Neck local initial=neck.C0
 start()
 local ui=assert(gui:FindFirstChild("GuideDialogue"),"Fill dialogue UI missing")
 local voice=assert(game:GetService("SoundService"):FindFirstChild("FillVoice"),"Uploaded Fill voice Sound missing from SoundService")
 assert(voice:IsA("Sound") and math.abs(voice.Volume-.78)<.001,"Fill uploaded voice Sound is misconfigured")
 assert(ui:FindFirstChild("FillVoice")==nil,"Fill voice must not be parented inside the dialogue ScreenGui")
 assert(not ui:FindFirstChildWhichIsA("AudioTextToSpeech",true),"Text-to-speech returned to Fill")
 render:Fire(.2) task.wait()
 assert(neck.C0~=initial,"Fill did not turn toward nearby local user")
 triggered:Fire() task.wait(6.5)
 assert(ui.dialogResponses.Choice1.Visible and ui.dialogResponses.Choice5.Visible,"Five English Fill responses did not appear")
 assert(ui.dialogResponses.Choice1.text.Text=="How does the game work?","Fill dialogue is not English")
 assert(ui.dialogResponses.Choice5.text.Text=="Nothing right now.","Fill fifth response missing")
 input:Fire({KeyCode=Enum.KeyCode.One},false) task.wait(.2)
 assert(not ui.dialogResponses.Choice1.Visible,"Chosen Fill response did not hide choices")
 p:SetAttribute("InRound",true) render:Fire(.2) task.wait()
 assert(not npc.Head.gui.dialog.Visible and not TEST_PROMPT.Enabled,"Fill dialogue did not close on round entry")
 p:SetAttribute("InRound",false) render:Fire(.2) task.wait()
 assert(TEST_PROMPT.Enabled,"Fill prompt did not return after leaving round")
 npc.Parent=nil render:Fire(.2) task.wait()
 assert(not gui:FindFirstChild("GuideDialogue"),"Fill UI cleanup failed")
 return {ok=true,localGaze=true,englishUploadedVoice=true,noTTS=true,fiveChoices=true,roundEntryCleanup=true}
end,debug.traceback)
for i=1,6 do resources:SetAttribute("Voice"..i,savedVoiceIds[i]) end
host:Destroy() npc:Destroy() p:Destroy() description:Destroy()
assert(ok,result)
return result
