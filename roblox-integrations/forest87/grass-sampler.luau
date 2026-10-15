local Sampler = {}
function Sampler.new(world)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include params.FilterDescendantsInstances = {workspace.Terrain, world.Decor}
	params.RespectCanCollide = true
	local self = {}
	function self:sample(cell, offsets)
		local heights, sum, valid = {}, 0, 0
		for i, offset in ipairs(offsets) do
			local x, z = cell.center.X + offset.X, cell.center.Z + offset.Z
			local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -300, 0), params)
			if hit and hit.Instance == workspace.Terrain and (hit.Material == Enum.Material.Grass or hit.Material == Enum.Material.LeafyGrass) and hit.Normal.Y > 0.25 then
				heights[i] = hit.Position.Y valid += 1 sum += hit.Position.Y
			end
		end
		return heights, valid > 0 and sum / valid or nil, valid
	end
	return self
end
return Sampler
