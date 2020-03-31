
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
		thresholds = thresholds,
		tiles = tiles,
		
		surfaceImage = nil,
		surfaceThresholds = nil,
		surfaceTiles = nil,

		sedimentImage = nil,
		sedimentThresholds = nil,
		sedimentTiles = nil,
	}
	
	setmetatable(self, TerrainGenerator)
	return self
end

function TerrainGenerator:setSurface(image, thresholds, tiles)
	self.surfaceImage = image
	self.surfaceThresholds = thresholds
	self.surfaceTiles = tiles
end

function TerrainGenerator:setSediments(image, thresholds, tiles)
	self.sedimentImage = image
	self.sedimentThresholds = thresholds
	self.sedimentTiles = tiles
end

function TerrainGenerator:generateTile(x, y)
	local surfaceValue = self.surfaceImage:get(x, y, self.seed)
	local tile = findThreshold(self.surfaceThresholds, self.surfaceTiles, surfaceValue)

	if tile == -1 then
		local sedimentValue = self.sedimentImage:get(x, y, self.seed)
		tile = findThreshold(self.sedimentThresholds, self.sedimentTiles, sedimentValue)
	end
	
	return tile
end

return TerrainGenerator