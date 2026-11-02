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
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-chakra-wallwalk-v8"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-chakra-r6-motion-v9",
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

-- Probe the actual universe before selecting assets from the user's Boogie R6
-- pack. Unavailable uploaded IDs are NEVER selected as playable motion.
local probed = S.decode("json", fs.readFile("r6-test/animation-probe.json"))
local choices = {
    idle = {102425446560812, 180435571, 180435792},
    walk = {17747141146, 180426354},
    run = {11605590459, 11123175969, 45828430, 1721906652, 15256643328, 11872298900, 17747141146, 180426354},
    jump = {17747185294, 125750702},
    fall = {17747187834, 180436148},
    climb = {11605578996, 180436334},
    sit = {178130996},
}
local animationNames = {
    idle = "Animation1", walk = "WalkAnim", run = "RunAnim",
    jump = "JumpAnim", fall = "FallAnim", climb = "ClimbAnim", sit = "SitAnim",
}
local selected = {}
for mode, candidates in pairs(choices) do
    local usable
    for _, id in ipairs(candidates) do
        local data = probed[tostring(id)]
        if data and data.loaded and data.length and data.length > 0.07 then
            usable = id
            break
        end
    end
    assert(usable, "No usable R6 animation for " .. mode)
    selected[mode] = usable
    local previous = animator:FindFirstChild(mode)
    if previous then previous:Destroy() end
    local folder = R.Instance.new("Folder")
    folder.Name = mode
    folder.Parent = animator
    local animation = R.Instance.new("Animation")
    animation.Name = animationNames[mode]
    animation.AnimationId = "rbxassetid://" .. tostring(usable)
    animation.Parent = folder
end
-- The original Naruto Animate/Controller and GravityController remain installed.
-- Patch only the R6 motion selection: formerly it forced WALK even at run speed,
-- and its unused run entry was literally "run.xml".
local module = animator:FindFirstChild("R6")
assert(module and module:IsA("ModuleScript"))
assert(S.hash("sha256", module.Source)
    == "571a1392e3bab92efc4ac61f3e70df784f8aad2bfb0865d582b841243f7e283b",
    "Unexpected original Naruto R6 module source")
local r6source = module.Source
local oldRun = '{ id = "run.xml", weight = 10 }'
assert(r6source:find(oldRun, 1, true), "Naruto R6 run config changed")
r6source = r6source:gsub('run%.xml', "rbxassetid://" .. tostring(selected.run), 1)
local startMark = "function onRunning(speed)"
local endMark = "\nfunction onDied()"
local startIndex = assert(r6source:find(startMark, 1, true))
local endIndex = assert(r6source:find(endMark, startIndex, true))
local newRunning = [[local runningSpeed = 0
function onRunning(speed)
    runningSpeed = speed
    if speed > 0.01 then
        local mode = speed >= 19 and "run" or "walk"
        playAnimation(mode, 0.13, Humanoid)
        if currentAnimTrack then
            local nominal = mode == "run" and 23 or 14.5
            setAnimationSpeed(math.clamp(speed / nominal, 0.75, 1.85))
        end
        pose = "Running"
    else
        if emoteNames[currentAnim] == nil then
            playAnimation("idle", 0.15, Humanoid)
            pose = "Standing"
        end
    end
end
]]
r6source = r6source:sub(1, startIndex - 1) .. newRunning .. r6source:sub(endIndex)
local oldMove = 'elseif (pose == "Running") then\n\t\tplayAnimation("walk", 0.1, Humanoid)'
assert(r6source:find(oldMove, 1, true), "Naruto movement loop changed")
r6source = r6source:gsub('playAnimation%("walk", 0%.1, Humanoid%)',
    'playAnimation(runningSpeed >= 19 and "run" or "walk", 0.1, Humanoid)', 1)
module.Source = r6source
L.compile(module.Source)

-- ContextActionService only changes WalkSpeed. There is no second animator,
-- no animated GUI catalog, no custom RenderStepped joint manipulation.
local sprint = R.Instance.new("LocalScript")
sprint.Name = "NarutoSprintInput"
sprint.Source = fs.readFile("r6-test/sprint-input.luau")
L.compile(sprint.Source)
sprint.Disabled = false
sprint.Parent = characterScripts

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
place.Workspace:SetAttribute("R6TestBuild", "r6-chakra-r6-motion-v9")
place.Workspace:SetAttribute("R6OriginalWallrunOnly", false)
place.Workspace:SetAttribute("R6ChakraWallWalk", true)
place.Workspace:SetAttribute("R6MotionVerifiedAssets", true)

local manifest = {
 build = "r6-chakra-r6-motion-v9",
 source = "WallWalkNarutoV1(5).rbxl",
 originalSHA256 = expected,
 originalWallWalkSourceSHA256 = S.hash("sha256", originalWallSource),
 playerCharacter = {"Animate", "ChakraWallWalk", "NarutoSprintInput"},
 selectedAnimationIds = selected,
 nativeCandidateMeasurements = probed,
 patchedNarutoR6Motion = true,
 originalNarutoR6SHA256 = "571a1392e3bab92efc4ac61f3e70df784f8aad2bfb0865d582b841243f7e283b",
 playerScripts = {"RbxCharacterSounds", "PlayerScriptsLoader"},
 replicatedDependencies = {"GravityController", "DrawClass", "VFX"},
 mobileChakraButton = true,
 olderWallRunRemoved = true,
 otherPacksExcluded = true,
 note = "Original Naruto chakra gravity and VFX; R6 original motion selector patched to use a separate running track chosen from accessible Boogie assets. Native probe selects accessible idle/walk/run/jump/fall/climb/sit. Minimal mobile sprint speed input, no per-frame motor animations. Visual client playtest pending.",
}
fs.writeFile("r6-test/animation-manifest.json", S.encode("json", manifest, true))
fs.writeFile("r6-test/arena.rbxl", R.serializePlace(place))
print("CHAKRA_R6_ANIMATIONS_OK", S.encode("json", selected))
