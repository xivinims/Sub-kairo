local M={}
function M.weight(point,origin)local d=(Vector2.new(point.X-origin.X,point.Z-origin.Z)).Magnitude local t=math.clamp((72-d)/25,0,1)return t*t*(3-2*t)end
function M.apply(point,origin,mode,day)
 local L=game.Lighting local weight=M.weight(point,origin)local air=L:FindFirstChild("ForestAtmosphere")
 if not air then return end
 -- Absolute targets: repeated updates do not accumulate fog or darken the scene.
 air.Density=.24+.09*weight air.Haze=.65+.55*weight air.Offset=.16
 air.Color=Color3.fromRGB(184,201,194):Lerp(Color3.fromRGB(171,190,171),weight*.45)
 air.Glare=.12*(day or 1)
end
return M
