local RunService = game:GetService("RunService")

local WireController = {}
WireController.__index = WireController

function WireController.new(config)
    local self = setmetatable({}, WireController)
    self.Config = config
    self.Held = nil
    self.StartAttachment = nil
    self.EndAttachment = nil
    self.Beam = nil
    self.TargetPart = nil
    self.Changed = Instance.new("BindableEvent")
    return self
end

function WireController:_ensurePreview()
    if self.Beam then return end

    local startPart = Instance.new("Part")
    startPart.Name = "_WirePreviewStart"
    startPart.Size = Vector3.new(0.1, 0.1, 0.1)
    startPart.Transparency = 1
    startPart.Anchored = true
    startPart.CanCollide = false
    startPart.CanTouch = false
    startPart.CanQuery = false
    startPart.Parent = workspace

    local endPart = startPart:Clone()
    endPart.Name = "_WirePreviewEnd"
    endPart.Parent = workspace

    local a0 = Instance.new("Attachment")
    a0.Parent = startPart
    local a1 = Instance.new("Attachment")
    a1.Parent = endPart

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Width0 = 0.14
    beam.Width1 = 0.14
    beam.FaceCamera = true
    beam.Segments = 12
    beam.Color = ColorSequence.new(Color3.fromRGB(201, 51, 54))
    beam.Transparency = NumberSequence.new(0.08)
    beam.Parent = startPart

    self.StartPart = startPart
    self.EndPart = endPart
    self.StartAttachment = a0
    self.EndAttachment = a1
    self.Beam = beam
end

function WireController:Begin(wireId, origin)
    self:_ensurePreview()
    self.Held = wireId
    self.StartPart.Position = origin
    self.EndPart.Position = origin
    self.Beam.Enabled = true
    self.Changed:Fire("begin", wireId)
end

function WireController:UpdateTarget(position, valid)
    if not self.Held or not self.Beam then return end
    self.EndPart.Position = position
    self.Beam.Color = ColorSequence.new(valid and Color3.fromRGB(139, 198, 119) or Color3.fromRGB(201, 51, 54))
end

function WireController:End()
    local wire = self.Held
    self.Held = nil
    if self.Beam then self.Beam.Enabled = false end
    self.Changed:Fire("end", wire)
end

function WireController:Destroy()
    if self.StartPart then self.StartPart:Destroy() end
    if self.EndPart then self.EndPart:Destroy() end
    self.Changed:Destroy()
end

return WireController
