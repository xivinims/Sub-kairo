-- Static test of the original Wallrun-only character build.
local fs=require("@lune/fs")
local R=require("@lune/roblox")
local S=require("@lune/serde")
local L=require("@lune/luau")
local g=R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local manifest=S.decode("json",fs.readFile("r6-test/animation-manifest.json"))
assert(g.Workspace:GetAttribute("R6TestBuild")=="r6-original-wallrun-only-v7")
assert(g.Workspace:GetAttribute("R6OriginalWallrunOnly")==true)
assert(g.StarterPlayer.CharacterRigType==R.Enum.HumanoidRigType.R6)
assert(g.Players.CharacterAutoLoads==true)
local sc=g.StarterPlayer.StarterCharacterScripts
assert(#sc:GetChildren()==1, "Other animation controllers must be deleted")
local wall=sc:FindFirstChild("Wallrun")
assert(wall and wall:IsA("LocalScript") and not wall.Disabled)
assert(S.hash("sha256",wall.Source)==manifest.originalSourceHashes.Wallrun)
local count=0
for _,obj in ipairs(wall:GetDescendants()) do
 if obj:IsA("ModuleScript") then
  assert(manifest.originalSourceHashes[obj.Name], "Unknown module: "..obj.Name)
  assert(S.hash("sha256",obj.Source)==manifest.originalSourceHashes[obj.Name],
      "Original module changed: "..obj.Name)
  L.compile(obj.Source)
  count+=1
 end
end
L.compile(wall.Source)
assert(count==10 and #wall.Animations:GetChildren()==4)
for name,id in pairs(manifest.originalAnimationIds) do
 local clip=wall.Animations:FindFirstChild(name)
 assert(clip and clip:IsA("Animation"))
 assert(tostring(clip.AnimationContent):find(id,1,true), "Original AnimationId changed")
end
for _,group in ipairs({g.StarterPlayer.StarterPlayerScripts,g.StarterGui,g.StarterPack,
  g.ServerScriptService,g.ServerStorage,g.ReplicatedStorage}) do
 assert(#group:GetChildren()==0, "Other packs still installed: "..group.Name)
end
assert(not g.Workspace:FindFirstChild("TrainingBots"))
assert(#manifest.installedCharacterScripts==1 and manifest.installedCharacterScripts[1]=="Wallrun")
print(S.encode("json",{ok=true,build=manifest.build,characterScripts=1,originalModules=count,
 originalAnimations=4,previousAnimationGUI=false,otherPacksRemoved=true},true))
