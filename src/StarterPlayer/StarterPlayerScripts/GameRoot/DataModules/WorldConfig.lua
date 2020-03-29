


--[[
	Chunk size is restricted by data store string storage
	Datastore only accepts UTF-8, which means ASCII characters ranging
	from \0 to \127. Therefore each char can store 7 bits instead of 8.
--]]
local BITS = 7
local MAX_UINT = 2^28 - 1 --ignoring the first 4 bits

local CHUNK_DIM = 4*BITS --4 chars form an integer
local CHUNK_ROW = 64
local CHUNK_COL = 8
local CHUNK_COUNT = CHUNK_ROW * CHUNK_COL  --512
local CHUNK_TILES = CHUNK_DIM * CHUNK_DIM

local MAP_X = CHUNK_DIM * CHUNK_COL  --224
local MAP_Y = CHUNK_DIM * CHUNK_ROW  --1792

local TILE_SIZE = 4



local floor = math.floor

-- Converts (chunkIndex) -> (chunkX, chunkY)
local function chunkIndexToXY(index)
	return (index-1) % CHUNK_COL, floor((index-1)/CHUNK_COL)
end
-- Converts (chunkX, chunkY) -> (chunkIndex)
local function chunkXYtoIndex(x, y)
	return 1 + y*CHUNK_COL + x
end


-- Converts (tileIndex) -> (tileX, tileY)
local function tileIndexToXY(index)
	return (index-1) % CHUNK_DIM, floor((index-1)/CHUNK_DIM)
end
-- Converts (tileX, tileY) -> (tileIndex)
local function tileXYtoIndex(x, y)
	return 1 + (y % CHUNK_DIM)*CHUNK_DIM + (x % CHUNK_DIM)
end




-- Converts (tileX, tileY) -> (chunkIndex)
local function tileXYtoChunkIndex(x, y)
	return chunkXYtoIndex(floor(x/CHUNK_DIM), floor(y/CHUNK_DIM))
end
-- Converts (tileX, tileY) -> (chunkX, chunkY)
local function tileXYtoChunkXY(x, y)
	return floor(x/CHUNK_DIM), floor(y/CHUNK_DIM)
end



-- Is this one useless?????

-- Converts (tileX, tileY) -> (binaryX, binaryY)
local function tileXYtoBinaryXY(x, y)
	return x % CHUNK_DIM, y % CHUNK_DIM + 1
end



return 
{
	BITS = BITS,
	MAX_UINT = MAX_UINT,
	
	CHUNK_DIM = CHUNK_DIM,
	CHUNK_ROW = CHUNK_ROW,
	CHUNK_COL = CHUNK_COL,
	CHUNK_COUNT = CHUNK_COUNT,
	CHUNK_TILES = CHUNK_TILES,
	
	MAP_X = MAP_X,
	MAP_Y = MAP_Y,
	TILE_SIZE = TILE_SIZE,
	
	chunkIndexToXY = chunkIndexToXY,
	chunkXYtoIndex = chunkXYtoIndex,
	
	tileIndexToXY = tileIndexToXY,
	tileXYtoIndex = tileXYtoIndex,
	
	tileXYtoChunkIndex = tileXYtoChunkIndex,
	tileXYtoChunkXY = tileXYtoChunkXY,
	
	tileXYtoBinaryXY = tileXYtoBinaryXY,
}
