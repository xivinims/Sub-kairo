local Controller={}
local Players=game:GetService("Players")local Run=game:GetService("RunService")
function Controller.start(runtime,world)
 local npc=assert(world:FindFirstChild("OwnerNPC"))local root=npc.HumanoidRootPart
 require(runtime.NPCPose).seat(npc)
 local remote=runtime.OwnerDialogue local last={}local lastCommand={}local inside={}local globalVoice=-math.huge
 local phrases={"Olá!","Oiii!"}local sequence=0
 local function aliveRoot(player)
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then return r,h end
 end
 local function greet(player,conversation)
  local r=aliveRoot(player)if not r or(r.Position-root.Position).Magnitude>15 then return false end
  local now=workspace:GetServerTimeNow()
  if now-(last[player]or -math.huge)<(conversation and 1.5 or 35)then
   if conversation then remote:FireClient(player,"dialogue","Olá!")return true end
   return false
  end
  last[player]=now sequence+=1
  local line=phrases[sequence%2+1]npc:SetAttribute("WaveStarted",now)
  remote:FireClient(player,conversation and "dialogue"or "greeting",line)
  if now-globalVoice>20 and sequence%3~=0 then
   globalVoice=now
   if sequence%4==0 then npc.Head.YayVoice:Play()
   else npc.Head.HiVoice.PlaybackSpeed=sequence%2==0 and 1 or 1.025 npc.Head.HiVoice:Play()end
  end
  return true
 end
 npc.Head.TalkPrompt.Triggered:Connect(function(player)greet(player,true)end)
 remote.OnServerEvent:Connect(function(player,choice)
  if type(choice)~="string"or#choice>12 then return end
  local r=aliveRoot(player)if not r or(r.Position-root.Position).Magnitude>16 then return end
  local now=workspace:GetServerTimeNow()if now-(lastCommand[player]or 0)<.75 then return end lastCommand[player]=now
  if choice=="hello"then
   npc:SetAttribute("WaveStarted",now)remote:FireClient(player,"reply","Que bom te ver por aqui! 😄")
   if now-globalVoice>20 then globalVoice=now npc.Head.YayVoice:Play()end
  elseif choice=="forest"then remote:FireClient(player,"reply","Siga as trilhas, atravesse o rio pelas pontes e aproveite a floresta. À noite, as lanternas iluminam o caminho.")
  elseif choice=="bye"then remote:FireClient(player,"close","Até mais!")end
 end)
 Players.PlayerRemoving:Connect(function(player)last[player]=nil lastCommand[player]=nil inside[player]=nil end)
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.25 then return end elapsed=0
  local closest,best=nil,17
  for _,player in ipairs(Players:GetPlayers())do
   local r=aliveRoot(player)
   local distance=r and(r.Position-root.Position).Magnitude or math.huge
   if distance<best then closest=r best=distance end
   if distance<12.5 then if not inside[player]then inside[player]=true greet(player,false)end
   elseif distance>19 then inside[player]=nil end
  end
  npc:SetAttribute("LookTarget",closest and closest.Position+Vector3.new(0,1.5,0)or nil)
 end)
 return {greet=greet,aliveRoot=aliveRoot}
end
return Controller
