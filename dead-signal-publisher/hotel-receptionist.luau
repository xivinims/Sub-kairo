local Players=game:GetService('Players')
local Receptionist={}
local SHIRT=7978206628
local PANTS=6296971062
local HEAD=14802934596
local HAT=8208242118
local BANDAGE=14492889106
local function appendAsset(value,id)
 local items={}
 for asset in string.gmatch(tostring(value or ''),'[^,]+') do table.insert(items,string.gsub(asset,'%s+','')) end
 local wanted=tostring(id)
 for _,asset in ipairs(items) do if asset==wanted then return table.concat(items,',') end end
 table.insert(items,wanted);return table.concat(items,',')
end
local function description()
 local d
 if game.CreatorType==Enum.CreatorType.User and game.CreatorId>0 then
  local ok,value=pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(game.CreatorId) end)
  if ok then d=value end
 end
 if not d then d=Instance.new('HumanoidDescription') end
 d.Shirt=SHIRT;d.Pants=PANTS;d.Head=HEAD;d.HatAccessory=appendAsset(d.HatAccessory,HAT);d.FaceAccessory=appendAsset(d.FaceAccessory,BANDAGE)
 return d
end
local function build()
 local ok,model=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(description(),Enum.HumanoidRigType.R15) end)
 if not ok then
  warn('[HotelReceptionist] Avatar items unavailable; loading the pajamas on a default R15 avatar.')
  local fallback=Instance.new('HumanoidDescription');fallback.Shirt=SHIRT;fallback.Pants=PANTS
  local fallbackOk,fallbackModel=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(fallback,Enum.HumanoidRigType.R15) end)
  if fallbackOk then model=fallbackModel else model=Players:CreateHumanoidModelFromDescriptionAsync(Instance.new('HumanoidDescription'),Enum.HumanoidRigType.R15) end
 end
 model.Name='HotelReceptionist'
 local humanoid=model:FindFirstChildOfClass('Humanoid');local root=model:FindFirstChild('HumanoidRootPart')
 assert(humanoid and root,'Receptionist avatar could not be created')
 humanoid.DisplayName='Recepcionista';humanoid.NameDisplayDistance=24;humanoid.HealthDisplayDistance=0;humanoid.AutoRotate=false;humanoid.BreakJointsOnDeath=false;humanoid.RequiresNeck=false
 for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.CanCollide=false;part.CanTouch=false;part.CanQuery=true end end
 root.Anchored=true;model.PrimaryPart=root
 local badge=Instance.new('BillboardGui');badge.Name='ReceptionistNameplate';badge.Size=UDim2.fromOffset(180,30);badge.StudsOffset=Vector3.new(0,3.1,0);badge.AlwaysOnTop=true;badge.MaxDistance=36;badge.Parent=root
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text='RECEPCIONISTA';label.Font=Enum.Font.RobotoCondensed;label.TextSize=13;label.TextColor3=Color3.fromRGB(237,221,190);label.TextStrokeColor3=Color3.fromRGB(14,14,13);label.TextStrokeTransparency=.32;label.Parent=badge
 local idle=Instance.new('Animation');idle.AnimationId='rbxassetid://507766666';idle.Parent=model
 task.spawn(function() local animator=humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator',humanoid);local ok,track=pcall(function() return animator:LoadAnimation(idle) end);if ok and track then track.Looped=true;track.Priority=Enum.AnimationPriority.Idle;track:Play(.35) end end)
 return model
end
function Receptionist.Initialize(map,interactions)
 assert(not workspace:FindFirstChild('HotelActors'),'Hotel actors already initialized')
 local tableModel=assert(map:FindFirstChild('PoolTable1',true),'Pool table is missing')
 local surface
 for _,part in ipairs(tableModel:GetDescendants()) do if part:IsA('BasePart') and part.Size.X>10 and part.Size.Z>5 and part.Size.Y<.01 then surface=part;break end end
 assert(surface,'Pool felt surface missing')
 local folder=Instance.new('Folder');folder.Name='HotelActors';folder.Parent=workspace
 local model=build();model.Parent=folder
 local side=4.5
 local origin=surface.Position+surface.CFrame.LookVector*side+Vector3.new(0,12,0)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={tableModel,folder};params.RespectCanCollide=true
 local hit=workspace:Raycast(origin,Vector3.new(0,-50,0),params)
 local floor=hit and hit.Position or surface.Position+surface.CFrame.LookVector*side-Vector3.new(0,3,0)
 local position=floor+Vector3.new(0,2.9,0);local target=Vector3.new(surface.Position.X,position.Y,surface.Position.Z)
 model:PivotTo(CFrame.lookAt(position,target))
 interactions.RegisterActor(model,'Receptionist')
 return model
end
return Receptionist
