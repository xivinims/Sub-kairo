assert(game.PlaceVersion==91)
local out={readOnly=true,version=game.PlaceVersion,terrain={},tables={},ruins={},bridges={}}
local ok,value=pcall(function()return workspace.Terrain.Decoration end)out.terrain.decorationReadable=ok out.terrain.decoration=ok and value or tostring(value)
local ok2,b=pcall(function()return game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})end)
out.terrain.serializeOK=ok2 out.terrain.serializedLength=ok2 and buffer.len(b)or tostring(b)
if ok2 then local enc=game:GetService("EncodingService")local good,base64=pcall(function()return enc:Base64Encode(buffer.fromstring(buffer.readstring(b,0,math.min(256,buffer.len(b)))))end)out.terrain.header=good and buffer.tostring(base64)or tostring(base64)end
local xml='<roblox version="4"><Item class="Part" referent="P"><Properties><string name="Name">SerializationProbe</string></Properties></Item></roblox>'
local good,objects=pcall(function()return game:GetService("SerializationService"):DeserializeInstancesAsync(buffer.fromstring(xml))end)out.terrain.xmlDeserialize=good out.terrain.xmlError=not good and tostring(objects)or nil if good then for _,o in ipairs(objects)do o:Destroy()end end
local world=workspace.ForestWorld local C=game:GetService("CollectionService")
for _,p in ipairs(C:GetTagged("TreeWorldTeaPrompt"))do if p:IsDescendantOf(world)then local corner=p.Parent.Parent.Parent local t=corner:FindFirstChild("AntiqueTeaTable")if t then local cf,s=t:GetBoundingBox()out.tables[#out.tables+1]={path=corner:GetFullName(),size={s.X,s.Y,s.Z},scale=t:GetScale(),pivot={t:GetPivot().X,t:GetPivot().Y,t:GetPivot().Z}}end end end
for _,m in ipairs({world.Amenities.ForestRuins,world.Amenities.ForestLandmarks.MossySanctuary,world.Amenities.ForestLandmarks.StoneToriiGlade,world.Amenities.ForestLandmarks.BrokenWatchtower})do local p=m:GetAttribute("Origin")out.ruins[#out.ruins+1]={name=m.Name,origin={p.X,p.Y,p.Z},parts=#m:GetDescendants()}end
for _,m in ipairs(world.Amenities.WoodenBridges:GetChildren())do local a,b=m:GetAttribute("DeckStart"),m:GetAttribute("DeckEnd")out.bridges[#out.bridges+1]={name=m.Name,start={a.X,a.Y,a.Z},finish={b.X,b.Y,b.Z},width=m:GetAttribute("DeckWidth")}end
return out
