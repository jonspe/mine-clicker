local HttpService = game:GetService("HttpService")

local ROOT = script.Parent.Parent
local Chunk = require(ROOT.DataModules.Chunk)
local BinaryChunk = require(ROOT.DataModules.BinaryChunk)
local Signal = require(ROOT.HelperModules.Signal)
local Timer = require(ROOT.HelperModules.Timer).new()

local bor = bit32.bor
local lshift = bit32.lshift
local extract = bit32.extract
local replace = bit32.replace
local byte = string.byte
local char = string.char
local floor = math.floor
local format = string.format

--[[**
	Converts 4 character bytes to integer by chaining them together
**--]]
local function charsToInt(bt0, bt1, bt2, bt3)
	return bor(lshift(bt0, 21), lshift(bt1, 14), lshift(bt2, 7), bt3)
end

--[[**
	Converts integer to string of character from the integer's four 8 bit segments
**--]]
local function intToChars(int)
	return char(
		extract(int, 21, 7),
		extract(int, 14, 7),
		extract(int, 7, 7),
		extract(int, 0, 7))
end

--[[**
	Iterates through a long string and gives integers formed from each set of 4 chars
	If input is not divisible by 4, ignores the remainder
	Returns intIndex (starts from 0), integerData
**--]]
local function stringIntIter(data)
	local size = string.len(data)
	local intIndex = -1
	
	return function()
		intIndex = intIndex + 1
		local ch = 4*intIndex + 1
		
		if ch+3 <= size then
			return intIndex, charsToInt(byte(data, ch, ch+3))
		end
	end
end


--[[**
	Chunk size is restricted by data store string storage
	Datastore only accepts UTF-8, which means ASCII characters ranging
	from \0 to \127. Therefore each char can store 7 bits instead of 8.
**--]]

local BITS = 7
local INT_BITS = 4*BITS
local MAX_UINT = 2^28 - 1

local CHUNK_DIM = INT_BITS
local CHUNK_ROW = 64
local CHUNK_COL = 8
local CHUNK_COUNT = CHUNK_ROW * CHUNK_COL
local CHUNK_TILES = CHUNK_DIM * CHUNK_DIM

local MAP_X = CHUNK_DIM * CHUNK_COL
local MAP_Y = CHUNK_DIM * CHUNK_ROW

local TILE_SIZE = 4


local function inBounds(x, y)
	if x < 0 or y < 0 or x >= MAP_X or y >= MAP_Y then
		return false
	end
	return true
end

local function tileToChunkCoordinates(x, y)
	return
		math.floor(x/CHUNK_DIM),
		math.floor(y/CHUNK_DIM)
end

local function wrapTileCoordinates(x, y)
	return
		x % CHUNK_DIM,
		y % CHUNK_DIM
end


local WorldData = {
	BITS = BITS,
	INT_BITS = INT_BITS,
	MAX_UINT = MAX_UINT,

	CHUNK_DIM = CHUNK_DIM,
	CHUNK_ROW = CHUNK_ROW,
	CHUNK_COL = CHUNK_COL,
	CHUNK_COUNT = CHUNK_COUNT,
	CHUNK_TILES = CHUNK_TILES,

	MAP_X = MAP_X,
	MAP_Y = MAP_Y,

	TILE_SIZE = TILE_SIZE,

	tileToChunkCoordinates = tileToChunkCoordinates,
	wrapTileCoordinates = wrapTileCoordinates,
}

WorldData.__index = WorldData

function WorldData.new(terrainGenerator)
	local self = {
		terrainGenerator = terrainGenerator,

		tileChunks = Chunk.new(CHUNK_COL, CHUNK_ROW),
		binaryChunks = Chunk.new(CHUNK_COL, CHUNK_ROW),

		tileChangedSignal = Signal(),
		presenceChangedSignal = Signal(),
	}

	self.tileChanged = self.tileChangedSignal:GetEvent()
	self.presenceChanged = self.presenceChangedSignal:GetEvent()

	setmetatable(self, WorldData)
	
	self:initBinary()
	return self
end


function WorldData:initBinary()
	for x, y in self.binaryChunks:horizontalIterator() do
		self.binaryChunks:set(x, y, BinaryChunk.new(CHUNK_DIM, CHUNK_DIM, 0))
	end
end


-- need bound and nil checks for getters and setters
function WorldData:getTile(x, y)
	local chunk = self.tileChunks:get(tileToChunkCoordinates(x, y))
	return chunk:get(wrapTileCoordinates(x, y))
end

function WorldData:getPresence(x, y)
	local chunk = self.binaryChunks:get(tileToChunkCoordinates(x, y))
	return chunk:get(wrapTileCoordinates(x, y)) == 0
end

function WorldData:setTile(x, y, tileId)
	local chunk = self.tileChunks:get(tileToChunkCoordinates(x, y))
	local tx, ty = wrapTileCoordinates(x, y)
	chunk:set(tx, ty, tileId)
	self.tileChangedSignal:Fire(x, y, tileId)
end

function WorldData:setPresence(x, y, presence)
	local chunk = self.binaryChunks:get(tileToChunkCoordinates(x, y))
	local tx, ty = wrapTileCoordinates(x, y)
	chunk:set(tx, ty, presence)
	self.presenceChangedSignal:Fire(x, y, presence)
end


function WorldData:setTerrainGenerator(generator)
	self.terrainGenerator = generator
end


function WorldData:loadBinaryDataString(dataString)
	local chunkBuffer = {}
	for index, int in stringIntIter(dataString) do
		local chunkX = floor(index/CHUNK_DIM) % CHUNK_COL
		local chunkY = floor(index/MAP_X)
		
		table.insert(chunkBuffer, int)
		
		if index % CHUNK_DIM == CHUNK_DIM-1 then --end of chunk
			self.binaryChunks:set(chunkX, chunkY, BinaryChunk.new(
					CHUNK_DIM,
					CHUNK_DIM,
					chunkBuffer))
			
			chunkBuffer = {}
		end
	end
end

function WorldData:binaryDataToString()
	local saveStringBuffer = {}
	
	for _, _, chunk in self.binaryChunks:horizontalIterator() do
		for int in chunk:intIterator() do
			table.insert(saveStringBuffer, intToChars(int))
		end
	end
	
	return table.concat(saveStringBuffer)
end

function WorldData:generateChunk(x, y)
	local tileChunk = Chunk.new(CHUNK_DIM, CHUNK_DIM)
	
	Timer:tick("Chunk gen")
	for tx, ty in tileChunk:horizontalIterator() do
		tileChunk:set(tx, ty, self.terrainGenerator:generateTile(
				x*CHUNK_DIM + tx,
				y*CHUNK_DIM + ty))
	end
	Timer:tock()
	
	self.tileChunks:set(x, y, tileChunk)
	return tileChunk
end

function WorldData:loadChunk(x, y)
	local chunk = self.tileChunks:get(x, y)
	if chunk == nil then
		chunk = self:generateChunk(x, y)
	end
	
	return chunk
end

function WorldData:getTileChunk(x, y)
	return self:loadChunk(tileToChunkCoordinates(x, y))
end

function WorldData:unloadChunk(x, y)
	--lets just keep it in memory instead for now, but fire event so terrain is hidden
end


return WorldData