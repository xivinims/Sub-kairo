-- Server-side materialized sculpture of the exact public Roblox username ch_ckz2n.
-- This is not a fake humanoid. If the username/avatar API is unavailable the pedestal stays empty.
local Players=game:GetService("Players")
local map=workspace:WaitForChild("OvergrownAtrium",30)
if not map then return end
local wing=map:WaitForChild("CathedralWing",20)
local chamber=wing and wing:FindFirstChild("02_HaloChamber")
local socket=chamber and chamber:FindFirstChild("AvatarStatueAnchor")
if not socket then warn("[DeadSignalStatue] Missing monument anchor");return end

local username="ch_ckz2n"
local stone=Color3.fromRGB(186,195,201)
local function create()
 local id=Players:GetUserIdFromNameAsync(username)
 assert(type(id)=="number" and id>0,"Username could not be resolved")
 local statue=Players:CreateHumanoidModelFromUserIdAsync(id)
 assert(statue and statue:IsA("Model"),"Roblox returned no character model")
 statue.Name="AvatarOf_"..username
 statue:SetAttribute("SourceUsername",username)
 statue:SetAttribute("SourceUserId",id)
 -- Preserve the shape and accessories while painting every visible surface.
 for _,piece in ipairs(statue:GetDescendants()) do
  if piece:IsA("LuaSourceContainer") or piece:IsA("Decal") or piece:IsA("Texture") or piece:IsA("SurfaceAppearance")
   or piece:IsA("Shirt") or piece:IsA("Pants") or piece:IsA("ShirtGraphic")
   or piece:IsA("BodyColors") or piece:IsA("ParticleEmitter") or piece:IsA("Trail")
   or piece:IsA("Sound") or piece:IsA("Highlight") then
   piece:Destroy()
  elseif piece:IsA("BasePart") then
   piece.Anchored=true
   piece.CanCollide=false;piece.CanTouch=false;piece.CanQuery=false
   piece.Color=stone
   piece.Material=Enum.Material.Marble
   piece.Reflectance=.02
   if piece:IsA("MeshPart") then piece.TextureID="" end
   if piece.Name=="HumanoidRootPart" then piece.Transparency=1 else piece.Transparency=0 end
  elseif piece:IsA("SpecialMesh") then
   piece.TextureId=""
  elseif piece:IsA("Humanoid") then
   piece.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
   piece.BreakJointsOnDeath=false
  end
 end
 statue.Parent=chamber
 -- Put the actual lowermost avatar geometry on the plinth, even with uneven accessories.
 local pivot=statue:GetPivot()
 local bounds,boundsSize=statue:GetBoundingBox()
 local bottom=bounds.Position.Y-boundsSize.Y*.5
 local destination=Vector3.new(socket:GetAttribute("CenterX"),socket:GetAttribute("PedestalTopY"),socket:GetAttribute("CenterZ"))
 statue:PivotTo(pivot+Vector3.new(destination.X-bounds.Position.X,destination.Y-bottom,destination.Z-bounds.Position.Z))
 socket:SetAttribute("SourceUserId",id)
 socket:SetAttribute("StatueModel",statue.Name)
 socket:SetAttribute("Status","Ready")
end
local lastError
for attempt=1,3 do
 if chamber:FindFirstChild("AvatarOf_"..username) then socket:SetAttribute("Status","Ready");return end
 socket:SetAttribute("Status","Loading")
 local ok,err=pcall(create)
 if ok then return end
 lastError=tostring(err)
 warn("[DeadSignalStatue] Attempt "..attempt..": "..lastError)
 if attempt<3 then task.wait(5*attempt) end
end
socket:SetAttribute("Status","Unavailable")
socket:SetAttribute("Error",string.sub(lastError or "Avatar unavailable",1,180))
