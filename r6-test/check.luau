local fs=require("@lune/fs")
local R=require("@lune/roblox")
local S=require("@lune/serde")
local L=require("@lune/luau")
local g=R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local m=S.decode("json",fs.readFile("r6-test/animation-manifest.json"))
assert(g.Workspace:GetAttribute("R6TestBuild")=="r6-chakra-wallwalk-v8")
assert(g.Workspace:GetAttribute("R6ChakraWallWalk")==true)
assert(m.source=="WallWalkNarutoV1(5).rbxl")
local sc=g.StarterPlayer.StarterCharacterScripts
assert(#sc:GetChildren()==2 and sc:FindFirstChild("Animate") and sc:FindFirstChild("ChakraWallWalk"))
assert(sc.Animate.Source and sc.Animate.R6 and sc.Animate.Controller)
assert(not sc.ChakraWallWalk.Disabled)
assert(sc.ChakraWallWalk.Source:find('SetTitle("ToggleChakraFeet"',1,true))
assert(sc.ChakraWallWalk.Source:find('Enum.KeyCode.B',1,true))
assert(not sc:FindFirstChild("Wallrun") and not sc:FindFirstChild("R6Locomotion"))
local ps=g.StarterPlayer.StarterPlayerScripts
assert(#ps:GetChildren()==2 and ps.RbxCharacterSounds and ps.PlayerScriptsLoader)
assert(ps.PlayerScriptsLoader.Loaded.Value==true and ps.PlayerScriptsLoader.Disabled)
assert(g.ReplicatedStorage.GravityController and g.ReplicatedStorage.DrawClass and g.ReplicatedStorage.VFX.ChakraFeet)
for name, hash in pairs(m.originalSHA256) do
 if name~="WallWalk" then
  local src=(name=="Animate" and sc.Animate)
   or (name=="RbxCharacterSounds" and ps.RbxCharacterSounds)
   or g.ReplicatedStorage:FindFirstChild(name)
  assert(src and S.hash("sha256",src.Source)==hash,"Original Naruto script changed: "..name)
 end
end
local count=0
for _,obj in ipairs(g:GetDescendants()) do
 if obj:IsA("LuaSourceContainer") then L.compile(obj.Source);count+=1 end
end
assert(#g.ServerScriptService:GetChildren()==1 and g.ServerScriptService.R6AvatarServer)
assert(#g.StarterGui:GetChildren()==0 and #g.StarterPack:GetChildren()==0)
print(S.encode("json",{ok=true,build=m.build,checked=count,chakraFeet=true,
 playerCharacterScripts=2,otherPacksRemoved=true,touchButton=true},true))
