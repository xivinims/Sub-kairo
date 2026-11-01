-- Bake a small static 2D footprint from the actual combat map, never enemy positions.
local map=assert(workspace:FindFirstChild('CombatMap'),'Combat map missing')
local center,size=map:GetBoundingBox()
local minX,minZ=center.Position.X-size.X/2,center.Position.Z-size.Z/2
local candidates={}
for _,part in ipairs(map:GetDescendants()) do
 if part:IsA('BasePart') and part.Transparency<.9 and part.Size.Y>=2 and math.max(part.Size.X,part.Size.Z)>=4 then
  table.insert(candidates,{part=part,area=part.Size.X*part.Size.Z})
 end
end
table.sort(candidates,function(a,b)return a.area>b.area end)
local rects={}
for i=1,math.min(120,#candidates) do
 local p=candidates[i].part
 table.insert(rects,{(p.Position.X-minX)/size.X,(p.Position.Z-minZ)/size.Z,p.Size.X/size.X,p.Size.Z/size.Z,-p.Orientation.Y})
end
assert(size.X>1 and size.Z>1 and #rects>0,'Combat map has no radar footprint')
local old=game.ReplicatedStorage:FindFirstChild('FalloutRadarData');if old then old:Destroy() end
local module=Instance.new('ModuleScript');module.Name='FalloutRadarData'
module.Source="return game:GetService('HttpService'):JSONDecode([==["..game:GetService('HttpService'):JSONEncode({minX=minX,minZ=minZ,width=size.X,depth=size.Z,rects=rects}).."]==])"
module:SetAttribute('Source','Workspace.CombatMap');module.Parent=game.ReplicatedStorage
