local Priority={}
function Priority.plan(active,candidates,limit,empty,now)
 local wanted,queue={},{}local accepted=0
 for _,cell in ipairs(candidates)do
  if not empty[cell.key]or empty[cell.key]<now then
   if accepted>=limit then break end accepted+=1 wanted[cell.key]=true
   if not active[cell.key]then queue[#queue+1]=cell end
  end
 end
 local remove={}
 for key in pairs(active)do if not wanted[key]then remove[#remove+1]=key end end
 return remove,queue
end
return Priority
