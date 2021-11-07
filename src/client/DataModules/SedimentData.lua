
local function copyInsert(tabFrom, tabTo)
	for _, v in ipairs(tabFrom) do
		table.insert(tabTo, v)
	end
end

local SedimentData = {}

local _metaData = nil
local _sedimentThresholds = nil
local _tileThresholds = nil
local _tiles = nil
local _layerCount = nil
local _depth = nil

function SedimentData.loadData(dataset)
	_metaData = {}
	_sedimentThresholds = {}
	_tileThresholds = {}
	_tiles = {}
	_layerCount = #dataset

	local cumulativeDepth = 0

	-- first pass, process metadata
	for index, layerData in ipairs(dataset) do
		local depth = layerData[3]
		_metaData[index] = {
			index = index,
			name = layerData[1],
			description = layerData[2],
			
			top = cumulativeDepth,
			bottom = cumulativeDepth + depth,
			depth = depth,
			
			oreBase = layerData[4],
			oreCommon = layerData[5],
			oreRare = layerData[6],
			orePrecious = layerData[7],
		}
		
		cumulativeDepth = cumulativeDepth + depth
	end
	
	-- second pass to compress threshold value ranges to their own top-bottom
	for _, sedimentLayer in ipairs(_metaData) do
		local scale = (sedimentLayer.bottom - sedimentLayer.top)/cumulativeDepth
		local top = sedimentLayer.top/cumulativeDepth

		-- calculate thresholds (offset from stepped sediments)
		table.insert(_tileThresholds, top)  --base ore
		table.insert(_tileThresholds, top + 0.25 * scale) --common
		table.insert(_tileThresholds, top + 0.5 * scale) --rare
		table.insert(_tileThresholds, top + 0.75 * scale) --precious
		
		-- add tile data
		table.insert(_tiles, sedimentLayer.oreBase)
		table.insert(_tiles, sedimentLayer.oreCommon)
		table.insert(_tiles, sedimentLayer.oreRare)
		table.insert(_tiles, sedimentLayer.orePrecious)
		
		-- add sediment-specific threshold weights
		table.insert(_sedimentThresholds, sedimentLayer.top/cumulativeDepth)
	end

	_depth = cumulativeDepth
end

function SedimentData.getLayerByIndex(index)
	return _metaData[index]
end

function SedimentData.getLayerByDepth(depth)
	-- hmm?
end

function SedimentData.getTotalDepth()
	return _depth
end

function SedimentData.getSedimentThresholds()
	return _sedimentThresholds
end

function SedimentData.getTileThresholds()
	return _tileThresholds
end

function SedimentData.getLayerCount()
	return _layerCount
end

function SedimentData.getTiles()
	return _tiles
end

return SedimentData
