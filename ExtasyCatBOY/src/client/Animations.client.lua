-- Animacoes procedurais R6 avaliadas em CADA cliente.
-- Motor6D.Transform nao replica do servidor; a avaliacao local garante a visualizacao.
-- PreSimulation ocorre depois do Animator e antes do passo fisico.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local companions = workspace:WaitForChild("ExtasyCompanions")

local function jointTransform(joint, desired)
    if joint and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
        joint.Transform = desired
    end
end

local function animate(model, now)
    local torso = model:FindFirstChild("Torso")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not torso or not root then return end
    local ownerId = tonumber(model:GetAttribute("OwnerId")) or 0
    local phase = (ownerId % 53) / 8
    local mood = model:GetAttribute("Personality") or "gentil"
    local kind = model:GetAttribute("Kind") or "cat"
    local speed = Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
    local stride = math.clamp((speed - .8)/5,0,1)
    local pace = mood == "sonolento" and 6 or (mood == "brincalhao" and 11 or 8)
    local t = now*pace + phase
    local swing = math.sin(t) * .40 * stride
    local upper = mood == "timido" and -.12 or (mood == "tsundere" and .07 or 0)
    local bouncy = mood == "brincalhao" and .08 or .035

    jointTransform(torso:FindFirstChild("Right Shoulder"),CFrame.Angles(-swing + upper,0,0))
    jointTransform(torso:FindFirstChild("Left Shoulder"),CFrame.Angles(swing + upper,0,0))
    jointTransform(torso:FindFirstChild("Right Hip"),CFrame.Angles(swing,0,0))
    jointTransform(torso:FindFirstChild("Left Hip"),CFrame.Angles(-swing,0,0))
    jointTransform(torso:FindFirstChild("Neck"),
        CFrame.Angles(math.sin(now*1.6+phase)*.045+(mood=="timido" and .1 or 0),
            0,math.sin(now*1.2+phase)*.06))
    jointTransform(root:FindFirstChild("RootJoint"),
        CFrame.new(0,math.abs(math.sin(t)) * bouncy * stride,0) *
        CFrame.Angles(0,0,math.sin(t)*.032*stride))
    local tail = torso:FindFirstChild("CuteTailMotor")
    local wag = kind=="dog" and .45 or .2
    jointTransform(tail,
        CFrame.Angles(0,math.sin(now*3.9+phase)*wag,
            math.sin(now*2.7+phase)*.22))
end

RunService.PreSimulation:Connect(function()
    local now = os.clock()
    local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _,model in ipairs(companions:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("ExtasyNPC") then
            local root=model:FindFirstChild("HumanoidRootPart")
            if root and (not myRoot or (root.Position-myRoot.Position).Magnitude<140) then
                animate(model,now)
            end
        end
    end
end)
