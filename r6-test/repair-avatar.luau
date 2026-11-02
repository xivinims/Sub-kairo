-- v8: Chakra feet wall walking from the user's WallWalkNarutoV1(5).rbxl
-- This upload is binary-identical to WallWalkNarutoV1(4).rbxl. Reuse the
-- intact Naruto originals archived by the prior R6 test build, not any
-- animation bank, generic wallrun or other unrelated uploaded packages.
local fs = require("@lune/fs")
local R = require("@lune/roblox")
local S = require("@lune/serde")
local L = require("@lune/luau")
local place = R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local original = R.deserializePlace(fs.readFile("r6-test/naruto-archive-v6.rbxl"))
local archived = original.ServerStorage:FindFirstChild("StudioPacks")
assert(archived, "Missing preserved original packs in v6")
local naruto = archived:FindFirstChild("WallWalkNaruto_R6")
assert(naruto, "Naruto original was not preserved")
assert(place.Workspace:GetAttribute("R6TestBuild") == "r6-original-wallrun-only-v7"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-chakra-wallwalk-v8",
    "Wrong private R6 test version")

local function find(root, name, kind)
    local object = root:FindFirstChild(name, true)
    assert(object and (not kind or object:IsA(kind)),
        "Naruto original missing: " .. name)
    return object
end
local sourceWall = find(naruto.StarterPlayer, "WallWalk", "LocalScript")
local sourceAnimate = find(naruto.StarterPlayer, "Animate", "LocalScript")
local sourceSound = find(naruto.StarterPlayer, "RbxCharacterSounds", "LocalScript")
local sourceGravity = find(naruto.ReplicatedStorage, "GravityController", "ModuleScript")
local sourceDraw = find(naruto.ReplicatedStorage, "DrawClass", "ModuleScript")
local sourceVfx = find(naruto.ReplicatedStorage, "VFX", "Folder")
local expected = {
 WallWalk = "5d41e96a5dd7393a2d238e2726022371125f72db7929586708c54355135016ca",
 GravityController = "3ff2b6d8a425f1ef61b2ee84ddd138035d9d75acb706c5a830ce097f92129f3e",
 DrawClass = "11d6dc3209b17406cf915c505b53e292c5b3b7595de84eaf8fe7426027af8d88",
 RbxCharacterSounds = "eced77a0fe96ffd1fc5cb0914718434c12c61c5bcf9be457f13e7b00453be233",
 Animate = "255cc6c9c8144b8962851a4ab0ab9aa80e415741afc5dbdaaecf5e6678ffe03d",
}
for name, obj in pairs({
 WallWalk = sourceWall, GravityController = sourceGravity,
 DrawClass = sourceDraw, RbxCharacterSounds = sourceSound, Animate = sourceAnimate,
}) do
 assert(S.hash("sha256", obj.Source) == expected[name],
    "Different source from the actual uploaded Naruto file: " .. name)
end
local playerScripts = place.StarterPlayer.StarterPlayerScripts
local characterScripts = place.StarterPlayer.StarterCharacterScripts
local rep = place.ReplicatedStorage
characterScripts:ClearAllChildren()
playerScripts:ClearAllChildren()
rep:ClearAllChildren()
local function install(object, parent)
    local clone = object:Clone()
    clone.Parent = parent
    return clone
end
local animator = install(sourceAnimate, characterScripts)
animator.Disabled = false
-- The real WallWalk script is INSIDE the player R6 model.
local walker = install(sourceWall, characterScripts)
walker.Name = "ChakraWallWalk"
local originalWallSource = walker.Source
-- Mobile support changes only the ActionBinding: original B key still works.
local needle = 'end,\n\tfalse,\n\tEnum.KeyCode.B'
assert(originalWallSource:find(needle, 1, true), "Naruto B-key action layout changed")
walker.Source = originalWallSource:gsub('end,\n\tfalse,\n\tEnum.KeyCode.B',
    'end,\n\ttrue,\n\tEnum.KeyCode.B', 1)
walker.Source = walker.Source .. [[

-- Mobile control for the original B chakra toggle.
local CAS = game:GetService("ContextActionService")
CAS:SetTitle("ToggleChakraFeet", "CHAKRA")
CAS:SetPosition("ToggleChakraFeet", UDim2.new(1,-150,1,-300))
]]
L.compile(walker.Source)
walker.Disabled = false

-- Only Naruto walking-on-surfaces dependencies. No old PlayerScriptsLoader
-- camera patch: it relies on 2020 internals removed from modern Roblox.
install(sourceGravity, rep)
install(sourceDraw, rep)
install(sourceVfx, rep)
local sounds = install(sourceSound, playerScripts)
sounds.Disabled = false
local shim = R.Instance.new("LocalScript")
shim.Name = "PlayerScriptsLoader"
shim.Disabled = true
local ready = R.Instance.new("BoolValue")
ready.Name = "Loaded"
ready.Value = true
ready.Parent = shim
shim.Parent = playerScripts

-- Roblox's existing PlayerModule supplies movement/camera on touch and PC.
-- Keep the R6 avatar spawner and only this Naruto ability.
local server = place.ServerScriptService:FindFirstChild("R6AvatarServer")
assert(server and server.Source:find("CreateHumanoidModelFromDescriptionAsync", 1, true))
assert(#place.ServerScriptService:GetChildren() == 1)
place.StarterPack:ClearAllChildren()
place.StarterGui:ClearAllChildren()
place.ServerStorage:ClearAllChildren()
place.Workspace:SetAttribute("R6TestBuild", "r6-chakra-wallwalk-v8")
place.Workspace:SetAttribute("R6OriginalWallrunOnly", false)
place.Workspace:SetAttribute("R6ChakraWallWalk", true)

local manifest = {
 build = "r6-chakra-wallwalk-v8",
 source = "WallWalkNarutoV1(5).rbxl",
 originalSHA256 = expected,
 originalWallWalkSourceSHA256 = S.hash("sha256", originalWallSource),
 playerCharacter = {"Animate", "ChakraWallWalk"},
 playerScripts = {"RbxCharacterSounds", "PlayerScriptsLoader"},
 replicatedDependencies = {"GravityController", "DrawClass", "VFX"},
 mobileChakraButton = true,
 olderWallRunRemoved = true,
 otherPacksExcluded = true,
 note = "Original Naruto wall gravity and ChakraFeet VFX; only BindAction made touch-capable. Classic camera loader replaced with an inert Loaded shim. Visual playtest needed.",
}
fs.writeFile("r6-test/animation-manifest.json", S.encode("json", manifest, true))
fs.writeFile("r6-test/arena.rbxl", R.serializePlace(place))
print("CHAKRA_WALLWALK_SOURCE_OK", #sourceWall.Source, #sourceGravity.Source, #sourceVfx:GetDescendants())
