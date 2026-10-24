-- Server-owned round admission and inventory. No client supplies points or damage.
local Rules={Duration=220,Intermission=30,Capacity=8,Bleedout=30,ReviveTime=2}
function Rules.new() return {id=0,phase="Intervalo",entries={}} end
function Rules.begin(s) s.id+=1 s.phase="Partida" table.clear(s.entries) end
function Rules.count(s)
 local n=0 for _,e in pairs(s.entries) do if e.status=="alive" or e.status=="downed" or e.status=="loading" then n+=1 end end return n
end
function Rules.join(s,id)
 if s.phase~="Partida" or s.entries[id] or Rules.count(s)>=Rules.Capacity then return false end
 s.entries[id]={status="loading",boost=true,points=0,hits=0,falls=0,survivalTime=0} return true
end
function Rules.down(s,id,now)
 local e=s.entries[id] if not e or e.status~="alive" then return false end
 e.status="downed" e.deadline=now+Rules.Bleedout return true
end
function Rules.revive(s,healer,target,now)
 local h,t=s.entries[healer],s.entries[target]
 if healer==target or not h or not t or h.status~="alive" or t.status~="downed" or now>=t.deadline then return false end
 t.status="alive" t.deadline=nil h.points+=10 return true
end
return Rules

