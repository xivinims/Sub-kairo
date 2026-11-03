local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")

local id=Workspace:GetAttribute("LoadingLogoAssetId")
assert(type(id)=="number" and id>0,"Loading logo asset id missing")
assert(Workspace:GetAttribute("LoadingIndicator")=="ProgressBar","Loading indicator is not progress bar")
assert(Workspace:GetAttribute("LoadingSeconds")==3,"Loading duration is not 3 seconds")

local loader=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
assert(loader and loader:IsA("LocalScript"),"MapLoadingScreen missing")

local src=loader.Source
assert(string.find(src,"rbxassetid://"..tostring(id),1,true),"Logo asset is not wired into loading screen")
assert(string.find(src,'logo.Name="OveryardLogo"',1,true),"Logo ImageLabel missing")
assert(string.find(src,'fill.Name="LoadingBar"',1,true),"Loading bar missing")
assert(string.find(src,'pct.Name="LoadingPercent"',1,true),"Loading percent missing")
assert(string.find(src,'local duration=3',1,true),"Loading duration source mismatch")
assert(not string.find(src,'string.rep("•"',1,true),"Old three-dot indicator remains")
assert(not string.find(src,'d.Text=string.rep',1,true),"Old dot animation remains")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	logoAssetId=id,
	indicator=Workspace:GetAttribute("LoadingIndicator"),
	loadingSeconds=Workspace:GetAttribute("LoadingSeconds"),
}
