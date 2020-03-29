
local function copyInsert(tabFrom, tabTo)
	for _, v in ipairs(tabFrom) do
		table.insert(tabTo, v)
	end
end

local SedimentLayers = {}
SedimentLayers.__index = SedimentLayers

function SedimentLayers.new()
	local self = {
		metaData = nil,
		thresholdData = nil,
		tileData = nil,
		
		cumulativeDepth = nil,
	}
	
	setmetatable(self, SedimentLayers)
	return self
end

function SedimentLayers:processData(data)
	self.metaData = {}
	self.thresholdData = {}
	self.tileData = {}
	
	local layerCount = #data
	local cumulativeDepth = 0
	
	-- first pass, process metadata
	for index, layerData in ipairs(data) do
		local depth = layerData[3]
		self.metaData[index] = {
			index = index,
			name = layerData[1],
			description = layerData[2],
			
			top = cumulativeDepth,
			bottom = cumulativeDepth + depth,
			depth = depth,
			
			thresholds = layerData[4],
			tiles = layerData[5]
		}
		
		cumulativeDepth = cumulativeDepth + depth
	end
	
	-- second pass, to compress threshold value ranges to their own top-bottom
	for _, sedimentLayer in ipairs(self.metaData) do
		local scale = (sedimentLayer.bottom - sedimentLayer.top)/cumulativeDepth
		for __, threshold in ipairs(sedimentLayer.thresholds) do
			table.insert(self.thresholdData, sedimentLayer.top/cumulativeDepth + threshold * scale)
		end
		
		-- also add tile data
		for __, tile in ipairs(sedimentLayer.tiles) do
			table.insert(self.tileData, tile)
		end
	end
	
	print(unpack(self.thresholdData))
	self.cumulativeDepth = cumulativeDepth
end

function SedimentLayers:getLayerByIndex(index)
	return self.metaData[index]
end

function SedimentLayers:getLayerByDepth(depth)
	-- hmm?
end


	
return SedimentLayers
