-- Sprint input only. DOES NOT play any animation track or touch Motor6D.
-- The original Naruto R6 animator receives running speed from GravityController,
-- so walking, running, jumping and ChakraFeet stay in a single animation system.
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local localPlayer=Players.LocalPlayer
local character=script.Parent
local humanoid=character:WaitForChild("Humanoid")
if humanoid.RigType~=Enum.HumanoidRigType.R6 or localPlayer.Character~=character then return end
local baseSpeed=16
local sprintSpeed=24
local sprinting=false
humanoid.WalkSpeed=baseSpeed
local function update(state)
    if humanoid.Health<=0 then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then sprinting=true
    elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then sprinting=false
    else return Enum.ContextActionResult.Pass end
    humanoid.WalkSpeed=sprinting and sprintSpeed or baseSpeed
    character:SetAttribute("NarutoSprinting",sprinting)
    return Enum.ContextActionResult.Sink
end
CAS:BindAction("NarutoR6Sprint",function(_,state)return update(state)end,true,Enum.KeyCode.LeftShift)
CAS:SetTitle("NarutoR6Sprint","CORRER")
CAS:SetPosition("NarutoR6Sprint",UDim2.new(1,-145,1,-205))
local function cleanup()
 CAS:UnbindAction("NarutoR6Sprint")
end
humanoid.Died:Once(cleanup)
script.Destroying:Once(cleanup)
