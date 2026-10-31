-- Keep the source door controller and enable the main entrance without a key.
-- Story door progression is disabled; the interaction runtime unlocks the main entrance.
return function(dm)
 local module=dm:GetService('ServerScriptService').DoorManager
 assert(module and module:IsA('ModuleScript'),'Source DoorManager missing')
 assert(module.Source:find('function DoorManager.EnableDoor',1,true),'Original campaign door API unavailable')
 -- Deliberately leave the original door module unchanged.
 dm:GetService('Workspace'):SetAttribute('DoorLockVersion','mystery-main-door-without-key-v1')
end
