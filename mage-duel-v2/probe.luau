local result={version=game.PlaceVersion,build=workspace:GetAttribute('BuildVersion'),roots={},assets={},loaders={}}
for _,p in ipairs(workspace:GetChildren()) do table.insert(result.roots,{name=p.Name,class=p.ClassName}) end
for _,s in ipairs({game.ReplicatedFirst,game.StarterGui,game.StarterPlayer.StarterPlayerScripts,game.ServerScriptService}) do
 for _,p in ipairs(s:GetChildren()) do table.insert(result.loaders,{name=p:GetFullName(),class=p.ClassName}) end
end
for _,id in ipairs({115275786272862,9132974153,3832698706,84222065610676,106281505667193,102185762902096,126521784338665}) do
 local ok,model=pcall(function()return game:GetService('InsertService'):LoadAsset(id)end)
 local row={id=id,ok=ok,classes={},nodes={},scripts={}}
 if ok then
  for _,p in ipairs(model:GetDescendants()) do
   row.classes[p.ClassName]=(row.classes[p.ClassName] or 0)+1
   if p:IsA('LuaSourceContainer') then table.insert(row.scripts,{path=p:GetFullName(),source=p.Source:sub(1,3000),length=#p.Source})
   elseif #row.nodes<65 then
    local n={path=p:GetFullName(),class=p.ClassName}
    if p:IsA('BasePart') then n.size=tostring(p.Size);n.pos=tostring(p.Position);n.anchored=p.Anchored end
    if p:IsA('ParticleEmitter') then n.texture=p.Texture;n.rate=p.Rate;n.attributes=p:GetAttributes() end
    if p:IsA('Animation') then n.animation=p.AnimationId end
    if p:IsA('Humanoid') then n.rig=tostring(p.RigType);n.health=p.MaxHealth end
    table.insert(row.nodes,n)
   end
  end
  model:Destroy()
 else row.error=tostring(model) end
 table.insert(result.assets,row)
end
return result
