local HttpService = game:GetService("HttpService")


local ROOT = script.Parent.Parent

local Signal = require(ROOT.HelperModules.Signal)
local Timer = require(ROOT.HelperModules.Timer).new()
local WorldConfig = require(ROOT.DataModules.WorldConfig)


-- For efficiency's sake
local BITS = WorldConfig.BITS
local MAX_UINT = WorldConfig.MAX_UINT

local MAP_X = WorldConfig.MAP_X
local MAP_Y = WorldConfig.MAP_Y

local CHUNK_COL = WorldConfig.CHUNK_COL
local CHUNK_ROW = WorldConfig.CHUNK_ROW
local CHUNK_DIM = WorldConfig.CHUNK_DIM
local CHUNK_TILES = WorldConfig.CHUNK_TILES
local CHUNK_COUNT = WorldConfig.CHUNK_COUNT

local bor = bit32.bor
local lshift = bit32.lshift
local extract = bit32.extract
local replace = bit32.replace
local byte = string.byte
local char = string.char
local floor = math.floor
local format = string.format

-- Converts 4 character bytes to integer by chaining them together
local function charsToInt(bt0, bt1, bt2, bt3)
	return bor(lshift(bt0, 21), lshift(bt1, 14), lshift(bt2, 7), bt3)
end

-- Converts integer to string of character from the integer's four 8 bit segments
local function intToChars(int)
	return char(
		extract(int, 21, 7),
		extract(int, 14, 7),
		extract(int, 7, 7),
		extract(int, 0, 7))
end

-- Iterates through a long string and gives integers formed from each set of 4 chars
-- If input is not divisible by 4, ignores the remainder
-- Returns intCounter (starts from 0), integerData
local function string_int_iter(data)
	local size = string.len(data)
	local intCounter = -1
	
	return function()
		intCounter = intCounter + 1
		local ch = 4*intCounter + 1
		
		if ch+3 <= size then
			return intCounter, charsToInt(byte(data, ch, ch+3))
		end
	end
end

local function inBounds(x, y)
	if x < 0 or y < 0 or x >= MAP_X or y >= MAP_Y then
		return false
	end
	return true
end




local WorldData = {}
WorldData.__index = WorldData

WorldData.new = function(terrainGen)
	local self = {
		chunkTileData = {}, --1024 integers for tileids each chunk
		chunkBinaryData = {}, --32 of 32-bit integers in each chunk
		terrainGen = terrainGen,
		
		binaryChangedSignal = Signal(),  --for terraindisplay update terrain
		tileChangedSignal = Signal(), --for terraindisplay update terrain
	}
	
	self.binaryChanged = self.binaryChangedSignal:GetEvent()
	self.tileChanged = self.tileChangedSignal:GetEvent()
	
	setmetatable(self, WorldData)
	
	self:initZeroBinaryData()
	return self
end

function WorldData:initZeroBinaryData()
	for chunkIndex = 1, CHUNK_COUNT do
		self.chunkBinaryData[chunkIndex] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	end
end
--efficiencyscape



--[[**
	Iterator for all tiles at specified chunk.

	@param [t:number] chunkIndex
	@returns tileId, binary, x, y, tileIndex each iteration
--**]]
function WorldData:chunk_iterator(chunkIndex)
	local index = -1
	local tile = self.chunkTileData[chunkIndex]
	local binary = self.chunkBinaryData[chunkIndex]
	
	return function()
		index = index + 1
		local x = index % CHUNK_DIM
		local y = floor(index/CHUNK_DIM)
		
		if index < CHUNK_TILES then
			--print(y)
			return tile[index+1], extract(binary[y+1], x), x, y, index+1
		end
	end
end

function WorldData:getBinary(x, y)
	if not inBounds(x, y) then
		return nil
	end
	
	local chunk = self.chunkBinaryData[WorldConfig.tileXYtoChunkIndex(x, y)] --checks?
	local col, row = WorldConfig.tileXYtoBinaryXY(x, y)

	return extract(chunk[row], col)
end

function WorldData:getTile(x, y)
	if not inBounds(x, y) then
		return nil
	end
	
	local chunk = self:getTileChunk(x, y)
	return chunk[WorldConfig.tileXYtoIndex(x, y)]
end

function WorldData:setBinary(x, y, bit)
	if not inBounds(x, y) then
		return nil
	end
	
	local chunk = self.chunkBinaryData[WorldConfig.tileXYtoChunkIndex(x, y)] --checks?
	local col, row = WorldConfig.tileXYtoBinaryXY(x, y)
	chunk[row] = replace(chunk[row], bit, col)
	
	self.binaryChangedSignal:Fire(x, y, bit)
end

function WorldData:setTile(x, y, tileId)
	if not inBounds(x, y) then
		return nil
	end
	
	local chunk = self:getTileChunk(x, y)
	chunk[WorldConfig.tileXYtoIndex(x, y)] = tileId
	
	self.tileChangedSignal:Fire(x, y, tileId)
end

function WorldData:loadBinaryData(dataString)
	local chunkBuffer = {}
	for counter, int in string_int_iter(dataString) do
		local chunkIndex = floor(counter/CHUNK_DIM)
		local chunkCol = chunkIndex % CHUNK_COL
		local chunkRow = floor(counter/MAP_X)
		
		table.insert(chunkBuffer, int)
		
		if counter % CHUNK_DIM == CHUNK_DIM-1 then --end of chunk
			self.chunkBinaryData[chunkIndex+1] = chunkBuffer
			chunkBuffer = {}
			
		--	print(format("loaded chunk %d, %d data", chunk_col, chunk_row))
		--elseif counter % CHUNK_DIM == 0 then
		--	print(format("started loading chunk %d, %d data", chunk_col, chunk_row))
		end
	end
end

function WorldData:loadSaveFile(saveFileDataString)
	local save = HttpService:JSONDecode(saveFileDataString)
	--json shit
end


function WorldData:binaryDataToString()
	local saveStringBuffer = {}
	
	-- saving chunk at a time
	for chunk_index = 1, CHUNK_COUNT do
		local chunk = self.chunkBinaryData[chunk_index]
		for row = 1, CHUNK_DIM do
			table.insert(saveStringBuffer, intToChars(chunk[row]))
		end
	end
	
	return table.concat(saveStringBuffer)
end

function WorldData:generateChunk(x, y)
	local tileChunk = {}
	
	for index = 0, CHUNK_TILES-1 do
		local tx, ty = WorldConfig.tileIndexToXY(index+1)
		tileChunk[index+1] = self.terrainGen:generateTile(x*CHUNK_DIM+tx, y*CHUNK_DIM+ty)
	end
	
	self.chunkTileData[WorldConfig.chunkXYtoIndex(x, y)] = tileChunk
	return tileChunk
end

function WorldData:loadChunk(x, y)
	local chunk = self.chunkTileData[WorldConfig.chunkXYtoIndex(x, y)]
	if chunk == nil then
		chunk = self:generateChunk(x, y)
	end
	
	return chunk
end

function WorldData:getTileChunk(x, y)
	return self:loadChunk(WorldConfig.tileXYtoChunkXY(x, y))
end

function WorldData:unloadChunk(x, y)
	--lets just keep it in memory instead for now, but fire event so terrain is hidden
end

return WorldData