local function sourceHash(value)
 local hash=0
 for i=1,#value do hash=(hash*31+string.byte(value,i))%4294967296 end
 return hash
end
local function protectedSnapshot()
 local rows={}
 local changedSource={['ReplicatedStorage.FalloutUI']=true,['StarterPlayer.StarterPlayerScripts.FalloutClient']=true}
 for _,serviceName in ipairs({'Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterPlayer','StarterGui','StarterPack','Teams','Lighting'}) do
  for _,item in ipairs(game:GetService(serviceName):GetDescendants()) do
   local path=item:GetFullName();local row=item.ClassName..'|'..path
   if item:IsA('BasePart') then
    row..='|'..tostring(item.CFrame)..'|'..tostring(item.Size)..'|'..tostring(item.Color)..'|'..tostring(item.Material)..'|'..tostring(item.Transparency)..'|'..tostring(item.Anchored)
   end
   if item:IsA('MeshPart') then row..='|'..item.MeshId..'|'..item.TextureID end
   if item:IsA('LuaSourceContainer') and not changedSource[path] then row..='|'..item.Source end
   local attributes={}
   for name,value in pairs(item:GetAttributes()) do
    if not(path=='ReplicatedStorage.FalloutItemVisuals' and name=='UseReliableIcons') then table.insert(attributes,name..'='..tostring(value)) end
   end
   table.sort(attributes);row..='|'..table.concat(attributes,'|')
   table.insert(rows,row)
  end
 end
 table.sort(rows)
 return tostring(#rows)..':'..tostring(sourceHash(table.concat(rows,'\n')))
end
