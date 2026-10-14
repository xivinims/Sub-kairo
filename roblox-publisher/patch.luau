assert(game.PlaceVersion==91)
local S=game:GetService("SerializationService")
local roots={}for _,name in ipairs({"Workspace","ReplicatedStorage","ServerScriptService","StarterPlayer","StarterGui","StarterPack","ReplicatedFirst","Lighting","SoundService","MaterialService","Teams","TextChatService"})do roots[#roots+1]=game:GetService(name)end
local ok,b=pcall(function()return S:SerializeInstancesAsync(roots)end)
return{readOnly=true,serializationOK=ok,size=ok and buffer.len(b)or tostring(b),header=ok and buffer.tostring(game:GetService("EncodingService"):Base64Encode(buffer.fromstring(buffer.readstring(b,0,math.min(128,buffer.len(b))))))or nil,streamingMin=workspace.StreamingMinRadius,streamingTarget=workspace.StreamingTargetRadius}
