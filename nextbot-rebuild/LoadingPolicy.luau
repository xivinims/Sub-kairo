local M={}
function M.CanReveal(boot,ready,currentRevision,loadedRevision,interfaceReady)
 return boot==true and ready==true and interfaceReady==true and type(currentRevision)=='number'and currentRevision==loadedRevision
end
return M
