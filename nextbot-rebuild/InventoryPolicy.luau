local M={}
local slots={flashlight='Light',headlamp='Light',nvg='Light',compass='Utility',timer='Utility',radio='Utility',radar='Utility',decoy='Utility',baton='Power',barrier='Usable',cola='Usable'}
function M.Visible(item,category,filter,owned)
 if item.available~=true then return false end
 if category~='Em destaque'and item.category~=category then return false end
 if not filter then return true end
 if not owned then return false end
 if filter=='Emote'then return item.source~=nil end
 if filter=='Perk'then return item.category=='Personagem'end
 return slots[item.id]==filter
end
function M.IsOwned(item,count,permanent)
 return permanent==true or type(count)=='number'and count>0
end
return M
