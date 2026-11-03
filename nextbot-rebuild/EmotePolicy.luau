local M={}
function M.normalize(value)
 value=type(value)=='table' and value or {}
 local coins=tonumber(value.coins) or 0
 if coins~=coins or coins==math.huge or coins==-math.huge then coins=0 end
 local result={coins=math.clamp(math.floor(coins),0,100000000),owned={},slots={},revision=tonumber(value.revision) or 0}
 if type(value.owned)=='table' then for k,v in pairs(value.owned) do if type(k)=='string' and v==true then result.owned[k]=true end end end
 if type(value.slots)=='table' then for i=1,6 do local id=value.slots[tostring(i)];if type(id)=='string' and result.owned[id] then result.slots[tostring(i)]=id end end end
 return result
end
function M.buy(value,id,price)
 local p=M.normalize(value)
 if type(id)~='string' or type(price)~='number' or price~=price or price<0 or price==math.huge or price%1~=0 then return p,'invalid' end
 if p.owned[id] then return p,'owned' end
 if p.coins<price then return p,'funds' end
 p.coins-=price;p.owned[id]=true;p.revision+=1;return p,'purchased'
end
function M.equip(value,id,slot)
 local p=M.normalize(value)
 if type(slot)~='number' or slot%1~=0 or slot<1 or slot>6 or not p.owned[id] then return p,'invalid' end
 for k,v in pairs(p.slots) do if v==id then p.slots[k]=nil end end
 p.slots[tostring(slot)]=id;p.revision+=1;return p,'equipped'
end
return M
