assert(game.PlaceVersion==92)game:GetService("ServerStorage")
local r={readOnly=true,scripts={}}
local roots={game.ServerScriptService.ForestServer}
for _,m in ipairs(game.ReplicatedStorage.ForestRuntime:GetDescendants())do if m:IsA("ModuleScript")then roots[#roots+1]=m end end
for _,m in ipairs(roots)do local code=m.Source local row={name=m:GetFullName(),length=#code,prefix=code:sub(1,180)}
 if m:IsA("ModuleScript")then local ok,v=pcall(require,m)row.ok=ok row.error=not ok and tostring(v)or nil end r.scripts[#r.scripts+1]=row
end
return r