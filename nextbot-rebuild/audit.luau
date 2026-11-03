local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
local result={}
for _,meta in ipairs(serde.decode('json',fs.readFile('/tmp/nb-assets/meta.json'))) do
	if meta.file then
		local roots=R.deserializeModel(fs.readFile(meta.file))
		local report={id=meta.id,name=meta.name,sha256=meta.sha256,roots={},animations={},sounds={},scripts={},parts=0,thumbnails={}}
		for _,root in ipairs(roots) do
			table.insert(report.roots,{name=root.Name,class=root.ClassName,descendants=#root:GetDescendants()})
			for _,item in ipairs(root:GetDescendants()) do
				if item:IsA('KeyframeSequence') then table.insert(report.animations,{path=item:GetFullName(),kind='KeyframeSequence',poses=#item:GetDescendants()})
				elseif item:IsA('Animation') then table.insert(report.animations,{path=item:GetFullName(),id=tostring(item.AnimationId)})
				elseif item:IsA('Sound') then table.insert(report.sounds,{path=item:GetFullName(),id=tostring(item.SoundId)})
				elseif item:IsA('LuaSourceContainer') then table.insert(report.scripts,{path=item:GetFullName(),source=item.Source})
				elseif item:IsA('BasePart') then report.parts+=1 end
			end
		end
		table.insert(result,report)
	else table.insert(result,meta) end
end
fs.writeFile('/tmp/nb-assets/audit.json',serde.encode('json',result,true))
for _,r in ipairs(result) do
	if r.scripts then for _,s in ipairs(r.scripts) do s.sourceBytes=#s.source;s.source=nil end end
end
print(serde.encode('json',result))
