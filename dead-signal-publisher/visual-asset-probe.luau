local source=workspace:FindFirstChild("PoppyTestMap")
assert(source,"Current map missing")
local r={version=game.PlaceVersion,doors={},named={},bays={},lights={},meshProbe={},cells={}}
local function round(v) return math.floor(v*100+0.5)/100 end
local function vector(v) return {round(v.X),round(v.Y),round(v.Z)} end
local function rec(d)
 local rx,ry,rz=d.CFrame:ToOrientation()
 return {n=d.Name,p=vector(d.Position),s=vector(d.Size),r=vector(Vector3.new(rx,ry,rz)),c=vector(Vector3.new(d.Color.R,d.Color.G,d.Color.B)),t=round(d.Transparency),collide=d.CanCollide,cls=d.ClassName}
end
local names={}
local sample
for _,d in ipairs(source:GetDescendants()) do
 if d:IsA("BasePart") then
  local n=d.Name:lower()
  names[d.Name]=(names[d.Name] or 0)+1
  if n:find("door") or n:find("gate") or n:find("window") or n:find("entrance") then table.insert(r.doors,rec(d)) end
  if d.Size.Y>3 and d.Size.Y<70 and math.abs(d.Position.Y)<40 and #r.bays<220 then table.insert(r.bays,rec(d)) end
  if not sample and d:IsA("MeshPart") then sample=d end
 elseif d:IsA("Light") then table.insert(r.lights,{name=d.Name,parent=d.Parent.Name}) end
end
for n,count in pairs(names) do table.insert(r.named,{name=n,count=count}) end
table.sort(r.named,function(a,b) return a.count>b.count end)
if sample then
 local ok,mesh=pcall(function() return game:GetService("AssetService"):CreateEditableMeshAsync(Content.fromUri(sample.MeshId)) end)
 r.meshProbe={ok=ok,part=sample.Name,meshId=sample.MeshId,result=ok and #mesh:GetVertices() or tostring(mesh)}
 if ok then mesh:Destroy() end
end
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={source}; params.RespectCanCollide=true
for x=-550,550,20 do
 for z=-600,500,20 do
  local hit=workspace:Raycast(Vector3.new(x,8,z),Vector3.new(0,-17,0),params)
  if hit and hit.Normal.Y>0.85 then
   local block=workspace:Blockcast(CFrame.new(hit.Position+Vector3.new(0,0.3,0)),Vector3.new(2.6,0.2,2.6),Vector3.new(0,5.8,0),params)
   if not block then table.insert(r.cells,{x,round(hit.Position.Y),z}) end
  end
 end
end
return game:GetService("HttpService"):JSONEncode(r)
