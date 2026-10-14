local Seasons={Names={"Primavera","Verao","Outono","Inverno"}}
function Seasons.axes(x,z)
 return x+28*math.noise(x/40+.37,z/40+.71,33.2),z+28*math.noise(x/40+.37,z/40+.71,36.8)
end
function Seasons.at(x,z)
 local jx,jz=Seasons.axes(x,z)
 if jx>=0 then return jz<0 and "Primavera"or "Verao"end
 return jz>=0 and "Outono"or "Inverno"
end
local function smooth(t)t=math.clamp(t,0,1)return t*t*(3-2*t)end
function Seasons.weights(x,z)
 local jx,jz=Seasons.axes(x,z)local east=smooth((jx+24)/48)local south=smooth((jz+24)/48)
 return{Primavera=east*(1-south),Verao=east*south,Outono=(1-east)*south,Inverno=(1-east)*(1-south)}
end
function Seasons.visual(point,day)
 local w=Seasons.weights(point.X,point.Z)local air=game.Lighting:FindFirstChild("ForestAtmosphere")local color=game.Lighting:FindFirstChild("ForestColor")
 if not air or not color then return end
 air.Density=.28+w.Inverno*.045 air.Haze=1.15+w.Inverno*.25
 local tint=Color3.fromRGB(247,246,234):Lerp(Color3.fromRGB(225,238,251),w.Inverno):Lerp(Color3.fromRGB(255,232,202),w.Outono)
 color.TintColor=color.TintColor:Lerp(tint,.25*day)
 color.Saturation+=w.Primavera*.025-w.Inverno*.06+w.Outono*.015
end
return Seasons
