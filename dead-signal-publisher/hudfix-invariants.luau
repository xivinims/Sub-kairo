local function protectedSnapshot()
 local rows={}
 local excluded={['Workspace.Shopkeeper']=true,['ReplicatedStorage.FalloutUI']=true,['ServerScriptService.FalloutRuntime.ShopkeeperLayout']=true,['ServerScriptService.FalloutRuntime.FrozenAvatar']=true,['ReplicatedStorage.LobbyHealthTemplate']=true}
 local changedSource={['ServerScriptService.FalloutRuntime.Profiles']=true,['ServerScriptService.FalloutRuntime.Server']=true,['StarterPlayer.StarterPlayerScripts.FalloutClient']=true}
 local function ignored(item)
  local current=item
  while current and current~=game do if excluded[current:GetFullName()] then return true end;current=current.Parent end
  return false
 end
 for _,serviceName in ipairs({'Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterPlayer','StarterGui','StarterPack','Teams','Lighting'}) do
  for _,item in ipairs(game:GetService(serviceName):GetDescendants()) do
   if not ignored(item) then
    local path=item:GetFullName();local row=item.ClassName..'|'..path
    if item:IsA('BasePart') then row..='|'..tostring(item.CFrame)..'|'..tostring(item.Size)..'|'..tostring(item.Color)..'|'..tostring(item.Material) end
    if item:IsA('LuaSourceContainer') and not changedSource[path] then row..='|'..item.Source end
    table.insert(rows,row)
   end
  end
 end
 table.sort(rows)
 local hash=0;for _,row in ipairs(rows)do for i=1,#row do hash=(hash*31+string.byte(row,i))%4294967296 end;hash=(hash*31+10)%4294967296 end
 return tostring(#rows)..':'..tostring(hash)
end
