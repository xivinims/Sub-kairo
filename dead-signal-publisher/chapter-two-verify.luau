local W=workspace
assert(game.GameId==9421505041 and game.PlaceId==87600271104551,'Wrong Chapter 2 experience')
assert(W:GetAttribute('OriginalPreflight')==true,'Chapter 2 preflight was not installed')
assert(W:GetAttribute('ExperienceChapter')==2,'Chapter 2 experience marker missing')
assert(W:GetAttribute('SelectedChapter')==2,'Chapter 2 was not selected on startup')
assert(W:GetAttribute('GameMode')=='Match','Chapter 2 preflight did not enter gameplay')
assert(W:GetAttribute('IslandWorldReady')==true,'Chapter 2 world did not load')
local map=assert(W:FindFirstChild('ChapterTwoWorld'),'Greenhouse map missing')
assert(map:FindFirstChild('MemoryFragments') and #map.MemoryFragments:GetChildren()==3,'Memory fragments missing')
assert(map:FindFirstChild('GeneratorConsole') and map:FindFirstChild('ExitDoor'),'Generator or exit missing')
return {verified=true,version=game.PlaceVersion,chapter=2,world='greenhouse',fragments=#map.MemoryFragments:GetChildren()}
