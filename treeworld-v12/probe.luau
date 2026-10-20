local out={version=game.PlaceVersion,assets={}}
for _,id in ipairs({9731248486,6557969904,74899630735614,119986768245480,73852738603629,11946229834})do
 local ok,m=pcall(function()return game:GetService('InsertService'):LoadAsset(id)end)
 local row={id=id,ok=ok,classes={},scripts={},textures={},names={}}
 if ok then
  local written=0
  for _,p in ipairs(m:GetDescendants())do
   row.classes[p.ClassName]=(row.classes[p.ClassName]or 0)+1
   if p:IsA('LuaSourceContainer')then
    local s=p.Source;table.insert(row.scripts,{name=p:GetFullName(),source=string.sub(s,1,math.max(0,18000-written)),length=#s});written+=#s
   elseif p:IsA('Decal')then table.insert(row.textures,{name=p:GetFullName(),texture=p.Texture})
   elseif p:IsA('Sound')then table.insert(row.textures,{name=p:GetFullName(),sound=p.SoundId,volume=p.Volume})
   elseif #row.names<50 and (p:IsA('BasePart')or p:IsA('ScreenGui')or p:IsA('Frame')or p:IsA('Model'))then table.insert(row.names,{name=p:GetFullName(),size=p:IsA('BasePart')and tostring(p.Size)or nil})end
  end
  m:Destroy()
 else row.error=tostring(m)end
 table.insert(out.assets,row)
end
out.streaming={enabled=workspace.StreamingEnabled,min=workspace.StreamingMinRadius,target=workspace.StreamingTargetRadius}
out.tts={}
local ok,err=pcall(function()local t=Instance.new('AudioTextToSpeech');t.Text='Olá! Eu sou o Caio. Que bom te encontrar por aqui.';t.VoiceId='1001';t.AutoLocalize=false;t.Parent=workspace;out.tts.class=true;out.tts.status=tostring(t:LoadAsync());out.tts.loaded=t.IsLoaded;out.tts.duration=t.TimeLength;t:Destroy()end)
out.tts.ok=ok;out.tts.error=not ok and tostring(err)or nil
local world=workspace:FindFirstChild('OveryardPhotoWorld');out.hero={}
if world then for _,m in ipairs(world:GetDescendants())do if m:IsA('Model')and m:GetAttribute('Tree')then
 local r=m:GetAttribute('RootPosition');if r and (Vector2.new(r.X-12,r.Z)).Magnitude<45 then
  local row={name=m:GetFullName(),root=tostring(r),parts={}}
  for _,p in ipairs(m:GetChildren())do if p:IsA('BasePart')then table.insert(row.parts,{name=p.Name,position=tostring(p.Position),size=tostring(p.Size),mesh=p:IsA('MeshPart')and p.MeshId or nil})end end;table.insert(out.hero,row)
 end
end end end
return out
