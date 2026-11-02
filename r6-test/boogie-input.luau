-- Boogie Woogie / Todo: one clap to exchange YOUR position with the target.
-- This LocalScript lives on the user's R6 character. No looping animations,
-- no movement override, no interfering with Naruto chakra wall walking.
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local character=script.Parent
local humanoid=character:WaitForChild("Humanoid")
if humanoid.RigType~=Enum.HumanoidRigType.R6 then return end
local remote=ReplicatedStorage:WaitForChild("BoogieSwap",10)
if not remote then warn("[Boogie] Remote missing"); return end
local actionName="BoogieWoogieR6"
local maxDistance=65
local processing=false

local function valid(model)
 if not model or model==character or not model:IsA("Model") then return nil end
 local h=model:FindFirstChildOfClass("Humanoid")
 local root=model:FindFirstChild("HumanoidRootPart")
 if not h or not root or h.Health<=0 then return nil end
 if not model:IsDescendantOf(workspace) then return nil end
 return root
end
local function targets()
 local found={}
 for _,other in ipairs(Players:GetPlayers()) do
  if other~=player and other.Character then table.insert(found,other.Character) end
 end
 local dummy=workspace:FindFirstChild("BoogieTestDummy")
 if dummy then table.insert(found,dummy) end
 return found
end
local function selectTarget()
 local camera=workspace.CurrentCamera
 local ourRoot=character:FindFirstChild("HumanoidRootPart")
 if not camera or not ourRoot then return nil end
 local center=camera.ViewportSize*0.5
 local best,bestScore=nil,math.huge
 for _,model in ipairs(targets()) do
  local root=valid(model)
  if root then
   local distance=(root.Position-ourRoot.Position).Magnitude
   if distance<=maxDistance then
    local screen,inView=camera:WorldToViewportPoint(root.Position)
    local screenDistance=(Vector2.new(screen.X,screen.Y)-center).Magnitude
    -- Looking toward a character takes precedence; nearest viable target
    -- remains available when testing solo on mobile.
    local score=distance
    if inView and screen.Z>0 and screenDistance<=center.Magnitude*0.75 then
     score=screenDistance*0.03
    else
     score=800+distance
    end
    if score<bestScore then best,bestScore=model,score end
   end
  end
 end
 return best
end
local function activate(_,state)
 if state~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
 if player.Character~=character or humanoid.Health<=0 then return Enum.ContextActionResult.Sink end
 if processing then return Enum.ContextActionResult.Sink end
 local target=selectTarget()
 if not target then
  CAS:SetTitle(actionName,"SEM ALVO")
  task.delay(0.9,function()if character.Parent then CAS:SetTitle(actionName,"BOOGIE") end end)
  return Enum.ContextActionResult.Sink
 end
 processing=true
 remote:FireServer(target)
 task.delay(0.6,function()processing=false end)
 return Enum.ContextActionResult.Sink
end
CAS:BindAction(actionName,activate,true,Enum.KeyCode.G)
CAS:SetTitle(actionName,"BOOGIE")
CAS:SetPosition(actionName,UDim2.new(1,-150,1,-385))
remote.OnClientEvent:Connect(function(status)
 if player.Character~=character then return end
 if status=="ok" then
  CAS:SetTitle(actionName,"TROCOU")
  task.delay(0.6,function()if character.Parent then CAS:SetTitle(actionName,"BOOGIE") end end)
 elseif status=="cooldown" then
  CAS:SetTitle(actionName,"RECARGA")
  task.delay(0.6,function()if character.Parent then CAS:SetTitle(actionName,"BOOGIE") end end)
 end
end)
local function cleanup()
 CAS:UnbindAction(actionName)
end
humanoid.Died:Once(cleanup)
script.Destroying:Once(cleanup)
