
local function findThreshold(thresholds, tileIDs, value)
	for i = 2, #thresholds do
		if thresholds[i] > value then
			return tileIDs[i-1]
		end
	end
	return tileIDs[#tileIDs]
end

--[[
local floor = math.floor
local function findThreshold(thresholds, tiles, value)
	local first = 1
	local it = first
	local count, step = #thresholds, nil
	while count > 0 do
		it = first
		step = floor(count/2)
		it = it + step
		
		if thresholds[it] < value then
			it = it + 1
			first = it
			count = count - step + 1
		else
			count = step
		end
	end
	
	return first
end
]]


local TerrainGenerator = {}
TerrainGenerator.__index = TerrainGenerator

function TerrainGenerator.new(seed)
	local self = {
		seed = seed,
		layers = {}
	}
	
	setmetatable(self, TerrainGenerator)
	return self
end

function TerrainGenerator:addLayer(image, thresholds, tiles)
	table.insert(self.layers, {image, thresholds, tiles})
end

function TerrainGenerator:generateTile(x, y)
	local tile = -1
	for i = #self.layers, 1, -1 do
		local layer = self.layers[i]
		if tile == -1 then
			local value = layer[1]:get(x, y, self.seed)
			tile = findThreshold(layer[2], layer[3], value)
		end
	end

	return tile
end

return TerrainGenerator