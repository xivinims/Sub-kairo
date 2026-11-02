local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau');local J=require('@lune/serde')
local game=R.deserializePlace(fs.readFile('water-rpg/live-before-menu.rbxl'))
local function snapshot()
 local counts={};local outfits={};local position=R.Vector3.zero
 for _,x in ipairs(game.Workspace:GetDescendants()) do
  counts[x.ClassName]=(counts[x.ClassName] or 0)+1
  if x:IsA('BasePart') and not x:IsA('Terrain') then position+=x.CFrame.Position end
 end
 for _,n in ipairs(game.Workspace.Residents:GetChildren()) do table.insert(outfits,n.Name..':'..n:GetAttribute('ExpectedShirt')..':'..n:GetAttribute('ExpectedPants')) end
 table.sort(outfits)
 return J.encode('json',{counts=counts,position={position.X,position.Y,position.Z},outfits=outfits})
end
local before=snapshot()
local preserved={}
for _,path in ipairs({'ServerScriptService','ReplicatedStorage'}) do
 for _,x in ipairs(game:GetService(path):GetDescendants()) do
  if x:IsA('LuaSourceContainer') then preserved[x:GetFullName()]=x.Source end
 end
end
local target=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('WaterRPGClient')
assert(target and target:IsA('LocalScript'),'Live RPG client missing')
local code=fs.readFile('water-rpg/src/Client.client.lua');luau.load(code,{debugName='WaterRPGClient'});target.Source=code
local m=game.ReplicatedStorage.WaterRPG:FindFirstChild('MenuScene')
if not m then m=R.Instance.new('ModuleScript');m.Name='MenuScene';m.Parent=game.ReplicatedStorage.WaterRPG end
m.Source=fs.readFile('water-rpg/src/MenuScene.lua');luau.load(m.Source,{debugName='MenuScene'})
assert(snapshot()==before,'Menu patch changed world geometry, positions or outfits')
for _,x in ipairs(game:GetDescendants()) do
 if x:IsA('LuaSourceContainer') and preserved[x:GetFullName()] then assert(x.Source==preserved[x:GetFullName()],'Non-menu source changed: '..x:GetFullName()) end
end
local ability=game.StarterPlayer.StarterPlayerScripts.PlayerAbilities
assert(ability and ability:IsA('LocalScript'),'Live abilities missing')
local abilityCode=fs.readFile('water-rpg/src/Abilities.client.lua');luau.load(abilityCode,{debugName='PlayerAbilities'});ability.Source=abilityCode
game.Workspace:SetAttribute('ControlsRevision','right-circles-jump-safe-v1')
game.Workspace:SetAttribute('MenuRevision','reference-3d-transitions-v2')
fs.writeFile('water-rpg/menu-patched.rbxl',R.serializePlace(game))
print('Targeted menu patch: geometry, resident outfits, server gameplay preserved; circular action client updated')
