local M={}
M.items={flashlight={slot='Light',permanent=true},compass={slot='Utility'},timer={slot='Utility'},radar={slot='Utility'},decoy={slot='Utility'},radio={slot='Utility'},headlamp={slot='Light',permanent=true},nvg={slot='Light',permanent=true},baton={slot='Power'},barrier={slot='Usable'},cola={slot='Usable'}}
function M.canEquip(id,owned)
 return type(id)=='string' and M.items[id]~=nil and type(owned)=='table' and type(owned[id])=='number' and owned[id]>0
end
function M.remaining(deadline,now)return math.max(0,math.ceil(deadline-now))end
function M.pulse(distance)return .15+1.85*math.clamp(distance/150,0,1)end -- Tuning, original range not confirmed.
function M.consume(owned,id,round,used)
 if type(id)~='string' or not M.items[id] then return false end
 if used[id]==round then return true end
 if not M.canEquip(id,owned) then return false end
 if M.items[id].permanent then return true end
 owned[id]-=1;used[id]=round;return true
end
return M
