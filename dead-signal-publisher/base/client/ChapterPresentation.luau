local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local Tags=game:GetService("CollectionService")
local Presentation={}
function Presentation.Start(gui,remotes,protocol,input)
    local player=Players.LocalPlayer
    local layer=Instance.new("ScreenGui"); layer.Name="DeadSignalFrontEnd"; layer.IgnoreGuiInset=true
    layer.ResetOnSpawn=false; layer.DisplayOrder=60; layer.Parent=gui.Parent
    local function label(parent,text,pos,size,font)
        local p=Instance.new("TextLabel"); p.BackgroundTransparency=1; p.Text=text
        p.Position=pos; p.Size=size; p.Font=font or Enum.Font.Gotham; p.TextColor3=Color3.fromRGB(226,218,194)
        p.TextScaled=true; p.TextXAlignment=Enum.TextXAlignment.Left; p.Parent=parent; return p
    end
    local function button(parent,text,pos,size,fn)
        local b=Instance.new("TextButton"); b.Text=text; b.Position=pos; b.Size=size
        b.BackgroundColor3=Color3.fromRGB(24,31,30); b.BackgroundTransparency=0.2; b.TextColor3=Color3.fromRGB(228,219,192)
        b.Font=Enum.Font.GothamMedium; b.TextSize=22; b.AutoButtonColor=true; b.Parent=parent
        local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(102,106,83); stroke.Transparency=0.5; stroke.Parent=b
        b.Activated:Connect(fn); return b
    end
    local menu=Instance.new("Frame"); menu.Size=UDim2.fromScale(1,1); menu.BackgroundColor3=Color3.fromRGB(7,12,11)
    menu.BackgroundTransparency=0.32; menu.Parent=layer
    local shade=Instance.new("UIGradient"); shade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.6,0.3),NumberSequenceKeypoint.new(1,0.85)}); shade.Parent=menu
    label(menu,"DEAD\nSIGNAL",UDim2.fromScale(0.075,0.1),UDim2.fromScale(0.46,0.29),Enum.Font.Antique)
    label(menu,"CAPÍTULO 01 · A LINHA DE ESCUTA",UDim2.fromScale(0.08,0.405),UDim2.fromScale(0.6,0.045))
    label(menu,"AURIVANE WORKS / SIGNALWORKS 1978",UDim2.fromScale(0.08,0.91),UDim2.fromScale(0.72,0.027))
    label(menu,"BUILD 03 · TESTE",UDim2.fromScale(0.73,0.94),UDim2.fromScale(0.25,0.025))
    for i=1,18 do
        local l=Instance.new("Frame"); l.BackgroundColor3=Color3.new(0,0,0); l.BackgroundTransparency=0.85
        l.BorderSizePixel=0; l.Size=UDim2.new(1,0,0,1); l.Position=UDim2.fromScale(0,i/19); l.Parent=menu
    end
    local message=label(layer,"",UDim2.fromScale(0.13,0.13),UDim2.fromScale(0.74,0.09)); message.TextXAlignment=Enum.TextXAlignment.Center
    message.BackgroundColor3=Color3.fromRGB(19,29,27); message.TextWrapped=true; message.Visible=false
    local pending=false; local playing=false; local savedCamera
    input:SetEnabled(false); gui.Enabled=false
    local settings=Instance.new("Frame"); settings.Size=UDim2.fromScale(0.78,0.76); settings.Position=UDim2.fromScale(0.11,0.12)
    settings.BackgroundColor3=Color3.fromRGB(18,27,25); settings.Visible=false; settings.Parent=layer
    label(settings,"CONFIGURAÇÕES",UDim2.fromScale(0.07,0.06),UDim2.fromScale(0.8,0.1))
    local volume=1; local reduced=false; local shadows=true
    local function sendSettings() remotes[protocol.Events.ChapterAction]:FireServer("settings",{masterVolume=volume,reducedMotion=reduced,shadows=shadows}) end
    local volumeButton
    volumeButton=button(settings,"Volume: 100%",UDim2.fromScale(0.07,0.24),UDim2.fromScale(0.86,0.14),function()
        volume=volume==1 and 0.5 or volume==0.5 and 0 or 1
        volumeButton.Text="Volume: "..math.floor(volume*100).."%"; sendSettings()
    end)
    local motionButton
    motionButton=button(settings,"Movimento reduzido: não",UDim2.fromScale(0.07,0.43),UDim2.fromScale(0.86,0.14),function()
        reduced=not reduced; motionButton.Text="Movimento reduzido: "..(reduced and "sim" or "não"); sendSettings()
    end)
    local shadowButton
    shadowButton=button(settings,"Sombras: sim",UDim2.fromScale(0.07,0.62),UDim2.fromScale(0.86,0.14),function()
        shadows=not shadows; Lighting.GlobalShadows=shadows; shadowButton.Text="Sombras: "..(shadows and "sim" or "não"); sendSettings()
    end)
    button(settings,"FECHAR",UDim2.fromScale(0.65,0.83),UDim2.fromScale(0.28,0.11),function() settings.Visible=false end)
    local function start(action)
        if pending then return end; pending=true
        remotes[protocol.Events.ChapterAction]:FireServer(action)
        task.delay(12,function() pending=false end)
    end
    button(menu,"CONTINUAR",UDim2.fromScale(0.08,0.51),UDim2.fromScale(0.36,0.105),function() start("continue") end)
    local confirm=false; local newButton
    newButton=button(menu,"NOVO JOGO",UDim2.fromScale(0.08,0.64),UDim2.fromScale(0.36,0.105),function()
        if not confirm then
            confirm=true; newButton.Text="CONFIRMAR NOVO JOGO"
            task.delay(5,function() confirm=false; newButton.Text="NOVO JOGO" end)
        else start("new") end
    end)
    button(menu,"CONFIGURAÇÕES",UDim2.fromScale(0.08,0.77),UDim2.fromScale(0.36,0.08),function() settings.Visible=true end)
    local gear=button(layer,"⚙",UDim2.new(1,-62,0,48),UDim2.fromOffset(46,46),function() settings.Visible=not settings.Visible end); gear.Visible=false
    local drop=button(layer,"SOLTAR",UDim2.new(1,-225,1,-115),UDim2.fromOffset(94,48),function() remotes[protocol.Events.ChapterAction]:FireServer("drop") end); drop.Visible=false
    remotes[protocol.Events.WireState].OnClientEvent:Connect(function(kind)
        if kind=="carry-start" then drop.Visible=true elseif kind=="carry-end" then drop.Visible=false end
    end)
    local cross=label(layer,"·",UDim2.fromScale(0.49,0.47),UDim2.fromScale(0.02,0.05)); cross.Visible=false
    local sound=Instance.new("Sound"); sound.Name="SignalworksFoley"
    -- Engine-provided stock foley, never audio extracted from another game.
    sound.SoundId="rbxasset://sounds/electronicpingshort.wav"; sound.Volume=0.22; sound.Parent=SoundService
    local ambient=Instance.new("Sound"); ambient.Name="TransformerBed"
    ambient.SoundId="rbxasset://sounds/electronicpingshort.wav"; ambient.PlaybackSpeed=0.18
    ambient.Looped=true; ambient.Volume=0.025; ambient.Parent=SoundService
    local steps=Instance.new("Sound"); steps.Name="ThreadbareSteps"
    steps.SoundId="rbxasset://sounds/action_footsteps_plastic.mp3"; steps.Looped=true
    steps.PlaybackSpeed=0.65; steps.Volume=0; steps.Parent=SoundService
    ambient:Play(); steps:Play()
    local token=0
    remotes[protocol.Events.ChapterFeedback].OnClientEvent:Connect(function(text,kind)
        pending=false
        if kind=="started" then
            playing=true; menu.Visible=false; gear.Visible=true; gui.Enabled=true; cross.Visible=true; input:SetEnabled(true)
            workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
            if player.Character then workspace.CurrentCamera.CameraSubject=player.Character:FindFirstChildOfClass("Humanoid") end
        end
        ambient.Volume=0.025*volume
        if volume>0 then sound.Volume=0.22*volume; sound:Play() end
        token+=1; local n=token; message.Text=text; message.Visible=true
        task.delay(kind=="chase" and 5 or 3.5,function() if n==token then message.Visible=false end end)
    end)
    player.CharacterAdded:Connect(function(character)
        if playing then workspace.CurrentCamera.CameraSubject=character:WaitForChild("Humanoid") end
    end)
    task.spawn(function()
        local ok,state=pcall(function() return remotes[protocol.Functions.GetGameState]:InvokeServer() end)
        if ok and state and state.settings then
            volume=state.settings.masterVolume or 1; reduced=state.settings.reducedMotion==true
            shadows=state.settings.shadows~=false; Lighting.GlobalShadows=shadows
            volumeButton.Text="Volume: "..math.floor(volume*100).."%"
            motionButton.Text="Movimento reduzido: "..(reduced and "sim" or "não")
            shadowButton.Text="Sombras: "..(shadows and "sim" or "não")
        end
    end)
    local original={}; local elapsed=0
    RunService.RenderStepped:Connect(function(dt)
        elapsed+=dt
        if not playing then
            local camera=workspace.CurrentCamera
            if camera then camera.CameraType=Enum.CameraType.Scriptable
                local base=CFrame.lookAt(Vector3.new(12,8,66),Vector3.new(-19,7,83))
                camera.CFrame=base*(reduced and CFrame.new() or CFrame.Angles(0,math.sin(elapsed*0.15)*0.025,0))
            end
        end
        -- Nearby visual animation only. No server AI or pathfinding every render frame.
        if reduced then return end
        local camera=workspace.CurrentCamera
        for _,rig in ipairs(Tags:GetTagged("DeadSignalStalker")) do
            local root=rig:FindFirstChild("HumanoidRootPart")
            if root and camera and (camera.CFrame.Position-root.Position).Magnitude<110 then
                local speed=root.AssemblyLinearVelocity.Magnitude
                steps.Volume=playing and math.clamp(1-(camera.CFrame.Position-root.Position).Magnitude/65,0,1)*(speed>1 and 0.25 or 0)*volume or 0
                for _,joint in ipairs(root:GetChildren()) do
                    if joint:IsA("Motor6D") then
                        original[joint]=original[joint] or joint.C0
                        local arm=string.find(joint.Name,"Arm") or string.find(joint.Name,"Leg")
                        local phase=string.find(joint.Name,"Left") and 0 or math.pi
                        joint.C0=original[joint]*CFrame.Angles(arm and math.sin(elapsed*(speed>12 and 11 or 3)+phase)*(speed>1 and 0.4 or 0.018) or 0,0,math.sin(elapsed*1.7)*0.018)
                    end
                end
            end
        end
    end)
end
return Presentation
