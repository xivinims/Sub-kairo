local S={}
S.Defaults={master=1,music=.8,sfx=.8,brightness=.5,fov=70,sensitivity=1,quality=7,subtitles=true,scanlines=true,motion=true,cameraMode="Livre"}
local ranges={master={0,1},music={0,1},sfx={0,1},brightness={0,1},fov={50,110},sensitivity={.2,3},quality={1,10}}
function S.Clean(input)
 input=type(input)=="table" and input or {}
 local result={}
 for k,default in pairs(S.Defaults) do
  if k=="cameraMode" then
   local mode=input[k]
   result[k]=(mode=="Livre" or mode=="Terceira pessoa" or mode=="Primeira pessoa") and mode or default
  elseif type(default)=="boolean" then result[k]=type(input[k])=="boolean" and input[k] or default;if input[k]==false then result[k]=false end
  else
   local n=tonumber(input[k]);if k=="quality" and input[k]=="Baixa" then n=2 elseif k=="quality" and input[k]=="Alta" then n=7 end
   if not n or n~=n or math.abs(n)==math.huge then n=default end
   result[k]=math.clamp(n,ranges[k][1],ranges[k][2]);if k=="fov" or k=="quality" then result[k]=math.floor(result[k]+.5) end
  end
 end
 return result
end
function S.Percent(v) return string.format("%d%%",math.floor(v*100+.5)) end
return S
