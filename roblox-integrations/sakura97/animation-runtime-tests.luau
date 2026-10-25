local realGame=game local RS=game:GetService("ReplicatedStorage")
local host=Instance.new("Folder",workspace) host.Name="AnimationPlaybackTest"
local pg=Instance.new("Folder",host)
local world=Instance.new("WorldModel",pg)
local portrait=RS.Survival.PresentationJason:Clone() portrait:SetAttribute("PresentationPursuer",true) portrait.Parent=world
local p={attrs={InRound=true,MoveMode="run",Injured=false}}
function p:WaitForChild(name) if name=="PlayerGui" then return pg end end
function p:GetAttribute(name) return self.attrs[name] end
p.Character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R6)
p.Character.Parent=host
local animate=p.Character:FindFirstChild("Animate") or Instance.new("LocalScript",p.Character) animate.Name="Animate" animate.Enabled=true
local simulate
local proxy={ReplicatedStorage=RS}
function proxy:GetService(name)
 if name=="Players" then return {LocalPlayer=p,GetPlayers=function() return {p} end}
 elseif name=="RunService" then return {PreSimulation={Connect=function(_,fn) simulate=fn end}} end
 return realGame:GetService(name)
end
local function controller()
 local game=proxy
__ANIMATION_TEST_SOURCE__
 return {prepare=prepare,resolve=locomotionName,apply=apply}
end
local function posed(model)
 local count=0
 for _,m in ipairs(model:GetDescendants()) do if (m:IsA("Motor6D") or m:IsA("AnimationConstraint")) and m.Transform~=CFrame.identity then count+=1 end end
 return count
end
local ok,err=xpcall(function()
 local api=controller() assert(simulate)
 local d=api.prepare(p.Character,RS.Survival.SurvivorClips)
 local diagnostics={}
 if d then for name,c in pairs(d.clips) do diagnostics[name]={bound=c.boundCount,frames=c.frameCount,length=c.length} end else diagnostics.prepare="nil" end
 diagnostics.motors={}
 for _,v in ipairs(p.Character:GetDescendants()) do if v:IsA("Motor6D") then table.insert(diagnostics.motors,v.Name..":"..(v.Part1 and v.Part1.Name or "nil")) end end
 local diagnosticText=game:GetService("HttpService"):JSONEncode(diagnostics)
 for i=1,6 do simulate(.2) end
 assert(posed(portrait)>=4,"Winning clip did not animate the original Jason portrait")
 assert(posed(p.Character)>=4,"Run clip did not animate R6 character: posed="..posed(p.Character).." disabled="..tostring(animate.Disabled).." state="..tostring(p.Character.Humanoid:GetState()).." "..diagnosticText)
 assert(animate.Disabled,"Default Animate conflicts with custom locomotion")
 p.attrs.MoveMode="walk" p.attrs.Injured=true
 simulate(.2) assert(posed(p.Character)>=4,"Injured clip did not animate")
 local actions=assert(RS.Survival:FindFirstChild("SurvivorActionClips"),"Survivor action clip package missing")
 local actionData=api.prepare(p.Character,actions)
 assert(actionData and actionData.clips.CrouchWalk and actionData.clips.CrouchWalk.boundCount>=4,"CrouchWalk cannot drive R6")
 assert(actionData.clips.InjuredCrouchWalk and actionData.clips.InjuredCrouchWalk.boundCount>=4,"InjuredCrouchWalk cannot drive R6")
 assert(actionData.clips.Stun and actionData.clips.Stun.boundCount>=4,"Stun cannot drive R6")
 api.apply(actionData,"CrouchWalk",.2,true)
 assert(posed(p.Character)>=4,"CrouchWalk did not animate R6 character")
 api.apply(actionData,"InjuredCrouchWalk",.2,true)
 assert(posed(p.Character)>=4,"InjuredCrouchWalk did not animate R6 character")
 api.apply(actionData,"Stun",.18,false,.18)
 assert(posed(p.Character)>=4,"Stun did not animate R6 character")
 p.attrs.Downed=true simulate(.2) assert(posed(p.Character)>=1 and animate.Disabled,"Downed pose conflicts with Animator")
 local rootPart=p.Character:FindFirstChild("HumanoidRootPart")
 local root=nil
 for _,joint in ipairs(p.Character:GetDescendants()) do
  if joint:IsA("Motor6D") and joint.Part0==rootPart then root=joint break end
 end
 local downedTransform=root and root.Transform or CFrame.identity
 p.attrs.BeingExecuted=true p.attrs.ExecutionAt=workspace:GetServerTimeNow() p.attrs.ExecutionDuration=1.85
 simulate(.2)
 assert(root and root.Transform~=downedTransform,"Execution pose does not override downed pose")
 assert(math.abs(root.Transform.Position.Y)<.6,"Execution victim incorrectly remains in horizontal downed pose")
 for _,folder in ipairs(RS.Survival.VictimMotionLibraries:GetChildren()) do
  local victim=api.prepare(p.Character,folder) assert(victim and victim.clips.VictimExecution and victim.clips.VictimExecution.boundCount>=4,"Missing victim joints: "..folder.Name)
  local length=victim.clips.VictimExecution.length
  api.apply(victim,"VictimExecution",.2,false,length*.35)
  local before=root.Transform
  api.apply(victim,"VictimExecution",.2,false,length*.85)
  assert(posed(p.Character)>=4 and root.Transform~=before,"Victim execution is frozen: "..folder.Name)
 end
 p.attrs.BeingExecuted=false p.attrs.Downed=false
 simulate(.2)
 p.attrs.InRound=false simulate(.2)
 assert(not animate.Disabled,"Default Animate was not restored outside round")
 assert(posed(p.Character)==0,"Custom pose remained after round")
end,debug.traceback)
host:Destroy()
assert(ok,err)
return {ok=true,winningPortrait=true,runPlayback=true,r6AvatarJoints=true,downedPose=true,executionOverridesDowned=true,injuredPlayback=true,crouchPlayback=true,injuredCrouchPlayback=true,stunPlayback=true,defaultAnimationRestored=true,poseCleanup=true,survivorActionClips=true}
