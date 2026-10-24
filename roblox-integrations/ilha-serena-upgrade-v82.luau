assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==81,"Published version changed")
local world=workspace.IlhaSerena assert(world:GetAttribute("UpgradeVersion")==81,"Wrong island baseline")
local runtime=game.ReplicatedStorage.SerenaRuntime
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)
 local s=Instance.new(class)s.Name=name s.Source=code
 if old then for _,child in ipairs(old:GetChildren())do child.Parent=s end old:Destroy()end
 s.Parent=parent return s
end
local function run(code)
 local m=Instance.new("ModuleScript")m.Name="GrassStage82"m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage
 local result=require(m)()m:Destroy()return result
end
local function module(code)
 local m=Instance.new("ModuleScript")m.Name="GrassFactory82"m.Source=code m.Parent=game.ServerStorage
 local result=require(m)m:Destroy()return result
end

source(runtime,"ModuleScript","GrassCodec",[========[-- Fixed-size, printable storage for 100 terrain offsets; no per-blade Instances.
local Codec={Invalid=-32768}
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local digits={}for i=1,#alphabet do digits[alphabet:byte(i)]=i-1 end
function Codec.encode(offsets)
 local raw=buffer.create(#offsets*2)
 for i,v in ipairs(offsets)do
  assert(v==Codec.Invalid or(v>=-32000 and v<=32000 and v%1==0),"Invalid terrain offset")
  buffer.writei16(raw,(i-1)*2,v)
 end
 local bytes=buffer.tostring(raw)local output={}
 for i=1,#bytes,3 do
  local a,b,c=bytes:byte(i,i+2)local n=a*65536+(b or 0)*256+(c or 0)
  output[#output+1]=alphabet:sub(math.floor(n/262144)%64+1,math.floor(n/262144)%64+1)
   ..alphabet:sub(math.floor(n/4096)%64+1,math.floor(n/4096)%64+1)
   ..(b and alphabet:sub(math.floor(n/64)%64+1,math.floor(n/64)%64+1)or"=")
   ..(c and alphabet:sub(n%64+1,n%64+1)or"=")
 end
 return table.concat(output)
end
function Codec.decode(encoded,count)
 local bytes={}
 for i=1,#encoded,4 do
  local a,b,c,d=encoded:byte(i,i+3)
  local n=assert(digits[a])*262144+assert(digits[b])*4096+(digits[c]or 0)*64+(digits[d]or 0)
  bytes[#bytes+1]=string.char(math.floor(n/65536)%256)
  if c~=61 then bytes[#bytes+1]=string.char(math.floor(n/256)%256)end
  if d~=61 then bytes[#bytes+1]=string.char(n%256)end
 end
 local raw=buffer.fromstring(table.concat(bytes))assert(buffer.len(raw)==count*2,"Corrupt grass coverage")
 return raw
end
function Codec.height(raw,index,base)
 local offset=buffer.readi16(raw,(index-1)*2)
 if offset==Codec.Invalid then return nil end
 return(base+offset)/100
end
return Codec
]========])

source(runtime,"ModuleScript","GrassField",[========[-- Spatial index for the complete field. Only nearby real mesh copies are allocated.
local Field={}Field.__index=Field
function Field.new(coverage)
 local self=setmetatable({spacing=coverage:GetAttribute("Spacing"),minimum=coverage:GetAttribute("Min"),
  gridCount=coverage:GetAttribute("GridCount"),cells={},count=0},Field)
 local Http=game:GetService("HttpService")
 for _,chunk in ipairs(coverage:GetChildren())do if chunk:IsA("StringValue")then
  for _,data in ipairs(Http:JSONDecode(chunk.Value))do
   local cell={ix=data[1],iz=data[2],base=data[3],encoded=data[4],roots=data[5]}
   cell.center=Vector3.new(self.minimum+cell.ix*self.spacing,cell.base/100,self.minimum+cell.iz*self.spacing)
   cell.key=cell.ix*self.gridCount+cell.iz+1
   assert(not self.cells[cell.key],"Duplicate grass volume")self.cells[cell.key]=cell self.count+=1
  end
 end end
 assert(self.count==coverage:GetAttribute("PatchCount"),"Missing grass coverage chunk")
 return self
end
function Field:get(ix,iz)
 if ix<0 or iz<0 or ix>=self.gridCount or iz>=self.gridCount then return nil end
 return self.cells[ix*self.gridCount+iz+1]
end
function Field:around(point,radius)
 local gx,gz=(point.X-self.minimum)/self.spacing,(point.Z-self.minimum)/self.spacing
 local steps=math.ceil(radius/self.spacing)+1 local ix,iz=math.floor(gx+.5),math.floor(gz+.5)
 local cells={}local radiusSquared=radius^2
 for x=ix-steps,ix+steps do for z=iz-steps,iz+steps do
  local cell=self:get(x,z)
  if cell then
   local dx,dz=cell.center.X-point.X,cell.center.Z-point.Z
   if dx*dx+dz*dz<=radiusSquared then cells[#cells+1]=cell end
  end
 end end
 table.sort(cells,function(a,b)
  local adx,adz=a.center.X-point.X,a.center.Z-point.Z local bdx,bdz=b.center.X-point.X,b.center.Z-point.Z
  return adx*adx+adz*adz<bdx*bdx+bdz*bdz
 end)
 return cells
end
return Field
]========])

source(runtime,"ModuleScript","SkinnedGrass",[========[--[[
	An interactive grass module utilizing skinned meshes
	Made by xander22 (youtube.com/@xand3r22, x.com/x4nder22)
	
	CREDITS:
	
	Octree by Quenty
]]

-- Modules
local Octree = require(script.Octree)  
local utils = require(script.SkinnedGrassUtils)

-- Services
local TweenService = game:GetService("TweenService")

-- default settings, can be overriden at runtime with UpdateSettings()
local DEFAULT_SETTINGS = {
	RenderDistanceEnabled = true, -- If grass should be rendered in/out
	RenderDistance = 100, -- Distance at which grass is fully rendered out --150
	RenderInAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- TweenInfo to apply to bones rendering in. Set to nil for no animation (more performant)
	RenderOutAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), -- TweenInfo to apply to bones rendering out. Set to nil for no animation (more performant)
	RenderOutOffset = CFrame.new(0, -3, 0), -- Offset for bones when rendering in/out
	MeshStorage = nil, -- Folder to store meshes that are rendered out. By default creates a folder in ReplicatedStorage

	CollisionsEnabled = true, -- If grass should be simulated with collisions. To disable collisions, set this bool to false rather than setting collision distance to 0
	CollisionDistance = 100, -- Distance at which collisions are simulated
	CollisionRadiusInner = 4, -- Radius around collision where bones are fully displaced
	CollisionRadiusOuter = 6, -- Radius around collision where the displacement effect ends
	CollisionAngle = 90, -- Angle of the displacement effect
	CollisionTranslation = Vector3.new(0, 0, 0), -- Position offset of the displacement effect
	CollisionReturnDelay = 0, -- Time that the grass stays displaced before bouncing back (begins after collision stops)
	CollisionReturnInfo = TweenInfo.new(1.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), -- TweenInfo for the return animation

	WindEnabled = true, -- If grass should be simulated with wind. To disable wind, set this to false rather than setting wind distance to 0
	WindDistanceInner = 10, -- Distance at which wind is simulated with max frame rate
	WindDistanceOuter = 50, -- Distance at which wind is simulated with min frame rate
	WindFramerateInner = 1, -- Frame rate for wind in inner range (1 = 100% frames, 0.5 = 50% frames, etc)
	WindFramerateOuter = 0.25, -- Frame rate for wind in outer range
	WindNoiseSize = 16, -- Size for wind noise calculations
	WindNoiseIntensity = 2, -- Intensity for wind noise calculations
	UseGlobalWind = true, -- When set to true, overrides WindDirection, WindSpeed, WindAngle and WindTranslation settings with Roblox's wind
	WindDirection = Vector3.new(1, 0, 0), -- Direction of the wind effect
	WindSpeed = 8, -- Speed of the wind effect
	WindAngleMin = 35, -- Min angle of the wind effect
	WindAngleMax = 45, -- Max angle of the wind effect
	WindTranslationMin = Vector3.new(0, 0, 0), -- Min position offset of the wind effect
	WindTranslationMax = Vector3.new(0, 0, 0), -- Max position offset of the wind effect
}

local SkinnedGrass = {}
SkinnedGrass.__index = SkinnedGrass

-- initialize new grass object
function SkinnedGrass.new(initialSettings)
	local obj = {
		Settings = {},
		SkinnedMeshesRenderedIn = {},
		MeshParents = {},
        MeshRecords = {},
		MeshTweenOuts = {},
		MeshOctree = {},
		BoneOctree = Octree.new(),
		DisplaceBones = {},
		ReturnBones = {},
		FrameCountInner = 1,
		FrameCountOuter = 1
	}
	setmetatable(obj, SkinnedGrass)
	
	obj.MeshOctree = Octree.new()
	
	obj.Settings = initialSettings or {}
	for i,v in DEFAULT_SETTINGS do
		if obj.Settings[i] == nil then
			obj.Settings[i] = v
		end
	end

	return obj
end

-- updates settings. 'settingsTable' argument should have the same format as DEFAULT_SETTINGS. Leave arguments empty to reset settings to default
function SkinnedGrass:UpdateSettings(settingsTable : {})
	if self.Settings == nil then
		self.Settings = {}
	end

	if settingsTable == nil then
		for i,v in DEFAULT_SETTINGS do
			self.Settings[i] = v
		end
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in DEFAULT_SETTINGS do
		if settingsTable[i] ~= nil then
			self.Settings[i] = settingsTable[i]
		elseif self.Settings[i] == nil then
			self.Settings[i] = v
		end
	end
end

-- adds meshes to grass object
function SkinnedGrass:AddMeshes(skinnedMeshModels : {Model})
	if typeof(skinnedMeshModels) ~= "table" then warn("AddMeshes() parameter must be a table") return end
	
	if self.MeshFolder == nil then
		local folder = self.Settings.MeshStorage or game.ReplicatedStorage:FindFirstChild("SkinnedGrass_Storage")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "SkinnedGrass_Storage"
			folder.Parent = game.ReplicatedStorage
		end
		self.MeshFolder = folder
	end
	
	for _,model in skinnedMeshModels do
		if not model:IsA("Model") then warn(model, "is not a model") continue end
		if self.MeshParents[model] then continue end -- check if model has already been added to simulation
		local meshPart = model:FindFirstChildOfClass("MeshPart")
		if not meshPart then -- yield thread if meshpart hasn't loaded
			local timeout = 0
			while not meshPart and timeout < 5 do
				meshPart = model:FindFirstChildOfClass("MeshPart")
				timeout += task.wait()
			end
			if not meshPart then
				warn(model, "does not have a loaded mesh part. Consider setting ModelStreamingMode to atomic")
				continue
			end
		end
		-- cache the bones for looping
		local bones = meshPart:GetChildren()
        local record = { mesh = meshPart, bones = {} }
        self.MeshRecords[model] = record
		-- create origin bone for transforming bones en masse
		local originBone = Instance.new("Bone")
		originBone.Parent = meshPart
		originBone.WorldCFrame = meshPart.CFrame
		originBone.Name = "SkinnedGrass_Origin"
		-- loop through each bone and reparent to origin bone
		for _,bone in bones do
			if not bone:IsA("Bone") then continue end
			record.bones[bone] = self.BoneOctree:CreateNode(bone.TransformedWorldCFrame.Position, bone)
			bone.Parent = originBone
		end
		-- set origin bone to below skinned mesh for fade in
		originBone.Transform = self.Settings.RenderDistanceEnabled and CFrame.new(0, -3, 0) or CFrame.identity
        record.origin = originBone
		record.meshNode = self.MeshOctree:CreateNode(originBone.WorldCFrame.Position, meshPart)
		-- store mesh in replicated storage until needed (bones aren't calculated when not in workspace)
		self.MeshParents[model] = model.Parent
		if self.Settings.RenderDistanceEnabled then model.Parent = self.Settings.MeshStorage or self.MeshFolder end
	end
end

-- Proximity streaming releases every octree entry and animation record.
function SkinnedGrass:RemoveMeshes(models)
 for _,model in ipairs(models) do
  local record=self.MeshRecords[model]
  if record then
   for bone,node in pairs(record.bones) do node:Destroy() self.DisplaceBones[bone]=nil self.ReturnBones[bone]=nil end
   record.meshNode:Destroy()
   local index=table.find(self.SkinnedMeshesRenderedIn,record.mesh)
   if index then table.remove(self.SkinnedMeshesRenderedIn,index) end
   index=table.find(self.MeshTweenOuts,record.origin)
   if index then table.remove(self.MeshTweenOuts,index) end
   self.MeshRecords[model]=nil self.MeshParents[model]=nil
  end
 end
end
function SkinnedGrass:Destroy()
 local models={}for model in pairs(self.MeshRecords) do table.insert(models,model) end
 self:RemoveMeshes(models)
 table.clear(self.MeshTweenOuts) table.clear(self.SkinnedMeshesRenderedIn)
end

-- main logic of the module, called every interval. Put in RunService.RenderStepped for smoothest simulation
-- targetPos = position the simulation is based around (ie the player's position)
-- collisions = table of information for the displacement effect
-- each index of collisions should be a Vector3 or a table with the following format: {collisionPos, customSettings}
-- customSettings is a table of custom displacement settings for that collision, follows the same format as DEFAULT_SETTINGS
function SkinnedGrass:Step(deltaTime : number, collisions : {}, targetPos : Vector3)
	if targetPos == nil then -- if no target pos center simulation around player character
		local char = game.Players.LocalPlayer.Character
		if char then
			targetPos = char.PrimaryPart.Position
		else
			return
		end
	end
	local settingsTable = self.Settings
	local meshesToRemove = table.clone(self.SkinnedMeshesRenderedIn)
	if settingsTable.RenderDistanceEnabled then
		local skinnedMeshesInRenderDistance = self.MeshOctree:RadiusSearch(targetPos, settingsTable.RenderDistance)
		for _,v in skinnedMeshesInRenderDistance do
			if table.find(self.SkinnedMeshesRenderedIn, v) == nil then
				table.insert(self.SkinnedMeshesRenderedIn, v)
                local pending=table.find(self.MeshTweenOuts,v.SkinnedGrass_Origin)
                if pending then table.remove(self.MeshTweenOuts,pending)end
				--v.Parent.Parent = workspace
				local model = v:FindFirstAncestorOfClass("Model")
				if not model then continue end
				model.Parent = self.MeshParents[model]
				--print("spawn mesh", v)
				if settingsTable.RenderInAnimation then
					TweenService:Create(v.SkinnedGrass_Origin, settingsTable.RenderInAnimation, { Transform = CFrame.new(0, 0, 0) }):Play()
				else
					v.SkinnedGrass_Origin.Transform = CFrame.new(0, 0, 0)
				end		
			end
			local removeIndex=table.find(meshesToRemove,v)
            if removeIndex then table.remove(meshesToRemove,removeIndex)end
		end
		for _,v in meshesToRemove do
			table.remove(self.SkinnedMeshesRenderedIn, table.find(self.SkinnedMeshesRenderedIn, v))
			if settingsTable.RenderOutAnimation then
				TweenService:Create(v.SkinnedGrass_Origin, settingsTable.RenderOutAnimation, { Transform = settingsTable.RenderOutOffset }):Play()
				table.insert(self.MeshTweenOuts, v.SkinnedGrass_Origin)
			else
				local model = v:FindFirstAncestorOfClass("Model")
				model.Parent = settingsTable.MeshStorage
			end
		end
		for i,v in self.MeshTweenOuts do
			if (v.Transform.Position - settingsTable.RenderOutOffset.Position).Magnitude <= 0 then
				table.remove(self.MeshTweenOuts, i)
				v:FindFirstAncestorOfClass("Model").Parent = settingsTable.MeshStorage
			end
		end
	end
	
	local transformedBones = {}
	
	local windDir = game.Workspace.GlobalWind
	if not settingsTable.UseGlobalWind then
		windDir = settingsTable.WindDirection
	end
	if windDir.Magnitude == 0 then windDir = Vector3.new(0, 0, 1) end
	local windIntensity = math.min(game.Workspace.GlobalWind.Magnitude, 20)
	self.FrameCountInner += 1
	if self.FrameCountInner >= 1 / settingsTable.WindFramerateInner then self.FrameCountInner = 1 end
	self.FrameCountOuter += 1
	if self.FrameCountOuter >= 1 / settingsTable.WindFramerateOuter then self.FrameCountOuter = 1 end
	
	if self.WindAnimation == nil or self.WindAnimation >= 1 then
		self.WindAnimation = 0
	end
	local windSpeed = 1 + windIntensity / 20
	if not settingsTable.UseGlobalWind then
		windSpeed = 1 + settingsTable.WindSpeed / 20
	end
	self.WindAnimation += deltaTime * windSpeed
	local minAngle = 0
	local maxAngle = 0
	local minTranslation = Vector3.zero
	local maxTranslation = Vector3.zero
	if self.Settings.WindEnabled then
		minAngle = math.max(windIntensity * 2, -2)
		maxAngle = math.max(windIntensity * 3, 2)
		if not settingsTable.UseGlobalWind then
			minAngle = settingsTable.WindAngleMin
			maxAngle = settingsTable.WindAngleMax
			minTranslation = settingsTable.WindTranslationMin
			maxTranslation = settingsTable.WindTranslationMax
		end
		if self.FrameCountInner == 1 then
			local bonesInWindDistance = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceInner)
			for i = 1, #bonesInWindDistance do
				local bone = bonesInWindDistance[i]
				local windCFrame = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = windCFrame
			end
		end
		if self.FrameCountOuter == 1 then
			local bonesInWindDistanceOuter = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceOuter)
			for i = 1, #bonesInWindDistanceOuter do
				local bone = bonesInWindDistanceOuter[i]
				local windCFrame = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = windCFrame
			end
		end
	end

	if settingsTable.CollisionsEnabled and collisions then
		local collisionsInRange = {}
		for _,collision in collisions do
			local pos, customSettings
			if typeof(collision) == "table" then
				pos = collision[1]
				customSettings = collision[2]
			else
				pos = collision
				customSettings = {}
			end
			if (pos - targetPos).Magnitude > settingsTable.CollisionDistance then continue end -- outside of the collision sim distance
			local collisionSettings = table.clone(settingsTable)
			for key,value in customSettings do -- custom settings
				if collisionSettings[key] then
					collisionSettings[key] = value
				end
			end

			local bonesInCollisionDistance = self.BoneOctree:RadiusSearch(pos, collisionSettings.CollisionRadiusOuter - 0.1) --slight offset to prevent return starting instantly
			local displaceFadeRange : number = collisionSettings.CollisionRadiusOuter - collisionSettings.CollisionRadiusInner 
			for _,bone in bonesInCollisionDistance do
				table.insert(transformedBones, bone)

				local displaceInfo = self.DisplaceBones[bone]
				if displaceInfo == nil then --first time calculating, set target rotation and displace percent
					displaceInfo = {}
					displaceInfo[1] = collisionSettings --settings
					displaceInfo[2] = self.ReturnBones[bone] and self.ReturnBones[bone][2] or 0 --displace percent

					local offset = bone.TransformedWorldCFrame.Position - pos
                    local directionToKnock = offset.Magnitude > .001 and offset.Unit or Vector3.new(1,0,0)
					local localKnockDirection = bone.WorldCFrame:VectorToObjectSpace(directionToKnock)

					-- Preserve the current Y rotation, only affect X and Z
					local _, currentYRotation, _ = bone.Transform:ToOrientation() -- Extract the Y rotation

					local horizontal = Vector3.new(localKnockDirection.X, 0, localKnockDirection.Z)
                    local tiltDirection = horizontal.Magnitude > .001 and horizontal.Unit or Vector3.new(1,0,0)

					-- Knock the bone over by tilting it based on the knock intensity
					local tiltAngle = math.rad(settingsTable.CollisionAngle)
					local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
					local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction
					local newTranslation = settingsTable.CollisionTranslation
					-- Set the new orientation while preserving the Y rotation
					local targetCFrame = (bone:GetAttribute("SerenaTerrainOffset") or CFrame.identity) * CFrame.new(newTranslation) * CFrame.Angles(newXRotation, currentYRotation, newZRotation)
					displaceInfo[4] = targetCFrame
				end

				-- calculate displacement percentage by checking where the bone is at between the displacement radius inner and displacement radius outer
				local distFromOrigin : number = ((bone:GetAttribute("SerenaGroundPoint") or bone.WorldCFrame.Position) - pos).Magnitude
				local range = math.min(1 - (distFromOrigin - collisionSettings.CollisionRadiusInner) / displaceFadeRange, 1)
				if range > displaceInfo[2] then --displace amount can only go up, not down (out animation handled by return table)
					displaceInfo[2] = range --percent displaced, 0 = no displacement, 1 = full displacement
				end
				displaceInfo[3] = range
				self.DisplaceBones[bone] = displaceInfo
				self.ReturnBones[bone] = nil

			end

		end

		for bone,displaceInfo in self.DisplaceBones do
			local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
			-- Keep the terrain translation fixed while blades bend. Rotating or
			-- scaling that translation lifts roots off slopes during partial contact.
			bone.Transform = windRot:Lerp(displaceInfo[4], math.clamp(displaceInfo[2], 0, 1))

			if displaceInfo[3] <= 0 or table.find(transformedBones, bone) == nil then --out of range, do return
				local returnInfo = {}
				returnInfo[1] = displaceInfo[1] --settings
				returnInfo[2] = displaceInfo[2] --percent displaced
				returnInfo[3] = tick() --time of displacement leaving range
				returnInfo[4] = bone.Transform -- cframe to lerp from
				self.ReturnBones[bone] = returnInfo
				self.DisplaceBones[bone] = nil
				continue
			end
		end

		for bone,returnInfo in self.ReturnBones do
			local collisionSettings = returnInfo[1]
			local timeSinceCollision = tick() - returnInfo[3]
			if timeSinceCollision < collisionSettings.CollisionReturnDelay then 
				local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = returnInfo[4]
				continue
			end
			local returnTweenInfo : TweenInfo = collisionSettings.CollisionReturnInfo
			if timeSinceCollision >= collisionSettings.CollisionReturnDelay + returnTweenInfo.Time then 
				self.ReturnBones[bone] = nil
				continue
			end

			local percentReturned = (timeSinceCollision - collisionSettings.CollisionReturnDelay) / returnTweenInfo.Time
			local tweenValue = TweenService:GetValue(percentReturned, returnTweenInfo.EasingStyle, returnTweenInfo.EasingDirection)
			returnInfo[2] = 1 - tweenValue
			local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
			local newRot = returnInfo[4]:lerp(windRot, tweenValue)
			
			bone.Transform = CFrame.new(Vector3.zero) * newRot
		end
	end

end

return SkinnedGrass
]========])

local grass=module([========[local Grass={Spacing=4,Min=-384,Max=384,ChunkSize=128}
function Grass.install(world,runtime)
 local Codec=require(runtime.GrassCodec)
 local fine=runtime.SkinnedGrassTemplates.FineStudio
 local mesh=fine:FindFirstChildOfClass("MeshPart")
 assert(mesh.MeshId=="rbxassetid://80159239673273","Wrong grass variant")
 local bones={}for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then table.insert(bones,b)end end
 table.sort(bones,function(a,b)return a.Name<b.Name end)assert(#bones==100)
 local minimum=Vector3.new(math.huge,math.huge,math.huge)local maximum=-minimum
 for _,b in ipairs(bones)do minimum=minimum:Min(b.CFrame.Position)maximum=maximum:Max(b.CFrame.Position)end
 local span=maximum-minimum
 assert(Grass.Spacing<span.X and Grass.Spacing<span.Z,"Grass volumes leave gaps")
 local old=runtime:FindFirstChild("GrassCoverage")if old then old:Destroy()end
 local coverage=Instance.new("Folder")coverage.Name="GrassCoverage"
 coverage:SetAttribute("FormatVersion",2)coverage:SetAttribute("Spacing",Grass.Spacing)
 coverage:SetAttribute("Min",Grass.Min)coverage:SetAttribute("Max",Grass.Max)
 coverage:SetAttribute("GridCount",(Grass.Max-Grass.Min)/Grass.Spacing+1)
 coverage:SetAttribute("BoneCount",#bones)coverage:SetAttribute("RootSpan",span)
 coverage:SetAttribute("SourceAssetId",87377915371959)coverage.Parent=runtime
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include
 ray.FilterDescendantsInstances={workspace.Terrain,world}ray.IgnoreWater=false ray.RespectCanCollide=true
 local terrainRay=RaycastParams.new()terrainRay.FilterType=Enum.RaycastFilterType.Include terrainRay.FilterDescendantsInstances={workspace.Terrain}
 local function green(x,z)
  local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-300,0),ray)
  if hit and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Grass and hit.Normal.Y>.2 then return hit.Position.Y end
 end
 local function containsGreen(x,z)
  if green(x,z)then return true end
  for _,p in ipairs({Vector2.new(-2.5,-2.5),Vector2.new(0,-2.5),Vector2.new(2.5,-2.5),Vector2.new(-2.5,0),Vector2.new(2.5,0),Vector2.new(-2.5,2.5),Vector2.new(0,2.5),Vector2.new(2.5,2.5)})do
   if green(x+p.X,z+p.Y)then return true end
  end
  return false
 end
 local Http=game:GetService("HttpService")local batch={}local chunks=0 local count=0 local roots=0 local sampled=0
 local function flush()
  if #batch==0 then return end chunks+=1
  local chunk=Instance.new("StringValue")chunk.Name=string.format("Chunk%04d",chunks)
  chunk.Value=Http:JSONEncode(batch)chunk.Parent=coverage batch={}
 end
 for ix=0,(Grass.Max-Grass.Min)/Grass.Spacing do
  local x=Grass.Min+ix*Grass.Spacing
  for iz=0,(Grass.Max-Grass.Min)/Grass.Spacing do
   local z=Grass.Min+iz*Grass.Spacing
   if not containsGreen(x,z)then continue end
   local ground=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-300,0),terrainRay)
   local base=math.floor((ground and ground.Position.Y or 0)*100+.5)
   local heights={}local valid=0
   for i,b in ipairs(bones)do
    local y=green(x+b.CFrame.X,z+b.CFrame.Z)sampled+=1
    if y then heights[i]=math.floor(y*100+.5)-base valid+=1 else heights[i]=Codec.Invalid end
   end
   if valid>0 then
    count+=1 roots+=valid
    batch[#batch+1]={ix,iz,base,Codec.encode(heights),valid}
    if #batch>=Grass.ChunkSize then flush()end
   end
  end
  if ix%8==0 then task.wait()end
 end
 flush()
 assert(count>10000 and roots>900000,"Dense grass field is incomplete")
 coverage:SetAttribute("PatchCount",count)coverage:SetAttribute("RootCount",roots)
 coverage:SetAttribute("NearRadiusTouch",48)coverage:SetAttribute("NearRadiusDesktop",80)
 coverage:SetAttribute("MaxActiveTouch",640)coverage:SetAttribute("MaxActiveDesktop",1600)
 fine:SetAttribute("RootSpan",span)
 world:SetAttribute("GrassCoveragePatches",count)world:SetAttribute("GrassCoverageRoots",roots)
 world:SetAttribute("GrassSpacing",Grass.Spacing)world:SetAttribute("GrassRootSpan",span)
 world:SetAttribute("DenseGrass",true)world:SetAttribute("WholeMapGrass",true)
 pcall(function()workspace.Terrain.Decoration=true end)
 return {assetId=87377915371959,variant="StudioFine",spacing=Grass.Spacing,rootSpan={span.X,span.Z},
  overlap={span.X-Grass.Spacing,span.Z-Grass.Spacing},patches=count,greenRoots=roots,chunks=chunks,sampledRoots=sampled,
  comparedWithVersion81={spacing=22,patches=503,greenRoots=44994},relativeDensity=(22/Grass.Spacing)^2}
end
return Grass
]========]).install(world,runtime)

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaGrassClient",[========[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("SerenaRuntime")local player=Players.LocalPlayer
local Codec=require(runtime:WaitForChild("GrassCodec"))local Field=require(runtime:WaitForChild("GrassField"))
local SkinnedGrass=require(runtime:WaitForChild("SkinnedGrass"))
local coverage=runtime:WaitForChild("GrassCoverage")local field=Field.new(coverage)
local template=runtime:WaitForChild("SkinnedGrassTemplates"):WaitForChild("FineStudio")
local visible=Instance.new("Folder")visible.Name="SerenaInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="SerenaGrassLocalStorage"storage.Parent=RS
local radius=coverage:GetAttribute(UIS.TouchEnabled and"NearRadiusTouch"or"NearRadiusDesktop")
local maxActive=coverage:GetAttribute(UIS.TouchEnabled and"MaxActiveTouch"or"MaxActiveDesktop")
local keepRadius=radius+6
local grass=SkinnedGrass.new({RenderDistanceEnabled=false,MeshStorage=storage,
 CollisionDistance=30,CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionAngle=68,
 CollisionReturnDelay=.08,CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=UIS.TouchEnabled and 12 or 20,WindDistanceOuter=UIS.TouchEnabled and 32 or 48,
 WindFramerateInner=1,WindFramerateOuter=.25,UseGlobalWind=true})
local active={}local count=0 local queue={}local nextCell=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if h and h.Health>0 and r then return r,h end
end
local function add(cell)
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center))model.Parent=visible
 local mesh=model:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end
 table.sort(bones,function(a,b)return a.Name<b.Name end)
 local heights=Codec.decode(cell.encoded,#bones)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=Codec.height(heights,i,cell.base)
  local point=height and Vector3.new(original.X,height-.045,original.Z)or(original-Vector3.new(0,240,0))
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)
  b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 grass:AddMeshes({model})active[cell.key]={model=model,cell=cell}count+=1
end
local function remove(key)
 local entry=active[key]if not entry then return end
 grass:RemoveMeshes({entry.model})entry.model:Destroy()active[key]=nil count-=1
end
player:SetAttribute("SerenaGrassCoveragePatches",field.count)
player:SetAttribute("SerenaWholeMapGrassReady",true)
local heartbeat=RunService.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end
 refresh+=dt
 if refresh>=.15 then
  refresh=0
  for key,entry in pairs(active)do
   local dx,dz=entry.cell.center.X-root.Position.X,entry.cell.center.Z-root.Position.Z
   if dx*dx+dz*dz>keepRadius^2 then remove(key)end
  end
  queue={}nextCell=1
  for _,cell in ipairs(field:around(root.Position,radius))do if not active[cell.key]then queue[#queue+1]=cell end end
 end
 local budget=player:GetAttribute("SerenaGrassNearbyReady")and 4 or 8
 for _=1,budget do
  local cell=queue[nextCell]if not cell or count>=maxActive then break end nextCell+=1
  if not active[cell.key]then add(cell)end
 end
 player:SetAttribute("SerenaGrassLoadedPatches",count)
 player:SetAttribute("SerenaGrassNearbyReady",nextCell>#queue)
end)
local rendered=RunService.RenderStepped:Connect(function(dt)
 if destroyed then return end stepTime+=dt
 if stepTime<(UIS.TouchEnabled and 1/24 or 1/30)then return end local step=math.min(stepTime,.1)stepTime=0
 local root=rootOf(player)if not root then return end local actors={}
 for _,p in ipairs(Players:GetPlayers())do
  local r,h=rootOf(p)
  if r and(r.Position-root.Position).Magnitude<30 then
   local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)
   actors[#actors+1]=Vector3.new(r.Position.X,feet+.1,r.Position.Z)
  end
 end
 grass:Step(step,actors,root.Position)
end)
script.Destroying:Connect(function()
 destroyed=true heartbeat:Disconnect()rendered:Disconnect()
 grass:Destroy()visible:Destroy()storage:Destroy()table.clear(active)
end)
]========])

local tests=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime
local Codec=require(runtime.GrassCodec)local Field=require(runtime.GrassField)
local coverage=runtime.GrassCoverage local field=Field.new(coverage)
local mesh=runtime.SkinnedGrassTemplates.FineStudio:FindFirstChildOfClass("MeshPart")
local bones={}for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end
table.sort(bones,function(a,b)return a.Name<b.Name end)
local offsets={Codec.Invalid,-32000,-1,0,1,32000}local encoded=Codec.encode(offsets)local decoded=Codec.decode(encoded,#offsets)
for i,n in ipairs(offsets)do assert(buffer.readi16(decoded,(i-1)*2)==n,"Terrain codec changed heights")end
-- Dense world-space samples detect uncovered ground, independently of mesh bounding boxes.
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,workspace.IlhaSerena}
ray.RespectCanCollide=true ray.IgnoreWater=false
local buffers={}local candidates={}
for rx=0,3 do for rz=0,3 do
 local list={}
 for dx=-1,1 do for dz=-1,1 do for i,b in ipairs(bones)do
  local x,z=dx*4+b.CFrame.X-rx,dz*4+b.CFrame.Z-rz local distance=x*x+z*z
  if distance<9 then list[#list+1]={dx=dx,dz=dz,index=i,distance=distance}end
 end end end
 table.sort(list,function(a,b)return a.distance<b.distance end)candidates[rx*4+rz]=list
end end
local greenSamples=0 local gaps=0 local maxDistance=0 local worst={}local denseNativeNear=0
for x=coverage:GetAttribute("Min")+1,coverage:GetAttribute("Max")-1,2 do
 for z=coverage:GetAttribute("Min")+1,coverage:GetAttribute("Max")-1,2 do
  local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-300,0),ray)
  if not(hit and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Grass and hit.Normal.Y>.2)then continue end
  greenSamples+=1
  local gx,gz=math.floor((x-field.minimum)/4),math.floor((z-field.minimum)/4)
  local rx,rz=x-(field.minimum+gx*4),z-(field.minimum+gz*4)
  local distance=math.huge
  for _,candidate in ipairs(candidates[rx*4+rz])do
   local cell=field:get(gx+candidate.dx,gz+candidate.dz)
   if cell then
    local data=buffers[cell.key]if not data then data=Codec.decode(cell.encoded,#bones)buffers[cell.key]=data end
    if Codec.height(data,candidate.index,cell.base)then distance=math.sqrt(candidate.distance)break end
   end
  end
  if distance>maxDistance then maxDistance=distance worst={x,z}end
  if distance>1.25 then gaps+=1 end
 end
end
assert(gaps==0,"Uncovered green ground: "..gaps.." worst "..table.concat(worst,",").." distance "..maxDistance)
assert(greenSamples>40000,"Coverage audit missed the island")
-- Execute the real client source on three adjacent full-green cells, with native meshes/bones.
local fixture=Instance.new("Folder")fixture.Name="GrassQA82"fixture.Parent=game.ServerStorage
local limited=Instance.new("Folder")limited.Parent=fixture
for name,value in pairs(coverage:GetAttributes())do limited:SetAttribute(name,value)end
local chosen
for _,cell in pairs(field.cells)do
 local a,b=field:get(cell.ix+1,cell.iz),field:get(cell.ix,cell.iz+1)
 if cell.roots==100 and a and b and a.roots==100 and b.roots==100 then chosen={cell,a,b}break end
end
assert(chosen,"No contiguous dense green area")
local data={}for _,c in ipairs(chosen)do data[#data+1]={c.ix,c.iz,c.base,c.encoded,c.roots}end
local chunk=Instance.new("StringValue")chunk.Value=game:GetService("HttpService"):JSONEncode(data)chunk.Parent=limited limited:SetAttribute("PatchCount",3)
local function signal()
 local callbacks={}local s={}
 function s:Connect(fn)local entry={fn=fn,live=true}callbacks[#callbacks+1]=entry return{Disconnect=function()entry.live=false end}end
 function s:Fire(...)for _,entry in ipairs(callbacks)do if entry.live then entry.fn(...)end end end
 return s
end
local root=Instance.new("Part")root.Name="HumanoidRootPart"root.Anchored=true root.Parent=fixture
local humanoid={Health=100,RigType=Enum.HumanoidRigType.R6}
local character={}
function character:FindFirstChild(name)return name=="HumanoidRootPart"and root end
function character:FindFirstChildOfClass(name)return name=="Humanoid"and humanoid end
local attrs={}local player={Character=character}
function player:GetAttribute(k)return attrs[k]end function player:SetAttribute(k,v)attrs[k]=v end
local players={LocalPlayer=player}function players:GetPlayers()return{player}end
local run={Heartbeat=signal(),RenderStepped=signal()}local mockScript={Destroying=signal()}
local fakeGame={}
function fakeGame:GetService(name)
 if name=="Players"then return players elseif name=="RunService"then return run elseif name=="UserInputService"then return{TouchEnabled=true}end
 return game:GetService(name)
end
local proxy={}
function proxy:WaitForChild(name)if name=="GrassCoverage"then return limited end return runtime:WaitForChild(name)end
local m=Instance.new("ModuleScript")m.Parent=fixture
local source=game.StarterPlayer.StarterPlayerScripts.SerenaGrassClient.Source:gsub('local runtime=RS:WaitForChild%("SerenaRuntime"%)',"local runtime=env.runtime\n")
m.Source="return function(env)\nlocal game=env.game local script=env.script\n"..source.."\nreturn {grass=grass,active=active,field=field}\nend"
root.CFrame=CFrame.new(chosen[1].center+Vector3.new(0,3,0))
local client=require(m)({game=fakeGame,script=mockScript,runtime=proxy})
for _=1,12 do run.Heartbeat:Fire(.05)run.RenderStepped:Fire(.05)end
assert(attrs.SerenaGrassLoadedPatches==3 and attrs.SerenaGrassNearbyReady,"Dense adjacent grass did not load")
local original=root.CFrame
for _,entry in pairs(client.active)do
 local part=entry.model:FindFirstChildOfClass("MeshPart")assert(part.MeshId==mesh.MeshId and not part.CanCollide and not part.CanQuery)
 for _,bone in ipairs(part:GetDescendants())do if bone:IsA("Bone")and bone:GetAttribute("SerenaGreenRoot")then
  denseNativeNear+=1 local point=bone:GetAttribute("SerenaGroundPoint")
  assert(math.abs(bone.TransformedWorldCFrame.Y-point.Y)<.02,"Dense grass root floated")
 end end
end
assert(denseNativeNear==300,"Adjacent volumes lost blades")
local displaced=0 for _ in pairs(client.grass.DisplaceBones)do displaced+=1 end assert(displaced>0,"Walking does not bend the dense grass")
for _=1,30 do
 root.CFrame=original+Vector3.new(120,0,0)
 run.Heartbeat:Fire(.2)run.RenderStepped:Fire(.05)
 assert(attrs.SerenaGrassLoadedPatches==0 and next(client.grass.MeshRecords)==nil,"Distant grass did not release")
 assert(#client.grass.BoneOctree:RadiusSearch(original.Position,1000)==0,"Unloaded grass leaked octree nodes")
 assert(next(client.grass.DisplaceBones)==nil and next(client.grass.ReturnBones)==nil,"Unloaded blades kept animation records")
 root.CFrame=original
 for _=1,3 do run.Heartbeat:Fire(.1)run.RenderStepped:Fire(.05)end
 assert(attrs.SerenaGrassLoadedPatches==3,"Walking back did not restore continuous grass")
end
local activePeak=0
for _,cell in pairs(field.cells)do
 if cell.key%17==0 then activePeak=math.max(activePeak,#field:around(cell.center,54))end
end
assert(activePeak<coverage:GetAttribute("MaxActiveTouch"),"Touch budget would create visible missing volumes")
mockScript.Destroying:Fire()
assert(not workspace:FindFirstChild("SerenaInteractiveGrass")and next(client.grass.MeshRecords)==nil,"Client cleanup leaked the field")
fixture:Destroy()
return {codecExact=true,greenSamples=greenSamples,uncoveredSamples=gaps,maxRootDistance=maxDistance,worstSample=worst,
 nativeContiguousRoots=denseNativeNear,actualTouchSource=true,walkBending=true,
 proximityUnloadAndReload=true,repeatTravelCycles=30,noBoneOrAnimationLeaks=true,maxTouchResidentPatches=activePeak}
]========])

local coverage=runtime.GrassCoverage coverage:SetAttribute("AuditSamples",tests.greenSamples)coverage:SetAttribute("AuditGaps",tests.uncoveredSamples)coverage:SetAttribute("AuditMaxRootDistance",tests.maxRootDistance)

local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do
 if s:IsA("Script")or s:IsA("LocalScript")then
  local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
  local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
 end
end end
assert(compiled==15,"Runtime scripts incomplete")
local old=game.ReplicatedStorage:FindFirstChild("SkinnedGrass_Storage")if old and #old:GetChildren()==0 then old:Destroy()end
local mapParts=0 for _,d in ipairs(world:GetDescendants())do if d:IsA("BasePart")then mapParts+=1 end end
assert(mapParts==4960,"Map geometry changed unexpectedly")
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834,"Wind changed")
world:SetAttribute("UpgradeVersion",82)
game:GetService("AssetService"):SavePlaceAsync()
return {sourceVersion=game.PlaceVersion,published=true,grass=grass,tests=tests,compiledScripts=compiled,mapParts=mapParts}
