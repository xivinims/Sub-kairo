local world=workspace:FindFirstChild('OveryardPhotoWorld')
local map=world and world:FindFirstChild('WholeMapPhotoDetailV14')
return {
 placeVersion=game.PlaceVersion,
 hasMap=map~=nil,
 mapVersion=map and map:GetAttribute('Version')or nil,
 grass=map and map:GetAttribute('GrassCount')or nil,
 caioDesc=world and world:FindFirstChild('Caio')and #world.Caio:GetDescendants()or -1,
 voiceRevision=workspace:GetAttribute('VoiceTouchRevision')
}