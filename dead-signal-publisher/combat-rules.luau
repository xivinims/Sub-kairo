local M={Weapons={}}
function M.ValidVector(v)
 return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e7 and math.abs(v.Y)<1e7 and math.abs(v.Z)<1e7
end
function M.CanShoot(state,now)
 return state and state.ammo>0 and now>=(state.reloadingUntil or 0) and now>=(state.nextShot or 0)
end
function M.SpendShot(state,config,now)
 if not M.CanShoot(state,now) then return false end
 state.ammo-=1;state.nextShot=now+config.interval;return true
end
return M
