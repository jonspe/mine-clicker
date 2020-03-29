local min = math.min
local max = math.max
local abs = math.abs
local clamp = math.clamp

local BLEND_OPERATIONS = {
	MIX = function(a, b) return b end,
	ADD = function(a, b) return a+b end,
	SUBTRACT = function(a, b) return a-b end,
	MULTIPLY = function(a, b) return a*b end,
	SCREEN = function(a, b) return 1 - (1-a)*(1-b) end,
	DARKEN = function(a, b) return min(a, b) end, --or MIN
	LIGHTEN = function(a, b) return max(a, b) end, --or MAX
	DIFFERENCE = function(a, b) return abs(a-b) end,
	OVERLAY = function(a, b) return a<0.5 and 2*a*b or 1-2*(1-a)*(1-b) end,
	MASK = function(a, b) return a<b and 0 or 1 end,
	
	--THRESHOLD_MASK = function(a, b)
}

local function lerp(a, b, t)
	return a + t*(b - a);
end




local ImageProcessor = {}
ImageProcessor.__index = ImageProcessor

function ImageProcessor.new()
	local self = {
		layers = {}
	}
	
	setmetatable(self, ImageProcessor)
	return self
end

function ImageProcessor:blend(blendMode, opacity, drawFunc)
	table.insert(self.layers, {drawFunc, BLEND_OPERATIONS[blendMode], opacity})
end

function ImageProcessor:draw(x, y, seed)
	local result = 0
	for _, layer in ipairs(self.layers) do
		local blend = layer[2](result, layer[1](x, y, seed))
		result = clamp(lerp(result, blend, layer[3]), 0, 1)
	end
	
	return result
end

return ImageProcessor
