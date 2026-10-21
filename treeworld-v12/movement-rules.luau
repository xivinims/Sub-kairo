-- Pure policy: an accusation or a client-reported ping is never evidence.
local R={Window=4,ReportTTL=600}
function R.network(ping,jitter)
 if ping>=.35 or jitter>=.12 then return 'red' end
 if ping>=.16 or jitter>=.055 then return 'yellow' end
 return 'green'
end
function R.evaluate(s)
 if s.grace or s.badNetwork or s.serverStall or s.seated or s.swimming or s.climbing or s.dead then return nil end
 local cap=math.max(30,(s.allowedSpeed or 16)*1.65)
 local tolerance=10+cap*math.min((s.ping or 0)*3,1.2)
 if (s.jumpDistance or 0)>math.max(140,cap*((s.replicationGap or 0)+1)+tolerance) then return 'teleport' end
 if (s.airTime or 0)>5 and (s.floatingTime or 0)>3.5 and (s.groundDistance or 0)>14 then return 'flight' end
 if (s.windowTime or 0)>=R.Window and (s.planarDistance or 0)>cap*s.windowTime+tolerance then return 'speed' end
 return nil
end
function R.shouldKick(events,now,firstWarning,stableFor)
 if not firstWarning or now-firstWarning<18 or stableFor<10 then return false end
 local strong=0
 for _,e in ipairs(events)do if now-e.time<45 and (e.kind=='speed' or e.kind=='flight')then strong+=1 end end
 return strong>=5
end
return R
