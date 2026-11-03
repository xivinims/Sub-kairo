-- Remove campaign mystery triggers and ritual props while preserving the mansion and door/seat interactions.
return function(dm)
 local W=dm:GetService('Workspace')
 local SSS=dm:GetService('ServerScriptService')
 local SP=dm:GetService('StarterPlayer')
 local content=assert(W:FindFirstChild('Content'),'Mystery map Content folder missing')
 local exterior=content:FindFirstChild('Exterior')
 local storyTriggers=exterior and exterior:FindFirstChild('EventTriggers')
 local removedTriggerCount=storyTriggers and #storyTriggers:GetDescendants() or 0
 if storyTriggers then storyTriggers:Destroy() end
 local storm=exterior and exterior:FindFirstChild('Storm')
 local cloudMesh=storm and storm:FindFirstChild('CloudMesh')
 if cloudMesh then cloudMesh:Destroy() end
 for _,d in ipairs(W.Terrain:GetChildren()) do
  if d:IsA('Clouds') then d:Destroy() end
 end
 local removals={}
 for _,d in ipairs(content:GetDescendants()) do
  local name=string.lower(d.Name)
  local path=string.lower(d:GetFullName())
  local insideDoorSensor=path:find('.door_interior_frame_',1,true)~=nil
  local insideSeatClick=path:find('.click_sit.',1,true)~=nil
  local mysteryTrigger=name:find('triggervolume',1,true)~=nil
   or name:find('event_trigger',1,true)~=nil
   or path:find('.eventtriggers.',1,true)~=nil
   or path:find('.event_skyportal.',1,true)~=nil and name:find('trigger',1,true)~=nil
   or path:find('.tree_floating_grp.',1,true)~=nil and name=='trigger'
  if mysteryTrigger and not insideDoorSensor and not insideSeatClick then table.insert(removals,d) end
 end
 for _,d in ipairs(removals) do if d.Parent then d:Destroy();removedTriggerCount+=1 end end
 local ritualRemovals={}
 for _,d in ipairs(content:GetDescendants()) do
  if string.lower(d.Name):find('ritual',1,true) then
   local parent=d.Parent;local nested=false
   while parent and parent~=content do
    if string.lower(parent.Name):find('ritual',1,true) then nested=true;break end
    parent=parent.Parent
   end
   if not nested then table.insert(ritualRemovals,d) end
  end
 end
 local removedRitualCount=0
 for _,d in ipairs(ritualRemovals) do if d.Parent then d:Destroy();removedRitualCount+=1 end end
 local storyServerNames={EventManager=true,MissionsLogic=true,PlayerMissionRespawn=true,GameStateManager=true}
 for _,script in ipairs(SSS:GetDescendants()) do
  if storyServerNames[script.Name] and script:IsA('BaseScript') then
   script.Disabled=true
   script:SetAttribute('DisabledReason','Story objectives and mystery triggers removed by the exploration build')
  end
 end
 local ritualSupport=SSS:FindFirstChild('RitualSupport',true)
 if ritualSupport then ritualSupport:Destroy() end
 local starterScripts=SP:FindFirstChild('StarterPlayerScripts')
 local storyClientNames={EventManagerClient=true,MissionsLogicClient=true,GameStateClient=true,InVolumeChecker=true}
 for _,script in ipairs(starterScripts and starterScripts:GetDescendants() or {}) do
  if storyClientNames[script.Name] and script:IsA('BaseScript') then
   script.Disabled=true
   script:SetAttribute('DisabledReason','Story trigger controller removed by the exploration build')
  end
 end
 local removalsByName={}
 for _,d in ipairs(content:GetDescendants()) do
  local name=string.lower(d.Name)
  local firearm=name:find('weapon',1,true) or name:find('firearm',1,true)
   or name:find('rifle',1,true) or name:find('pistol',1,true)
   or name:find('shotgun',1,true) or name=='gun' or name:find('gunpickup',1,true)
  if firearm or d:IsA('Tool') and not name:find('key',1,true) then
   local parent=d.Parent;local nested=false
   while parent and parent~=content do
    if removalsByName[parent] then nested=true;break end
    parent=parent.Parent
   end
   if not nested then removalsByName[d]=true end
  end
 end
 for d in pairs(removalsByName) do if d.Parent then d:Destroy() end end
 local wrecks={}
 for _,d in ipairs(content:GetDescendants()) do
  local name=string.lower(d.Name)
  if name=='suv_damaged' or name:find('wreck',1,true) then table.insert(wrecks,d) end
 end
 for _,d in ipairs(wrecks) do if d.Parent then d:Destroy() end end
 W:SetAttribute('MysteryStoryTriggersRemoved',true)
 W:SetAttribute('MysteryStoryTriggerRemovalCount',removedTriggerCount)
 W:SetAttribute('MysteryRitualObjectsRemoved',true)
 W:SetAttribute('MysteryRitualRemovalCount',removedRitualCount)
 W:SetAttribute('MysteryCloudRemoved',cloudMesh~=nil)
 W:SetAttribute('MysteryWreckRemoved',true)
 W:SetAttribute('MysteryWeaponsRemoved',true)
end
