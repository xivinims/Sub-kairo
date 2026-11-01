local function protectedSnapshot()
 local rows={}
 local excluded={
  ['ServerScriptService.FalloutRuntime.Progress']=true,
  ['ServerScriptService.FalloutRuntime.Nametags']=true,
  ['ServerScriptService.FalloutRuntime.NametagController']=true,
  ['ServerStorage.FalloutNametagTemplate']=true,
 }
 local function ignored(item)
  local current=item
  while current and current~=game do
   if excluded[current:GetFullName()] then return true end
   current=current.Parent
  end
  return false
 end
 for _,serviceName in ipairs({'Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterPlayer','StarterGui','StarterPack','Teams','Lighting'}) do
  local service=game:GetService(serviceName)
  for _,item in ipairs(service:GetDescendants()) do
   if not ignored(item) then
    local row=item.ClassName..'|'..item:GetFullName()
    if item:IsA('BasePart') then row..='|'..tostring(item.CFrame)..'|'..tostring(item.Size)..'|'..tostring(item.Color)..'|'..tostring(item.Material) end
    if item:IsA('LuaSourceContainer') and item:GetFullName()~='ServerScriptService.FalloutRuntime.Profiles' then row..='|'..item.Source end
    table.insert(rows,row)
   end
  end
 end
 table.sort(rows)
 local hash=0
 for _,row in ipairs(rows) do for i=1,#row do hash=(hash*31+string.byte(row,i))%4294967296 end;hash=(hash*31+10)%4294967296 end
 return tostring(#rows)..':'..tostring(hash)
end
