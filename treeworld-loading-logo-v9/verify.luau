local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155)
assert(Workspace:GetAttribute("LoadingLogoAssetId")==138675502621883)
assert(Workspace:GetAttribute("LoadingLogoPreload")==true)
assert(Workspace:GetAttribute("LoadingLogoFallback")==true)
assert(Workspace:GetAttribute("LoadingSeconds")==3)

local loader=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
assert(loader and loader:IsA("LocalScript"))
local src=loader.Source
assert(string.find(src,"ContentProvider:PreloadAsync",1,true),"Logo preload missing")
assert(string.find(src,"logo.IsLoaded",1,true),"Image loaded check missing")
assert(string.find(src,"rbxassetid://",1,true),"Primary logo URI missing")
assert(string.find(src,"rbxthumb://type=Asset",1,true),"Fallback logo URI missing")
assert(string.find(src,'logo.Name="OveryardLogo"',1,true),"Logo element missing")
assert(string.find(src,'local duration=3',1,true),"3 second visible loading missing")
assert(string.find(src,'fill.Name="LoadingBar"',1,true),"Progress bar missing")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	logoAssetId=Workspace:GetAttribute("LoadingLogoAssetId"),
	preload=Workspace:GetAttribute("LoadingLogoPreload"),
	fallback=Workspace:GetAttribute("LoadingLogoFallback"),
}
