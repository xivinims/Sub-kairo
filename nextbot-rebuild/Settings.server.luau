local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local DSS=game:GetService('DataStoreService')
local package=RS:WaitForChild('NextbotReference')
local config=require(package.Config)
local remote=package.Settings
local store=DSS:GetDataStore('NextbotReferenceSettings_v1')
local sessions={}
local policy=require(package.SettingsPolicy)
local function sanitize(input)
	return policy(config.Settings,input)
end
local function load(p)
	if sessions[p] then return end
	local session={loading=true,dirty=false,lastRequest=0,data=table.clone(config.Settings)}
	sessions[p]=session
	local ok,data=pcall(function()return store:GetAsync('u'..p.UserId)end)
	if sessions[p]~=session then return end
	session.loading=false;session.writable=ok
	if ok then session.data=sanitize(data) else warn('Nextbot settings load unavailable for '..p.UserId) end
	if p.Parent then remote:FireClient(p,'Loaded',session.data) end
end
local function save(p,session)
	if session.loading or not session.writable or not session.dirty or session.saving then return end
	session.saving=true;local snapshot=table.clone(session.data)
	local revision=session.revision
	local ok=pcall(function()store:UpdateAsync('u'..p.UserId,function()return snapshot end)end)
	if ok and session.revision==revision then session.dirty=false end
	session.saving=false
	if not ok then warn('Nextbot settings save unavailable for '..p.UserId) end
end
Players.PlayerAdded:Connect(load)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(load,p) end
remote.OnServerEvent:Connect(function(p,action,input)
	local session=sessions[p]
	if not session or session.loading then return end
	local now=os.clock();if now-session.lastRequest<.25 then return end;session.lastRequest=now
	if action=='Load' then remote:FireClient(p,'Loaded',session.data)
	elseif action=='Save' and type(input)=='table' then
		session.data=sanitize(input);session.dirty=true;session.revision=(session.revision or 0)+1
	end
end)
Players.PlayerRemoving:Connect(function(p)
	local session=sessions[p]
	if session then
		local deadline=os.clock()+15
		while session.saving and os.clock()<deadline do task.wait(.1) end
		save(p,session)
	end
	sessions[p]=nil
end)
task.spawn(function()while task.wait(30) do for p,s in pairs(sessions) do task.spawn(save,p,s) end end end)
game:BindToClose(function()
	local pending=0
	for p,s in pairs(sessions) do pending+=1;task.spawn(function()save(p,s);pending-=1 end) end
	local deadline=os.clock()+25;while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
