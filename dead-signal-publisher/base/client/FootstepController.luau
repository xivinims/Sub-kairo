-- Material-aware temporary foley. These are Roblox engine sounds, not Poppy Playtime recordings.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local Footsteps={}
function Footsteps.Start(layer)
    local p=Players.LocalPlayer
    local running=Instance.new("Sound"); running.Name="DeadSignalPlayerSteps"
    running.SoundId="rbxasset://sounds/action_footsteps_plastic.mp3"; running.Looped=true; running.Volume=0; running.Parent=SoundService
    local eq=Instance.new("EqualizerSoundEffect"); eq.Parent=running
    local reverb=Instance.new("ReverbSoundEffect"); reverb.DecayTime=1.2; reverb.WetLevel=-19; reverb.DryLevel=-1; reverb.Parent=running
    running:Play()
    RunService.Heartbeat:Connect(function()
        local char=p.Character; local h=char and char:FindFirstChildOfClass("Humanoid"); local root=char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local builtIn=root:FindFirstChild("Running"); if builtIn and builtIn:IsA("Sound") then builtIn.Volume=0 end
        end
        local moving=h and h.Health>0 and h.FloorMaterial~=Enum.Material.Air and h.MoveDirection.Magnitude>0.1
        local enabled=p:GetAttribute("DeadSignalPlaying") and not p:GetAttribute("DeadSignalPaused")
        local master=layer:GetAttribute("MasterVolume") or 1
        local sfx=layer:GetAttribute("SfxVolume") or 0.85
        running.Volume=enabled and moving and (h.WalkSpeed<10 and 0.055 or 0.17)*master*sfx or 0
        if h then
            running.PlaybackSpeed=math.clamp(h.WalkSpeed/16,0.65,1.35)
            local metal=h.FloorMaterial==Enum.Material.Metal or h.FloorMaterial==Enum.Material.DiamondPlate
            local wood=h.FloorMaterial==Enum.Material.Wood or h.FloorMaterial==Enum.Material.WoodPlanks
            eq.HighGain=metal and 5 or wood and -7 or 0
            eq.LowGain=wood and 4 or -1
        end
    end)
end
return Footsteps
