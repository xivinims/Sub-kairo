while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local SS=game:GetService('ServerStorage')
local Residents=require(script.Parent.IslandResidents);local Chunks=require(script.Parent.IslandChunks)
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.3) end
local cache=Instance.new('Folder');cache.Name='ResidentCache';cache.Parent=SS
local world=Instance.new('Folder');world.Name='IslandResidents';world.Parent=workspace
local event=RS:WaitForChild('ResidentDialogue');local states={}
local D=require(script.Parent.DisasterService);D.Residents=states
for _,def in ipairs(Residents.Definitions) do
 local ok,rig=pcall(Residents.Build,def)
 if not ok then warn('[Residents] '..def.id..': '..tostring(rig));workspace:SetAttribute('ResidentError_'..def.id,tostring(rig))
 else
  rig.Parent=cache;local spawn=workspace.IslandDestinations[def.island]
  table.insert(states,{def=def,rig=rig,origin=spawn.Position+def.offset,island=def.island,placed=false,nextMove=0})
 end
 task.wait(.1)
end

for _,s in ipairs(states) do
 local pos=Residents.FindGround(s.def)
 if pos then
  s.origin=pos;local root=s.rig.HumanoidRootPart;local hum=s.rig.Humanoid
  s.rig:PivotTo(CFrame.new(pos+Vector3.new(0,hum.HipHeight+root.Size.Y/2,0)));s.placed=true
  local prompt=Instance.new('ProximityPrompt');s.prompt=prompt;prompt.ActionText='Conversar';prompt.ObjectText=s.def.name..' · '..s.def.role;prompt.MaxActivationDistance=9;prompt.RequiresLineOfSight=false;prompt.Parent=s.rig.Head
  local last={}
  prompt.Triggered:Connect(function(p)
   local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   if r and (r.Position-root.Position).Magnitude<12 and os.clock()-(last[p.UserId] or 0)>2 then last[p.UserId]=os.clock()
    if s.leader and s.leader~=p then event:FireClient(p,s.rig,'Já estou acompanhando alguém.');return end
    s.leader=s.leader==p and nil or p;s.cancelPath=true;task.delay(.3,function() s.cancelPath=false end)
    event:FireClient(p,s.rig,s.leader and (D.Phase=='Active' and 'ME TIRA DAQUI! Eu vou com você!' or 'Eu vou com você. Me leva para um lugar seguro.') or s.def.line) end
  end)
 else warn('[Residents] No safe placement for '..s.def.id);workspace:SetAttribute('ResidentError_'..s.def.id,'No safe placement') end
end
local lastPhase=''
Players.PlayerRemoving:Connect(function(p) for _,s in ipairs(states) do if s.leader==p then s.leader=nil end end end)
while task.wait(.5) do
 local active=0
 for _,s in ipairs(states) do if s.placed then
  local rig=s.rig;rig:SetAttribute('ResidentIsland',s.island);local root=rig.HumanoidRootPart;local hum=rig.Humanoid
  if s.leader and (not s.leader.Parent or not s.leader.Character or not s.leader.Character:FindFirstChild('HumanoidRootPart') or s.leader.Character.Humanoid.Health<=0) then s.leader=nil end
  local danger=(D.Phase=='Warning' or D.Phase=='Active') and s.island==D.Target
  if D.Phase=='Recovery' and lastPhase~='Recovery' then hum.Health=hum.MaxHealth;rig:SetAttribute('ResidentInjured',false);s.home=nil end
  local nearby=false
  for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if r and p:GetAttribute('IslandDestination')==s.island and (r.Position-root.Position).Magnitude<180 then nearby=true;break end end
  local live=nearby or s.leader~=nil
  if live then
   if rig.Parent~=world then rig.Parent=world;root.Anchored=false;root.CanCollide=true;pcall(function() root:SetNetworkOwner(nil) end) end
   active+=1
   local target
   if s.leader then
    local leaderRoot=s.leader.Character.HumanoidRootPart
    if (leaderRoot.Position-root.Position).Magnitude>7 then target=leaderRoot.Position-leaderRoot.CFrame.LookVector*4 end
   elseif danger then
    if s.homeRound~=D.Round then s.homeRound=D.Round;s.home=D.FindShelter(root.Position,s.island) end
    target=s.home
   end
   hum.WalkSpeed=danger and 12 or 6
   if target and (target-root.Position).Magnitude>4 then D.Move(s,target) else hum:MoveTo(root.Position) end
   local safe=danger and D.Covered(root.Position,s.island)
   rig:SetAttribute('ResidentSheltered',safe==true)
   if safe and s.safeRound~=D.Round then
    s.safeRound=D.Round
    if s.leader then D.Saved+=1;s.leader:SetAttribute('NPCRescues',(s.leader:GetAttribute('NPCRescues') or 0)+1);D.Say(s,'Aqui tem teto! Obrigado por não me deixar para trás.') end
   end
   if danger and not safe and os.clock()>(s.nextCry or 0) then
    s.nextCry=os.clock()+18+math.random(0,8)
    D.Say(s,s.home and 'CORRE! Precisamos entrar!' or 'SOCORRO! Alguém me chama, não sei para onde ir!')
   end
  else root.Anchored=true;rig.Parent=cache end
  s.prompt.ActionText=s.leader and 'Parar de seguir' or (danger and 'Chamar / socorrer' or 'Chamar para seguir')
 end end
 lastPhase=D.Phase;workspace:SetAttribute('ResidentsActive',active)
end
