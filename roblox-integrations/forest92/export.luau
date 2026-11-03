local E={}
function E.build()
 local roots={}local manifest={}
 for _,name in ipairs({"Workspace","ReplicatedStorage","ServerScriptService","StarterPlayer","StarterGui","StarterPack","ReplicatedFirst","Lighting","SoundService","MaterialService","Teams","TextChatService"})do
  for _,obj in ipairs(game:GetService(name):GetChildren())do
   if obj.Archivable and not obj:IsA("Camera")and obj.Name~="TerrainRegion"then
    roots[#roots+1]=obj manifest[#manifest+1]={name=obj.Name,class=obj.ClassName,service=name}
   end
  end
 end
 local properties={}
 local lists={Workspace={"Gravity","GlobalWind","FallenPartsDestroyHeight"},StarterPlayer={"CameraMinZoomDistance","CameraMaxZoomDistance","CameraMode","CharacterWalkSpeed","CharacterJumpPower","CharacterUseJumpPower","AutoJumpEnabled","EnableMouseLockOption"},Lighting={"LightingStyle","PrioritizeLightingQuality","GlobalShadows","ShadowSoftness","Brightness","ClockTime","GeographicLatitude","Ambient","OutdoorAmbient","EnvironmentDiffuseScale","EnvironmentSpecularScale","ExposureCompensation"},MaterialService={"Use2022Materials"}}
 for service,names in pairs(lists)do for _,name in ipairs(names)do local ok,v=pcall(function()return game:GetService(service)[name]end)
  if ok then local kind=typeof(v)local row={service=service,name=name}
   if kind=="boolean"or kind=="number"then row.kind=kind row.value=v
   elseif kind=="EnumItem"then row.kind="enum"row.value=v.Value
   elseif kind=="Vector3"then row.kind="vector"row.value={v.X,v.Y,v.Z}
   elseif kind=="Color3"then row.kind="color"row.value={v.R,v.G,v.B}end
   if row.kind then properties[#properties+1]=row end
  end
 end end
 local payload=game:GetService("SerializationService"):SerializeInstancesAsync(roots)
 return{binaryPlaceBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(payload)),serviceRoots=manifest,serviceProperties=properties,exportSize=buffer.len(payload)}
end
return E
