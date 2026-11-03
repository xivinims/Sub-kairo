-- Read-only: resolve marketplace emote to its internal Animation.AnimationId.
-- Runs in a temporary Roblox Luau execution task; no persistent edits.
local ITEM_ID=103686359406944
local HttpService=game:GetService('HttpService')
local result={catalogAssetId=ITEM_ID,animations={}}
local MarketplaceService=game:GetService('MarketplaceService')
local infoOk,info=pcall(function() return MarketplaceService:GetProductInfoAsync(ITEM_ID,Enum.InfoType.Asset) end)
if infoOk and type(info)=='table' then
 result.title=info.Name
 result.assetTypeId=info.AssetTypeId
 result.creator=info.Creator and info.Creator.Name or nil
else result.productInfoError=tostring(info) end
local InsertService=game:GetService('InsertService')
local ok,model=pcall(function() return InsertService:LoadAsset(ITEM_ID) end)
result.insertOk=ok
if ok and model then
 result.assetClass=model.ClassName
 for _,object in ipairs(model:GetDescendants()) do
  if object:IsA('Animation') then table.insert(result.animations,{path=object:GetFullName(),name=object.Name,animationId=object.AnimationId}) end
 end
 model:Destroy()
else result.insertError=tostring(model) end
-- Also check playback of the RESOLVED animation on a temporary R15 humanoid.
-- This is a read-only, ephemeral test session, never altering the published game.
if #result.animations>0 then
 local animId=result.animations[1].animationId
 local Players=game:GetService('Players')
 local description=Instance.new('HumanoidDescription')
 local rigOk,rig=pcall(function()
  return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
 end)
 result.rigOk=rigOk
 if rigOk and rig then
  rig.Name='TemporaryEmotePlaybackAudit'
  rig.Parent=workspace
  rig:PivotTo(CFrame.new(0,100000,0))
  local hum=rig:FindFirstChildOfClass('Humanoid')
  local animator=hum and (hum:FindFirstChildOfClass('Animator') or Instance.new('Animator',hum))
  local anim=Instance.new('Animation')
  anim.AnimationId=animId
  if animator then
   local loadOk,track=pcall(function() return animator:LoadAnimation(anim) end)
   result.loadOk=loadOk
   if loadOk and track then
    result.playOk=pcall(function() track:Play(0,1,1) end)
    task.wait(5)
    result.trackLength=track.Length
    result.trackPlaying=track.IsPlaying
    result.timePosition=track.TimePosition
    pcall(function() track:Stop(0) end)
   else result.loadError=tostring(track) end
  else result.loadError='Animator unavailable' end
  rig:Destroy()
 else result.rigError=tostring(rig) end
end
return HttpService:JSONEncode(result)
