const key=process.env.ROBLOX_API_KEY;
const base='https://apis.roblox.com/cloud/v2/';
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function api(path,options={}){const r=await fetch(base+path,{...options,headers:{'x-api-key':key,'content-type':'application/json'},signal:AbortSignal.timeout(180000)});const d=await r.json();if(!r.ok)throw new Error(JSON.stringify(d));return d;}
const script=`assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local f=game:GetService("ServerStorage"):WaitForChild("SpringSourceConverted")
local m=f.MissDelightSource:Clone();m.Name="AnimationConversionValidation"
local root=m:FindFirstChild("RootPart",true);local rig=root.Parent
local controller=rig:FindFirstChildOfClass("AnimationController") or Instance.new("AnimationController",rig)
local animator=controller:FindFirstChildOfClass("Animator") or Instance.new("Animator",controller)
m.Parent=workspace
local result={version=game.PlaceVersion,build=f:GetAttribute("BuildId"),clips={}}
for _,name in ipairs({"walk","jumpscare"}) do
 local animation=f.SourceAnimations:FindFirstChild(name)
 local track=animator:LoadAnimation(animation);track:Play(0)
 local deadline=os.clock()+8
 while track.Length==0 and os.clock()<deadline do task.wait(0.2) end
 task.wait(0.4)
 local moving=0
 for _,b in ipairs(m:GetDescendants()) do if b:IsA("Bone") and b.Transform~=CFrame.new() then moving+=1 end end
 result.clips[name]={length=track.Length,playing=track.IsPlaying,movingBones=moving}
 track:Stop(0);track:Destroy()
end
m:Destroy();return game:GetService("HttpService"):JSONEncode(result)`;
let t=await api('universes/9421311218/places/118064584465155/luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'90s',script})});
while(['QUEUED','PENDING','PROCESSING'].includes(t.state)){await pause(1000);t=await api(t.path);}
if(t.error||t.state!=='COMPLETE')throw new Error(JSON.stringify(t.error||t));
const result=JSON.parse(t.output.results[0]);
result.restart=await api('universes/9421311218:restartServers',{method:'POST',body:'{}'});
console.log(JSON.stringify({stage:'staged-source-runtime-check',result},null,2));
