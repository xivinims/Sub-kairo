assert(game.PlaceVersion==89)
local Asset=game:GetService("AssetService")local report={readOnly=true,assets={}}
for _,id in ipairs({8474839527,119785112337064,18831822897})do
 local ok,raw=pcall(function()return Asset:LoadAssetAsync(id)end)local row={id=id,ok=ok,items={}}report.assets[tostring(id)]=row
 if ok then for _,d in ipairs(raw:GetDescendants())do
  if d:IsA("BasePart")then row.items[#row.items+1]={name=d.Name,class=d.ClassName,cf={d.CFrame:GetComponents()},size={d.Size.X,d.Size.Y,d.Size.Z},mesh=d:IsA("MeshPart")and d.MeshId or nil}
  elseif d:IsA("Model")then local cf,size=d:GetBoundingBox()row.items[#row.items+1]={name=d.Name,class="Model",size={size.X,size.Y,size.Z},pivot={d:GetPivot():GetComponents()}}
  elseif d:IsA("LuaSourceContainer")then row.items[#row.items+1]={class=d.ClassName,name=d.Name,source=d.Source}end
 end raw:Destroy()else row.error=tostring(raw)end
end
local description=game.Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
local rig=game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)description:Destroy()
for _,s in ipairs(rig:GetDescendants())do if s:IsA("LuaSourceContainer")then s:Destroy()end end
rig.Parent=workspace rig:PivotTo(CFrame.new(0,100,0))rig.HumanoidRootPart.Anchored=true
local animator=rig.Humanoid:FindFirstChildOfClass("Animator")or Instance.new("Animator",rig.Humanoid)
local animation=Instance.new("Animation")animation.AnimationId="rbxassetid://92824429927180"
game:GetService("ContentProvider"):PreloadAsync({animation})
local track=animator:LoadAnimation(animation)track.Looped=true track:Play(0)
local timeout=os.clock()+8 repeat task.wait(.1)until track.Length>0 or os.clock()>timeout
report.animation={length=track.Length,playing=track.IsPlaying,samples={}}
local motors={}for _,m in ipairs(rig:GetDescendants())do if m:IsA("Motor6D")then motors[#motors+1]=m end end
local function pose(time)
 track.TimePosition=time animator:StepAnimations(0)
 local done={[rig.HumanoidRootPart]=true}
 for _=1,18 do for _,m in ipairs(motors)do if done[m.Part0]and not done[m.Part1]then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.Transform*m.C1:Inverse()done[m.Part1]=true end end end
 local p=rig.LowerTorso local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,d in ipairs(rig:GetDescendants())do if d:IsA("BasePart")and not d:IsDescendantOf(rig:FindFirstChildWhichIsA("Accessory")or rig.Humanoid)then local v=d.Position lo=lo:Min(v)hi=hi:Max(v)end end
 local joints={}for _,m in ipairs(motors)do joints[m.Name]={m.Transform:GetComponents()}end
 return{time=time,torso={p.CFrame:GetComponents()},leftFoot={rig.LeftFoot.Position.X,rig.LeftFoot.Position.Y,rig.LeftFoot.Position.Z},rightFoot={rig.RightFoot.Position.X,rig.RightFoot.Position.Y,rig.RightFoot.Position.Z},joints=joints}
end
for _,t in ipairs({0,1,2,3,4})do if t<track.Length then report.animation.samples[#report.animation.samples+1]=pose(t)end end
local ok,clip=pcall(function()return game:GetService("AnimationClipProvider"):GetAnimationClipAsync(animation.AnimationId)end)
report.clip={ok=ok}
if ok then report.clip.class=clip.ClassName report.clip.children=#clip:GetDescendants()clip:Destroy()else report.clip.error=tostring(clip)end
track:Stop(0)rig:Destroy()animation:Destroy()
return report
