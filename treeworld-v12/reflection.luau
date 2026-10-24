local M={}
function M.create(character,guiParent,worldParent)
 local patch=Instance.new("Part")patch.Name="LocalRiverReflection"patch.Size=Vector3.new(8,.02,12)patch.Transparency=1 patch.Anchored=true patch.CanCollide=false patch.CanQuery=false patch.CanTouch=false patch.CastShadow=false patch.Parent=worldParent
 local surface=Instance.new("SurfaceGui")surface.Name="RiverAvatarReflection"surface.Adornee=patch surface.Face=Enum.NormalId.Top surface.CanvasSize=Vector2.new(96,144)surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize surface.AlwaysOnTop=false surface.LightInfluence=0 surface.Enabled=false surface.Parent=guiParent
 local view=Instance.new("ViewportFrame")view.Size=UDim2.fromScale(1,1)view.BackgroundTransparency=1 view.ImageTransparency=.90 view.ImageColor3=Color3.fromRGB(136,175,185)view.Ambient=Color3.fromRGB(180,180,180)view.LightColor=Color3.fromRGB(180,180,180)view.Parent=surface
 local scene=Instance.new("WorldModel")scene.Parent=view local camera=Instance.new("Camera")camera.Parent=view view.CurrentCamera=camera
 local rig=Instance.new("Model")rig.Name="ReflectedAvatar"rig.Parent=scene
 local hum=Instance.new("Humanoid")hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.Parent=rig
 for _,d in ipairs(character:GetChildren())do if d:IsA("Shirt")or d:IsA("Pants")or d:IsA("ShirtGraphic")then d:Clone().Parent=rig end end
 local pairs={}local parts={}
 for _,p in ipairs(character:GetDescendants())do if p:IsA("BasePart")and p.Name~="HumanoidRootPart"and p.Transparency<.95 then parts[#parts+1]=p end end
 table.sort(parts,function(a,b)return(a.Parent==character and 0 or 1)<(b.Parent==character and 0 or 1)end)
 for i=1,math.min(32,#parts)do local p=parts[i]local archived=p.Archivable;p.Archivable=true;local copy=p:Clone();p.Archivable=archived
  for _,d in ipairs(copy:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("JointInstance")or d:IsA("Constraint")or d:IsA("Sound")or d:IsA("ParticleEmitter")or d:IsA("WrapLayer")or d:IsA("Light")then d:Destroy()end end
  copy.Anchored=true copy.CanCollide=false copy.CanQuery=false copy.CanTouch=false copy.LocalTransparencyModifier=0 copy.Parent=rig pairs[#pairs+1]={source=p,copy=copy}
 end
 local self={surface=surface,view=view,patch=patch,camera=camera,pairs=pairs}
 function self.update(point,viewer)
  if viewer.Position.Y<point.Y+.8 then surface.Enabled=false return end
  patch.CFrame=CFrame.new(point+Vector3.yAxis*.018)surface.Enabled=true
  local eye=Vector3.new(viewer.Position.X,2*point.Y-viewer.Position.Y,viewer.Position.Z)
  camera.CFrame=CFrame.lookAt(eye,point,Vector3.zAxis)camera.FieldOfView=math.clamp(math.deg(2*math.atan(6/(eye-point).Magnitude)),20,90)
  for _,v in ipairs(pairs)do if v.source.Parent then v.copy.CFrame=v.source.CFrame v.copy.Transparency=v.source.Position.Y<point.Y-.4 and 1 or v.source.Transparency end end
 end
 function self.hide()surface.Enabled=false end
 function self.destroy()surface:Destroy()patch:Destroy()end
 return self
end
return M
