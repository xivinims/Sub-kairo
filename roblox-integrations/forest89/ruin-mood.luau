local Mood={}
function Mood.weight(point,origin)
 local distance=(Vector2.new(point.X-origin.X,point.Z-origin.Z)).Magnitude
 local t=math.clamp((115-distance)/45,0,1)return t*t*(3-2*t)
end
function Mood.apply(point,origin,mode,day)
 local lighting=game.Lighting local weight=Mood.weight(point,origin)
 local air=lighting:FindFirstChild("ForestAtmosphere")local color=lighting:FindFirstChild("ForestColor")
 if not air or not color then return end
 local fog=mode=="Neblina"
 if weight==0 then return end
 air.Density+=(fog and .12 or -.025)*weight
 air.Haze+=(fog and .85 or -.15)*weight
 air.Color=air.Color:Lerp(fog and Color3.fromRGB(157,181,159)or Color3.fromRGB(223,208,159),weight*(fog and .40 or .33)*day)
 color.TintColor=color.TintColor:Lerp(fog and Color3.fromRGB(213,230,211)or Color3.fromRGB(255,237,196),weight*.27)
 color.Saturation+=weight*(fog and -.03 or .035)
 local rays=lighting:FindFirstChild("ForestSunRays")if rays then rays.Intensity+=weight*(fog and -.035 or .018)*day end
end
return Mood
