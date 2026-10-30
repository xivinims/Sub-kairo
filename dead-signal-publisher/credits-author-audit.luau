-- Read-only attribution audit of content ALREADY present in Still Here.
-- No gameplay edits and no asset imports.
local market=game:GetService('MarketplaceService')
local HttpService=game:GetService('HttpService')
local list={{'Duvall Drive',7902470429},{'Beyond the Dark',7208091524},{'FPS System Demo',15864801103},{'Massive Black Hole audio',9045936046},{'Low Gravity item',103686359406944}}
local out={}
for _,entry in ipairs(list) do
 local ok,info=pcall(function() return market:GetProductInfoAsync(entry[2],Enum.InfoType.Asset) end)
 local row={name=entry[1],assetId=entry[2],ok=ok}
 if ok and type(info)=='table' then
  row.title=info.Name
  row.creatorName=info.Creator and info.Creator.Name or nil
  row.creatorType=info.Creator and tostring(info.Creator.CreatorType) or nil
  row.creatorTargetId=info.Creator and info.Creator.Id or nil
 else row.error=tostring(info) end
 table.insert(out,row)
end
return HttpService:JSONEncode(out)
