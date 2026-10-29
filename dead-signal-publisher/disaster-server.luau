local Players=game:GetService('Players');local Run=game:GetService('RunService')
local D=require(script.Parent.DisasterService);local Chunks=require(script.Parent.IslandChunks)
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.3) end
local rng=Random.new();local debris=Instance.new('Folder');debris.Name='DisasterDebris';debris.Parent=workspace
local lifted={};local clones={}
local function reset()
 for p,v in pairs(lifted) do if p.Parent then p.Transparency=v.trans;p.CanCollide=v.collide end end
 for _,p in ipairs(clones) do p:Destroy() end
 table.clear(lifted);table.clear(clones);debris:ClearAllChildren()
end
local function bodies()
 local list={}
 for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute('IslandDestination')==D.Target and p.Character then table.insert(list,{rig=p.Character,player=p}) end end
 for _,s in ipairs(D.Residents) do if s.island==D.Target and s.rig:IsDescendantOf(workspace) then table.insert(list,{rig=s.rig,state=s}) end end
 return list
end
local function damage(entry,amount)
 local h=entry.rig:FindFirstChildOfClass('Humanoid');if h and h.Health>0 then if entry.state then h.Health=math.max(5,h.Health-amount);entry.rig:SetAttribute('ResidentInjured',h.Health<20) else h:TakeDamage(amount) end end
end
local function moveHouse(center)
 local island=workspace.Islands[D.Target];local candidates={}
 for _,p in ipairs(island:GetDescendants()) do
  local id=p:IsA('BasePart') and p:GetAttribute('DisasterStructureId')
  if id and not lifted[p] and (p.Position-center).Magnitude<150 then candidates[id]=candidates[id] or {};table.insert(candidates[id],p) end
 end
 local chosen
 for _,parts in pairs(candidates) do if #parts>=40 and #parts<=350 then
  local safe=true
  for _,e in ipairs(bodies()) do local r=e.rig:FindFirstChild('HumanoidRootPart');if r and (r.Position-parts[1].Position).Magnitude<24 then safe=false end end
  if safe then chosen=parts;break end
 end end
 if not chosen then return end
 local model=Instance.new('Model');model.Name='AirborneHouse';model.Parent=debris
 local origin=chosen[1].CFrame.Position
 for _,p in ipairs(chosen) do
  lifted[p]={trans=p.Transparency,collide=p.CanCollide};p.Transparency=1;p.CanCollide=false
  local c=p:Clone();for _,d in ipairs(c:GetDescendants()) do if d:IsA('Light') or d:IsA('ProximityPrompt') then d:Destroy() end end
  c.Transparency=lifted[p].trans;c.Anchored=true;c.CanCollide=false;c.CanTouch=false;c.CanQuery=false;c.Parent=model
 end
 table.insert(clones,model);model.WorldPivot=CFrame.new(origin)
 task.spawn(function()
  for step=1,160 do
   if D.Phase~='Active' or not model.Parent then break end
   local t=step/160;model:PivotTo(CFrame.new(origin+Vector3.new(t*800,t*t*1000,-t*600))*CFrame.Angles(t*2,t*5,t));task.wait(.1)
  end
  if model.Parent then model:Destroy() end
 end)
end
local function hazards()
 local tick=0
 while D.Phase=='Active' do
  tick+=1;local center=workspace.IslandDestinations[D.Target].Position
  local entries=bodies();if entries[1] then center=entries[1].rig:GetPivot().Position end
  local phase=os.clock();local vortex=center+Vector3.new(math.sin(phase*.08)*65,0,math.cos(phase*.08)*65)
  workspace:SetAttribute('DisasterCenter',vortex)
  if D.Kind=='Meteors' and tick%4==0 then
   local target=center+Vector3.new(rng:NextNumber(-65,65),0,rng:NextNumber(-65,65))
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain,workspace.Islands[D.Target]}
   local hit=workspace:Raycast(target+Vector3.new(0,100,0),Vector3.new(0,-180,0),rp)
   if hit then
    workspace:SetAttribute('MeteorTarget',hit.Position);workspace:SetAttribute('MeteorCue',workspace:GetServerTimeNow())
    task.delay(2,function() if D.Phase=='Active' and D.Kind=='Meteors' then for _,e in ipairs(bodies()) do local r=e.rig:FindFirstChild('HumanoidRootPart');if r and (r.Position-hit.Position).Magnitude<15 then damage(e,35) end end end end)
   end
  end
  for _,e in ipairs(entries) do
   local r=e.rig:FindFirstChild('HumanoidRootPart')
   if r then
    local cover=D.Covered(r.Position,D.Target)
    if D.Kind=='AcidRain' and not cover then damage(e,3)
    elseif D.Kind=='Earthquake' and not cover and tick%8==0 then damage(e,4)
    elseif (D.Kind=='Tornado' or D.Kind=='Gale') and not cover and not r.Anchored then
     local delta=vortex-r.Position;local dir=D.Kind=='Tornado' and Vector3.new(delta.X,0,delta.Z).Unit or Vector3.new(1,0,.35).Unit
     if dir.Magnitude==dir.Magnitude then r:ApplyImpulse((dir*(D.Kind=='Tornado' and 16 or 9)+Vector3.new(0,D.Kind=='Tornado' and 7 or 1,0))*r.AssemblyMass) end
     if D.Kind=='Tornado' and delta.Magnitude<22 then damage(e,4) end
    end
   end
  end
  if (D.Kind=='Tornado' or D.Kind=='Gale') and tick%24==0 then moveHouse(center) end
  task.wait(.5)
 end
end
local index=0
D.SetPhase('Calm','', 'city',90)
while true do
 task.wait(90)
 if #Players:GetPlayers()==0 then continue end
 index=index%#D.Types+1;D.Round+=1;D.Saved=0
 local people=Players:GetPlayers();local target=people[rng:NextInteger(1,#people)]:GetAttribute('IslandDestination') or 'city'
 local kind=D.Types[index]
 local ok,err=xpcall(function()
  D.SetPhase('Warning',kind,target,25);task.wait(25)
  D.SetPhase('Active',kind,target,70)
  workspace:SetAttribute('DisasterRound',D.Round)
  task.spawn(hazards);task.wait(70)
 end,debug.traceback)
 D.SetPhase('Recovery',kind,target,15);reset()
 workspace:SetAttribute('DisasterSaved',D.Saved)
 if not ok then warn('[Disaster] '..tostring(err)) end
 task.wait(15);D.SetPhase('Calm','',target,90)
end
