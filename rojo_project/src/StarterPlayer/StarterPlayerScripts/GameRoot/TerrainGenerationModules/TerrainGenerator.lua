

local floor = math.floor

local function findThreshold(thresholds, tileIDs, value)
	local highest = thresholds[1]
	local index = 1
	
	for i = 2, #thresholds do
		local t = thresholds[i]
		if t > highest and t <= value then
			highest = t
			index = i
		end
	end
	
	return tileIDs[index]
end

--[[
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
		
		layers = {}
	}
	
	setmetatable(self, TerrainGenerator)
	return self
end

function TerrainGenerator:addImageProcessor(processor)
	table.insert(self.layers, processor)
end

function TerrainGenerator:generateTile(x, y)
	--[[
	local tile_id = -1
	for i = 1, #self.layers do
		local v = self.layers[i]:draw(x, y, self.seed)
		if v ~= -1 then
			tile_id = v
		end
	end
	return tile_id
	]]
	return findThreshold(self.thresholds, self.tiles, self.layers[1]:draw(x, y, self.seed))
end

return TerrainGenerator