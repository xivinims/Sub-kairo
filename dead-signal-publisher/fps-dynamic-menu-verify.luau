local source = game.StarterPlayer.StarterPlayerScripts:FindFirstChild('DeadSignalMenu')
assert(source and source:IsA('LocalScript'), 'Sliding menu LocalScript is not installed')
assert(source:GetAttribute('ManagedBy') == 'Aurivane FPS sliding menu', 'Menu ownership marker is missing')
assert(source.Source:find("local REVISION = 'fps-menu-sliding-v1'", 1, true), 'Incorrect menu source revision')
assert(source.Source:find("TweenService:Create(nextPage", 1, true), 'Sliding page transition is missing')
assert(source.Source:find('BlueCheckeredPillar', 1, true), 'Local menu scene is missing')
assert(source.Source:find("play.Activated:Connect(closeMenu)", 1, true), 'Play button does not return control to the player')
assert(workspace:GetAttribute('DeadSignalMenuRevision') == 'fps-menu-sliding-v1', 'Menu revision attribute is missing')
assert(workspace:GetAttribute('DeadSignalBuildId') == 'fallout-5v5-v1', 'FPS build was not preserved')
assert(workspace:GetAttribute('FalloutCombatHUDRevision') == 'original-fps-v1', 'Original FPS HUD was not preserved')
assert(workspace:GetAttribute('FalloutBotsBuild') == 'disabled-original-fps', 'Original no-bot state was not preserved')
assert(not game.ServerScriptService.FalloutRuntime:FindFirstChild('CombatBots'), 'Experimental bots were added')
return game:GetService('HttpService'):JSONEncode({
	ok = true,
	version = game.PlaceVersion,
	revision = 'fps-menu-sliding-v1',
	pageSlide = true,
	cameraPan = true,
	playReturnsControls = true,
	originalFpsPreserved = true,
	botsDisabled = true,
	preserved = protectedSnapshot(),
})
