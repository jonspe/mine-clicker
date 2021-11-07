local floor = math.floor

local Timer = {}
Timer.__index = Timer

function Timer.new()
	local self = {
		tickStart = tick(),
		tickMsg = "",
	}
	
	setmetatable(self, Timer)
	return self
end

function Timer:tick(msg)
	self.tickMsg = msg .. ": " or ""
	self.tickStart = tick()
end

function Timer:tock()
	local t = tick()
	print(self.tickMsg .. floor(1000*(t - self.tickStart)) .. " ms elapsed")
end

return Timer