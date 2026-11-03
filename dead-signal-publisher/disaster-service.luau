local Players=game:GetService('Players');local Path=game:GetService('PathfindingService')
local M={Residents={},Round=0,Kind='',Phase='Calm',Target='city',Saved=0}
M.Types={'Earthquake','AcidRain','Tornado','Meteors','Gale'}
M.Labels={Earthquake='TERREMOTO',AcidRain='CHUVA ÁCIDA',Tornado='TORNADO',Meteors='CHUVA DE METEOROS',Gale='VENTANIA EXTREMA'}
function M.CanTravel() return workspace:GetAttribute('DisasterPhase')~='Active' end
function M.SetPhase(phase,kind,target,duration)
 M.Phase=phase;M.Kind=kind or '';M.Target=target or 'city'
 workspace:SetAttribute('DisasterPhase',phase);workspace:SetAttribute('DisasterKind',M.Kind);workspace:SetAttribute('DisasterIsland',M.Target)
 workspace:SetAttribute('DisasterEndsAt',workspace:GetServerTimeNow()+(duration or 0))
end
function M.Covered(pos,id)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Islands[id]};rp.RespectCanCollide=true
 local hit=workspace:Raycast(pos,Vector3.new(0,70,0),rp)
 return hit and not hit.Instance:GetAttribute('IslandWind') and hit.Instance.Transparency<.8
end
function M.FindShelter(pos,id)
 if id~='city' then return nil end
 local catalog=game:GetService('ServerStorage').IslandGeometryCatalog.city;local seen={};local choices={}
 for _,part in ipairs(catalog:GetDescendants()) do if part:IsA('BasePart') then
  local key=part:GetAttribute('IslandDoorId');local pivot=part:GetAttribute('IslandDoorPivot')
  if key and not seen[key] and (pivot.Position-pos).Magnitude<180 then seen[key]=true;table.insert(choices,pivot) end
 end end
 table.sort(choices,function(a,b) return (a.Position-pos).Magnitude<(b.Position-pos).Magnitude end)
 local Chunks=require(script.Parent.IslandChunks)
 for i=1,math.min(#choices,8) do
  local pivot=choices[i];Chunks.Warm(id,pivot.Position,64)
  for _,side in ipairs({-1,1}) do
   local sample=pivot.Position+pivot.LookVector*side*7
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain,workspace.Islands[id]};rp.RespectCanCollide=true
   local floor=workspace:Raycast(sample+Vector3.new(0,3,0),Vector3.new(0,-14,0),rp)
   if floor and floor.Material~=Enum.Material.Water and M.Covered(floor.Position+Vector3.new(0,3,0),id) then return floor.Position+Vector3.new(0,3,0) end
  end
 end
 return nil
end
function M.Say(state,line)
 local event=game:GetService('ReplicatedStorage'):FindFirstChild('ResidentDialogue');if not event then return end
 for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  if r and (r.Position-state.rig.HumanoidRootPart.Position).Magnitude<65 then event:FireClient(p,state.rig,line) end
 end
end
function M.Evacuate(player,id,cf)
 if not M.CanTravel() then return end
 local index=0
 for _,s in ipairs(M.Residents) do if s.leader==player and s.rig.Parent==workspace:FindFirstChild('IslandResidents') then
  index+=1;s.island=id;s.origin=cf.Position;s.rig:PivotTo(cf*CFrame.new(index*3,2,5));s.home=nil
  if M.Phase=='Warning' and id~=M.Target and s.safeRound~=M.Round then s.safeRound=M.Round;M.Saved+=1;player:SetAttribute('NPCRescues',(player:GetAttribute('NPCRescues') or 0)+1);M.Say(s,'Você me tirou de lá a tempo. Obrigado!') end
 end end
end
function M.Move(state,target)
 if state.pathBusy or os.clock()<(state.nextPath or 0) then return end
 state.nextPath=os.clock()+2;state.pathBusy=true
 task.spawn(function()
  local rig=state.rig;local root=rig:FindFirstChild('HumanoidRootPart');local hum=rig:FindFirstChildOfClass('Humanoid')
  if not root or not hum then state.pathBusy=false;return end
  local ok,err=pcall(function()
   local path=Path:CreatePath({AgentRadius=1.4,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
   path:ComputeAsync(root.Position,target)
   if path.Status~=Enum.PathStatus.Success then state.rig:SetAttribute('ResidentPathBlocked',true);hum:MoveTo(target);return end
   state.rig:SetAttribute('ResidentPathBlocked',false)
   local points=path:GetWaypoints()
   for i=2,math.min(#points,5) do
    if not rig:IsDescendantOf(workspace) or state.cancelPath then break end
    if points[i].Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
    hum:MoveTo(points[i].Position)
    local deadline=os.clock()+1.5
    repeat task.wait(.15) until not root.Parent or (root.Position-points[i].Position).Magnitude<3 or os.clock()>deadline
   end
  end)
  if not ok then warn('[ResidentPath] '..tostring(err)) end
  state.pathBusy=false
 end)
end
return M
