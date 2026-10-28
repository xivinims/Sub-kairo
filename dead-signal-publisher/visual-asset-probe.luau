-- Read-only Creator Store audit. Model scripts are destroyed before the
-- hierarchy is inspected; nothing is parented to Workspace or executed.
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ids = {
	130515502281374,
	11730123582,
	11946229834,
	15482908101,
	134979255746081,
	2626635090,
}
local report = {}

local function partCount(root)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then n += 1 end
	end
	if root:IsA("BasePart") then n += 1 end
	return n
end

for _, id in ipairs(ids) do
	local entry = { id = id, classes = {}, scriptsRemoved = 0, sounds = {}, candidates = {} }
	local ok, assetOrError = pcall(function()
		return AssetService:LoadAssetAsync(id)
	end)
	if not ok then
		entry.error = tostring(assetOrError)
		table.insert(report, entry)
		continue
	end
	local asset = assetOrError
	if not asset then
		entry.error = "LoadAssetAsync returned nil"
		table.insert(report, entry)
		continue
	end

	for _, d in ipairs(asset:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			entry.scriptsRemoved += 1
			d:Destroy()
		elseif d:IsA("Sound") then
			table.insert(entry.sounds, {name=d.Name, id=d.SoundId, volume=d.Volume})
		end
	end
	entry.rootClass = asset.ClassName
	entry.rootName = asset.Name
	for _, d in ipairs(asset:GetDescendants()) do
		entry.classes[d.ClassName] = (entry.classes[d.ClassName] or 0) + 1
		if d:IsA("Model") then
			local n = partCount(d)
			if n > 0 then
				local cf, size = d:GetBoundingBox()
				table.insert(entry.candidates, {
					name=d.Name, class=d.ClassName, parts=n,
					size={math.floor(size.X*100)/100, math.floor(size.Y*100)/100, math.floor(size.Z*100)/100},
					center={math.floor(cf.X*100)/100, math.floor(cf.Y*100)/100, math.floor(cf.Z*100)/100},
				})
			end
		end
	end
	entry.rootParts = partCount(asset)
	for _, d in ipairs(asset:GetDescendants()) do
		if d:IsA("MeshPart") then
			table.insert(entry.candidates, {
				name=d.Name, class=d.ClassName, parts=1,
				mesh=d.MeshId, texture=d.TextureID,
				size={math.floor(d.Size.X*100)/100, math.floor(d.Size.Y*100)/100, math.floor(d.Size.Z*100)/100},
			})
		end
	end
	asset:Destroy()
	table.insert(report, entry)
	task.wait(0.5)
end

return HttpService:JSONEncode(report)
