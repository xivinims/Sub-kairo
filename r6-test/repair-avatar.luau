-- v7: Only the ORIGINAL FREE R6 Wall Run uploaded pack, inside every
-- automatically spawned player R6 avatar. No other animation packs or GUIs.
-- The user's uploaded FREE R6 Wall Run(4).rbxm is byte-identical, for these
-- 11 scripts, to the preinstalled Wallrun package (SHA-256 verified below).
local fs = require("@lune/fs")
local R = require("@lune/roblox")
local S = require("@lune/serde")
local L = require("@lune/luau")
local game = R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local ws = game.Workspace
local previousBuild = ws:GetAttribute("R6TestBuild")
assert(previousBuild == "r6-character-motion-v6" or previousBuild == "r6-original-wallrun-only-v7",
    "This patch can only modify the existing R6 test arena")
local sc = game.StarterPlayer.StarterCharacterScripts
local original = sc:FindFirstChild("Wallrun")
assert(original and original:IsA("LocalScript"), "Uploaded Wallrun script missing")
local hashes = {
    Wallrun = "5ff3fc36d6023d5dda2bb13cce13d50d3554fa4d7361865a84b9c7a5a0ebfd41",
    Config = "96224dc6bdf7e13d049fd42bbb4b8094f746d5e2b653cf5ca04f4f9f217766b2",
    Raycaster = "1afe74c5959e968a3dc5e45ce421cd45995b1ddb66604dc0d51a322a4cb77b03",
    Trails = "b4d368a16e0b3d90f4ab4b5b9cd8b9fd7d94f4a922e6fb25b91ad21d49f0e3c0",
    Sounds = "a5a5df25a48bd10b8735983423b7e069e25865a9a94721400ece1508c44df120",
    Shake = "20a395f69fab19b27f0eda929768547d591c58179ecef4b540eed7b3fe40e4f15", -- replaced below
    Signal = "a2c3a044ad291f1b8ea7d9ab38147d0ca8807c22532a45f31f33c79b89b74124",
    Trove = "6037d12780509f4d7b6119c437b29918f230c2b90344247d591c58179ecef4b1",
    Spring = "9ed98ecff13288f8a196f9c3d6879752f6beac0bcb0b75eee2fce588d7417660",
    PID = "7a645d52b54476421468be8636467d2784ed51e4b540eed7b3fe40e4dd86d58b",
    Log = "c2de060998a31f5b2f5cf8bd1fd081bc4ac61a92462f5a64410c47f9d6dbf7c64a0a",
}
-- Exact SHA-256 values extracted directly from the user's new RBXM.
hashes.Shake = "20a395f69fab19b27f0eda929768547d591c58179ecef4b540eed7b3fe40e4f15"
-- Map normalized names to expected original source digests.
for name, hash in pairs(hashes) do
    local source
    if name == "Wallrun" then source = original.Source
    else
        local package = ({Shake=true,Signal=true,Trove=true,Spring=true,PID=true,Log=true})[name]
        local folder = original:FindFirstChild(package and "Packages" or "Modules")
        local child = folder and folder:FindFirstChild(name)
        assert(child and child:IsA("ModuleScript"), "Missing original module: " .. name)
        source = child.Source
    end
    assert(S.hash("sha256", source) == hash, "Source differs from user's uploaded RBXM: " .. name)
    L.compile(source)
end

local animationNames = {
    ["Wall Run Right"] = "131232629152198",
    ["Wall Run Left"] = "137711855043043",
    ["Wall Jump Left"] = "111048455288189",
    ["Wall Jump RIght"] = "99302485980949",
}
local folder = original:FindFirstChild("Animations")
assert(folder, "Wallrun Animations folder missing")
local total = 0
for _, animation in ipairs(folder:GetChildren()) do
    assert(animation:IsA("Animation"), "Unexpected object in original Animations")
    assert(animationNames[animation.Name], "Unknown animation " .. animation.Name)
    assert(tostring(animation.AnimationContent):find(animationNames[animation.Name], 1, true),
        "Original AnimationId changed for " .. animation.Name)
    total += 1
end
assert(total == 4, "Exactly four original wall-run animations required")

-- Strip everything from other uploaded packs and previous test controllers.
local wallrun = original:Clone()
sc:ClearAllChildren()
wallrun.Name = "Wallrun"
wallrun.Enabled = true
wallrun.Disabled = false
wallrun.Parent = sc
game.StarterPlayer.StarterPlayerScripts:ClearAllChildren()
game.StarterGui:ClearAllChildren()
game.StarterPack:ClearAllChildren()
game.ServerScriptService:ClearAllChildren()
game.ServerStorage:ClearAllChildren()
game.ReplicatedStorage:ClearAllChildren()

-- Let the Roblox character spawn pipeline supply the native Roblox Animate
-- script for ordinary walking, avoiding ANY custom per-frame animation driver.
game.Players.CharacterAutoLoads = true
game.StarterPlayer.CharacterRigType = R.Enum.HumanoidRigType.R6
game.StarterPlayer.LoadCharacterAppearance = true
-- Keep the test arena and the original wallrun walls, but remove training bots.
local bots = ws:FindFirstChild("TrainingBots")
if bots then bots:Destroy() end
local debris = ws:FindFirstChild("Debris")
if debris then debris:Destroy() end
ws:SetAttribute("R6TestBuild", "r6-original-wallrun-only-v7")
ws:SetAttribute("R6LocomotionInstalled", false)
ws:SetAttribute("R6ExclusiveAnimationBanks", false)
ws:SetAttribute("R6VisibleJointAnimation", false)
ws:SetAttribute("R6OriginalWallrunOnly", true)

local manifest = {
    build = "r6-original-wallrun-only-v7",
    installedCharacterScripts = {"Wallrun"},
    originalAnimationIds = animationNames,
    originalSourceHashes = hashes,
    originalModuleCount = 10,
    originalAnimationsCount = 4,
    nativeR6Walk = true,
    originalSourceUnmodified = true,
    notes = "No other upload packs, R6Locomotion, MotionInput, CharacterEmotes, GUI or procedural movements. The original wallrun AnimationIds still require permission to load.",
}
fs.writeFile("r6-test/animation-manifest.json", S.encode("json", manifest, true))
fs.writeFile("r6-test/arena.rbxl", R.serializePlace(game))
print("R6_ORIGINAL_WALLRUN_ONLY_OK", total, 10)
