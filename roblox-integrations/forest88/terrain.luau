local TerrainBuilder = {}
function TerrainBuilder.build(Scene)
	local terrain = workspace.Terrain
	terrain:Clear()
	for _, d in ipairs(terrain:GetChildren()) do d:Destroy() end
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(88, 120, 68))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(83, 113, 63))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(104, 86, 66))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(84, 75, 58))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(103, 107, 105))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(159, 150, 119))
	local bottom, top, resolution = -64, 152, 4
	local ny = (top - bottom) / resolution
	local chunks, greenColumns, waterColumns, minHeight, maxHeight = 0, 0, 0, math.huge, -math.huge
	for bx = Scene.Minimum, Scene.Maximum - 1, 128 do
		for bz = Scene.Minimum, Scene.Maximum - 1, 128 do
			local materials, occupancy, liquid = {}, {}, {}
			for ix = 1, 32 do
				materials[ix], occupancy[ix], liquid[ix] = {}, {}, {}
				for iy = 1, ny do materials[ix][iy], occupancy[ix][iy], liquid[ix][iy] = {}, {}, {} end
				for iz = 1, 32 do
					local x, z = bx + (ix - 0.5) * resolution, bz + (iz - 0.5) * resolution
					local height, surface, water = Scene.sample(x, z)
					-- Separate liquid/solid channels preserve smooth banks and avoid air gaps above partial river-bed cells.
					minHeight, maxHeight = math.min(minHeight, height), math.max(maxHeight, height)
					if Scene.isGreen(x, z) then greenColumns += 1 end
					if water > height then waterColumns += 1 end
					for iy = 1, ny do
						local low = bottom + (iy - 1) * resolution
						local solid = math.clamp((height - low) / resolution, 0, 1)
						if solid > 0 then
							materials[ix][iy][iz] = low > height - 8 and surface or Enum.Material.Rock
							occupancy[ix][iy][iz] = solid
						else materials[ix][iy][iz], occupancy[ix][iy][iz] = Enum.Material.Air, 0 end
						liquid[ix][iy][iz] = solid < 1 and math.clamp((water - low) / resolution, 0, 1) or 0
					end
				end
			end
			terrain:WriteVoxelChannels(Region3.new(Vector3.new(bx, bottom, bz), Vector3.new(bx + 128, top, bz + 128)), resolution,
				{SolidMaterial=materials,SolidOccupancy=occupancy,LiquidOccupancy=liquid})
			chunks += 1 task.wait()
		end
	end
	terrain.WaterColor = Color3.fromRGB(49, 100, 106)
	terrain.WaterTransparency = 0.34 terrain.WaterReflectance = 0.20 terrain.WaterWaveSize = 0.055 terrain.WaterWaveSpeed = 7
	pcall(function() terrain.Decoration = true end)
	local clouds = Instance.new("Clouds") clouds.Name = "ForestClouds"
	clouds.Cover = 0.35 clouds.Density = 0.30 clouds.Color = Color3.fromRGB(241, 244, 247) clouds.Parent = terrain
	return {chunks = chunks, greenColumns = greenColumns, waterColumns = waterColumns, minHeight = minHeight, maxHeight = maxHeight,
		size = {1024, top - bottom, 1024}, riverSurface = Scene.RiverY}
end
return TerrainBuilder
