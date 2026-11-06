-- Pure state machine; the server owns the clock, votes and admission.
local M={}
function M.new(now,intermission,duration)
 assert(intermission>0 and duration>0)
 return {phase='Intermission',deadline=now+intermission,round=0,intermission=intermission,duration=duration,normalRounds=0,specialRemaining=0}
end
function M.botsAllowed(s)return s.phase=='Round'end
function M.tick(s,now,ready)
 if now<s.deadline then return false end
 if s.phase=='Intermission'then
  if not ready then s.deadline=now+1;return false end
  s.phase='Round';s.round+=1;s.deadline=now+s.duration
 elseif s.phase=='Round'then s.phase='Intermission';s.deadline=now+s.intermission
 else return false end
 return true
end
function M.NextKind(s,chasersAvailable,random)
 if not chasersAvailable then s.normalRounds+=1;return 'normal'end
 if s.specialRemaining>0 then s.specialRemaining-=1;return 'chasers'end
 if s.normalRounds>=3 then
  s.normalRounds=0;s.specialRemaining=(random or math.random)(1,2)-1
  return 'chasers'
 end
 s.normalRounds+=1;return 'normal'
end
function M.CountVotes(votes,choices)
 local counts={};for _,name in ipairs(choices)do counts[name]=0 end
 for _,name in pairs(votes)do if counts[name]~=nil then counts[name]+=1 end end
 return counts
end
function M.Winner(votes,choices,fallback,random)
 local counts=M.CountVotes(votes,choices);local best=0;local tied={}
 for _,name in ipairs(choices)do
  if counts[name]>best then best=counts[name];tied={name}
  elseif counts[name]==best and best>0 then table.insert(tied,name)end
 end
 if #tied==0 then return fallback end
 return tied[(random or math.random)(1,#tied)]
end
return M
