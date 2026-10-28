local W=workspace
local errors={}
local function check(ok,msg) if not ok then table.insert(errors,msg) end end
local map=W:FindFirstChild("OvergrownAtrium")
check(map~=nil,"Missing atrium")
if not map then return {ok=false,errors=errors} end
check(not W:FindFirstChild("PoppyTestMap"),"Old map remains")
local parts=0;local flowers=0;local treads=0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("BasePart") then parts+=1;if d.Name=="Moonflower" then flowers+=1 end;if d.Name=="StairTread" then treads+=1 end end
 check(not d:IsA("LuaSourceContainer"),"Map contains source script")
 check(not d:IsA("Seat"),"Unwanted chair")
end
check(parts<5000,"Part budget exceeded");check(flowers>600,"Flower field missing");check(treads==132,"Incomplete staircases")
local params=RaycastParams.new();params.RespectCanCollide=true
local spawn=map:FindFirstChild("AtriumSpawn")
check(spawn~=nil,"Spawn missing")
local markers=map.RouteMarkers
local floorChecks={}
for _,name in ipairs({"Start","Garden","Floor1","Floor2","Floor3"}) do
 local p=markers:FindFirstChild(name)
 local hit=p and W:Raycast(p.Position,Vector3.new(0,-7,0),params)
 floorChecks[name]=hit~=nil;check(hit~=nil,"Checkpoint lacks floor "..name)
 if p then
  local overlap=OverlapParams.new();overlap.RespectCanCollide=true
  local blockers=W:GetPartBoundsInBox(CFrame.new(p.Position),Vector3.new(3,4,3),overlap)
  check(#blockers==0,"Checkpoint intersects solid "..name)
 end
end
-- Sweep every flight at avatar standing height. Each half-stud step needs support.
for level=0,2 do
 local sign=level%2==0 and 1 or -1
 for i=0,44 do
  local t=i/44;local v=Vector3.new((-30+60*t)*sign,level*22+22*t+3,level%2==0 and -65 or -51)
  check(W:Raycast(v,Vector3.new(0,-5,0),params)~=nil,"Unsupported stair "..level..":"..i)
 end
end
local navigation={}
local pathService=game:GetService("PathfindingService")
local chain={"Start","Garden","Floor1","Floor2","Floor3"}
for i=1,#chain-1 do
 local path=pathService:CreatePath({AgentRadius=1.5,AgentHeight=5,AgentCanJump=true,WaypointSpacing=4})
 local success,err=pcall(function() path:ComputeAsync(markers[chain[i]].Position,markers[chain[i+1]].Position) end)
 local key=chain[i].."->"..chain[i+1]
 navigation[key]=success and path.Status==Enum.PathStatus.Success
 check(navigation[key],"Unreachable route "..key..":"..tostring(err or path.Status))
end
local runtime=game:GetService("ServerScriptService"):FindFirstChild("AtriumRuntime")
check(runtime and runtime:FindFirstChild("AtriumServer")~=nil,"Server absent")
local DS=require(runtime.DoorService);local service=DS.new(nil)
local doorChecks={}
for _,model in ipairs(map.Doors:GetChildren()) do
 local d=service:Register(model);local closed=d.panel.CFrame
 service:SetOpen(d.id,true,true);check(d.panel.Position.Y>closed.Position.Y+8,"Door did not open")
 local hit=W:Raycast(Vector3.new(closed.Position.X,4,90),Vector3.new(0,0,18),params)
 check(hit==nil,"Open door passage obstructed: "..d.id)
 service:SetOpen(d.id,false,true);doorChecks[d.id]=d.panel.CFrame==closed
end
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("AtriumClient")~=nil,"Client missing")
check(game:GetService("ReplicatedFirst"):FindFirstChild("AurivaneLoading")~=nil,"Loading missing")
check(game:GetService("ReplicatedStorage"):GetAttribute("AurivaneLogo")~=nil,"Logo missing")
check(W:GetAttribute("DeadSignalBuildId")=="dead-signal-reference-menu-v1","Build mismatch")
local RS=game:GetService("ReplicatedStorage")
local settings=require(RS.AtriumSettings)
local clean=settings.Clean({master=99,music=-2,fov=0/0,sensitivity=math.huge,quality="Baixa",scanlines=false,unexpected="discard"})
check(clean.master==1 and clean.music==0 and clean.fov==70 and clean.sensitivity==1 and clean.quality==2 and clean.scanlines==false and clean.unexpected==nil,"Settings validation failed")
check(settings.Percent(.8)=="80%","Volume percentage failed")
local viewFactory=require(RS.AtriumMenuView)
local testGui=Instance.new("ScreenGui")
local view=viewFactory.Create(testGui)
local layoutChecks={}
for _,dims in ipairs({{736,414,false},{1920,1080,false},{844,390,true},{390,844,true}}) do
 view.Resize(dims[1],dims[2],dims[3])
 local lastBottom=-1
 for i,b in ipairs(view.Buttons) do
  local pos=b.Position;local size=b.Size
  check(pos.Y.Offset>lastBottom,"Menu buttons overlap")
  check(pos.X.Offset+size.X.Offset<=dims[1] and pos.Y.Offset+size.Y.Offset<=dims[2],"Menu button outside viewport")
  if dims[3] then check(size.Y.Offset>=44,"Touch target too short") end
  check(b.Font==Enum.Font.Michroma and b:FindFirstChildOfClass("UIStroke").Thickness==1,"Reference button style mismatch")
  lastBottom=pos.Y.Offset+size.Y.Offset
 end
 layoutChecks[tostring(dims[1]).."x"..tostring(dims[2])]=true
end
check(view.Buttons[1].Text=="CONTINUE" and view.Buttons[5].Text=="QUIT","Menu actions incomplete")
testGui:Destroy()
local starter=game:GetService("StarterPlayer")
check(starter.CameraMode==Enum.CameraMode.Classic and starter.CameraMinZoomDistance==.5 and starter.CameraMaxZoomDistance==24,"Free camera configuration missing")
return {ok=#errors==0,errors=errors,build=W:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,menuLayouts=layoutChecks,settingsValidated=true,freeCamera=true,navigation=navigation,parts=parts,flowers=flowers,stairTreads=treads,checkpoints=floorChecks,doors=doorChecks,logo=game:GetService("ReplicatedStorage"):GetAttribute("AurivaneLogo")}
