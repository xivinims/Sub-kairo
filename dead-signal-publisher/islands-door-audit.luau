local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'))
for _,d in ipairs(dm:GetService('Workspace'):GetDescendants()) do
 local n=d.Name:lower()
 if n:find('car',1,true) and not n:find('card',1,true) and not n:find('carpet',1,true) or n:find('vehicle',1,true) or n:find('crash',1,true) then
 print('CAR_AUDIT '..J.encode('json',{path=d:GetFullName(),class=d.ClassName}))
 end
end
local sp=dm:GetService('StarterPlayer')
for _,n in ipairs({'CharacterJumpHeight','CharacterJumpPower','CharacterUseJumpPower','CharacterWalkSpeed'}) do local ok,v=pcall(function() return sp[n] end);print(n..' '..tostring(ok and v or 'default')) end
