local M={Defaults={volume=.8,brightness=.5,fov=70,sensitivity=1,shadows=true,bloom=true,objectives=true,loadingHints=true}}
function M.Clean(data)
 if typeof(data)~='table' then return nil end
 local out={}
 for key,default in pairs(M.Defaults) do
  local value=data[key]
  if typeof(default)=='boolean' then out[key]=typeof(value)=='boolean' and value or (value==nil and default or false)
  else
   if typeof(value)~='number' or value~=value or math.abs(value)==math.huge then value=default end
   local low,high=0,1
   if key=='fov' then low,high=60,90 elseif key=='sensitivity' then low,high=.2,2 end
   out[key]=math.clamp(value,low,high)
  end
 end
 return out
end
return M
