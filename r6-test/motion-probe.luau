local P=game:GetService('Players')
local character=P:CreateHumanoidModelFromDescriptionAsync(Instance.new('HumanoidDescription'),Enum.HumanoidRigType.R6)
character.Name='AnimationProbe';character:PivotTo(CFrame.new(0,8,0));character.Parent=workspace
character.HumanoidRootPart.Anchored=true
local animator=character.Humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator',character.Humanoid)
local ids={idle_original=135979869186041,walk_original=73997618195368,idle_public=180435571,walk_public=180426354,jump_public=125750702,naruto_idle=100251055326558,naruto_walk=77852689958686,naruto_run=89651256350359,naruto_jump=131725558168717,naruto_fall=95937026088317,sprint=137454594998955,wall_left=137711855043043,wall_right=131232629152198}
local report={};local tracks={}
for name,id in pairs(ids) do
 local a=Instance.new('Animation');a.AnimationId='rbxassetid://'..id
 local ok,result=pcall(animator.LoadAnimation,animator,a)
 report[name]={id=id,load=ok,error=not ok and tostring(result) or nil}
 if ok then tracks[name]=result;result:Play(0);result:AdjustWeight(0) end
end
task.wait(6)
for name,t in pairs(tracks) do report[name].length=t.Length;report[name].playing=t.IsPlaying;t:Stop(0) end
local links={}
for _,m in ipairs(character:GetDescendants()) do if m:IsA('Motor6D') then table.insert(links,{name=m.Name,part0=m.Part0 and m.Part0.Name,part1=m.Part1 and m.Part1.Name}) end end
character:Destroy()
return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion,animations=report,joints=links})
