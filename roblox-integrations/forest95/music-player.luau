local M={}
function M.new(parent,activity,status)
 local self={sound=nil,generation=0,volume=.25,paused=false}
 local function state(active)activity(active==true)end
 function self.stop()
  self.generation+=1 if self.sound then self.sound:Destroy()self.sound=nil end self.paused=false state(false)
 end
 function self.play(id,title)
  self.stop()local generation=self.generation
  local s=Instance.new("Sound")s.Name="TreeWorldPersonalMusic"s.SoundId="rbxassetid://"..id s.Volume=self.volume s.Looped=true s.Parent=parent self.sound=s status("Carregando…")
  local failed=false task.spawn(function()local ok=pcall(function()game:GetService("ContentProvider"):PreloadAsync({s})end)failed=not ok end)
  local deadline=os.clock()+12
  repeat task.wait(.1)until s.IsLoaded or failed or os.clock()>deadline or generation~=self.generation
  if generation~=self.generation then return false end
  if not s.IsLoaded or s.TimeLength<=0 then self.stop()status("Esse áudio não está disponível neste jogo.")return false end
  s:Play()state(true)status(title or"Sua música")return true
 end
 function self.pause()
  if not self.sound or not self.sound.IsLoaded then return end
  self.paused=not self.paused
  if self.paused then self.sound:Pause()state(false)status("Pausado")else self.sound:Resume()state(true)status("Ouvindo música")end
 end
 function self.setVolume(v)self.volume=math.clamp(v,0,.6)if self.sound then self.sound.Volume=self.volume end end
 return self
end
return M
