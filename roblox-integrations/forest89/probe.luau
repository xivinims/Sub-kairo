assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==88)
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),ray)end
local out={readOnly=true,version=game.PlaceVersion,sites={}}
local Scene=require(game.ReplicatedStorage.ForestRuntime.Scene)
for _,v in ipairs({Vector2.new(-180,30),Vector2.new(-165,-110),Vector2.new(-180,-180),Vector2.new(-180,-260),Vector2.new(-230,80),Vector2.new(-250,0),Vector2.new(-220,250)})do
 local minimum,maximum,norm,dry=math.huge,-math.huge,1,true
 for _,x in ipairs({-38,-19,0,19,38})do for _,z in ipairs({-28,-14,0,14,28})do
  local h=ground(v.X+x,v.Y+z)if not h or h.Material==Enum.Material.Water then dry=false else minimum=math.min(minimum,h.Position.Y)maximum=math.max(maximum,h.Position.Y)norm=math.min(norm,h.Normal.Y)end
 end end
 out.sites[#out.sites+1]={x=v.X,z=v.Y,dry=dry,minimum=minimum,maximum=maximum,variation=maximum-minimum,normal=norm,pathX=Scene.pathX(v.Y)}
end
return out
