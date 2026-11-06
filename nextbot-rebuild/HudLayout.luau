local Layout={}
function Layout.Compute(w,h)
 local s=math.clamp(math.min(w,h)*.12,48,72);local p,g=12,12
 local x,y=w-p-s,h-p-s;local ly=math.clamp(h*.32,76,math.max(76,h-2*s-100))
 local headerX=s+2*p
 local headerRight=x-s-g-p
 return {size=s,Menu={p,ly,s,s},POV={p,ly+s+g,s,s},Bag={x,s+p+g,s,s},Emote={x-s-g,s+p+g,s,s},Sprint={x,y-s-g,s,s},Crouch={x-s-g,y,s,s},Jump={x,y,s,s},Drop={x-2*(s+g),y-s-g,s,s},Health={p,h-58,132,46},Speed={156,h-58,58,46},Header={headerX,8,headerRight-headerX,82}}
end
return Layout
