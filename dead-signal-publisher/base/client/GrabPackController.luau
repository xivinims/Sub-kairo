local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local RunService=game:GetService("RunService")
local Grab={}
function Grab.Start(layer,remotes,protocol,input)
    local player=Players.LocalPlayer
    local geometry=game:GetService("ReplicatedStorage"):WaitForChild("DeadSignalFoundation"):WaitForChild("GrabPackGeometry")
    local view=Instance.new("Model"); view.Name="GrabPackViewModel"; view.Parent=workspace.CurrentCamera
    local sides={}
    local function clone(name)
        local m=geometry:WaitForChild(name):Clone(); m.Parent=view
        for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true; p.CanQuery=false; p.CanCollide=false; p.LocalTransparencyModifier=0 end end
        return m
    end
    for _,side in ipairs({"Left","Right"}) do
        local m=clone(side=="Left" and "BlueHand" or "RedHand")
        local cuff=clone(side=="Left" and "LeftLauncher" or "RightLauncher")
        local aPart=Instance.new("Part"); aPart.Transparency=1; aPart.Size=Vector3.new(0.05,0.05,0.05); aPart.Anchored=true
        aPart.CanQuery=false; aPart.CanCollide=false; aPart.CanTouch=false; aPart.Parent=view
        local bPart=aPart:Clone(); bPart.Parent=view
        local a=Instance.new("Attachment"); a.Parent=aPart
        local b=Instance.new("Attachment"); b.Parent=bPart
        local beam=Instance.new("Beam"); beam.Attachment0=a; beam.Attachment1=b; beam.Width0=0.065; beam.Width1=0.065
        beam.Color=ColorSequence.new(Color3.fromRGB(32,36,35)); beam.Segments=10; beam.FaceCamera=true; beam.Parent=aPart
        sides[side]={hand=m,cuff=cuff,a=aPart,b=bPart,beam=beam,shot=nil,last=0}
    end
    local function active()
        return player:GetAttribute("DeadSignalPlaying")==true and not player:GetAttribute("DeadSignalPaused") and not layer:GetAttribute("UIBlocked")
    end
    local function fire(side)
        if not active() or os.clock()-sides[side].last<0.5 then return end
        sides[side].last=os.clock()
        if sides[side].shot and sides[side].shot.latched then
            remotes[protocol.Events.GrabAction]:FireServer("Retract"); sides.Left.shot=nil; sides.Right.shot=nil; return
        end
        local cam=workspace.CurrentCamera
        if cam then remotes[protocol.Events.GrabAction]:FireServer(side,cam.CFrame.LookVector) end
    end
    input.PrimaryRequested.Event:Connect(function() fire("Left") end)
    CAS:BindAction("DeadSignalRightHand",function(_,state)
        if not active() then return Enum.ContextActionResult.Pass end
        if state==Enum.UserInputState.Begin then fire("Right") end
        return Enum.ContextActionResult.Sink
    end,false,Enum.UserInputType.MouseButton2,Enum.KeyCode.ButtonL2)
    UIS.InputBegan:Connect(function(i,processed)
        if not processed and i.KeyCode==Enum.KeyCode.R then
            remotes[protocol.Events.GrabAction]:FireServer("Retract"); sides.Left.shot=nil; sides.Right.shot=nil
        end
    end)
    local buttons={}
    for i,side in ipairs({"Left","Right"}) do
        local b=Instance.new("TextButton"); b.Name=side.."GrabTouch"; b.Text=side=="Left" and "MÃO AZUL" or "MÃO VERMELHA"
        b.Size=UDim2.fromOffset(96,58); b.Position=UDim2.new(1,-240+(i-1)*112,1,-236)
        b.BackgroundColor3=side=="Left" and Color3.fromRGB(28,53,95) or Color3.fromRGB(98,36,31)
        b.BackgroundTransparency=0.25; b.TextColor3=Color3.fromRGB(228,224,204); b.TextSize=13; b.Font=Enum.Font.Code
        b.Modal=false; b.Parent=layer; b.Activated:Connect(function() fire(side) end); table.insert(buttons,b)
    end
    remotes[protocol.Events.GrabState].OnClientEvent:Connect(function(payload)
        if payload.kind=="retract" then sides.Left.shot=nil; sides.Right.shot=nil; return end
        local s=sides[payload.side]
        if s and typeof(payload.target)=="Vector3" then
            s.shot={at=os.clock(),target=payload.target,latched=payload.latched,duration=payload.duration or 0.25,kind=payload.kind}
        end
    end)
    RunService:BindToRenderStep("DeadSignalGrabPack",Enum.RenderPriority.Camera.Value+2,function(dt)
        local cam=workspace.CurrentCamera; if not cam then return end
        local enabled=active()
        for _,b in ipairs(buttons) do b.Visible=enabled and UIS.TouchEnabled end
        local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local speed=hum and hum.MoveDirection.Magnitude or 0
        local reduced=layer:GetAttribute("ReducedMotion")
        local bob=reduced and 0 or math.sin(os.clock()*8)*0.025*speed
        for side,s in pairs(sides) do
            local sign=side=="Left" and -1 or 1
            local idle=cam.CFrame*CFrame.new(sign*0.75,-0.63+bob,-1.55)*CFrame.Angles(0,0,math.rad(sign*-7))
            local cuff=cam.CFrame*CFrame.new(sign*0.75,-1.12+bob,-1.02)*CFrame.Angles(math.rad(-8),0,0)
            local cf=idle
            if s.shot then
                local t=os.clock()-s.shot.at
                local outbound=math.clamp(t/0.18,0,1)
                local stop=s.shot.latched and s.shot.duration or 0.28
                if t>0.18+stop then outbound=1-math.clamp((t-0.18-stop)/0.22,0,1) end
                if t>0.4+stop then s.shot=nil
                else
                    local target=CFrame.lookAt(s.shot.target,s.shot.target+cam.CFrame.LookVector)
                    cf=idle:Lerp(target,outbound)
                end
            end
            s.hand:PivotTo(enabled and cf or CFrame.new(0,-200,0))
            s.cuff:PivotTo(enabled and cuff or CFrame.new(0,-200,0))
            s.a.CFrame=cuff; s.b.CFrame=cf
            s.beam.Enabled=enabled and s.shot~=nil
            s.beam.Color=ColorSequence.new(s.shot and (s.shot.kind=="charged" or s.shot.kind=="power-bridge") and Color3.fromRGB(73,145,189) or Color3.fromRGB(32,36,35))
            s.beam.LightEmission=s.shot and s.shot.latched and 0.55 or 0
        end
    end)
end
return Grab
