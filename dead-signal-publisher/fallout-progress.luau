-- Time is cumulative across connected sessions. XP earned before this update counts.
local Progress={BeginnerSeconds=2*60*60,VeteranSeconds=29*60*60,XPPerLevel=1000}
function Progress.seconds(value)
 if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return 0 end
 return math.max(0,math.floor(value))
end
function Progress.elapsed(saved,started,now)
 return Progress.seconds(saved)+math.max(0,math.floor(now-started))
end
function Progress.title(seconds)
 seconds=Progress.seconds(seconds)
 if seconds<Progress.BeginnerSeconds then return 'Iniciante' end
 if seconds>=Progress.VeteranSeconds then return 'Veterano' end
 return ''
end
function Progress.level(xp)
 return 1+math.floor(Progress.seconds(xp)/Progress.XPPerLevel)
end
return Progress
