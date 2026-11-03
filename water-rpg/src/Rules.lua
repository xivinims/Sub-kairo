local R={}
function R.level(xp) return 1+math.floor(math.max(0,xp)/100) end
function R.buy(coins,price,count) return type(coins)=='number' and price>0 and coins>=price and (count or 0)<10 end
function R.quest(stage,role)
 if role=='Guide' and stage==0 then return 1,'Entrega iniciada' end
 if role=='Apothecary' and stage==1 then return 2,'Entrega concluída' end
 return stage,nil
end
function R.distanceAllowed(distance) return distance>=0 and distance<=12 end
return R
