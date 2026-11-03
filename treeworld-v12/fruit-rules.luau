local R={Lifetime=420,MaxGroundFruit=48,DropInterval=38,TreeCooldown=50,PickupRange=10,MaxStack=9999}
function R.expired(born,now)return now-born>=R.Lifetime end
function R.pickup(state,now,distance)
 return state~=nil and not state.claimed and not R.expired(state.born,now)and distance<=R.PickupRange
end
function R.increment(count)return math.min(R.MaxStack,math.max(0,math.floor(count or 0))+1)end
function R.label(name,count)return name..(count>1 and ' x'..count or '')end
return R
