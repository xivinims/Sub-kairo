local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde')
for _,meta in ipairs(serde.decode('json',fs.readFile('/tmp/nb-assets/reference-meta.json')))do
 if meta.error then print('Reference model '..serde.encode('json',meta));continue end
 local ok,roots=pcall(R.deserializeModel,fs.readFile('/tmp/nb-assets/'..meta.id..'.rbxm'):gsub('^<%?xml.-%?>%s*',''))
 if not ok then print('Reference parse error '..tostring(roots));continue end
 local report={meta=meta,clips={},images={},settings={},models={},animations={},motors={},firstPoses={}}
 for _,root in ipairs(roots)do
  for _,v in ipairs(root:GetDescendants())do
   if v:IsA('Motor6D')then table.insert(report.motors,{name=v.Name,part0=v.Part0 and v.Part0.Name,part1=v.Part1 and v.Part1.Name,c0=tostring(v.C0),c1=tostring(v.C1)})
   elseif v:IsA('KeyframeSequence')then
    local max=0;local frames=0;local poseNames={}
    for _,f in ipairs(v:GetChildren())do if f:IsA('Keyframe')then max=math.max(max,f.Time);frames+=1 end end
    for _,pose in ipairs(v:GetDescendants())do if pose:IsA('Pose')then poseNames[pose.Name]=true end end
    if v.Name:lower():find('crouch')or v.Name:lower():find('down')or v.Name:lower():find('crawl')then local first=v:GetChildren()[1];if first then for _,pose in ipairs(first:GetDescendants())do if pose:IsA('Pose')then table.insert(report.firstPoses,{clip=v.Name,path=pose:GetFullName(),cf=tostring(pose.CFrame),weight=pose.Weight})end end end end
    table.insert(report.clips,{path=v:GetFullName(),name=v.Name,duration=max,frames=frames,poses=poseNames,loop=v.Loop})
   elseif v:IsA('Animation')then local good,id=pcall(function()return v.AnimationId end);table.insert(report.animations,{path=v:GetFullName(),id=good and tostring(id)or ''})
   elseif v:IsA('LuaSourceContainer')then
    local lines={};for line in v.Source:gmatch('[^\r\n]+')do if line:lower():find('speed')or line:lower():find('downed')or line:lower():find('crouch')or line:lower():find('crawl')or line:lower():find('animationid')then if #lines<32 then table.insert(lines,line:sub(1,220))end end end
    if #lines>0 then table.insert(report.settings,{path=v:GetFullName(),lines=lines})end
   elseif v:IsA('ImageLabel')or v:IsA('ImageButton')then
    if #report.images<80 then local good,id=pcall(function()return v.Image end);table.insert(report.images,{path=v:GetFullName(),id=good and tostring(id)or ''})end
   elseif v:IsA('Model')or v:IsA('Tool')then if #report.models<60 then table.insert(report.models,v:GetFullName())end end
  end
 end
 print('Reference model '..serde.encode('json',report))
end
