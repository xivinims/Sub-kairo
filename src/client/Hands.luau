local RunService=game:GetService("RunService")
local Hands={}
function Hands.new(camera)
 local self=setmetatable({camera=camera,models={},flights={},enabled=false},{__index=Hands})
 self.root=Instance.new("Folder");self.root.Name="BrambleViewmodel";self.root.Parent=camera
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=parent;return p
 end
 for side=1,2 do
  local m=Instance.new("Model");m.Name=if side==1 then "BlueHand" else "RedHand";m.Parent=self.root
  local color=if side==1 then Color3.fromRGB(26,78,196) else Color3.fromRGB(169,36,28)
  local palm=part(m,"Palm",Vector3.new(.6,.64,.22),CFrame.new(),color);m.PrimaryPart=palm
  for finger=1,4 do
   local length=({.42,.52,.49,.37})[finger]
   part(m,"Finger"..finger,Vector3.new(.12,length,.16),CFrame.new(-.24+(finger-1)*.16,.32+length/2,0),color)
  end
  local thumb=part(m,"Thumb",Vector3.new(.16,.43,.18),CFrame.new(if side==1 then .38 else -.38,.02,0)*CFrame.Angles(0,0,if side==1 then -.6 else .6),color)
  part(m,"Cuff",Vector3.new(.49,.22,.28),CFrame.new(0,-.45,0),Color3.fromRGB(174,126,27),Enum.Material.Metal)
  local from=part(self.root,"Wrist",Vector3.new(.02,.02,.02),CFrame.new(),color);from.Transparency=1
  local a=Instance.new("Attachment");a.Parent=from;local b=Instance.new("Attachment");b.Parent=palm
  local beam=Instance.new("Beam");beam.Attachment0=a;beam.Attachment1=b;beam.Width0=.025;beam.Width1=.025;beam.FaceCamera=true;beam.Color=ColorSequence.new(Color3.fromRGB(29,32,29));beam.Enabled=false;beam.Parent=from
  self.models[side]={model=m,from=from,beam=beam,thumb=thumb}
 end
 self.connection=RunService.RenderStepped:Connect(function()
  for side,item in ipairs(self.models) do
   local base=self.camera.CFrame*CFrame.new(if side==1 then -.88 else .88,-.62,-1.65)
   local flight=self.flights[side];local at=base
   if flight then
    local age=os.clock()-flight.start;local t=if age<.30 then age/.30 else 1-math.clamp((age-.42)/.3,0,1)
    local position=base.Position:Lerp(flight.point,t);at=CFrame.new(position)*base.Rotation
    if age>.72 then self.flights[side]=nil end
   end
   item.model:PivotTo(at);item.from.CFrame=base*CFrame.new(0,-.45,.2);item.beam.Enabled=self.enabled and self.flights[side]~=nil
   for _,p in ipairs(item.model:GetChildren()) do if p:IsA("BasePart") then p.Transparency=if self.enabled then 0 else 1 end end
  end
 end)
 return self
end
function Hands:launch(point,right) self.flights[if right then 2 else 1]={point=point,start=os.clock()} end
function Hands:setEnabled(enabled) self.enabled=enabled;if not enabled then self.flights={} end end
function Hands:destroy() self.connection:Disconnect();self.root:Destroy() end
return Hands
