local Workspace=game:GetService("Workspace")
local world=assert(Workspace:FindFirstChild("OveryardPhotoWorld"))
local root=assert(world:FindFirstChild("WholeMapPhotoDetailV14"),"Whole-map detail pass missing")
assert(root:GetAttribute("Version")=="whole-map-photo-detail-v14")
assert(game.PlaceVersion>(root:GetAttribute("SourcePlaceVersion")or 0),"Place version did not advance")

local caio=assert(world:FindFirstChild("Caio"),"Caio missing after map pass")
assert(#caio:GetDescendants()==root:GetAttribute("CaioDescendantsBefore"),"Caio changed during map-only pass")
assert(#game:GetService("StarterGui"):GetChildren()==root:GetAttribute("StarterGuiChildrenBefore"),"StarterGui changed")
assert(#game:GetService("ReplicatedFirst"):GetChildren()==root:GetAttribute("ReplicatedFirstChildrenBefore"),"Loading/UI changed")
assert(#game:GetService("StarterPlayer").StarterPlayerScripts:GetChildren()==root:GetAttribute("StarterPlayerScriptsBefore"),"Client UI/scripts changed")

assert(root:GetAttribute("GrassCount")>=500,"Not enough whole-map grass detail")
assert(root:GetAttribute("FlowerCount")>=100,"Not enough flowers")
assert(root:GetAttribute("RockCount")>=45,"Not enough rocks")
assert(root:GetAttribute("AccentTreeCount")>=60,"Not enough extra trees")
assert(root:GetAttribute("LanternCount")>=6,"Sanctuary lanterns missing")
assert(root:GetAttribute("ToriiCount")==1,"Map pass must add exactly one torii")
assert(root:GetAttribute("LeafPlateCount")>=150,"Autumn detail missing")
assert(root:GetAttribute("WaterDetailCount")>=6,"Water detail missing")

for _,name in ipairs({"Cliff","Jungle","Sunset","Falls","Blue","Shrine","Golden","StoneTrail","Emerald","WhitePath"})do
 assert(root:FindFirstChild(name),name.." map theme missing")
end
assert(root.Falls:FindFirstChild("WaterfallSheet",true),"Waterfall missing")
assert(root.Blue:FindFirstChild("WhiteForestDeer",true),"Deer missing")
assert(root.Shrine:FindFirstChild("SanctuaryTorii",true),"Single sanctuary torii missing")
assert(root.Shrine:FindFirstChild("SmallStonePagoda",true),"Pagoda missing")
assert(root.Jungle:FindFirstChild("CampfireAnchor",true),"Jungle camp detail missing")

for _,d in ipairs(root:GetDescendants())do
 assert(not d:IsA("LuaSourceContainer"),"Map detail folder must contain no scripts/UI logic")
 assert(not d:IsA("ScreenGui"),"Map detail folder must contain no UI")
end

return {
 ok=true,
 placeVersion=game.PlaceVersion,
 version=root:GetAttribute("Version"),
 grass=root:GetAttribute("GrassCount"),
 flowers=root:GetAttribute("FlowerCount"),
 rocks=root:GetAttribute("RockCount"),
 accentTrees=root:GetAttribute("AccentTreeCount"),
 lanterns=root:GetAttribute("LanternCount"),
 torii=root:GetAttribute("ToriiCount"),
 leafPlates=root:GetAttribute("LeafPlateCount"),
 waterDetails=root:GetAttribute("WaterDetailCount"),
 caioUntouched=true,
 uiUntouched=true,
}
