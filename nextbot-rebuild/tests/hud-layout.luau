-- Geometry regression for the actual module used by Match.client. These checks
-- complement rendered client inspection; they do not measure font rendering.
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local Layout=luau.load(fs.readFile('nextbot-rebuild/HudLayout.luau'))()
local sizes={{360,720},{390,844},{844,390},{1280,591},{1536,709},{1920,1080},{1024,768},{568,260}}
local controls={'Menu','POV','Bag','Emote','Sprint','Crouch','Jump','Drop','Health','Speed','Header'}
local function overlap(a,b)
 return a[1]<b[1]+b[3]and b[1]<a[1]+a[3]and a[2]<b[2]+b[4]and b[2]<a[2]+a[4]
end
for _,size in ipairs(sizes)do
 local w,h=table.unpack(size)
 local layout=Layout.Compute(w,h)
 for i,name in ipairs(controls)do
  local r=layout[name]
  assert(r[1]>=0 and r[2]>=0 and r[3]>0 and r[4]>0 and r[1]+r[3]<=w and r[2]+r[4]<=h,string.format('%s clipped at %dx%d',name,w,h))
  if name~='Health'and name~='Speed'and name~='Header'then assert(r[3]>=48 and r[4]>=48,'Touch target too small: '..name)end
  for j=i+1,#controls do local other=controls[j];assert(not overlap(r,layout[other]),string.format('%s overlaps %s at %dx%d',name,other,w,h))end
 end
 assert(layout.Jump[1]+layout.Jump[3]<=w-12 and layout.Jump[2]+layout.Jump[4]<=h-12,'Jump must stay inside safe GUI with bottom/right padding')
end
print('PASS: actual HUD geometry at 8 portrait/landscape/desktop/tablet sizes, control bounds, separation, touch target sizes and jump safe-area padding. Native GUI origin conversion and rendered visual inspection remain required in a Roblox client.')
