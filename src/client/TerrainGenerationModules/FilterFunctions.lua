
local function findThreshold(thresholds, value)
	for i = 2, #thresholds do
		if thresholds[i] > value then
			return thresholds[i-1]
		end
	end
	return thresholds[#thresholds]
end

local function step(thresholds)
    return function(p)
        return findThreshold(thresholds, p)
    end
end

return {
    step = step,
}


