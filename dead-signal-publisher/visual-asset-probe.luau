assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local AssetService=game:GetService("AssetService")
local report={}
for _,id in ipairs({11961684378,96103787859080,9609111841,8593730677,16551049618,16592756903,120661626985584,16390129962,136978268470872,72028919182927}) do
    local ok,asset=pcall(function() return AssetService:LoadAssetAsync(id) end)
    local entry={id=id,ok=ok,parts={},groups={}}
    if ok then
        -- Never parent untrusted source containers into the DataModel.
        for _,d in ipairs(asset:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("Sound") then d:Destroy() end
        end
        for _,d in ipairs(asset:GetDescendants()) do
            if d:IsA("BasePart") and #entry.parts<90 then
                table.insert(entry.parts,{name=d.Name,parent=d.Parent.Name,size={d.Size.X,d.Size.Y,d.Size.Z},class=d.ClassName})
            elseif d:IsA("Model") and #entry.groups<40 then
                local count=0; for _,p in ipairs(d:GetDescendants()) do if p:IsA("BasePart") then count+=1 end end
                if count>0 then
                    local _,size=d:GetBoundingBox()
                    table.insert(entry.groups,{name=d.Name,parent=d.Parent.Name,parts=count,size={size.X,size.Y,size.Z}})
                end
            end
        end
        asset:Destroy()
    else entry.error=tostring(asset) end
    table.insert(report,entry)
end
return game:GetService("HttpService"):JSONEncode(report)
