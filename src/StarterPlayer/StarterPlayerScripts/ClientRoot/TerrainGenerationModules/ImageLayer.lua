local min = math.min
local max = math.max
local abs = math.abs
local clamp = math.clamp

local BLEND_OPERATIONS = {
	MIX = function(a, b) return b end,
	ALPHA_MIX = function(a, b) return a>0 and a or b end,
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



local ImageLayer = {}
ImageLayer.__index = ImageLayer

function ImageLayer.new()
	local self = {
		layers = {}
	}
	
	setmetatable(self, ImageLayer)
	return self
end

function ImageLayer:draw(blendMode, opacity, drawFunc)
	table.insert(self.layers, {0, drawFunc, BLEND_OPERATIONS[blendMode], opacity})
end

function ImageLayer:filter(blendMode, opacity, filterFunc)
	table.insert(self.layers, {1, filterFunc, BLEND_OPERATIONS[blendMode], opacity})
end

function ImageLayer:mix(blendMode, opacity, otherLayer)
	table.insert(self.layers, {2, otherLayer, BLEND_OPERATIONS[blendMode], opacity})
end

function ImageLayer:get(x, y, seed)
	local result = 0
	for _, layer in ipairs(self.layers) do
		local blend
		local layerType = layer[1]
		if layerType == 0 then --draw
			blend = layer[3](result, layer[2](x, y, seed))
		elseif layerType == 1 then --filter
			blend = layer[3](result, layer[2](result))
		elseif layerType == 2 then --layer mix
			blend = layer[3](result, layer[2]:get(x, y, seed))
		end
		
		result = clamp(lerp(result, blend, layer[4]), 0, 1)
	end
	
	return result
end

return ImageLayer
