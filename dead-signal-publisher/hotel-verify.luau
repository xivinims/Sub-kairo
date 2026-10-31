assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong experience')
assert(workspace:GetAttribute('DeadSignalBuildId')=='still-here-hotel-mystery-ui-v1','Wrong release')
local RS=game:GetService('ReplicatedStorage')
local map=assert(workspace:FindFirstChild('HotelMap'))
local ui=assert(RS:FindFirstChild('MysteryInterface'))
assert(not workspace:FindFirstChild('Content') and not workspace:FindFirstChild('Islands'),'Old map is still active')
assert(workspace:GetAttribute('WorldReady') and workspace:GetAttribute('GameMode')=='Match','World not ready')
assert(ui.HUD.Frame.HeadlampButton:IsA('ImageButton') and ui.HUD.Frame.GrabReleaseButton:IsA('ImageButton'),'Source buttons missing')
local interactions=require(game:GetService('ServerScriptService').StillHereRuntime.MapInteractions)
local doors,spawns,parts=0,0,0
for _,d in ipairs(map:GetDescendants()) do
 assert(not d:IsA('ScreenGui') and not d:IsA('LuaSourceContainer') and not d:IsA('Tool'),'Map/UI separation broken')
 if d:IsA('BasePart') then parts+=1 end
 if d:IsA('SpawnLocation') and d.Enabled then
  spawns+=1
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={d};params.RespectCanCollide=true
  local hit=workspace:Raycast(d.Position+Vector3.new(0,2,0),Vector3.new(0,-10,0),params)
  assert(hit and hit.Normal.Y>.6,'Unsupported hotel spawn '..d:GetFullName())
 end
 if d:GetAttribute('InteractionKind')=='Door' then
  doors+=1
  local before=d.Hinge.CFrame
  assert(interactions.SetDoorOpen(d,true,true),'Door open rejected')
  assert(d.Open.Value and not d.Hitbox.CanCollide and d.Hinge.CFrame~=before,'Door did not open')
  assert(interactions.SetDoorOpen(d,false,true),'Door close rejected')
  assert(not d.Open.Value and d.Hitbox.CanCollide,'Door did not close')
  assert(d.Hitbox:FindFirstChild('StillHereInteract'),'Door prompt missing')
 end
end
assert(doors==4 and spawns==10,'Door/spawn count mismatch')
assert(parts==map:GetAttribute('SourcePartCount'),'Source geometry count mismatch')
for _,d in ipairs(ui:GetDescendants()) do assert(not d:IsA('BasePart') and not d:IsA('LuaSourceContainer'),'UI package depends on map') end
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId'),parts=parts,screens=#ui:GetChildren(),doors=doors,spawns=spawns,separateMapAndUI=true})
