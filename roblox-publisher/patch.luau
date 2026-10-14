assert(game.PlaceVersion==91)
local roots={}for _,name in ipairs({"Workspace","ReplicatedStorage","ServerScriptService","StarterPlayer","StarterGui","StarterPack","ReplicatedFirst","Lighting","SoundService","MaterialService","Teams","TextChatService"})do roots[#roots+1]=game:GetService(name)end
local b=game:GetService("SerializationService"):SerializeInstancesAsync(roots)
return{readOnly=true,exportOnly=true,exportSize=buffer.len(b),binaryPlaceBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(b))}
