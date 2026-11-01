local Rules = {}
function Rules.team(counts, capacity, seed)
 if counts[1]>=capacity and counts[2]>=capacity then return nil end
 if counts[1]==counts[2] then return seed%2+1 end
 return counts[1]<counts[2] and 1 or 2
end
function Rules.damage(health, amount, downed, threshold)
 if downed then return 'eliminated',0 end
 local nextHealth=health-amount
 if nextHealth<=0 then return 'eliminated',0 end
 if nextHealth<=threshold then return 'downed',nextHealth end
 return 'hit',nextHealth
end
function Rules.canDamage(a,b,phase)
 return phase=='Match' and a and b and a.id~=b.id and a.team~=b.team and a.active and b.active and not a.downed and not b.protected
end
function Rules.rank(rows)
 table.sort(rows,function(a,b)
  if a.kills~=b.kills then return a.kills>b.kills end
  if a.downs~=b.downs then return a.downs<b.downs end
  return a.userId<b.userId
 end)
 return rows
end
function Rules.winner(scores)
 if scores[1]==scores[2] then return 0 end
 return scores[1]>scores[2] and 1 or 2
end
function Rules.purchase(profile,item)
 if not item then return false,'Item inválido' end
 if profile.owned[item.id] then return true,'Você já tem esse item' end
 if profile.coins<item.price then return false,'Moedas insuficientes' end
 profile.coins-=item.price;profile.owned[item.id]=true
 return true,'Compra concluída'
end
return Rules
