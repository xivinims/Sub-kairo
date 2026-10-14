assert(game.PlaceVersion==91)local S=game:GetService("SerializationService")local report={readOnly=true,services={}}
for _,name in ipairs({"Workspace","ReplicatedStorage","ServerScriptService","StarterPlayer","StarterGui","Lighting"})do
 local service=game:GetService(name)local old=service.Archivable service.Archivable=true
 local ok,b=pcall(function()return S:SerializeInstancesAsync({service})end)report.services[#report.services+1]={name=name,archivable=old,ok=ok,size=ok and buffer.len(b)or tostring(b)}service.Archivable=old
end
return report
