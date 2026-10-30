-- This extension shares the original DoorManager state and original close tweens.
function DoorManager.SetPlayerLocked(door, locked)
 local info=doorInfos[door]
 if not info or (locked and not info.enabled) then return false end
 info.playerLocked=locked
 door:SetAttribute('PlayerLocked',locked)
 if locked then
  info.frontSideInfo.tween:Cancel();info.backSideInfo.tween:Cancel()
  task.spawn(StartClosing,info,info.frontSideInfo)
 else
  -- Re-evaluate proximity only if the original mission permits entry.
  if info.enabled then
   DoorManager.EnableDoor(door,true)
   if next(info.frontSideInfo.playersNear or {}) then task.spawn(StartOpening,info,info.frontSideInfo)
   elseif next(info.backSideInfo.playersNear or {}) then task.spawn(StartOpening,info,info.backSideInfo) end
  end
 end
 if info.lockSound then info.lockSound:Stop();info.lockSound:Play() end
 if info.lockPrompt then info.lockPrompt.ActionText=locked and 'Destrancar · 2 toques' or 'Trancar · 2 toques' end
 return true
end
local function InstallPlayerLock(door,info)
 local target=door.TargetR_Closed
 local prompt=Instance.new('ProximityPrompt');prompt.Name='PlayerDoorLock';prompt.ActionText='Trancar · 2 toques';prompt.ObjectText='Fechadura';prompt.HoldDuration=0;prompt.MaxActivationDistance=7;prompt.RequiresLineOfSight=true;prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.Parent=target
 info.lockPrompt=prompt
 -- Reuse the door's authored mechanical close sound, quietly and briefly.
 local authored=door:FindFirstChild('DoorLock',true) or info.soundClose or workspace:FindFirstChild('DoorClose',true) or workspace:FindFirstChild('DoorOpen',true)
 if authored and authored:IsA('Sound') then
  local sound=authored:Clone();sound.Name='PlayerLockSound';sound.Looped=false;sound.Volume=math.clamp(authored.Volume,.15,.4);sound.PlaybackSpeed=1.3;sound.RollOffMaxDistance=24;sound.Parent=target;info.lockSound=sound
 end
 local clicks=setmetatable({},{__mode='k'});local lastChange=0
 local function activate(player)
  local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart');local hum=character and character:FindFirstChildOfClass('Humanoid')
  if not root or not hum or hum.Health<=0 or player:GetAttribute('InterfaceOpen') then return end
  if (root.Position-target.Position).Magnitude>9 then clicks[player]=nil;return end
  if not info.enabled then return end
  local now=os.clock();if now-lastChange<.7 then return end
  local first=clicks[player];clicks[player]=now
  if not first or now-first>.45 or now-first<.06 then return end
  clicks[player]=nil;lastChange=now
  DoorManager.SetPlayerLocked(door,not info.playerLocked)
 end
 prompt.Triggered:Connect(activate)
 local detector=Instance.new('ClickDetector');detector.Name='DoubleClickLock';detector.MaxActivationDistance=7;detector.Parent=door;detector.MouseClick:Connect(activate)
 local function refresh() prompt.Enabled=info.enabled;detector.MaxActivationDistance=info.enabled and 7 or 0 end
 door:GetAttributeChangedSignal('DoorEnabled'):Connect(refresh);refresh()
 door:SetAttribute('PlayerLocked',false)
end
