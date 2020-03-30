
local function findThreshold(thresholds, value)
	local prev = thresholds[1]
	for i = 2, #thresholds do
		local t = thresholds[i]
		if t > value then
			return prev
		end
		prev = t
	end
	return prev
end


local function step(thresholds)
    return function(p)
        return findThreshold(thresholds, p)
    end
end



return {
    step = step,
}


