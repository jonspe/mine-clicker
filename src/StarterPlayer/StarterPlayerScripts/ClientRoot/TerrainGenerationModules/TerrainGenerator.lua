
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

function TerrainGenerator.new(seed, thresholds, tiles)
	local self = {
		seed = seed,
		thresholds = thresholds,
		tiles = tiles,
		
		surfaceLayer = nil,
		sedimentLayer = nil,
	}
	
	setmetatable(self, TerrainGenerator)
	return self
end

function TerrainGenerator:setSurfaceLayer(layer)
	self.surfaceLayer = layer
end

function TerrainGenerator:setSedimentLayer(layer)
	self.sedimentLayer = layer
end

function TerrainGenerator:generateTile(x, y)
	--local result = self.surfaceLayer:draw(x, y, self.seed)
	--if result <= 0 then
	local result = self.sedimentLayer:get(x, y, self.seed)
	--end
	--print(result)

	return findThreshold(self.thresholds, self.tiles, result)
end

return TerrainGenerator