local function vector(v)return {v.X,v.Y,v.Z}end
local function part(p)
 local r={path=p:GetFullName(),size=vector(p.Size),position=vector(p.Position),rotation={p.CFrame:ToOrientation()},transparency=p.Transparency,anchored=p.Anchored,collide=p.CanCollide}
 if p:IsA('MeshPart') then r.mesh=p.MeshId;r.texture=p.TextureID;r.meshSize=vector(p.MeshSize) end
 return r
end
local result={version=game.PlaceVersion,shop={},npc={},visuals={},clips={}}
local shop=workspace.Lobby.Shop;local cf,size=shop:GetBoundingBox();result.shopBounds={position=vector(cf.Position),size=vector(size)}
for _,p in ipairs(shop:GetDescendants()) do if p:IsA('BasePart') then table.insert(result.shop,part(p)) end end
local npc=workspace.Shopkeeper
result.npc.pivot={npc:GetPivot():GetComponents()};result.npc.parts={};result.npc.joints={};result.npc.attributes=npc:GetAttributes()
for _,p in ipairs(npc:GetDescendants()) do
 if p:IsA('BasePart') then table.insert(result.npc.parts,part(p)) end
 if p:IsA('Motor6D') then table.insert(result.npc.joints,{name=p.Name,part0=p.Part0 and p.Part0.Name,part1=p.Part1 and p.Part1.Name,c0={p.C0:GetComponents()},c1={p.C1:GetComponents()},transform={p.Transform:GetComponents()}}) end
 if p:IsA('Shirt') then result.npc.shirt=p.ShirtTemplate elseif p:IsA('Pants') then result.npc.pants=p.PantsTemplate end
end
result.npc.hipHeight=npc.Humanoid.HipHeight
result.npc.appearance=npc.Humanoid:GetAppliedDescription():GetAccessories(true)
for _,p in ipairs(game.ReplicatedStorage.FalloutItemVisuals:GetChildren()) do
 local r=part(p);r.children={};for _,i in ipairs(p:GetDescendants()) do table.insert(r.children,{name=i.Name,class=i.ClassName}) end
 table.insert(result.visuals,r)
end
for _,sequence in ipairs(game.ReplicatedStorage.FalloutNpcClips:GetChildren()) do
 local clip={name=sequence.Name,poses={},maxTranslations={},duration=0}
 for _,key in ipairs(sequence:GetKeyframes()) do
  clip.duration=math.max(clip.duration,key.Time)
  for _,pose in ipairs(key:GetDescendants()) do if pose:IsA('Pose') then
   clip.maxTranslations[pose.Name]=math.max(clip.maxTranslations[pose.Name] or 0,pose.CFrame.Position.Magnitude)
   if key.Time==0 then table.insert(clip.poses,{name=pose.Name,path=pose:GetFullName(),cframe={pose.CFrame:GetComponents()},weight=pose.Weight}) end
  end end
 end
 table.insert(result.clips,clip)
end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Lobby};params.RespectCanCollide=true
local root=npc.HumanoidRootPart
local hit=workspace:Raycast(root.Position+Vector3.new(0,10,0),Vector3.new(0,-50,0),params)
result.npc.floor=hit and {path=hit.Instance:GetFullName(),position=vector(hit.Position),normal=vector(hit.Normal)} or nil
result.spawn=vector(workspace.FalloutSpawns.Lobby:GetChildren()[1].Position)
local provider=game:GetService('ContentProvider');result.preload={}
local ok,err=pcall(function()provider:PreloadAsync(game.ReplicatedStorage.FalloutItemVisuals:GetChildren(),function(id,status) table.insert(result.preload,{id=id,status=status.Name}) end)end)
result.preloadOk=ok;result.preloadError=not ok and tostring(err) or nil
return game:GetService('HttpService'):JSONEncode(result)
