assert(game.PlaceVersion==90)
local out={readOnly=true,audio={}}
for _,id in ipairs({9116971475,9114518779,9112854613,9116279358,177940963,178190837})do
 local s=Instance.new("Sound")s.SoundId="rbxassetid://"..id s.Parent=workspace
 local ok,err=pcall(function()game:GetService("ContentProvider"):PreloadAsync({s})end)
 local infoOK,info=pcall(function()return game:GetService("MarketplaceService"):GetProductInfo(id)end)
 out.audio[#out.audio+1]={id=id,loaded=s.IsLoaded,length=s.TimeLength,name=infoOK and info.Name or "",ok=ok,error=not ok and tostring(err)or nil}s:Destroy()
end return out