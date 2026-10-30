-- Restore the source mansion's own door controller. No custom player locks.
-- Mission doors remain controlled by the source DoorManager and mission scripts.
return function(dm)
 local module=dm:GetService('ServerScriptService').DoorManager
 assert(module and module:IsA('ModuleScript'),'Source DoorManager missing')
 assert(module.Source:find('function DoorManager.EnableDoor',1,true),'Original campaign door API unavailable')
 -- Deliberately leave the original door module unchanged.
 dm:GetService('Workspace'):SetAttribute('DoorLockVersion','original-only-v2')
end
