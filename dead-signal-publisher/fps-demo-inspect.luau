local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
local path='/tmp/fps-system-demo-source'
local bytes=fs.readFile(path)
local ok,place=pcall(function() return R.deserializePlace(bytes) end)
local containerType='Place'
if not ok then
  local modelOk,models=pcall(function() return R.deserializeModel(bytes) end)
  if not modelOk then error('Downloaded asset is neither a readable Roblox place nor model: '..tostring(place)) end
  containerType='Model'
  place=R.Instance.new('DataModel')
  local workspace=place:GetService('Workspace')
  for _,model in ipairs(models) do model.Parent=workspace end
end
local counts={}
local top={}
local scripts={}
local suspicious={}
local function inspect(root)
  if root:IsA('DataModel') then
    for _,serviceName in ipairs({'Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterGui','StarterPlayer','Lighting','SoundService'}) do
      local service=root:GetService(serviceName)
      if service then
        counts['Service:'..serviceName]=1
        for _,child in ipairs(service:GetChildren()) do
          if #top<100 then table.insert(top,serviceName..'/'..child.Name..' ['..child.ClassName..']') end
        end
      end
    end
  else
    for _,child in ipairs(root:GetChildren()) do
      if #top<100 then table.insert(top,child.Name..' ['..child.ClassName..']') end
    end
  end
  local descendants=root:GetDescendants()
  for _,item in ipairs(descendants) do
    counts[item.ClassName]=(counts[item.ClassName] or 0)+1
    if item:IsA('LuaSourceContainer') then
      local source=''
      pcall(function() source=item.Source end)
      local record={path=item:GetFullName(),class=item.ClassName,length=#source}
      table.insert(scripts,record)
      local patterns={'loadstring%s*%(','HttpService:GetAsync','HttpService:PostAsync','require%s*%(%s*%d+','getfenv%s*%(','setfenv%s*%(','InsertService:LoadAsset','TeleportService:'}
      for _,pattern in ipairs(patterns) do
        if source:find(pattern) then
          table.insert(suspicious,{path=record.path,pattern=pattern})
        end
      end
    end
  end
end
inspect(place)
local result={containerType=containerType,descendantCount=#place:GetDescendants(),classCounts=counts,topLevel=top,scripts=scripts,suspiciousPatterns=suspicious}
return serde.encode('json',result)
