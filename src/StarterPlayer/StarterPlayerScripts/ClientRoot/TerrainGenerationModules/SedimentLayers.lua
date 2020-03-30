
local function copyInsert(tabFrom, tabTo)
	for _, v in ipairs(tabFrom) do
		table.insert(tabTo, v)
	end
end

local SedimentLayers = {}
SedimentLayers.__index = SedimentLayers

function SedimentLayers.new(sedimentDataSource)
	local self = {
		metaData = nil,
		sedimentThresholdData = nil,
		tileThresholdData = nil,
		tileData = nil,
		
		layerCount = nil,
		cumulativeDepth = nil,
	}
	
	setmetatable(self, SedimentLayers)
	self:processData(sedimentDataSource)

	return self
end

function SedimentLayers:processData(data)
	self.metaData = {}
	self.sedimentThresholdData = {}
	self.tileThresholdData = {}
	self.tileData = {}
	
	self.layerCount = #data

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
			
			baseOre = layerData[4],
			commonOre = layerData[5],
			rareOre = layerData[6],
			preciousOre = layerData[7],
		}
		
		cumulativeDepth = cumulativeDepth + depth
	end
	
	-- second pass to compress threshold value ranges to their own top-bottom
	for _, sedimentLayer in ipairs(self.metaData) do
		local scale = (sedimentLayer.bottom - sedimentLayer.top)/cumulativeDepth
		local top = sedimentLayer.top/cumulativeDepth

		-- calculate thresholds (offset from stepped sediments)
		table.insert(self.tileThresholdData, top)  --base ore
		table.insert(self.tileThresholdData, top + 0.25 * scale) --common
		table.insert(self.tileThresholdData, top + 0.5 * scale) --rare
		table.insert(self.tileThresholdData, top + 0.75 * scale) --precious
		
		-- add tile data
		table.insert(self.tileData, sedimentLayer.baseOre)
		table.insert(self.tileData, sedimentLayer.commonOre)
		table.insert(self.tileData, sedimentLayer.rareOre)
		table.insert(self.tileData, sedimentLayer.preciousOre)
		
		-- add sediment-specific threshold weights
		table.insert(self.sedimentThresholdData, sedimentLayer.top/cumulativeDepth)
	end

	self.cumulativeDepth = cumulativeDepth
end

function SedimentLayers:getLayerByIndex(index)
	return self.metaData[index]
end

function SedimentLayers:getLayerByDepth(depth)
	-- hmm?
end


	
return SedimentLayers
