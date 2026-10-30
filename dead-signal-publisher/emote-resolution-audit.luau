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
return HttpService:JSONEncode(result)
