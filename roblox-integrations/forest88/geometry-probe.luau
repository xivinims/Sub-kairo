assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==87)
local A=game:GetService("AssetService")
local output={readOnly=true,version=game.PlaceVersion,meshes={},audio={}}
local function v(p)return{p.X,p.Y,p.Z}end
local ids={}
local card=game.ReplicatedStorage.ForestRuntime.SkinnedGrassTemplates.GrassCard.Mesh
local examples={card}
for _,folder in ipairs({workspace.ForestWorld.Decor.Trees,workspace.ForestWorld.Decor.Plants})do
 local seen={}
 for _,m in ipairs(folder:GetChildren())do if not seen[m.Name]then
  seen[m.Name]=true
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")and(#examples<14)then examples[#examples+1]=p break end end
 end end
end
for _,p in ipairs(examples)do
 local r={name=p:GetFullName(),id=p.MeshId,size=v(p.Size)}
 local sizeOk,ms=pcall(function()return p.MeshSize end)if sizeOk then r.meshSize=v(ms)end
 local ok,e=pcall(function()return A:CreateEditableMeshAsync(Content.fromUri(p.MeshId))end)
 if ok and e then
  local verts=e:GetVertices()local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,vid in ipairs(verts)do local pos=e:GetPosition(vid)lo=lo:Min(pos)hi=hi:Max(pos)end
  r.vertices=#verts r.lo=v(lo)r.hi=v(hi)
  r.bindBones={}
  for _,bid in ipairs(e:GetBones())do if #r.bindBones<12 then r.bindBones[#r.bindBones+1]={name=e:GetBoneName(bid),cf={e:GetBoneCFrame(bid):GetComponents()}}end end
  local methods={"GetBones","GetVertexBoneWeights","GetVertexBones"}
  for _,method in ipairs(methods)do local good,res=pcall(function()return e[method](e,verts[1])end)r[method]=good and res or tostring(res)end
  e:Destroy()
 else r.editableError=tostring(e)end
 output.meshes[#output.meshes+1]=r
end
local raw=A:LoadAssetAsync(87377915371959)
output.rawGrass={}
for _,m in ipairs({raw.SkinnedGrass.GrassCard.Models.Model,raw.SkinnedGrass.Studio.Models.Model})do
 local part=m:FindFirstChildOfClass("MeshPart")local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,b in ipairs(part:GetChildren())do if b:IsA("Bone")then lo=lo:Min(b.CFrame.Position)hi=hi:Max(b.CFrame.Position)end end
 local meshSizeOk,ms=pcall(function()return part.MeshSize end)
 output.rawGrass[#output.rawGrass+1]={name=m:GetFullName(),scale=m:GetScale(),partSize=v(part.Size),boneLo=v(lo),boneHi=v(hi),meshSize=meshSizeOk and v(ms)or tostring(ms)}
end
raw:Destroy()
local ok,data=pcall(function()return A:GetAudioMetadataAsync({"rbxassetid://9059051593"})end)
output.audio.metadata=ok and data or tostring(data)
local sound=Instance.new("Sound")sound.SoundId="rbxassetid://9059051593"sound.Volume=.3 sound.Parent=game.SoundService
local statuses={}
local good,err=pcall(function()game:GetService("ContentProvider"):PreloadAsync({sound},function(id,status)statuses[#statuses+1]={id=id,status=tostring(status)}end)end)
output.audio.preload={ok=good,error=good and nil or tostring(err),statuses=statuses,loaded=sound.IsLoaded,length=sound.TimeLength}sound:Destroy()
local params=Instance.new("AudioSearchParams")params.SearchKeyword="yay"
local searchOk,pages=pcall(function()return A:SearchAudioAsync(params)end)
if searchOk then output.audio.yaySearch=pages:GetCurrentPage()else output.audio.searchError=tostring(pages)end
return output
