local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")

assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Wrong target")

local ids = {
	6432306802,       -- Roblox Forest Pack
	112552460612661,  -- Stylized Forest Props Pack
	86014764516390,   -- Low Poly Pine Tree Pack
	13478419902,      -- Wooden Bridge
	2252591871,       -- Medieval Wooden Bridge
	16039529,         -- Japanese Torii
	85287751198168,   -- Temple Arch
	49387516,         -- Ruins
	5036801877,       -- current medieval lamp post from earlier project
}

local report = {}
for _, id in ipairs(ids) do
	local entry = {id=id, ok=false}
	local ok, container = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if ok and container then
		entry.ok = true
		entry.class = container.ClassName
		entry.children = {}
		entry.counts = {BasePart=0, MeshPart=0, Model=0, Script=0, Decal=0, Texture=0}
		for _, child in ipairs(container:GetChildren()) do
			table.insert(entry.children, {name=child.Name, class=child.ClassName})
		end
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("BasePart") then entry.counts.BasePart += 1 end
			if d:IsA("MeshPart") then entry.counts.MeshPart += 1 end
			if d:IsA("Model") then entry.counts.Model += 1 end
			if d:IsA("LuaSourceContainer") then entry.counts.Script += 1 end
			if d:IsA("Decal") then entry.counts.Decal += 1 end
			if d:IsA("Texture") then entry.counts.Texture += 1 end
		end
		container:Destroy()
	else
		entry.error = tostring(container)
	end
	table.insert(report, entry)
end

return HttpService:JSONEncode({
	placeVersion=game.PlaceVersion,
	assets=report,
})
