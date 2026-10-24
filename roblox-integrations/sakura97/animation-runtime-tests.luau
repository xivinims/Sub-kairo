local realGame=game local RS=game:GetService("ReplicatedStorage")
local host=Instance.new("Folder",workspace) host.Name="AnimationPlaybackTest"
local pg=Instance.new("Folder",host)
local world=Instance.new("WorldModel",pg)
local portrait=RS.Survival.PresentationJason:Clone() portrait:SetAttribute("PresentationPursuer",true) portrait.Parent=world
local p={attrs={InRound=true,MoveMode="slow"}}
function p:WaitForChild(name) if name=="PlayerGui" then return pg end end
function p:GetAttribute(name) return self.attrs[name] end
p.Character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15)
p.Character.Parent=host
local animate=Instance.new("LocalScript",p.Character) animate.Name="Animate" animate.Enabled=true
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
end
local function posed(model)
 local count=0
 for _,m in ipairs(model:GetDescendants()) do if m:IsA("Motor6D") and m.Transform~=CFrame.identity then count+=1 end end
 return count
end
local ok,err=xpcall(function()
 controller() assert(simulate)
 for i=1,6 do simulate(.2) end
 assert(posed(portrait)>=4,"Winning clip did not animate the original Jason portrait")
 assert(posed(p.Character)>=4,"Crouch clip did not animate R15 character")
 assert(animate.Disabled,"Default Animate conflicts with custom locomotion")
 p.attrs.MoveMode="walk" p.attrs.Injured=true
 simulate(.2) assert(posed(p.Character)>=4,"Injured clip did not animate")
 p.attrs.InRound=false simulate(.2)
 assert(not animate.Disabled,"Default Animate was not restored outside round")
 assert(posed(p.Character)==0,"Custom pose remained after round")
end,debug.traceback)
host:Destroy()
assert(ok,err)
return {ok=true,winningPortrait=true,crouchPlayback=true,injuredPlayback=true,defaultAnimationRestored=true,poseCleanup=true}
