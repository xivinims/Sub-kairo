local host=Instance.new("Folder",workspace) host.Name="JasonAITest"
local event=Instance.new("BindableEvent",host)
local function module()
local TEST_RUN={Heartbeat=event.Event}
__AI_TEST_SOURCE__
end
local AI=module()
local rig=game.ServerStorage.SurvivalAssets.Killers.Jason:Clone() rig.Parent=host rig:PivotTo(CFrame.new(0,2000,0))
for _,p in ipairs(rig:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true end end
local map=Instance.new("Model",host) local points=Instance.new("Folder",map) points.Name="SafePoints"
for i=1,3 do local v=Instance.new("Vector3Value",points) v.Value=Vector3.new(i*20,2000,-30) end
local char=Instance.new("Model",host) local root=Instance.new("Part",char) root.Name="HumanoidRootPart" root.Size=Vector3.new(2,2,1) root.Anchored=true root.Position=Vector3.new(0,2000,-20)
local p={Character=char,UserId=991} local visible=true local attacks=0
local brain=AI.start(rig,map,{vision=70,hearing=65,speed=22,range=5.5},{players=function() return visible and {p} or {} end,vulnerable=function() return true end,catch=function() attacks+=1 end})
local function step(n) for i=1,n or 1 do event:Fire(.2) task.wait() end end
local ok,err=xpcall(function()
 step()
 assert(rig:GetAttribute("AIState")=="Chase" and rig:GetAttribute("TargetUserId")==991,"Visible target was not acquired")
 assert(rig:GetAttribute("DirectChase")==true,"Visible chase must bypass stale path waypoints")
 local wall=Instance.new("Part",host) wall.Size=Vector3.new(20,20,1) wall.Position=Vector3.new(0,2000,-10) wall.Anchored=true
 step()
 assert(rig:GetAttribute("TargetUserId")==0 and rig:GetAttribute("AIState")=="Search","Jason sees through walls")
 assert(rig:GetAttribute("DirectChase")==false,"Jason kept direct chase through wall")
 visible=false step(45) assert(rig:GetAttribute("AIState")=="Patrol","Jason did not abandon stale target")
 brain.noise(Vector3.new(15,2000,0),65) step() assert(rig:GetAttribute("AIState")=="Investigate","Audible noise not investigated")
 step(35) brain.noise(Vector3.new(500,2000,0),65) step() assert(rig:GetAttribute("AIState")=="Patrol","Jason heard outside hearing radius")
 wall:Destroy() visible=true root.Position=Vector3.new(0,2000,-3) step() assert(attacks==1,"Close target not attacked")
 step(3) assert(attacks==1,"Attack cooldown failed")
end,debug.traceback)
brain.stop() host:Destroy() assert(ok,err)
return {ok=true,lineOfSight=true,directPredictiveChase=true,pathFallback=true,searchMemoryExpires=true,hearingRadius=true,attackCooldown=true}
