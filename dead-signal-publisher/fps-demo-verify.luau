local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
local luau=require('@lune/luau')
local bytes=fs.readFile('/tmp/fps-system-demo-source')
local dm=R.deserializePlace(bytes)
assert(dm and dm:IsA('DataModel'),'Asset did not deserialize as a complete Roblox place')
local counts={}
local topLevel={}
local scripts={}
local suspicious={}
local sourceBytes=0
for _,service in ipairs(dm:GetChildren()) do
 table.insert(topLevel,service.Name..' ['..service.ClassName..']')
end
table.sort(topLevel)
for _,object in ipairs(dm:GetDescendants()) do
 counts[object.ClassName]=(counts[object.ClassName] or 0)+1
 if object:IsA('LuaSourceContainer') then
  local source=object.Source
  sourceBytes+=#source
  local ok,err=pcall(function() return luau.load(source,{debugName=object:GetFullName()}) end)
  assert(ok,'Luau compile failed in '..object:GetFullName()..': '..tostring(err))
  for _,pattern in ipairs({'loadstring%s*%(','HttpService:GetAsync','HttpService:PostAsync','require%s*%(%s*%d+','getfenv%s*%(','setfenv%s*%(','InsertService:LoadAsset'}) do
   if source:find(pattern) then table.insert(suspicious,{path=object:GetFullName(),pattern=pattern}) end
  end
  table.insert(scripts,object:GetFullName()..':'..#source)
 end
end
table.sort(scripts)
assert(#dm:GetDescendants()==198476,'Downloaded place instance count changed from the audited asset')
assert(#scripts==236,'Downloaded place script count changed from the audited asset')
assert(counts.MeshPart==1629 and counts.Part==1648,'Downloaded place geometry changed from the audited asset')
assert(dm:GetService('Workspace'):FindFirstChild('Map3'),'Requested FPS demo map is missing')
assert(dm:GetService('ServerScriptService'):FindFirstChild('Weapons'),'Requested weapon system is missing')
assert(#suspicious==0,'Source contains unexpected dynamic execution, network, asset loading or numeric require')
local summary={containerType='Place',descendantCount=#dm:GetDescendants(),classCounts=counts,topLevel=topLevel,scriptCount=#scripts,scriptBytes=sourceBytes,scripts=scripts,suspiciousPatterns=suspicious}
print(serde.encode('json',summary))
