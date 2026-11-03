local runtime=assert(game.ReplicatedStorage:FindFirstChild('LivingForest'))
local world=assert(workspace:FindFirstChild('OveryardPhotoWorld'))
local sps=game.StarterPlayer.StarterPlayerScripts
assert(world:GetAttribute('RefinementVersion')=='living-forest-v12','Forest unexpectedly replaced')
assert(workspace:GetAttribute('VoiceTouchRevision')=='voice-touch-v13','Hotfix missing')
assert(not game.StarterGui:FindFirstChild('Custom Inventory'),'Legacy touch surface remains')
for _,name in ipairs({'ForestInterface','CaioVoicePlayer'}) do assert(runtime:FindFirstChild(name)) end
for _,name in ipairs({'ForestInventoryClient','CaioDialogueClient'}) do
 assert(sps[name]:GetAttribute('Revision')=='voice-touch-v13','Wrong client revision')
end
assert(sps:FindFirstChild('OveryardCameraClient'),'Camera controller lost')
assert(game.StarterPlayer.CameraMode==Enum.CameraMode.Classic)

local UI=require(runtime.ForestInterface)
local screen=Instance.new('ScreenGui');screen.Parent=game.ReplicatedStorage
local choices=UI.choices(screen)
assert(not choices.frame.Visible and not choices.frame.Active and not choices.frame.ScrollingEnabled)
choices.button('Test','Test',1,function() end);choices.show(1)
assert(choices.frame.Visible and choices.frame.Active and choices.frame.Size.Y.Offset==42)
choices.hide()
assert(not choices.frame.Visible and not choices.frame.Active and not choices.frame.ScrollingEnabled)
assert(not choices.frame:FindFirstChild('Test'),'Closed dialog retains interactive children')
choices.show(0);assert(not choices.frame.Visible,'Empty dialog captures touches')
screen:Destroy()

local inventory=UI.inventory({title='Mochila',subtitle='Frutas',empty='Vazia'})
inventory.gui.Parent=game.ReplicatedStorage
local function exposed(o)
 local p=o
 while p and p~=inventory.gui do if p:IsA('GuiObject') and not p.Visible then return false end;p=p.Parent end
 return true
end
local closedControls=0
for _,p in ipairs(inventory.gui:GetDescendants()) do
 if p:IsA('GuiButton') then assert(not p.Modal,'Modal UI steals camera') end
 if p:IsA('GuiObject') and p.Active and exposed(p) then
  closedControls+=1;assert(p==inventory.open,'Invisible/oversized closed inventory hit target')
 end
end
assert(closedControls==1 and inventory.open.Size==UDim2.fromOffset(44,44))
inventory.setOpen(true);assert(inventory.panel.Visible and inventory.panel.Active)
inventory.setOpen(false);assert(not inventory.panel.Visible and not inventory.panel.Active)
local slot=UI.fruitSlot(inventory.content,'Apple','Maçã',3,runtime.Meshes.Apple)
assert(slot.Amount.Text=='x3' and slot.Amount.TextSize==11,'Stack display regressed')
assert(not slot.Active and not slot.FruitPreview.Active,'Decorative preview captures drag')
inventory.gui:Destroy()

local Voice=require(runtime.CaioVoicePlayer)
local voice=Voice.new(nil,'pt',require(runtime.DialogueData),require(runtime.VoiceManifest))
voice:preload()
local deadline=os.clock()+25;local loaded=0
repeat
 loaded=0
 for _,row in pairs(voice.cache) do if row.source.IsLoaded and row.source.TimeLength>0 then loaded+=1 end end
 if loaded==7 then break end
 task.wait(.1)
until os.clock()>deadline
assert(loaded==7,'Portuguese voice assets unavailable: '..loaded..'/7')
local cancelled,reason=voice:play('hello',function() return false end)
assert(not cancelled and reason=='cancelled' and not voice.playback,'Walk-away cancellation failed')
local playback=assert(voice:play('hello',function() return true end))
assert(playback.kind=='recording' and playback.source.IsPlaying and playback.length>5)
assert(playback.source:IsDescendantOf(game.SoundService),'Voice still depends on NPC/camera distance')
assert(not playback.source.Parent:IsA('BasePart') and not playback.source.Parent:IsA('Attachment'))
voice:stop();assert(not playback.source.IsPlaying,'Conversation audio does not stop')
voice:destroy()
local trees=0
for _,p in ipairs(world:GetDescendants()) do if p:IsA('Model') and p:GetAttribute('Tree') then trees+=1 end end
assert(trees==7357,'Scenery changed during UI/audio hotfix')
assert(world.Caio.Humanoid.RigType==Enum.HumanoidRigType.R15)
return {ok=true,placeVersion=game.PlaceVersion,revision='voice-touch-v13',loadedPortugueseVoices=loaded,
 closedInventoryHitTargets=closedControls,backpackButtonPixels=44,hiddenChoicesCaptureInput=false,
 voicePlaybackStarted=true,voiceCancellation=true,fruitStack='x3',treesPreserved=trees}
