local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155)
local id=Workspace:GetAttribute("LoadingLogoAssetId")
assert(type(id)=="number" and id>0)
assert(Workspace:GetAttribute("LoadingLogoTransparent")==true)
assert(Workspace:GetAttribute("LoadingLogoImmediatePreload")==true)
assert(Workspace:GetAttribute("LoadingGreetingSequence")==true)
assert(Workspace:GetAttribute("LoadingSeconds")==3)

local loader=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
assert(loader and loader:IsA("LocalScript"))
local src=loader.Source
assert(string.find(src,"ContentProvider:PreloadAsync",1,true),"preload missing")
assert(string.find(src,'greeting.Text="Olá, "',1,true),"Olá greeting missing")
assert(string.find(src,"Seja bem-vindo",1,true),"welcome text missing")
assert(string.find(src,"Preparando o mapa...",1,true),"map text missing")
assert(string.find(src,"Carregando ambiente...",1,true),"environment text missing")
assert(string.find(src,"Quase pronto...",1,true),"final text missing")
assert(string.find(src,"rbxassetid://"..tostring(id),1,true),"transparent logo not wired")
assert(not string.find(src,"rbxthumb://",1,true),"old thumbnail fallback remains")

local updateClient=ReplicatedFirst:FindFirstChild("OveryardUpdateMigrationClient")
if updateClient then
	assert(string.find(updateClient.Source,"rbxassetid://"..tostring(id),1,true),"update screen still uses old logo")
end

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	logoAssetId=id,
	transparent=true,
	greeting=true,
	updateClientUpdated=updateClient~=nil,
}
