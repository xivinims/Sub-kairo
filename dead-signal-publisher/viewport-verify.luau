local RS=game:GetService('ReplicatedStorage')
local C=require(RS.FalloutConfig)
local UI=require(RS.FalloutUI)
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1')
assert(workspace:GetAttribute('FalloutViewportRevision')=='weapon-clones-v1')
assert(workspace:GetAttribute('FalloutHUDRevision')=='hud-shop-npc-v2')
assert(workspace:GetAttribute('FalloutNametagBuild')=='nametags-v1')
assert(C.MaxPlayers==10 and C.TeamSize==5 and C.RoundSeconds==600 and C.IntermissionSeconds==90)
assert(RS.FalloutItemVisuals:GetAttribute('UseReliableIcons')==nil)
local client=game.StarterPlayer.StarterPlayerScripts.FalloutClient.Source
assert(client:find('UI.catalogPreview(iconBox,visual,item)',1,true),'Shop must use model clones')
assert(not client:find('UseReliableIcons',1,true) and not client:find('UI.itemIcon(',1,true),'Shop must not hide or replace the models')
local before=protectedSnapshot()
local fixture=Instance.new('Folder')
local checked={}
local guns=0
for _,item in ipairs(C.Catalog) do
 local original=assert(RS.FalloutItemVisuals:FindFirstChild(item.id),'Missing source model: '..item.id)
 assert(original:IsA('MeshPart') and original.Archivable and original.MeshId~='')
 local sourceCFrame=original.CFrame
 for _,width in ipairs({76,96}) do
  local holder=Instance.new('Frame');holder.Size=UDim2.fromOffset(width,width/1.17);holder.Parent=fixture
  local viewport,clone=UI.catalogPreview(holder,original,item)
  assert(viewport.Visible and viewport.CurrentCamera and viewport:GetAttribute('SourceItemId')==item.id)
  assert(not holder:FindFirstChild('ItemIcon'))
  assert(clone~=original and clone.Parent:IsA('WorldModel') and clone.Parent.Parent==viewport)
  assert(clone.MeshId==original.MeshId and clone.TextureID==original.TextureID and clone.Size==original.Size)
  assert(clone.Anchored and not clone.CanCollide and clone.Transparency==0 and clone.LocalTransparencyModifier==0)
  local camera=viewport.CurrentCamera
  local tan=math.tan(math.rad(camera.FieldOfView/2));local aspect=1.17
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local point=camera.CFrame:PointToObjectSpace(clone.CFrame:PointToWorldSpace(Vector3.new(x*clone.Size.X/2,y*clone.Size.Y/2,z*clone.Size.Z/2)))
   assert(-point.Z>.05 and math.abs(point.X)<(-point.Z*tan*aspect) and math.abs(point.Y)<(-point.Z*tan),'Cropped preview: '..item.id)
  end end end
  holder:Destroy()
 end
 assert(original.Parent==RS.FalloutItemVisuals and original.CFrame==sourceCFrame,'Source weapon mutated')
 if item.kind=='Gun' then guns+=1 end
 table.insert(checked,item.id)
end
fixture:Destroy()
assert(#checked==14 and guns==8)
assert(protectedSnapshot()==before,'Preview creation changed game content')
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,revision='weapon-clones-v1',preserved=before,items=checked,guns=guns,previewSizes={76,96},clonesVerified=true,cameraBoundsVerified=true,clientRenderingVerified=false})
