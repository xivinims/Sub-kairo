local fs=require('@lune/fs');local R=require('@lune/roblox');local S=require('@lune/serde');local L=require('@lune/luau')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'));local archive=g:GetService('ServerStorage').OriginalSources;local imported=0;local errors={};local rigcount=0
for _,x in ipairs(g:GetDescendants()) do
 if x:IsA('LuaSourceContainer') then
  local ok,err=pcall(L.compile,x.Source);if not ok then table.insert(errors,x:GetFullName()..': '..tostring(err)) end
  if x:GetAttribute('OriginalId') then assert(x.Source==archive[x:GetAttribute('OriginalId')].Source);assert(S.hash('sha256',x.Source)==x:GetAttribute('OriginalSHA256'));imported+=1 end
 elseif x:IsA('Humanoid') then assert(x.RigType==R.Enum.HumanoidRigType.R6);rigcount+=1 end
end
assert(#g.Workspace.TrainingBots:GetChildren()==6);assert(g.StarterPlayer.StarterCharacter:FindFirstChild('Torso'));assert(not g.StarterPlayer.StarterCharacter:FindFirstChild('UpperTorso'))
print(S.encode('json',{imported=imported,rigs=rigcount,compileErrors=errors},true));assert(#errors==0,'Compilation failed')
