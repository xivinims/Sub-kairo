local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local InputController = {}
InputController.__index = InputController

function InputController.new(config)
    local self = setmetatable({}, InputController)
    self.Config = config
    self.InteractRequested = Instance.new("BindableEvent")
    self.CancelRequested = Instance.new("BindableEvent")
    self.PrimaryRequested = Instance.new("BindableEvent")
    self.Enabled = true
    return self
end

function InputController:_bindAction(name, callback, createTouchButton, ...)
    ContextActionService:BindAction(name, function(_, state, input)
        if not self.Enabled then return Enum.ContextActionResult.Pass end
        if state == Enum.UserInputState.Begin then
            callback(input)
        end
        return Enum.ContextActionResult.Sink
    end, createTouchButton, ...)
end

function InputController:Start()
    self:_bindAction(
        "DeadSignalInteract",
        function() self.InteractRequested:Fire() end,
        true,
        Enum.KeyCode.E,
        Enum.KeyCode.ButtonX
    )
    ContextActionService:SetTitle("DeadSignalInteract", "USAR")
    ContextActionService:SetPosition("DeadSignalInteract", UDim2.new(1, -150, 1, -155))

    self:_bindAction(
        "DeadSignalCancel",
        function() self.CancelRequested:Fire() end,
        false,
        Enum.KeyCode.Q,
        Enum.KeyCode.ButtonB
    )

    self:_bindAction(
        "DeadSignalPrimary",
        function(input) self.PrimaryRequested:Fire(input) end,
        false,
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2
    )
end

function InputController:SetEnabled(enabled)
    self.Enabled = enabled == true
end

function InputController:Destroy()
    ContextActionService:UnbindAction("DeadSignalInteract")
    ContextActionService:UnbindAction("DeadSignalCancel")
    ContextActionService:UnbindAction("DeadSignalPrimary")
    self.InteractRequested:Destroy()
    self.CancelRequested:Destroy()
    self.PrimaryRequested:Destroy()
end

return InputController
