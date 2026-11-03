local S={}
S.defaults={CameraBanking=true,CameraTilt=true,HighQuality=false,MusicVolume=.5,SFXVolume=.5,GlowPulse=true,PanelBob=true,DepthOfField=true,TextWave=true,ShowFPS=false,ReduceMotion=false}
function S.patch(value)
 local result={}
 if type(value)~='table' then return result end
 for key,default in pairs(S.defaults) do
  local v=value[key]
  if type(default)=='boolean' and type(v)=='boolean' then result[key]=v
  elseif type(default)=='number' and type(v)=='number' and v==v and math.abs(v)<math.huge then result[key]=math.clamp(v,0,1) end
 end
 return result
end
function S.clean(value)
 local result=table.clone(S.defaults)
 for key,v in pairs(S.patch(value)) do result[key]=v end
 return result
end
return S
