local realGame=game
local RS=game:GetService("ReplicatedStorage")
local field=workspace.FullIslandGrass
local coverage=workspace.SkinnedGrassCoverage
local heartbeat=Instance.new("BindableEvent")
local changed=Instance.new("BindableEvent")
local char=Instance.new("Model") char.Parent=workspace
local root=Instance.new("Part") root.Name="HumanoidRootPart" root.Anchored=true root.CFrame=workspace.IslandSpawn.CFrame+Vector3.new(0,3,0) root.Parent=char
local player={Character=char}
function player:GetAttribute() return true end
function player:GetAttributeChangedSignal() return changed.Event end
local proxy={}
function proxy:GetService(name)
 if name=="Players" then return {LocalPlayer=player,GetPlayers=function() return {player} end} end
 if name=="RunService" then return {Heartbeat=heartbeat.Event} end
 if name=="UserInputService" then return {TouchEnabled=true} end
 return realGame:GetService(name)
end
local allocated={}
local added=coverage.ChildAdded:Connect(function(model) allocated[model]=true end)
local function run()
 local game=proxy
__FULL_GRASS_CLIENT_SOURCE__
end
local ok,result=xpcall(function()
 run()
 local function settle()
  for i=1,110 do heartbeat:Fire(.05) task.wait() end
  assert(coverage:GetAttribute("InitialGrassReady"),"Full grass did not become ready")
  assert(coverage:GetAttribute("ClientGrassAllocated")<=96,"Mobile animation budget exceeded")
  local visible=0 for _,patch in ipairs(field:GetChildren()) do if patch.LocalTransparencyModifier<.5 then visible+=1 end end
  assert(visible+#coverage:GetChildren()==field:GetAttribute("PatchCount"),"Full island coverage lost while pooling")
  assert(visible>0,"All distant coverage disappeared")
 end
 settle()
 local far=field:GetChildren()[#field:GetChildren()]
 root.Position=far:GetAttribute("GroundPosition")+Vector3.new(0,3,0)
 settle()
 return {ok=true,fullIslandVisible=true,mobileAnimationCap=coverage:GetAttribute("ClientGrassAllocated"),patches=field:GetAttribute("PatchCount"),movementKeepsCoverage=true}
end,debug.traceback)
heartbeat:Destroy() changed:Destroy() added:Disconnect()
for model in pairs(allocated) do model:Destroy() end
for _,patch in ipairs(field:GetChildren()) do patch.LocalTransparencyModifier=0 end
for _,name in ipairs({"InitialGrassReady","ClientGrassPlaced","ClientGrassAllocated"}) do coverage:SetAttribute(name,nil) end
char:Destroy()
assert(ok,result)
return result
