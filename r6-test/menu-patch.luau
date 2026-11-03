local fs=require('@lune/fs');local R=require('@lune/roblox');local L=require('@lune/luau')
local g=R.deserializePlace(fs.readFile('r6-test/arena.rbxl'));local src=fs.readFile('r6-test/menu-client.luau');L.compile(src)
local ps=g.StarterPlayer.StarterPlayerScripts;local old=ps:FindFirstChild('DynamicMenu');if old then old:Destroy() end
local s=R.Instance.new('LocalScript');s.Name='DynamicMenu';s.Source=src;s.Parent=ps
local rs=g:GetService('ReplicatedStorage');local oldRig=rs:FindFirstChild('MenuR6Template');if oldRig then oldRig:Destroy() end
local rig=g.StarterPlayer.StarterCharacter:Clone();rig.Name='MenuR6Template';for _,x in ipairs(rig:GetDescendants()) do if x:IsA('LuaSourceContainer') then x:Destroy() end end;rig.Parent=rs
assert(rig.Humanoid.RigType==R.Enum.HumanoidRigType.R6);g.Workspace:SetAttribute('DynamicMenuRevision','r6-camera-menu-v1')
fs.writeFile('r6-test/arena.rbxl',R.serializePlace(g))
