assert(game.PlaceVersion==92)game:GetService("ServerStorage")
local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
local output={readOnly=true,version=game.PlaceVersion,roots={},nativeTerrain=buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})))}
local function vec(p)return{p.X,p.Y,p.Z}end
for _,entry in ipairs(runtime.ActualRootContacts:GetChildren())do local m=entry.Value if m and m:IsDescendantOf(world)and #output.roots<7 then
 local cf=m:GetPivot()local actual=m:GetAttribute("ActualRootPoint")local h=workspace:Raycast(actual+Vector3.yAxis*20,Vector3.yAxis*-40,rp)
 local point=entry:FindFirstChildOfClass("Vector3Value")local predicted=cf:PointToWorldSpace(point.Value)
 local row={name=m.Name,pivot=vec(cf.Position),actualRoot=vec(actual),actualFloor=h and h.Position.Y,predicted=vec(predicted)}
 local real={}
 for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")and p.Name:lower():find("trunk",1,true)then p.CanQuery=true real[#real+1]=p end end
 if #real>0 then local own=RaycastParams.new()own.FilterType=Enum.RaycastFilterType.Include own.FilterDescendantsInstances=real task.wait(.02)
 local hit=workspace:Raycast(Vector3.new(actual.X,actual.Y-10,actual.Z),Vector3.yAxis*50,own)row.rayRoot=hit and vec(hit.Position)
 end output.roots[#output.roots+1]=row
end end return output