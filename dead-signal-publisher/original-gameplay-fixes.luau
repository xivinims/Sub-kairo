-- Auditable compatibility fixes; weapon logic and mansion progression remain source-owned.
local R=require('@lune/roblox')
return function(dm)
 local RS=dm:GetService('ReplicatedStorage');local SP=dm:GetService('StarterPlayer');local SSS=dm:GetService('ServerScriptService');local W=dm:GetService('Workspace')
 local function replace(s,old,new)
  local a,b=s.Source:find(old,1,true);assert(a,'Source contract changed: '..s:GetFullName()..' / '..old)
  s.Source=s.Source:sub(1,a-1)..new..s.Source:sub(b+1)
  s:SetAttribute('CompatibilityChange','Gameplay stability v3: R15 locomotion, ordered camera effects and mission snapshot')
 end
 local function disable(s,reason) s.Disabled=true;s:SetAttribute('DisabledReason',reason) end
 disable(SP.StarterCharacterScripts.Movement,'Duplicate WASD movement conflicts with Roblox PlayerModule')
 disable(SP.StarterCharacterScripts.BodyVisible,'Forced first-person body visibility clips camera and FPS viewmodel')
 disable(RS.OriginalStarterGui.Scripts.Game.MouseTilt,'R6 joint tilt conflicts with R15 animation and first person')
 local characterInit=SP.StarterCharacterScripts.CharacterInit
 replace(characterInit,'Enum.HumanoidStateType.Climbing, false','Enum.HumanoidStateType.Climbing, true')
 SP.CharacterUseJumpPower=false;SP.CharacterJumpHeight=7.2;SP.CharacterJumpPower=50
 local movement=RS.Library.Client.MovementHandler
 replace(movement,'function movementHandler:CanCrouch()\n\t\n\treturn true','function movementHandler:CanCrouch()\n return library.WeaponsHandler.GetEquippedWeapon() ~= nil')
 replace(movement,'function movementHandler:CanSlide()\n\t\n\treturn true','function movementHandler:CanSlide()\n return self.humanoid.RigType == Enum.HumanoidRigType.R6 and self:CanCrouch()')
 replace(movement,'if toggle then\n\t\tif not self:CanCrouch()', 'if self.__states.Crouching == toggle then return end\n if toggle then\n\t\tif not self:CanCrouch()')
 replace(movement,'library.Utility.Tween(self.humanoid,TweenInfo.new(0.3),{HipHeight = -1})','if self.__hipTween then self.__hipTween:Cancel() end\n self.__hipTween=library.TweenService:Create(self.humanoid,TweenInfo.new(0.2),{HipHeight = math.max(0,self.__standingHipHeight-0.65)});self.__hipTween:Play()')
 replace(movement,'library.Utility.Tween(self.humanoid,TweenInfo.new(0.3),{HipHeight = 0})','if self.__hipTween then self.__hipTween:Cancel() end\n self.__hipTween=library.TweenService:Create(self.humanoid,TweenInfo.new(0.2),{HipHeight = self.__standingHipHeight});self.__hipTween:Play()')
 replace(movement,'self.config.SprintAcceleration * dt * 60','math.clamp(self.config.SprintAcceleration * dt * 60,0,1)')
 replace(movement,'self.config.SprintDeceleration * dt * 60','math.clamp(self.config.SprintDeceleration * dt * 60,0,1)')
 replace(movement,'TweenTargetOffset("Sprint",20,','TweenTargetOffset("Sprint",5,')
 replace(movement,'self.__cameraOffsetsHandler:ApplyOffsets(workspace.CurrentCamera,nil,nil,dt)','if workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable then\n self.__cameraOffsetsHandler:ApplyOffsets(workspace.CurrentCamera,nil,nil,dt)\n end')
 replace(movement,'library.FOVHandler:Impulse(50)','-- No jump FOV pulse; avoids repeated zoom pumping on stairs.')
 replace(movement,'self.__cameraShaker:ShakeOnce(1, 10, 0, 0.1)','-- No locomotion camera shake; original story effects remain.')
 replace(movement,'while self.humanoid.Health > 0 and self.humanoid:GetState() ~= Enum.HumanoidStateType.Landed do','while self.humanoid.Health > 0 and (self.humanoid:GetState() == Enum.HumanoidStateType.Jumping or self.humanoid:GetState() == Enum.HumanoidStateType.Freefall) do')
 replace(movement,'char:WaitForChild("HumanoidRootPart")','char:WaitForChild("HumanoidRootPart")\n self.__standingHipHeight = self.humanoid.HipHeight\n self.__states.Crouching=false;self.__states.Sliding=false;self.__states.Sprinting=false\n self.humanoid.UseJumpPower=false\n self.humanoid.JumpHeight=library.StarterPlayer.CharacterJumpHeight\n self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)')
 replace(movement,'"MovementHandlerRenderStep",Enum.RenderPriority.Camera.Value','"MovementHandlerRenderStep",Enum.RenderPriority.Camera.Value+1')
 replace(movement,'self:SetupInputs()',[[self:SetupInputs()
 local function equippedChanged()
  local equipped=library.WeaponsHandler.GetEquippedWeapon() ~= nil
  local button=library.ContextActionUtility:GetButton("Crouch")
  if button then button.Visible=equipped end
  if not equipped and self:IsCrouching() then self:ToggleCrouch(false) end
 end
 library.WeaponsHandler.WeaponEquipped:Connect(function() task.defer(equippedChanged) end)
 library.WeaponsHandler.WeaponUnequipped:Connect(function() task.defer(equippedChanged) end)
 equippedChanged()]])
 local client=RS.OriginalStarterGui.Scripts.Game.ClientHandler
 replace(client,'cameraOffsets:ApplyOffsets(camera)','-- Camera bob/slide/fall removed; original viewmodel animation and recoil remain.')
 replace(client,'runService.RenderStepped:Connect(RenderStepped)','runService:BindToRenderStep("OriginalFPSClient",Enum.RenderPriority.Camera.Value+3,RenderStepped)')
 local fov=RS.Library.Client.FOVHandler
 replace(fov,'function handler:Update(dt)','function handler:Update(dt)\n if workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then return end')
 replace(fov,'self.FOVSpring.Target = self:GetTarget()','self.FOVSpring.Target = self:GetTarget() + ((library.LocalPlayer:GetAttribute("PreferredFOV") or 70)-70)')
 replace(fov,'"FOVSpring",Enum.RenderPriority.Camera.Value','"FOVSpring",Enum.RenderPriority.Camera.Value+2')
 local recoil=RS.Library.Client.RecoilHandler
 replace(recoil,'function handler:Update(dt)','function handler:Update(dt)\n if workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then self.PreviousValue=self.RecoilValue.Value;return end')
 replace(recoil,'"RecoilUpdate",Enum.RenderPriority.First.Value','"RecoilUpdate",Enum.RenderPriority.Camera.Value+2')
 local manager=SSS.GameStateManager
 replace(manager,'return {demoConfig.GameEvents.GameState, currentState, stateInfo}','workspace:SetAttribute("OriginalMissionName",currentMission and currentMission.Name or "")\n workspace:SetAttribute("OriginalMissionState",currentState)\n return {demoConfig.GameEvents.GameState, currentState, stateInfo}')
 -- Delete only the audited wreck, not other vehicles or unrelated "car" names.
 local wreck=W.Content.Exterior.Props.Vechicles:FindFirstChild('SUV_Damaged')
 assert(wreck,'Audited SUV wreck missing');wreck:Destroy()
 local rattle=W.RandomAudioPlayback:FindFirstChild('CarRattle');if rattle then rattle:Destroy() end
 W:SetAttribute('GameplayFixVersion','r15-stability-v3');W:SetAttribute('WreckRemoved',true)
end
