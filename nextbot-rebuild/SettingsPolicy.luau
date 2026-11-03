return function(defaults,input)
	local out=table.clone(defaults)
	if type(input)~='table' then return out end
	for key,default in pairs(out) do
		local v=input[key]
		if typeof(v)==typeof(default) then
			if type(v)=='number' then
				if v==v and math.abs(v)<math.huge then
					out[key]=math.clamp(v,key=='FOV' and 70 or 0,key=='FOV' and 100 or 1)
				end
			else out[key]=v end
		end
	end
	return out
end
