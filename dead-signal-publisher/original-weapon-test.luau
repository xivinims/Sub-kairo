local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-original.rbxl'))
local base=dm:GetService('ReplicatedStorage').Library.Shared.WeaponsHandler.BaseWeapon
local source=base.Gun.Source
local a=assert(source:find('function gun:__setupInputs()',1,true));local b=assert(source:find('function gun:ChangeFiremode',a,true))
local methods=source:sub(a,b-1)
local callbacks={};local menu=false;local shots=0;local reloads=0;local aiming=false;local current='Auto';local weapon
local library={IsMobile=function() return true end,MovementHandler={IsSprinting=function() return false end},ContextActionUtility={BindAction=function(_,name,fn) callbacks[name]=fn end,UnbindAction=function(_,name) callbacks[name]=nil end}}
local factory=luau.load('return function(library,Enum,player,userInputService,wait) local gun={} local parentClass={__setupInputs=function() end,__removeInputs=function() end}\n'..methods..'\nreturn gun end')()
local gun=factory(library,R.Enum,{GetAttribute=function() return menu end},{IsMouseButtonPressed=function() return false end},function() if shots>=3 then weapon.__triggerHeld=false end end)
weapon=setmetatable({Ammo=30,WeaponTool={Ammo={Value=30}},WeaponInfo={ShootCooldown=.1},GetCurrentFiremode=function() return current end,CanFire=function() return true end,CanReload=function() return false end,Reload=function() reloads+=1 end,Shoot=function() shots+=1 end,CancelThread=function() end,IsAiming=function() return aiming end,ToggleAim=function(_,value) aiming=value end},{__index=gun})
weapon:__setupInputs();assert(callbacks.Shoot and callbacks.Reload and callbacks.ADS)
callbacks.Shoot('Shoot',R.Enum.UserInputState.Begin,{UserInputType=R.Enum.UserInputType.Touch});assert(shots==3,'Automatic fire did not work with touch and no mouse')
callbacks.Shoot('Shoot',R.Enum.UserInputState.End,{});assert(not weapon.__triggerHeld)
menu=true;callbacks.Shoot('Shoot',R.Enum.UserInputState.Begin,{});assert(shots==3,'Shot through settings modal');menu=false
current='SemiAuto';callbacks.Shoot('Shoot',R.Enum.UserInputState.Begin,{});assert(shots==4);callbacks.Shoot('Shoot',R.Enum.UserInputState.Begin,{});assert(shots==4,'Duplicate touch begin fired twice')
callbacks.Shoot('Shoot',R.Enum.UserInputState.Cancel,{});assert(not weapon.__triggerHeld and not weapon.Charging)
callbacks.Reload('Reload',R.Enum.UserInputState.Begin,{});assert(reloads==1)
callbacks.ADS('ADS',R.Enum.UserInputState.Begin,{});assert(aiming);callbacks.ADS('ADS',R.Enum.UserInputState.Begin,{});assert(not aiming)
weapon:__removeInputs();assert(not callbacks.Shoot and not callbacks.Reload and not callbacks.ADS)
assert(base.Source:find('os.clock()+3',1,true) and not base.Source:find('while self.Animations.Viewmodel:GetAnimation("Idle").Length == 0 do',1,true),'Unbounded equip wait remains')
print('WEAPON REGRESSION PASS: touch automatic fire without mouse, semi-auto deduplication, release/cancel, modal blocking, reload, aim toggle and unequip cleanup')
