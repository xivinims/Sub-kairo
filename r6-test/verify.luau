assert(workspace:GetAttribute('TestGridRevision')=='clean-grid-v1')
local sequences=0;for _,x in ipairs(game.ReplicatedStorage.OriginalR6Emotes:GetDescendants()) do if x:IsA('KeyframeSequence') then sequences+=1 end end;assert(sequences==19,'Emotes missing')
assert(workspace.TestArena.Floor:FindFirstChild('TestGrid'))
assert(workspace:GetAttribute('DynamicMenuRevision')=='r6-camera-menu-v1','Missing menu')
assert(game.ReplicatedStorage.MenuR6Template.Humanoid.RigType==Enum.HumanoidRigType.R6)
assert(game.StarterPlayer.StarterPlayerScripts.DynamicMenu:IsA('LocalScript'))
local SS=game:GetService('ServerStorage')
assert(workspace:GetAttribute('R6TestBuild')=='r6-arena-v1','Wrong arena build')
local count=0;local rigs=0
for _,x in ipairs(game:GetDescendants()) do
 if x:IsA('Humanoid') then assert(x.RigType==Enum.HumanoidRigType.R6,'R15 rig found: '..x:GetFullName());rigs+=1 end
 if x:IsA('LuaSourceContainer') and x:GetAttribute('OriginalId') then
  assert(x.Source==SS.OriginalSources[x:GetAttribute('OriginalId')].Source,'Imported source modified: '..x:GetFullName());count+=1
 end
end
assert(count==132,'Imported script count changed')
assert(#workspace.TrainingBots:GetChildren()==6)
local character=game.StarterPlayer.StarterCharacter
assert(character.Humanoid.RigType==Enum.HumanoidRigType.R6 and character:FindFirstChild('Torso'))
assert(game.StarterPlayer.StarterCharacterScripts.Run:FindFirstChild('StaminaBar'))
assert(game.StarterPlayer.StarterCharacterScripts:FindFirstChild('Stamina'),'Original stamina GUI missing')
for _,n in ipairs({'Floor','NorthWall','SouthWall','WestWall','EastWall','WallRunLeft','WallRunRight','Spawn'}) do assert(workspace.TestArena:FindFirstChild(n),'Missing geometry '..n) end
local hit=workspace:Raycast(Vector3.new(0,30,0),Vector3.new(0,-60,0));assert(hit and hit.Instance.Name=='Floor','Floor ray failed')
-- Run the integration in the disposable native session, then exercise real ray hits and respawn.
local runner=Instance.new('ModuleScript');runner.Source=game.ServerScriptService.ArenaServer.Source..'\nreturn true';runner.Parent=SS;require(runner)
local bot=workspace.TrainingBots['Bot 1'];local home=bot.HumanoidRootPart.Position
for i=1,7 do
 local arrow=Instance.new('Part');arrow.Name='VerificationArrow';arrow.Anchored=true;arrow.CanCollide=false;arrow.CanTouch=false;arrow.Size=Vector3.new(.1,.1,.1);arrow.Position=home+Vector3.new(0,0,5);arrow.Parent=workspace.Debris
 task.wait(.1);arrow.Position=home-Vector3.new(0,0,5);task.wait(.15)
 assert((i<7 and bot.Humanoid.Health==100-15*i) or (i==7 and bot.Humanoid.Health<=0),'Arrow damage incorrect at hit '..i..': '..bot.Humanoid.Health)
end
assert(bot.Humanoid.Health<=0,'Bot not killable');task.wait(5.5)
local respawn=workspace.TrainingBots:FindFirstChild('Bot 1');assert(respawn and respawn~=bot and respawn.Humanoid.Health==100,'Bot respawn failed');assert(#workspace.TrainingBots:GetChildren()==6,'Respawn duplicated bots')
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build='r6-arena-v1',originalScriptsUnchanged=count,r6Rigs=rigs,bots=6,arrowDamage=15,killAndRespawn=true,r15Rigs=0})
