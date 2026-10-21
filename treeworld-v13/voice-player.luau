-- Private conversation audio. World ambience remains spatial; Caio's voice
-- reaches this player's speakers without depending on camera zoom.
local Content = game:GetService('ContentProvider')
local SoundService = game:GetService('SoundService')
local Voice = {}
Voice.__index = Voice

function Voice.new(player, locale, data, manifest)
 local self = setmetatable({player=player,locale=locale,data=data,manifest=manifest,cache={},dead=false},Voice)
 self.folder = Instance.new('Folder')
 self.folder.Name = 'CaioLocalVoice'
 self.folder.Parent = SoundService
 return self
end

function Voice:_load(row)
 if row.loading or row.source.IsLoaded or self.dead then return end
 row.loading=true;row.finished=false;row.error=nil
 task.spawn(function()
  local ok,err=pcall(function()
   if row.kind=='recording' then
    Content:PreloadAsync({row.source},function(_,status) row.status=status end)
   else
    row.status=row.source:LoadAsync()
   end
  end)
  row.loading=false;row.finished=true
  if not ok then row.error=tostring(err) end
 end)
end

function Voice:_recording(id)
 local key='recording:'..id
 if self.cache[key] then self:_load(self.cache[key]);return self.cache[key] end
 if not self.manifest[id] then return nil end
 local sound=Instance.new('Sound')
 sound.Name='Caio_'..id;sound.SoundId='rbxassetid://'..self.manifest[id]
 sound.Volume=1;sound.Looped=false;sound.Parent=self.folder
 local row={source=sound,kind='recording'}
 self.cache[key]=row;self:_load(row);return row
end

function Voice:_speech(id)
 local key='speech:'..id
 if self.cache[key] then self:_load(self.cache[key]);return self.cache[key] end
 -- Optional synthesis never runs during controller initialization: a failure
 -- in the newer audio API must not disable prerecorded Portuguese dialogue.
 local source
 local ok,err=pcall(function()
  if not self.output then
   local output=Instance.new('AudioDeviceOutput')
   output.Name='CaioVoiceOutput';output.Player=self.player;output.Parent=self.folder;self.output=output
  end
  source=Instance.new('AudioTextToSpeech');source.Name='Caio_'..self.locale..'_'..id
  source.VoiceId=self.data.Voices[self.locale];source.AutoLocalize=false
  source.Text=self.data.Locales[self.locale][id];source.Speed=.96;source.Volume=1;source.Parent=self.folder
  local wire=Instance.new('Wire');wire.SourceInstance=source;wire.TargetInstance=self.output;wire.Parent=source
 end)
 if not ok then if source then source:Destroy() end;return nil,tostring(err) end
 local row={source=source,kind='speech'}
 self.cache[key]=row;self:_load(row);return row
end

function Voice:_ready(row,stillCurrent,seconds)
 if not row then return false end
 local deadline=os.clock()+seconds
 repeat
  if self.dead or not stillCurrent() then return false end
  if row.source.IsLoaded and row.source.TimeLength>0 then return true end
  if row.finished then return false end
  task.wait(.05)
 until os.clock()>=deadline
 return false
end

function Voice:preload()
 if self.locale~='pt' then return end
 -- Seven short recordings; warming them is independent of world streaming.
 for _,id in ipairs({'hello','about','cliff','pond','fruit','report','bye'}) do
  if not self.dead then self:_recording(id) end
 end
end

function Voice:stop()
 local playback=self.playback;self.playback=nil
 if not playback then return end
 if playback.connection then playback.connection:Disconnect() end
 pcall(function()
  if playback.source:IsA('Sound') then playback.source:Stop() else playback.source:Pause() end
 end)
end

function Voice:play(id,stillCurrent)
 local row
 if self.locale=='pt' then
  row=self:_recording(id)
  if not self:_ready(row,stillCurrent,6) then row=nil end
 end
 if self.dead or not stillCurrent() then return nil,'cancelled' end
 if not row then
  row=self:_speech(id)
  if not self:_ready(row,stillCurrent,10) then
   if self.dead or not stillCurrent() then return nil,'cancelled' end
   warn('[Caio voice] Unable to load '..self.locale..'/'..id..': '..tostring(row and (row.error or row.status) or 'synthesis unavailable'))
   return nil,'unavailable'
  end
 end
 if self.dead or not stillCurrent() then return nil,'cancelled' end
 self:stop()
 local playback={source=row.source,kind=row.kind,length=row.source.TimeLength,ended=false}
 playback.connection=row.source.Ended:Connect(function() playback.ended=true end)
 local ok,err=pcall(function() row.source.TimePosition=0;row.source:Play() end)
 if not ok then playback.connection:Disconnect();warn('[Caio voice] Playback failed: '..tostring(err));return nil,'unavailable' end
 self.playback=playback;return playback
end

function Voice:destroy()
 self.dead=true;self:stop();self.folder:Destroy();self.cache={}
end

return Voice
