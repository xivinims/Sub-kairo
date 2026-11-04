local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local CAS=game:GetService('ContextActionService')
local Collection=game:GetService('CollectionService')
local player=Players.LocalPlayer
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local remote=package:WaitForChild('Equipment')
local rules=require(package:WaitForChild('EquipmentRules'))
local gui=Instance.new('ScreenGui');gui.Name='EquipmentHUD';gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild('PlayerGui')
local function circle(text,x,y)
 local b=Instance.new('TextButton');b.Size=UDim2.fromOffset(76,76);b.Position=UDim2.new(x,-38,y,-38);b.BackgroundColor3=Color3.fromRGB(25,25,29);b.BackgroundTransparency=.45;b.TextColor3=Color3.new(1,1,1);b.Text=text;b.TextSize=16;b.Font=Enum.Font.GothamBold;b.Parent=gui
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(1,0);c.Parent=b
 local stroke=Instance.new('UIStroke');stroke.Thickness=3;stroke.Color=Color3.fromRGB(155,155,155);stroke.Parent=b
 return b
end
local lightButton=circle('LUZ',.09,.70)
local utilityButton=circle('USAR',.53,.88)
local powerButton=circle('BASTÃO',.44,.88)
powerButton.Activated:Connect(function()local id=player:GetAttribute('NBPower');if id and id~=''then remote:FireServer('Use',id)end end)
local indicator=circle('',.62,.88);indicator.Active=false
local function useLight()remote:FireServer('Use','flashlight')end
local function useUtility()local id=player:GetAttribute('NBUtility');if id and id~='' then remote:FireServer('Use',id)end end
lightButton.Activated:Connect(useLight);utilityButton.Activated:Connect(useUtility)
CAS:BindAction('NBLight',function(_,state)if state==Enum.UserInputState.Begin then useLight()end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.F)
CAS:BindAction('NBUtilityUse',function(_,state)if state==Enum.UserInputState.Begin then useUtility()end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.One)
local lampPart=Instance.new('Part');lampPart.Name='NBLocalLight';lampPart.Size=Vector3.new(.1,.1,.1);lampPart.Transparency=1;lampPart.Anchored=true;lampPart.CanCollide=false;lampPart.CanTouch=false;lampPart.CanQuery=false;lampPart.Parent=workspace
local lamp=Instance.new('SpotLight');lamp.Face=Enum.NormalId.Front;lamp.Range=50;lamp.Angle=65;lamp.Brightness=2;lamp.Shadows=true;lamp.Enabled=false;lamp.Parent=lampPart
local night=Instance.new('ColorCorrectionEffect');night.Name='NBNightVision';night.TintColor=Color3.fromRGB(135,255,145);night.Brightness=.2;night.Contrast=.15;night.Enabled=false;night.Parent=game:GetService('Lighting')
local elapsed=0;local phase=0
Run.RenderStepped:Connect(function(dt)
 local active=player:GetAttribute('NBInArena')==true
 powerButton.Visible=active and (player:GetAttribute('NBPower')or '')~=''
 gui.Enabled=active;lamp.Enabled=active and player:GetAttribute('NBFlashlight')==true
 night.Enabled=active and player:GetAttribute('NBFlashlight')==true and player:GetAttribute('NBLightID')=='nvg'
 local camera=workspace.CurrentCamera
 if camera then lampPart.CFrame=camera.CFrame*CFrame.new(.5,-.3,-.8) end
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local id=player:GetAttribute('NBUtility');indicator.Visible=active and id~=nil and id~='';utilityButton.Visible=active and id~=nil and id~='' and id~='compass' and id~='timer' and id~='radar'
 if not active then return end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if not root or not camera then return end
 indicator.Rotation=0
 if id=='timer' then
  local n=rules.remaining(package:GetAttribute('Deadline') or 0,workspace:GetServerTimeNow());indicator.Text=string.format('%d:%02d',math.floor(n/60),n%60)
 elseif id=='compass' then
  local direction=Vector3.new(0,0,-1);local distance=math.huge
  for _,v in ipairs(Collection:GetTagged('NBObjective')) do
   if v:IsDescendantOf(workspace) and v:IsA('BasePart') and v:GetAttribute('Completed')~=true then
    local delta=v.Position-root.Position;if delta.Magnitude<distance then distance=delta.Magnitude;direction=delta end
   end
  end
  local relative=camera.CFrame:VectorToObjectSpace(direction)
  indicator.Text='↑';indicator.Rotation=math.deg(math.atan2(relative.X,-relative.Z))
 elseif id=='radar' then
  local distance=math.huge
  for _,bot in ipairs(Collection:GetTagged('NBNextbot')) do
   local br=bot:FindFirstChild('HumanoidRootPart');if br and bot:IsDescendantOf(workspace) then distance=math.min(distance,(br.Position-root.Position).Magnitude)end
  end
  phase+=.1;local interval=rules.pulse(distance)
  indicator.Text='◉';indicator.BackgroundTransparency=phase%interval<.12 and .05 or .6
  -- Exact radar audio is unresolved. No unrelated sound ID is substituted.
 elseif id=='decoy' or id=='radio' or id=='baton' or id=='barrier' or id=='cola' then
  local n=rules.remaining(player:GetAttribute('NBDecoyReadyAt') or 0,workspace:GetServerTimeNow());indicator.Text=n>0 and tostring(n) or string.upper(id)
 end
end)
script.Destroying:Connect(function()lampPart:Destroy();gui:Destroy();CAS:UnbindAction('NBLight');CAS:UnbindAction('NBUtilityUse')end)

remote.OnClientEvent:Connect(function(status,userId,position)
 if status=='ping' and typeof(position)=='Vector3' then
  local marker=Instance.new('Part');marker.Size=Vector3.one;marker.Anchored=true;marker.CanCollide=false;marker.CanQuery=false;marker.Transparency=1;marker.Position=position;marker.Parent=workspace
  local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(180,50);gui.AlwaysOnTop=true;gui.Parent=marker
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text='📻 SINAL DE RÁDIO';label.TextSize=18;label.TextColor3=Color3.fromRGB(130,240,150);label.Font=Enum.Font.GothamBold;label.Parent=gui
  game:GetService('Debris'):AddItem(marker,8)
 end
end)

local function headphones()
 local equipped=player:GetAttribute('NBPerk')=='headphones'or player:GetAttribute('NBPerk2')=='headphones'
 for _,bot in ipairs(Collection:GetTagged('NBNextbot'))do for _,sound in ipairs(bot:GetDescendants())do if sound:IsA('Sound')then sound.RollOffMaxDistance=equipped and 180 or 100 end end end
end
Collection:GetInstanceAddedSignal('NBNextbot'):Connect(function()task.defer(headphones)end)
player:GetAttributeChangedSignal('NBPerk'):Connect(headphones);player:GetAttributeChangedSignal('NBPerk2'):Connect(headphones)
