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
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-chakra-r6-motion-v9"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-chakra-boogie-v10"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-cinematic-menu-npcs-v11"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-natural-climb-optional-chakra-v12"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-combat-animations-v13"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-real-motion-v14"
    or place.Workspace:GetAttribute("R6TestBuild") == "r6-original-best-run-v15",
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
local freshRuns = S.decode("json", fs.readFile("r6-test/forbidden-or-available-run-ids.json"))
for id, result in pairs(freshRuns) do
    if result and result.loaded and result.length and result.length > 0.07 then
        probed[id] = result
    end
end
local choices = {
    idle = {102425446560812, 180435571, 180435792},
    walk = {17747141146, 180426354},
    -- Native R6 run.xml is walk animation. A DIFFERENT R6 sprint gait
    -- will be played by R6PoseController rather than the incompatible R15
    -- Ninja Run 656118852, which has Length>0 but does not pose R6 limbs.
    run = {180426354},
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
-- When Naruto switches chakra on, tell the natural climber to stop.
-- Keep the original gravity system and effects untouched otherwise.
local originalToggle = 'ChakraFeetEnabled = not ChakraFeetEnabled'
assert(walker.Source:find(originalToggle, 1, true), "Original chakra toggle changed")
walker.Source = 'script.Parent:SetAttribute("ChakraActive", false)\n'
    .. walker.Source:gsub(originalToggle,
        originalToggle .. [[

        script.Parent:SetAttribute("ChakraActive", ChakraFeetEnabled)
        ContextActionService:SetTitle("ToggleChakraFeet",
            ChakraFeetEnabled and "CHAKRA ON" or "CHAKRA OFF")]], 1)
walker.Source = walker.Source .. [[

-- Only chakra gets a button; natural wall climbing needs no action button.
local CAS = game:GetService("ContextActionService")
CAS:SetTitle("ToggleChakraFeet", "CHAKRA OFF")
CAS:SetPosition("ToggleChakraFeet", UDim2.new(1,-150,1,-300))
]]
L.compile(walker.Source)
walker.Disabled = false

-- Adapt only the user's supplied R6 climbing branch. The original stamina
-- module is preserved, and the R6 climb animation comes from Naruto Animate.
local autoClimb = R.Instance.new("LocalScript")
autoClimb.Name = "NaturalR6Climb"
autoClimb.Source = fs.readFile("r6-test/natural-climb-r6.luau")
L.compile(autoClimb.Source)
autoClimb.Disabled = false
autoClimb.Parent = characterScripts
local staminaModule = R.Instance.new("ModuleScript")
staminaModule.Name = "StaminaBar"
staminaModule.Source = fs.readFile("r6-test/climb-stamina-original.luau")
L.compile(staminaModule.Source)
staminaModule.Parent = autoClimb

-- R6 fighting animation package: only the actual user-supplied AnimationIds
-- that the Roblox animation probe loaded are inserted as tracks. Everything
-- else has a short local action-only pose fallback instead of misleading IDs.
local combatProbe = S.decode("json", fs.readFile("r6-test/combat-probe.json"))
local combatAnimations = {
    M1_1 = 10469493270, M1_2 = 10469630950,
    M1_3 = 10469639222, M1_4 = 10469643643,
    Block = 10470389827, DodgeFront = 10479335397,
    DodgeBack = 10491993682, Uppercut = 10503381238,
    Downslam = 10470104242, HeavyPunch = 12983333733,
    Barrage = 10466974800, Kick_1 = 2515090838,
    Kick_2 = 13874028312,
}
local combatFolder = R.Instance.new("Folder")
combatFolder.Name = "CombatAnimations"
combatFolder.Parent = characterScripts
local usableCombat, unavailableCombat = {}, {}
for name, id in pairs(combatAnimations) do
    local metadata = combatProbe[tostring(id)]
    if metadata and metadata.loaded and metadata.length and metadata.length > 0.07 then
        local clip = R.Instance.new("Animation")
        clip.Name = name
        clip.AnimationId = "rbxassetid://" .. tostring(id)
        clip:SetAttribute("NativeVerifiedR6", true)
        clip.Parent = combatFolder
        usableCombat[name] = id
    else
        unavailableCombat[name] = id
    end
end
local combatClient = R.Instance.new("LocalScript")
combatClient.Name = "R6CombatInput"
combatClient.Source = fs.readFile("r6-test/combat-client.luau")
L.compile(combatClient.Source)
combatClient.Disabled = false
combatClient.Parent = characterScripts

-- Install the ORIGINAL unmodified KeyframeSequences from the public
-- [Best Run Animations R6] Creator Store model. No rekeyframing, no guessing IDs.
-- Model downloaded read-only through Roblox asset-delivery just before build.
local runArchive = fs.readFile("r6-test/free-r6-run-model.rbxm")
local runArchiveHash = S.hash("sha256", runArchive)
local sourceRunModels = R.deserializeModel(runArchive)
local runFolder = R.Instance.new("Folder")
runFolder.Name = "R6RunSource"
runFolder.Parent = characterScripts
local originalRunCounts = {}
for _, root in ipairs(sourceRunModels) do
    for _, obj in ipairs({root, table.unpack(root:GetDescendants())}) do
        if obj:IsA("KeyframeSequence")
            and (obj.Name == "Run1 [by M0rsDev]"
              or obj.Name == "Run2 [by Gusthabuo777]"
              or obj.Name == "Run3 [by Newb1e27]") then
            local sourceCount = #obj:GetChildren()
            assert(sourceCount > 8, "Original R6 run must have actual keyframes")
            assert(not runFolder:FindFirstChild(obj.Name), "Duplicate R6 run sequence")
            local exactCopy=obj:Clone()
            exactCopy.Parent=runFolder
            assert(#exactCopy:GetChildren()==sourceCount, "Original R6 keyframe count changed")
            originalRunCounts[obj.Name]=sourceCount
        end
    end
end
assert(#runFolder:GetChildren()==3 and originalRunCounts["Run3 [by Newb1e27]"]==17,
    "Public Best Run Animations R6 model content changed; stop instead of altering clips")

-- One locally running true R6 controller, shared between sprint and all
-- fighting actions. It moves the actual six Motor6D joints of the avatar.
-- No extra Animator tracks, no R15 IDs and no other duplicated pose drivers.
local poses=R.Instance.new("LocalScript")
poses.Name="R6PoseController"
poses.Source=fs.readFile("r6-test/r6-pose-controller.luau")
L.compile(poses.Source)
poses.Disabled=false
poses.Parent=characterScripts

-- Boogie Woogie, sourced from BoogieWoogieV1(5).rbxl and restored from the
-- complete earlier test arena. Install only the original clap assets.
local clapAssetNames = {"ClapAnimation", "ClapVFX", "SwapSound"}
for _, assetName in ipairs(clapAssetNames) do
    local source = original.ReplicatedStorage:FindFirstChild(assetName)
    assert(source, "Original Boogie Woogie asset missing: " .. assetName)
    install(source, rep)
end
local boogieRemote = R.Instance.new("RemoteEvent")
boogieRemote.Name = "BoogieSwap"
boogieRemote.Parent = rep
local input = R.Instance.new("LocalScript")
input.Name = "BoogieSwapInput"
input.Source = fs.readFile("r6-test/boogie-input.luau")
L.compile(input.Source)
input.Disabled = false
input.Parent = characterScripts
local oldBoogieServer = place.ServerScriptService:FindFirstChild("BoogieSwapServer")
if oldBoogieServer then oldBoogieServer:Destroy() end
local oldNPCServer = place.ServerScriptService:FindFirstChild("NPCWanderServer")
if oldNPCServer then oldNPCServer:Destroy() end
local boogieServer = R.Instance.new("Script")
boogieServer.Name = "BoogieSwapServer"
boogieServer.Source = fs.readFile("r6-test/boogie-server.luau")
L.compile(boogieServer.Source)
boogieServer.Disabled = false
boogieServer.Parent = place.ServerScriptService

-- A single R6 target makes the position swap testable even for one player.
-- Use the original pack's stripped-down NPC template; no AI or loop scripts.
local sourceDummy = original.ServerStorage:FindFirstChild("R6BotTemplate")
assert(sourceDummy, "Original R6 dummy template missing")
local oldDummy = place.Workspace:FindFirstChild("BoogieTestDummy")
if oldDummy then oldDummy:Destroy() end
local dummy = install(sourceDummy, place.Workspace)
dummy.Name = "BoogieTestDummy"
local dummyRoot = dummy:FindFirstChild("HumanoidRootPart")
local dummyHumanoid = dummy:FindFirstChildOfClass("Humanoid")
assert(dummyRoot and dummyHumanoid and dummyHumanoid.RigType == R.Enum.HumanoidRigType.R6)
local testArena = place.Workspace:FindFirstChild("TestArena")
assert(testArena and testArena:FindFirstChild("Spawn"), "Arena spawn missing")
local pivot = testArena.Spawn.CFrame * R.CFrame.new(12, 4, -14)
local delta = pivot * dummyRoot.CFrame:Inverse()
for _, part in ipairs(dummy:GetDescendants()) do
    assert(not part:IsA("LuaSourceContainer"), "Test dummy cannot contain unrelated scripts")
    if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end
end
dummyRoot.Anchored = true
dummyHumanoid.DisplayName = "BOOGIE | ALVO"
dummy:SetAttribute("BoogieTestTarget", true)

-- Three lightweight R6 wanderers near the spawn, visible after Play.
local previousNPCFolder = place.Workspace:FindFirstChild("NPCWanderers")
if previousNPCFolder then previousNPCFolder:Destroy() end
local npcFolder = R.Instance.new("Folder")
npcFolder.Name = "NPCWanderers"
npcFolder.Parent = place.Workspace
for index = 1, 4 do
    local npc = install(sourceDummy, npcFolder)
    npc.Name = "Explorer_" .. index
    npc:SetAttribute("NPCWanderer", true)
    npc:SetAttribute("NPCIndex", index)
    local npcHum = npc:FindFirstChildOfClass("Humanoid")
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    assert(npcRoot and npcHum and npcHum.RigType == R.Enum.HumanoidRigType.R6)
    npcHum.DisplayName = "EXPLORADOR 0" .. index
    npcHum.WalkSpeed = 11.5
    local target = testArena.Spawn.CFrame * R.CFrame.new(-27 + index * 11, 4, -15 - (index % 2) * 14)
    local adjustment = target * npcRoot.CFrame:Inverse()
    for _,part in ipairs(npc:GetDescendants()) do
        assert(not part:IsA("LuaSourceContainer"), "NPC template must have no extra scripts")
        if part:IsA("BasePart") then
            part.CFrame = adjustment * part.CFrame
            part.Anchored = false
        end
    end
end
local npcScript = R.Instance.new("Script")
npcScript.Name = "NPCWanderServer"
npcScript.Source = fs.readFile("r6-test/npc-wander-server.luau")
L.compile(npcScript.Source)
npcScript.Enabled = true
npcScript.Disabled = false
npcScript.Parent = place.ServerScriptService

-- The menu is a single client script with a local 3D checkerboard backdrop.
-- It is independent of the avatar and survives R6 respawns.
local menuRemote = R.Instance.new("RemoteEvent")
menuRemote.Name = "R6MenuRespawn"
menuRemote.Parent = rep
local menuScript = R.Instance.new("LocalScript")
menuScript.Name = "R6CinematicMenu"
menuScript.Source = fs.readFile("r6-test/cinematic-menu-client.luau")
L.compile(menuScript.Source)
menuScript.Disabled = false
menuScript.Parent = playerScripts

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
assert(#place.ServerScriptService:GetChildren() == 3)
server.Source = fs.readFile("r6-test/avatar-server.luau")
L.compile(server.Source)
place.StarterPack:ClearAllChildren()
place.StarterGui:ClearAllChildren()
place.ServerStorage:ClearAllChildren()
place.Workspace:SetAttribute("R6TestBuild", "r6-original-best-run-v15")
place.Workspace:SetAttribute("R6OriginalWallrunOnly", false)
place.Workspace:SetAttribute("R6ChakraWallWalk", true)
place.Workspace:SetAttribute("R6MotionVerifiedAssets", true)
place.Workspace:SetAttribute("BoogieWoogieInstalled", true)
place.Workspace:SetAttribute("R6DynamicCinematicMenu", true)
place.Workspace:SetAttribute("R6WanderingNPCCount", 4)
place.Workspace:SetAttribute("R6DeathMenuInstalled", true)
place.Workspace:SetAttribute("NaturalR6ClimbingInstalled", true)
place.Workspace:SetAttribute("OptionalChakraToggle", true)
place.Workspace:SetAttribute("R6CombatAnimationsInstalled", true)
place.Workspace:SetAttribute("R6RealJointPoseInstalled", true)
place.Workspace:SetAttribute("OriginalUnmodifiedR6RunInstalled", true)

local manifest = {
 build = "r6-original-best-run-v15",
 source = "WallWalkNarutoV1(5).rbxl",
 originalSHA256 = expected,
 originalWallWalkSourceSHA256 = S.hash("sha256", originalWallSource),
 playerCharacter = {"Animate", "ChakraWallWalk", "NarutoSprintInput", "BoogieSwapInput", "NaturalR6Climb", "R6CombatInput", "R6PoseController"},
 originalR6Run = {source = "Best Run Animations R6", assetId=136548520660837,
   sourceHash = runArchiveHash, selected="Run3 [by Newb1e27]",
   originalKeyframeCounts=originalRunCounts, modifiedOriginals=false,
   sourceOfTruth="raw KeyframeSequence (NOT a published animation ID)"},
 locomotionPoseDriver = {script="R6PoseController",rig="R6",
   joint="Motor6D.C0",mode={"idle","walk","run","jump","fall"},
   sprint = "Distinct handcrafted R6 pose cycle; replaces incompatible Ninja R15 asset",
   runningWhenWalkSpeedAtLeast=19, sharedWithCombat=true,
   priority = "Yield to optional Chakra and natural wall climb"},
 combat = {
    sourceModelCatalog = {16663903306, 75164220659481, 125909948357929, 114132474839078},
    allSuppliedAnimationIds = combatAnimations,
    usableAnimationIds = usableCombat,
    unavailableAnimationIds = unavailableCombat,
    measuredInUniverse = combatProbe,
    combo = {"M1_1", "M1_2", "M1_3", "M1_4"},
    actions = {"Block", "DodgeFront", "DodgeBack", "Uppercut", "Downslam",
        "HeavyPunch", "Barrage", "Kick_1", "Kick_2"},
    mobileButtons = {"SOCO", "DEF", "ESQ", "CHUTE", "ESP."},
    pcKeys = {"MouseButton1", "F", "Q", "E", "R"},
    fallback = "Local R6 cosmetic pose for unavailable animation IDs; not original Roblox uploaded clips",
    networkAttacks = false,
    onlyR6 = true,
 },
 naturalClimb = {package = "R15 & R6 Wall Climbing System.rbxl", rig = "R6",
   mode = "automatic-on-forward-into-wall", usesJoystick = true, button = false,
   climbingAnimation = "Animate.climb.ClimbAnim", staminaModule = "StaminaBar",
   drainPerSecond = 15, recoverPerSecond = 12, maxStamina = 100, cooldownSeconds = 2,
   blockedWhenChakraActive = true},
 chakraToggle = {button = "CHAKRA OFF / CHAKRA ON", key = "B",
   initialState = false, stateAttribute = "ChakraActive", optional = true},
 boogieWoogie = {package = "BoogieWoogieV1(5).rbxl", ability = "Swap positions with one target", remote = "BoogieSwap", originalClapAssets = clapAssetNames, server = "BoogieSwapServer", cooldownSeconds = 1.6, maxDistanceStuds = 65, testDummy = "BoogieTestDummy", mobileKey = "G"},
 selectedAnimationIds = selected,
 runCatalogCandidateIds = {72900620651167, 107952007153363, 93499989310243},
 runCandidateProbe = freshRuns,
 dynamicMenu = {screens = {"Home", "Settings", "Credits", "Update", "Death"},
    loadingTransition = true, editableSettings = true, client3DCheckerboard = true,
    deathRespawn = "R6MenuRespawn"},
 walkingNPCs = {count = 4, rig = "R6", humanoidMoveTo = true, testableBoogieTargets = true},

 nativeCandidateMeasurements = probed,
 patchedNarutoR6Motion = true,
 originalNarutoR6SHA256 = "571a1392e3bab92efc4ac61f3e70df784f8aad2bfb0865d582b841243f7e283b",
 playerScripts = {"RbxCharacterSounds", "PlayerScriptsLoader"},
 replicatedDependencies = {"GravityController", "DrawClass", "VFX"},
 mobileChakraButton = true,
 olderWallRunRemoved = true,
 otherPacksExcluded = true,
 note = "v15 installs three original unchanged R6 run sequences from the public Best Run Animations R6 model and plays Run3 directly from its saved keyframes. Existing combat, menu, chakra, Boogie and automatic climbing preserved.",
}
fs.writeFile("r6-test/animation-manifest.json", S.encode("json", manifest, true))
fs.writeFile("r6-test/arena.rbxl", R.serializePlace(place))
print("CHAKRA_R6_ANIMATIONS_OK", S.encode("json", selected))
