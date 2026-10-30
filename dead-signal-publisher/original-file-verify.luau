local fs=require('@lune/fs');local R=require('@lune/roblox');local J=require('@lune/serde')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-verified.rbxl'))
local original=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'));local fps=R.deserializePlace(fs.readFile('/tmp/asset-15864801103.rbxl'))
local W=dm:GetService('Workspace');local SS=dm:GetService('ServerStorage');local RS=dm:GetService('ReplicatedStorage');local SSS=dm:GetService('ServerScriptService')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-menu-swim-v6','Wrong live build')
assert(SS.OriginalWorld.Content.Interior and SS.Corrupt.Grandfather,'Source map hierarchy lost')
assert(not W:FindFirstChild('Content'),'Public menu contains mansion')
assert(dm:GetService('ReplicatedFirst').MenuAvatarClient.Source:find('CreateHumanoidModelFromUserIdAsync',1,true),'Actual player portrait missing')
local sceneSource=dm:GetService('ReplicatedFirst').MenuAvatarClient.Source
assert(sceneSource:find('507784897',1,true),'Roblox swimming animation missing from packaged script')
assert(sceneSource:find('CameraZoom',1,true),'Cinematic zoom not packaged')
assert(sceneSource:find('PassingStone',1,true),'Cinematic foreground/background debris not packaged')
local function resolve(root,path) for _,name in ipairs(path:split('.')) do root=assert(root:FindFirstChild(name),'Missing source path '..path) end;return root end
local exact,patched=0,0
local originals={}
for id,root in pairs({['7902470429']=original,['15864801103']=fps}) do
 originals[id]={}
 for _,d in ipairs(root:GetDescendants()) do if d:IsA('LuaSourceContainer') then local path=d:GetFullName();originals[id][path]=originals[id][path] or {};table.insert(originals[id][path],d.Source) end end
end
local guard="while not workspace:GetAttribute('GameMode') do task.wait(.1) end\nif workspace:GetAttribute('GameMode')~='Match' then return end\n"
for _,d in ipairs(dm:GetDescendants()) do if d:IsA('LuaSourceContainer') and d:GetAttribute('OriginalAsset') then
 local candidates=assert(originals[d:GetAttribute('OriginalAsset')][d:GetAttribute('OriginalPath')],'Source path absent')
 if d:GetAttribute('CompatibilityChange') then patched+=1 else local matched=false;for _,source in ipairs(candidates) do if d.Source==source or d.Source==guard..source then matched=true;break end end;assert(matched,'Unmarked source modification '..d:GetFullName());exact+=1 end
end end
assert(exact>250,'Too few preserved original source bodies')
assert(RS.OriginalStarterGui.HUD.Frame.HeadlampButton and RS.OriginalStarterGui.MainHud.Main.CombatHud,'Source HUD lost')
assert(not SSS.GameStateManager.Disabled and not SSS.Weapons.WeaponsServer.Disabled,'Original runtime not enabled')
print('ORIGINAL EXACT FILE VERIFIED '..J.encode('json',{exactOriginalBodies=exact,markedCompatibilityChanges=patched,sourceMansion='7902470429',sourceFPS='15864801103',menuIsolated=true}))
