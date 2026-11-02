-- Reproducible repair of the existing uploaded R6 test place.
-- No models, animation keyframes, clothing or imported source code are changed.
local fs = require("@lune/fs")
local R = require("@lune/roblox")
local S = require("@lune/serde")
local L = require("@lune/luau")

local place = R.deserializePlace(fs.readFile("r6-test/arena.rbxl"))
local sc = place.StarterPlayer.StarterCharacterScripts
local old = place.Workspace:GetAttribute("R6TestBuild")
assert(old == "r6-character-motion-v3" or old == "r6-character-motion-v4" or old == "r6-character-motion-v5" or old == "r6-character-motion-v6", "Not the R6 motion test place")
assert(sc and sc:FindFirstChild("Animate") and sc:FindFirstChild("Animations"), "Missing original character animation assets")
assert(sc:FindFirstChild("Run") and sc:FindFirstChild("Wallrun"), "Missing source motion scripts")
assert(place.ServerScriptService:FindFirstChild("R6AvatarServer"), "Missing R6 character spawner")
assert(#sc.Animations.Emotes:GetChildren() == 19, "Original keyframe emotes are missing")

local originalCount = 0
for _, object in ipairs(place:GetDescendants()) do
    if object:IsA("LuaSourceContainer") and object:GetAttribute("OriginalId") then
        local source = place.ServerStorage.OriginalSources:FindFirstChild(object:GetAttribute("OriginalId"))
        assert(source and source.Source == object.Source, "Imported script changed: " .. object:GetFullName())
        originalCount += 1
    end
end
assert(originalCount >= 15, "Original R6 sources unavailable")

-- Preserve imported Naruto Animate and its animation data inside the avatar.
-- Only its runtime is disabled, so it cannot fight the new motion driver.
sc.Animate.Enabled = false
sc.Animate.Disabled = true
local existing = sc:FindFirstChild("R6Locomotion")
if existing then existing:Destroy() end
local driver = R.Instance.new("LocalScript")
driver.Name = "R6Locomotion"
driver.Source = fs.readFile("r6-test/locomotion-client.luau")
L.compile(driver.Source)
driver.Enabled = true
driver.Disabled = false
driver.Parent = sc

-- Emotes are likewise owned by the avatar; don't re-enable old Animate.
local emotes = sc:FindFirstChild("CharacterEmotes")
assert(emotes, "CharacterEmotes is missing")
emotes.Source = fs.readFile("r6-test/character-emotes.luau")
L.compile(emotes.Source)
emotes.Enabled = true
emotes.Disabled = false

-- Keep only the two switching buttons. UI also lives in the character.
local previousGui = sc:FindFirstChild("AnimationBankGUI")
if previousGui then previousGui:Destroy() end
local switchingGui = R.Instance.new("LocalScript")
switchingGui.Name = "AnimationBankGUI"
switchingGui.Source = fs.readFile("r6-test/animation-bank-gui.luau")
L.compile(switchingGui.Source)
switchingGui.Disabled = false
switchingGui.Parent = sc

-- Preserve the user's avatar, manual R6 spawn, camera and existing systems.
local spawner = place.ServerScriptService.R6AvatarServer
assert(spawner.Source == fs.readFile("r6-test/avatar-server.luau"))
assert(#place.StarterPlayer.StarterPlayerScripts:GetChildren() == 0, "Preview UI must stay removed")
place.Workspace:SetAttribute("R6TestBuild", "r6-character-motion-v6")
place.Workspace:SetAttribute("R6LocomotionInstalled", true)
place.Workspace:SetAttribute("R6ExclusiveAnimationBanks", true)
place.Workspace:SetAttribute("R6VisibleJointAnimation", true)

local manifest = S.decode("json", fs.readFile("r6-test/animation-manifest.json"))
manifest.build = "r6-character-motion-v6"
manifest.characterController = "R6Locomotion (LocalScript in StarterCharacterScripts)"
manifest.exclusiveBanks = {Padrao = "R6 default locomotion animations", Arquivos = "UploadedMotion Animation IDs and compatible raw KeyframeSequences"}
manifest.bankButtons = {"R6 PADRÃO", "R6 ARQUIVOS"}
manifest.hudScript = "StarterPlayer.StarterCharacterScripts.AnimationBankGUI"
manifest.originalControllerPreservedDisabled = true
manifest.automaticMovement = {"idle", "walk", "run", "jump", "fall", "climb", "sit"}
manifest.fallbackNote = "v6 waits for Workspace to load tracks and applies real R6 KeyframeSequence poses to C0; unavailable IDs fall back to visibly animated C0 joints. R15 source clips are not installed on an R6 rig."
fs.writeFile("r6-test/animation-manifest.json", S.encode("json", manifest, true))
fs.writeFile("r6-test/arena.rbxl", R.serializePlace(place))
print("R6_AUTO_CHARACTER_REPAIR_OK", originalCount)
