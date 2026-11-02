assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, 'Wrong Roblox experience')
assert(workspace:GetAttribute('DeadSignalBuildId') == 'fallout-5v5-v1', 'FPS build is no longer active')
assert(workspace:GetAttribute('FalloutCombatHUDRevision') == 'original-fps-v1', 'Original FPS HUD state changed')
assert(workspace:GetAttribute('FalloutBotsBuild') == 'disabled-original-fps', 'FPS bot state changed')
assert(#game.Players:GetPlayers() == 0, 'Menu update requires an isolated Roblox execution session')

local input = ({ ... })[1]
assert(input and input.BinaryInput, 'Sliding menu patch payload is missing')
local bundle = game:GetService('SerializationService'):DeserializeInstancesAsync(input.BinaryInput)[1]
assert(bundle and bundle.Name == 'FPSDynamicMenuPatch', 'Incorrect sliding menu patch')
local incoming = assert(bundle:FindFirstChild('DeadSignalMenu'), 'Local menu script is missing')
assert(incoming:IsA('LocalScript') and incoming:GetAttribute('ManagedBy') == 'Aurivane FPS sliding menu', 'Unexpected menu payload')
local scripts = game.StarterPlayer.StarterPlayerScripts
local existing = scripts:FindFirstChild('DeadSignalMenu')
if existing then
 assert(existing:IsA('LocalScript') and existing:GetAttribute('ManagedBy') == 'Aurivane FPS sliding menu', 'Refusing to replace an unrelated player script')
 existing.Source = incoming.Source
else
 existing = incoming:Clone()
 existing.Parent = scripts
end
existing:SetAttribute('ManagedBy', 'Aurivane FPS sliding menu')
existing.Disabled = false
workspace:SetAttribute('DeadSignalMenuRevision', 'fps-menu-sliding-v1')
bundle:Destroy()
assert(protectedSnapshot() == beforeSnapshot, 'FPS map, HUD, server systems, or saved assets changed')
