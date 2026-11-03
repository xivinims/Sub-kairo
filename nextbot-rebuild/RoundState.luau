-- Pure state machine; the server owns the clock and participant admission.
local M={}
function M.new(now,intermission,duration)
	assert(intermission>0 and duration>0)
	return {phase='Intermission',deadline=now+intermission,round=0,intermission=intermission,duration=duration}
end
function M.tick(s,now,ready)
	if now<s.deadline then return false end
	if s.phase=='Intermission' then
		if not ready then s.deadline=now+1;return false end
		s.phase='Round';s.round+=1;s.deadline=now+s.duration
	else s.phase='Intermission';s.deadline=now+s.intermission end
	return true
end
return M
