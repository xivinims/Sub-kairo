return function(dm)
 local RS=dm:GetService('ReplicatedStorage');local SSS=dm:GetService('ServerScriptService')
 local function edit(s,old,new)
  local a,b=s.Source:find(old,1,true);assert(a,'Weapon source contract changed '..s:GetFullName()..' / '..old)
  s.Source=s.Source:sub(1,a-1)..new..s.Source:sub(b+1);s:SetAttribute('CompatibilityChange','Original weapon recovery: touch input, bounded animation waits, equip reconciliation')
 end
 local base=RS.Library.Shared.WeaponsHandler.BaseWeapon
 local start=base.Source:find('\t\twhile self.Animations.Viewmodel:GetAnimation("Idle").Length == 0 do',1,true)
 local finish=base.Source:find('\t\tself.Animations.Character:PlayAnimation("Equip",0)',start,true)
 assert(start and finish,'Original equip animation gate changed')
 edit(base,base.Source:sub(start,finish-1),[[
  -- Missing animation permissions must not hide the weapon or prevent firing.
  local deadline=os.clock()+3
  local idle=self.Animations.Viewmodel:GetAnimation("Idle")
  local equip=self.Animations.Viewmodel:GetAnimation("Equip")
  while self.IsEquipped and idle and equip and (idle.Length==0 or equip.Length==0) and os.clock()<deadline do task.wait(.1) end
  if not self.IsEquipped then return end
  if not idle or not equip or idle.Length==0 or equip.Length==0 then warn('[OriginalFPS] Animation unavailable; keeping weapon and controls active: '..self.Name) end

]])
 edit(base,'local weaponJoint:Motor6D = upperTorso.WeaponJoint','local weaponJoint:Motor6D = upperTorso:WaitForChild("WeaponJoint",10)\n if not weaponJoint then warn("[OriginalFPS] WeaponJoint missing");return end')
 edit(base,'local weaponJoint:Motor6D = upperTorso.WeaponJoint','local weaponJoint:Motor6D = upperTorso:FindFirstChild("WeaponJoint")')
 edit(base,'weaponJoint.Part1 = nil','if weaponJoint then weaponJoint.Part1 = nil end')
 edit(base,'self:OnAncestryChanged()\nend','self:OnAncestryChanged()\n if isClient then task.defer(function() if self.WeaponTool.Parent==self.Character and not self.IsEquipped then self:OnEquipped() end end) end\nend')
 edit(base,'function weapon:OnEquipped()','function weapon:OnEquipped()\n if self.IsEquipped then return end')
 -- Keep original weapon callbacks, but react to touch hold/release instead of querying a mouse.
 local gun=base.Gun
 edit(gun,'library.MovementHandler.ToggleSprint(false)','library.MovementHandler:ToggleSprint(false)')
 edit(gun,'local currentFiremode = self:GetCurrentFiremode()\n\n\t\tif inputState',[[local currentFiremode = self:GetCurrentFiremode()
  if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then self.__triggerHeld=false end
  if inputState == Enum.UserInputState.Cancel then self.Charging=false;self:CancelThread("Charge");return end
  if inputState == Enum.UserInputState.Begin then
   if self.__triggerHeld or player:GetAttribute('InterfaceOpen') then return end
   self.__triggerHeld=true
  end

  if inputState]])
 for _=1,2 do edit(gun,'if not userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end','if not self.__triggerHeld or player:GetAttribute("InterfaceOpen") then return end') end
 edit(gun,'function gun:__removeInputs()','function gun:__removeInputs()\n self.__triggerHeld=false')
 edit(gun,'end,true,Enum.KeyCode.B)','end,false,Enum.KeyCode.B)')
 -- Complete registration if the server equipped the Tool before Backpack.ChildAdded ran.
 local client=RS.OriginalStarterGui.Scripts.Game.ClientHandler
 edit(client,'backpack.ChildAdded:Connect(function(tool)\n\tNewWeapon(tool)\nend)',[[backpack.ChildAdded:Connect(function(tool) task.defer(NewWeapon,tool) end)
char.ChildAdded:Connect(function(tool) if tool:IsA('Tool') then task.defer(NewWeapon,tool) end end)
for _,tool in ipairs(char:GetChildren()) do if tool:IsA('Tool') then task.defer(NewWeapon,tool) end end]])
 local server=SSS.Weapons.WeaponsServer
 edit(server,'(char:FindFirstChild("UpperTorso") or char:WaitForChild("Torso"))','char:WaitForChild(char:WaitForChild("Humanoid").RigType==Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso")')
 -- Original mobile art and actions, independent of the default JumpButton's hitbox.
 local controls=RS.Library.Client.ContextActionUtility
 edit(controls,'TouchGui = PlayerGui:WaitForChild("TouchGui")\n\tTouchControlFrame = TouchGui:WaitForChild("TouchControlFrame")\n\tJumpButton = TouchControlFrame:WaitForChild("JumpButton")','TouchGui = PlayerGui:FindFirstChild("TouchGui")\n TouchControlFrame = TouchGui and TouchGui:FindFirstChild("TouchControlFrame")\n JumpButton = TouchControlFrame and TouchControlFrame:FindFirstChild("JumpButton")')
 edit(controls,'if isMobile then FixDefaultJumpButton() end','if isMobile and JumpButton then FixDefaultJumpButton() end')
 edit(controls,'local Buttons = {}',[[local Buttons = {}
local touchLayer
if isMobile then
 local gui=Instance.new('ScreenGui');gui.Name='OriginalWeaponTouch';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=80;gui.Parent=PlayerGui
 touchLayer=Instance.new('Frame');touchLayer.Size=UDim2.fromScale(1,1);touchLayer.BackgroundTransparency=1;touchLayer.Parent=gui
end
local placements={Shoot={78,180,72,'ATIRAR'},ADS={164,174,60,'MIRAR'},Reload={242,170,56,'RECARREGAR'},Crouch={164,92,56,'AGACHAR'},Sprint={242,92,56,'CORRER'}}
local function placeButton(button,action)
 local spec=placements[action];if not spec then return end
 local x,y,size=spec[1],spec[2],spec[3]
 if touchLayer.AbsoluteSize.X<600 then
  local portrait={Shoot={64,170},ADS={142,170},Reload={64,250},Crouch={142,250},Sprint={64,330}}
  x,y=portrait[action][1],portrait[action][2]
 end
 button.AnchorPoint=Vector2.new(.5,.5);button.Position=UDim2.new(1,-x,1,-y);button.Size=UDim2.fromOffset(size,size)
 local title=button:FindFirstChild('title')
 if not title then title=Instance.new('TextLabel');title.Name='title';title.Size=UDim2.fromScale(1,1);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamMedium;title.TextSize=10;title.TextWrapped=true;title.TextColor3=Color3.new(1,1,1);title.Parent=button end
 title.Text=spec[4];title.Visible=true
end
if touchLayer then touchLayer:GetPropertyChangedSignal('AbsoluteSize'):Connect(function() for name,data in pairs(Buttons) do placeButton(data.Button,name) end end) end]])
 edit(controls,'button.Parent = JumpButton',[[button.Parent = touchLayer
 button.Visible = actionName~='Crouch'
 placeButton(button,actionName)]])
 edit(controls,'local function inputBeganHandler(inputObject)',[[local function inputBeganHandler(inputObject)
  if inputObject.UserInputType~=Enum.UserInputType.Touch and inputObject.UserInputType~=Enum.UserInputType.MouseButton1 then return end]])
 -- All action buttons release on focus loss/menu opening, even if a finger leaves the button.
 edit(controls,'connections.End = button.InputEnded:Connect(inputEndedHandler)',[[connections.End = button.InputEnded:Connect(inputEndedHandler)
 connections.FocusLost=UserInputService.WindowFocusReleased:Connect(function() functionToBind(actionName,Enum.UserInputState.Cancel,nil) end)
 connections.Interface=Player:GetAttributeChangedSignal('InterfaceOpen'):Connect(function() if Player:GetAttribute('InterfaceOpen') then functionToBind(actionName,Enum.UserInputState.Cancel,nil) end end)]])
 dm:GetService('Workspace'):SetAttribute('WeaponFixVersion','original-touch-v5')
end
