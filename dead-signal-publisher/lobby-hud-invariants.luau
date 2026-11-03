local function sourceHash(value)
 local hash=0
 for i=1,#value do hash=(hash*31+string.byte(value,i))%4294967296 end
 return hash
end
local function protectedSnapshot()
 local excluded={
  ['ReplicatedStorage.FalloutUI']=true,
  ['ReplicatedStorage.FalloutHealthUI']=true,
  ['ReplicatedStorage.FalloutCombatHUD']=true,
  ['ReplicatedStorage.FalloutRadarData']=true,
  ['StarterPlayer.StarterPlayerScripts.FalloutClient']=true,
 }
 local function ignored(item)
  while item and item~=game do if excluded[item:GetFullName()] then return true end;item=item.Parent end
  return false
 end
 local rows={}
 for _,serviceName in ipairs({'Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterPlayer','StarterGui','StarterPack','Teams','Lighting'}) do
  for _,item in ipairs(game:GetService(serviceName):GetDescendants()) do
   if not ignored(item) then
    local row=item.ClassName..'|'..item:GetFullName()
    if item:IsA('BasePart') then row..='|'..tostring(item.CFrame)..'|'..tostring(item.Size)..'|'..tostring(item.Color)..'|'..tostring(item.Material)..'|'..tostring(item.Transparency)..'|'..tostring(item.Anchored) end
    if item:IsA('MeshPart') then row..='|'..item.MeshId..'|'..item.TextureID end
    if item:IsA('LuaSourceContainer') then row..='|'..item.Source end
    local attributes={};for key,value in pairs(item:GetAttributes()) do table.insert(attributes,key..'='..tostring(value)) end;table.sort(attributes)
    table.insert(rows,row..'|'..table.concat(attributes,'|'))
   end
  end
 end
 table.sort(rows)
 return tostring(#rows)..':'..tostring(sourceHash(table.concat(rows,'\n')))
end
