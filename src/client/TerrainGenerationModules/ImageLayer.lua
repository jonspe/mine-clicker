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
	MASK = function(a, b) return a<b and 0 or 1 end
}


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
	local size = #self.layers
	self.layers[size+1] = 0 --layerType
	self.layers[size+2] = drawFunc
	self.layers[size+3] = BLEND_OPERATIONS[blendMode]
	self.layers[size+4] = opacity
end

function ImageLayer:filter(blendMode, opacity, filterFunc)
	local size = #self.layers
	self.layers[size+1] = 1 --layerType
	self.layers[size+2] = filterFunc
	self.layers[size+3] = BLEND_OPERATIONS[blendMode]
	self.layers[size+4] = opacity
end

function ImageLayer:mix(blendMode, opacity, otherLayer)
	local size = #self.layers
	self.layers[size+1] = 2 --layerType
	self.layers[size+2] = otherLayer
	self.layers[size+3] = BLEND_OPERATIONS[blendMode]
	self.layers[size+4] = opacity
end

function ImageLayer:get(x, y, seed)
	local result = 0
	local layers = self.layers
	for i = 1, #layers, 4 do
		local blend
		local layerType = layers[i]
		if layerType == 0 then --draw
			blend = layers[i+2](result, layers[i+1](x, y, seed))
		elseif layerType == 1 then --filter
			blend = layers[i+2](result, layers[i+1](result))
		elseif layerType == 2 then --layer mix
			blend = layers[i+2](result, layers[i+1]:get(x, y, seed))
		end
		
		result = result + layers[i+3]*(blend - result)
	end
	
	return result
end

return ImageLayer
