local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Collection = game:GetService("CollectionService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
require(runtime:WaitForChild("Visuals")).apply()
while not workspace.CurrentCamera do Run.Heartbeat:Wait() end
local WindLines = require(runtime.WindEffects:WaitForChild("WindLines"))
local WindShake = require(runtime.WindEffects:WaitForChild("WindShake"))
local function foliage(part)
	if part:IsA("BasePart") then Collection:AddTag(part, "WindShake") end
end
for _, part in ipairs(Collection:GetTagged("ForestWindFoliage")) do foliage(part) end
local added = Collection:GetInstanceAddedSignal("ForestWindFoliage"):Connect(foliage)
local removed = Collection:GetInstanceRemovedSignal("ForestWindFoliage"):Connect(function(p) Collection:RemoveTag(p, "WindShake") end)
WindLines:Init({Direction = workspace.GlobalWind.Unit, Speed = 10, Lifetime = 2, SpawnRate = UIS.TouchEnabled and 5 or 8})
WindShake:SetDefaultSettings({WindDirection = workspace.GlobalWind.Unit, WindSpeed = 10, WindPower = 0.035})
WindShake:Init()
local animals = {}
local localFolder = Instance.new("Folder") localFolder.Name = "ForestLocalWildlife" localFolder.Parent = workspace
local function addAnimal(anchor)
	if not anchor:IsA("BasePart") or animals[anchor] then return end
	animals[anchor] = {anchor = anchor, model = nil, rest = anchor.CFrame}
end
local function removeAnimal(anchor)
	local entry = animals[anchor] if not entry then return end
	if entry.track then entry.track:Stop(0) end
	if entry.model then entry.model:Destroy() end animals[anchor] = nil
end
for _, a in ipairs(Collection:GetTagged("ForestWildlifeAnchor")) do addAnimal(a) end
local animalAdded = Collection:GetInstanceAddedSignal("ForestWildlifeAnchor"):Connect(addAnimal)
local animalRemoved = Collection:GetInstanceRemovedSignal("ForestWildlifeAnchor"):Connect(removeAnimal)
local function activate(entry)
	local template = runtime.WildlifeTemplates:FindFirstChild(entry.anchor:GetAttribute("WildlifeType"))
	if not template then return end
	local model = template:Clone() model:PivotTo(entry.rest) model.Parent = localFolder entry.model = model
	local controller = model:FindFirstChildOfClass("AnimationController")
	local animator = controller and controller:FindFirstChildOfClass("Animator")
	if animator then
		task.spawn(function()
			local animation = Instance.new("Animation") animation.AnimationId = "rbxassetid://" .. template:GetAttribute("AnimationId")
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end) animation:Destroy()
			if ok and entry.model == model then track.Looped = true track:Play(0.3, 1, 1) entry.track = track end
		end)
	end
end
local elapsed, scan = 0, 0
local step = Run.Heartbeat:Connect(function(dt)
	elapsed += dt scan += dt
	if elapsed < 1 / 24 then return end elapsed = 0
	local camera = workspace.CurrentCamera if not camera then return end
	local now = workspace:GetServerTimeNow()
	if scan > 0.5 then
		scan = 0 local wind = workspace.GlobalWind
		if wind.Magnitude > 0.01 then WindLines.Direction = wind.Unit end
		WindLines.Speed = math.clamp(wind.Magnitude * 1.2, 6, 13)
		WindShake:SetDefaultSettings({WindDirection = wind.Unit, WindSpeed = WindLines.Speed, WindPower = 0.035})
	end
	local active = 0
	for _, entry in pairs(animals) do
		local distance = (entry.rest.Position - camera.CFrame.Position).Magnitude
		if distance < 65 and active < (UIS.TouchEnabled and 4 or 8) then
			active += 1 if not entry.model then activate(entry) end
			if entry.model then
				local phase = entry.rest.Z * 0.07
				entry.model:PivotTo(entry.rest + Vector3.new(math.sin(now * 0.4 + phase) * 1.8, math.sin(now * 0.65 + phase) * 0.45, math.cos(now * 0.45 + phase) * 1.3))
			end
		elseif entry.model then
			if entry.track then entry.track:Stop(0) entry.track = nil end
			entry.model:Destroy() entry.model = nil
		end
	end
end)
script.Destroying:Connect(function()
	step:Disconnect() added:Disconnect() removed:Disconnect() animalAdded:Disconnect() animalRemoved:Disconnect()
	WindLines:Cleanup() WindShake:Cleanup()
	for anchor in pairs(animals) do removeAnimal(anchor) end localFolder:Destroy()
end)
