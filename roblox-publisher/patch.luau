assert(game.PlaceVersion==91)
local S=game:GetService("SerializationService")local out={readOnly=true}
local xml='<roblox version="4"><Item class="Terrain" referent="T"><Properties><string name="Name">Terrain</string><bool name="Decoration">true</bool><float name="GrassLength">0.45</float></Properties></Item></roblox>'
local ok,list=pcall(function()return S:DeserializeInstancesAsync(buffer.fromstring(xml))end)
out.deserialize=ok out.error=not ok and tostring(list)or nil
if ok then local t=list[1]out.class=t.ClassName
 local serial=S:SerializeInstancesAsync({t})out.copyBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(serial))
 local parentOK,err=pcall(function()t.Parent=Instance.new("WorldModel",game.ServerStorage)end)out.canParentIsolated=parentOK out.parentError=not parentOK and tostring(err)or nil
 t:Destroy()
end return out